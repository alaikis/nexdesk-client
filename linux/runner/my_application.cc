#include "my_application.h"
#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#include <X11/Xlib.h>
#include <X11/extensions/XShm.h>
#include <X11/extensions/XTest.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include <jpeglib.h>
#include <setjmp.h>

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Screen capture state
static Display* g_display = nullptr;
static Window g_root_window = 0;
static XShmSegmentInfo g_shm_info;
static bool g_capturing = false;
static FlMethodChannel* g_capture_channel = nullptr;
static FlMethodChannel* g_input_channel = nullptr;
static guint g_capture_timer = 0;
static int g_screen_width = 0;
static int g_screen_height = 0;

// JPEG error handler
struct my_error_mgr {
  struct jpeg_error_mgr pub;
  jmp_buf setjmp_buffer;
};

static void my_error_exit(j_common_ptr cinfo) {
  struct my_error_mgr* myerr = (struct my_error_mgr*)cinfo->err;
  longjmp(myerr->setjmp_buffer, 1);
}

// Encode RGB to JPEG
static uint8_t* encode_jpeg(uint8_t* rgb, int width, int height, int quality, unsigned long* out_size) {
  struct jpeg_compress_struct cinfo;
  struct my_error_mgr jerr;
  JSAMPROW row_pointer[1];
  uint8_t* out_buffer = nullptr;

  cinfo.err = jpeg_std_error(&jerr.pub);
  jerr.pub.error_exit = my_error_exit;

  if (setjmp(jerr.setjmp_buffer)) {
    jpeg_destroy_compress(&cinfo);
    return nullptr;
  }

  jpeg_create_compress(&cinfo);

  out_buffer = nullptr;
  jpeg_mem_dest(&cinfo, &out_buffer, out_size);

  cinfo.image_width = width;
  cinfo.image_height = height;
  cinfo.input_components = 3;
  cinfo.in_color_space = JCS_RGB;

  jpeg_set_defaults(&cinfo);
  jpeg_set_quality(&cinfo, quality, TRUE);
  jpeg_start_compress(&cinfo, TRUE);

  while (cinfo.next_scanline < cinfo.image_height) {
    row_pointer[0] = &rgb[cinfo.next_scanline * width * 3];
    jpeg_write_scanlines(&cinfo, row_pointer, 1);
  }

  jpeg_finish_compress(&cinfo);
  jpeg_destroy_compress(&cinfo);

  return out_buffer;
}

static void capture_frame() {
  if (!g_capturing || !g_display) return;

  // Capture screen using XShm
  XShmGetImage(g_display, g_root_window, g_shm_info.shminfo.shmaddr, 0, 0, AllPlanes);

  // Convert XImage to RGB
  XImage* img = g_shm_info.shminfo.shmaddr;
  int width = img->width;
  int height = img->height;

  uint8_t* rgb = (uint8_t*)malloc(width * height * 3);
  if (!rgb) return;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      unsigned long pixel = XGetPixel(img, x, y);
      rgb[(y * width + x) * 3 + 0] = (pixel >> 16) & 0xFF; // R
      rgb[(y * width + x) * 3 + 1] = (pixel >> 8) & 0xFF;  // G
      rgb[(y * width + x) * 3 + 2] = pixel & 0xFF;         // B
    }
  }

  // Encode to JPEG
  unsigned long jpeg_size = 0;
  uint8_t* jpeg_data = encode_jpeg(rgb, width, height, 80, &jpeg_size);
  free(rgb);

  if (jpeg_data) {
    // Base64 encode
    static const char base64_chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    int base64_len = 4 * ((jpeg_size + 2) / 3);
    char* base64 = (char*)malloc(base64_len + 1);
    if (base64) {
      int i = 0, j = 0;
      unsigned char char_array_3[3], char_array_4[4];
      while (jpeg_size--) {
        char_array_3[i++] = *(jpeg_data++);
        if (i == 3) {
          char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
          char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
          char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
          char_array_4[3] = char_array_3[2] & 0x3f;
          for (i = 0; i < 4; i++) base64[j++] = base64_chars[char_array_4[i]];
          i = 0;
        }
      }
      if (i) {
        for (int k = i; k < 3; k++) char_array_3[k] = '\0';
        char_array_4[0] = (char_array_3[0] & 0xfc) >> 2;
        char_array_4[1] = ((char_array_3[0] & 0x03) << 4) + ((char_array_3[1] & 0xf0) >> 4);
        char_array_4[2] = ((char_array_3[1] & 0x0f) << 2) + ((char_array_3[2] & 0xc0) >> 6);
        for (int k = 0; k < i + 1; k++) base64[j++] = base64_chars[char_array_4[k]];
        while (i++ < 3) base64[j++] = '=';
      }
      base64[j] = '\0';

      // Send frame to Flutter
      g_autoptr(FlValue) result = fl_value_new_map();
      fl_value_set_string_take(result, "data", fl_value_new_string(base64));
      fl_value_set_string_take(result, "width", fl_value_new_int(width));
      fl_value_set_string_take(result, "height", fl_value_new_int(height));
      fl_value_set_string_take(result, "timestamp", fl_value_new_int(g_get_monotonic_time() / 1000));

      fl_method_channel_invoke_method(g_capture_channel, "onFrame", result, nullptr, nullptr, nullptr);
      free(base64);
    }
    free(jpeg_data);
  }
}

static bool init_x11() {
  g_display = XOpenDisplay(nullptr);
  if (!g_display) return false;

  g_root_window = DefaultRootWindow(g_display);
  int screen = DefaultScreen(g_display);
  g_screen_width = DisplayWidth(g_display, screen);
  g_screen_height = DisplayHeight(g_display, screen);

  // Setup XShm
  g_shm_info.shmid = shmget(IPC_PRIVATE, g_screen_width * g_screen_height * 4, IPC_CREAT | 0777);
  if (g_shm_info.shmid == -1) return false;

  g_shm_info.shmaddr = (char*)shmat(g_shm_info.shmid, 0, 0);
  g_shm_info.readOnly = False;

  return XShmAttach(g_display, &g_shm_info);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window = GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "NEX");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "NEX");
  }

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb), self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Setup screen capture method channel
  g_autoptr(FlEngine) engine = fl_view_get_engine(view);
  g_autoptr(FlBinaryMessenger) messenger = fl_engine_get_binary_messenger(engine);

  g_capture_channel = fl_method_channel_new(messenger, "nex.flutter/screen_capture", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_handler(g_capture_channel, [](FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
    g_autoptr(FlValue) result = nullptr;
    const gchar* method = fl_method_call_get_name(method_call);

    if (g_strcmp0(method, "requestPermission") == 0) {
      result = fl_value_new_bool(true);
    } else if (g_strcmp0(method, "getScreenSize") == 0) {
      result = fl_value_new_map();
      if (g_display) {
        fl_value_set_string_take(result, "width", fl_value_new_int(DisplayWidth(g_display, DefaultScreen(g_display))));
        fl_value_set_string_take(result, "height", fl_value_new_int(DisplayHeight(g_display, DefaultScreen(g_display))));
        fl_value_set_string_take(result, "scale", fl_value_new_float(1.0));
      }
    } else if (g_strcmp0(method, "startCapture") == 0) {
      if (!g_display) init_x11();
      g_capturing = true;
      g_capture_timer = g_timeout_add(33, (GSourceFunc)capture_frame, nullptr); // ~30fps
      result = fl_value_new_bool(true);
    } else if (g_strcmp0(method, "stopCapture") == 0) {
      g_capturing = false;
      if (g_capture_timer) {
        g_source_remove(g_capture_timer);
        g_capture_timer = 0;
      }
      result = fl_value_new_bool(true);
    }

    fl_method_call_respond(method_call, result, nullptr);
  }, nullptr, nullptr);

  // Input injection channel
  g_input_channel = fl_method_channel_new(messenger, "nex.flutter/input_injector", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_handler(g_input_channel, [](FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
    const gchar* method = fl_method_call_get_name(method_call);

    if (g_strcmp0(method, "injectMouseEvent") == 0) {
      FlValue* args = fl_method_call_get_args(method_call);
      double x = fl_value_get_float(fl_value_lookup_string(args, "x"));
      double y = fl_value_get_float(fl_value_lookup_string(args, "y"));
      int button = fl_value_get_int(fl_value_lookup_string(args, "button"));
      int action = fl_value_get_int(fl_value_lookup_string(args, "action"));

      if (g_display) {
        XTestFakeMotionEvent(g_display, DefaultScreen(g_display), (int)x, (int)y, CurrentTime);
        XTestFakeButtonEvent(g_display, button + 1, action == 1, CurrentTime);
        XFlush(g_display);
      }
    } else if (g_strcmp0(method, "injectKey") == 0) {
      FlValue* args = fl_method_call_get_args(method_call);
      int keyCode = fl_value_get_int(fl_value_lookup_string(args, "keyCode"));
      bool down = fl_value_get_bool(fl_value_lookup_string(args, "down"));

      if (g_display) {
        XTestFakeKeyEvent(g_display, keyCode, down, CurrentTime);
        XFlush(g_display);
      }
    }

    g_autoptr(FlValue) result = fl_value_new_bool(true);
    fl_method_call_respond(method_call, result, nullptr);
  }, nullptr, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;
  return TRUE;
}

static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  if (g_display) {
    XCloseDisplay(g_display);
    g_display = nullptr;
  }
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                      "application-id", APPLICATION_ID, "flags",
                                      G_APPLICATION_NON_UNIQUE, nullptr));
}
