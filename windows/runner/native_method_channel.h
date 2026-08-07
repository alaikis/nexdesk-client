#ifndef RUNNER_NATIVE_METHOD_CHANNEL_H_
#define RUNNER_NATIVE_METHOD_CHANNEL_H_

#include <flutter/flutter_view_controller.h>
#include <windows.h>

class NativeMethodChannel {
 public:
  static void Register(flutter::FlutterViewController* controller);
};

#endif  // RUNNER_NATIVE_METHOD_CHANNEL_H_
