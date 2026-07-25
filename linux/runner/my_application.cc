#include "my_application.h"
#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#include <X11/Xlib.h>
#include <X11/extensions/XShm.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#endif

#include "flutter/generated_plugin_registrant.h"

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

static void capture_frame() {
  if (!g_capturing || !g_display) return;

  Window root;
  int x, y;
  unsigned int width, height, border, depth;
  XGetGeometry(g_display, g_root_window, &root, &x, &y, &width, &height, &border, &depth);

  // Capture screen using XShm
  XShmGetImage(g_display, g_root_window, g_shm_info.shmaddr, 0, 0, AllPlanes);

  // Convert to JPEG and send to Flutter (simplified - just send raw dimensions)
  // In production, you'd convert to JPEG/PNG and send base64
  g_autoptr(FlValue) result = fl_value_new_map();
  fl_value_set_string_take(result, "width", fl_value_new_int(width));
  fl_value_set_string_take(result, "height", fl_value_new_int(height));
  fl_value_set_string_take(result, "timestamp", fl_value_new_int(g_get_monotonic_time() / 1000));

  fl_method_channel_invoke_method(g_capture_channel, "onFrame", result, nullptr, nullptr, nullptr);
}

static void init_x11() {
  g_display = XOpenDisplay(nullptr);
  if (!g_display) return;

  g_root_window = DefaultRootWindow(g_display);

  // Setup XShm
  int screen = DefaultScreen(g_display);
  XVisualInfo vis;
  XMatchVisualInfo(g_display, screen, 24, TrueColor, &vis);

  g_shm_info.shmid = shmget(IPC_PRIVATE, DisplayWidth(g_display, screen) * DisplayHeight(g_display, screen)  * 4, IPC_CREAT | 0777);
  g_shm_info.shmaddr = (char*)shmat(g_shm_info.shmid, 0, 0);
  g_shm_info.readOnly = False;

  XShmAttach(g_display, &g_shm_info);
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
