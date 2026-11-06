#include "native_method_channel.h"

#include <flutter/flutter_view_controller.h>
#include <flutter/standard_method_codec.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>

#include <windows.h>

namespace {

flutter::FlutterViewController* g_flutter_controller = nullptr;

void HandleScreenCapture(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "isSupported") {
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

void HandleRemoteInput(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  result->NotImplemented();
}

void HandleSystemTray(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  result->NotImplemented();
}

}  // namespace

void NativeMethodChannel::Register(flutter::FlutterViewController* controller) {
  const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
  auto messenger = controller->engine()->messenger();
  g_flutter_controller = controller;

  flutter::MethodChannel<flutter::EncodableValue> screen_channel(
      messenger, "nex.flutter/screen_capture_windows",
      static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
  screen_channel.SetMethodCallHandler(HandleScreenCapture);

  flutter::MethodChannel<flutter::EncodableValue> input_channel(
      messenger, "nex.flutter/remote_input_windows",
      static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
  input_channel.SetMethodCallHandler(HandleRemoteInput);

  flutter::MethodChannel<flutter::EncodableValue> tray_channel(
      messenger, "nex.flutter/system_tray_windows",
      static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
  tray_channel.SetMethodCallHandler(HandleSystemTray);
}

void NativeMethodChannel::InvokeDragDrop(const std::vector<std::string>& files, int totalSize) {
  if (!g_flutter_controller) return;
  const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
  flutter::MethodChannel<flutter::EncodableValue> channel(
      g_flutter_controller->engine()->messenger(), "nex.flutter/drag_drop",
      static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));

  flutter::EncodableList fileList;
  for (const auto& f : files) {
    fileList.push_back(flutter::EncodableValue(f));
  }

  flutter::EncodableMap args;
  args[flutter::EncodableValue("files")] = flutter::EncodableValue(fileList);
  args[flutter::EncodableValue("totalSize")] = flutter::EncodableValue(totalSize);

  std::unique_ptr<flutter::EncodableValue> args_ptr =
      std::make_unique<flutter::EncodableValue>(args);
  channel.InvokeMethod("onFilesDropped", std::move(args_ptr));
}

void NativeMethodChannel::InvokeDragDropStatus(int status) {
  if (!g_flutter_controller) return;
  const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
  flutter::MethodChannel<flutter::EncodableValue> channel(
      g_flutter_controller->engine()->messenger(), "nex.flutter/drag_drop",
      static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));

  channel.InvokeMethod(status == 1 ? "onDragEnter" : "onDragLeave", nullptr);
}
