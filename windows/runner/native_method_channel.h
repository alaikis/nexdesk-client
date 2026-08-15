#ifndef RUNNER_NATIVE_METHOD_CHANNEL_H_
#define RUNNER_NATIVE_METHOD_CHANNEL_H_

#include <windows.h>
#include <flutter/flutter_view_controller.h>
#include <string>
#include <vector>

class NativeMethodChannel {
 public:
  static void Register(flutter::FlutterViewController* controller);
  static void InvokeDragDrop(const std::vector<std::string>& files, int totalSize);
  static void InvokeDragDropStatus(int status);
  class DropTarget;
};

extern NativeMethodChannel::DropTarget* g_drop_target;

#endif  // RUNNER_NATIVE_METHOD_CHANNEL_H_
