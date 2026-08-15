#include "my_application.h"
#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlView* fl_view;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void on_drag_motion(GtkWidget* widget, GdkDragContext* context, gint x, gint y, guint time, gpointer user_data) {
    MyApplication* self = MY_APPLICATION(user_data);
    if (self->fl_view && fl_view_get_engine(self->fl_view)) {
        FlMethodChannel* channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(self->fl_view)), "nex.flutter/drag_drop", fl_method_codec_standard_method_codec_get());
        fl_method_channel_invoke_method(channel, "onDragEnter", nullptr, nullptr, nullptr, nullptr);
        g_object_unref(channel);
    }
    gdk_drag_status(context, GDK_ACTION_COPY, time);
}

static void on_drag_leave(GtkWidget* widget, GdkDragContext* context, guint time, gpointer user_data) {
    MyApplication* self = MY_APPLICATION(user_data);
    if (self->fl_view && fl_view_get_engine(self->fl_view)) {
        FlMethodChannel* channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(self->fl_view)), "nex.flutter/drag_drop", fl_method_codec_standard_method_codec_get());
        fl_method_channel_invoke_method(channel, "onDragLeave", nullptr, nullptr, nullptr, nullptr);
        g_object_unref(channel);
    }
}

static void on_drag_data_received(GtkWidget* widget, GdkDragContext* context, gint x, gint y, GtkSelectionData* selection_data, guint info, guint time, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  gchar** uris = gtk_selection_data_get_uris(selection_data);
  if (!uris) {
    gtk_drag_finish(context, FALSE, FALSE, time);
    return;
  }

  GPtrArray* files = g_ptr_array_new();
  gint64 total_size = 0;

  for (int i = 0; uris[i] != nullptr; i++) {
    gchar* uri = uris[i];
    if (g_str_has_prefix(uri, "file://")) {
      gchar* path = g_filename_from_uri(uri, nullptr, nullptr);
      if (path) {
        g_ptr_array_add(files, path);
        GFile* file = g_file_new_for_path(path);
        GFileInfo* info = g_file_query_info(file, G_FILE_ATTRIBUTE_STANDARD_SIZE, G_FILE_QUERY_INFO_NONE, nullptr, nullptr);
        if (info) {
          total_size += g_file_info_get_size(info);
          g_object_unref(info);
        }
        g_object_unref(file);
      }
    }
    g_free(uri);
  }
  g_free(uris);

  if (files->len > 0 && self->fl_view && fl_view_get_engine(self->fl_view)) {
    FlMethodChannel* channel = fl_method_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(self->fl_view)), "nex.flutter/drag_drop", fl_method_codec_standard_method_codec_get());

    GVariantBuilder list_builder;
    g_variant_builder_init(&list_builder, G_VARIANT_TYPE("as"));
    for (guint i = 0; i < files->len; i++) {
      g_variant_builder_add_value(&list_builder, g_variant_new_string((const gchar*)g_ptr_array_index(files, i)));
    }

    GVariant* args = g_variant_new("(asi)", g_variant_builder_end(&list_builder), total_size);
    fl_method_channel_invoke_method(channel, "onFilesDropped", args, nullptr, nullptr, nullptr);
    g_object_unref(channel);
  }

  for (guint i = 0; i < files->len; i++) {
    g_free(g_ptr_array_index(files, i));
  }
  g_ptr_array_free(files, TRUE);

  gtk_drag_finish(context, TRUE, FALSE, time);
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

  self->fl_view = view;

  GtkTargetEntry target = {"text/uri-list", GTK_TARGET_OTHER_APP, 0};
  gtk_drag_dest_set(GTK_WIDGET(window), GTK_DEST_DEFAULT_ALL, &target, 1, GDK_ACTION_COPY);
  g_signal_connect(window, "drag-motion", G_CALLBACK(on_drag_motion), self);
  g_signal_connect(window, "drag-leave", G_CALLBACK(on_drag_leave), self);
  g_signal_connect(window, "drag-data-received", G_CALLBACK(on_drag_data_received), self);

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

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
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
