#include "native_method_channel.h"
#include "resource.h"

#include <flutter/flutter_view_controller.h>
#include <flutter/standard_method_codec.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>

#include <windows.h>
#include <shellapi.h>

namespace {

flutter::FlutterViewController* g_flutter_controller = nullptr;
HANDLE g_single_instance_mutex = nullptr;
NOTIFYICONDATAW g_tray_icon = {0};
HWND g_message_window = nullptr;
bool g_tray_created = false;

#define WM_TRAYICON (WM_USER + 100)

static HICON LoadAppIcon() {
  HINSTANCE hInst = GetModuleHandleW(nullptr);
  return static_cast<HICON>(LoadImageW(hInst, MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR));
}

LRESULT CALLBACK MessageWindowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
  if (msg == WM_TRAYICON) {
    if (lp == WM_LBUTTONDBLCLK || lp == WM_LBUTTONUP) {
      if (g_flutter_controller) {
        const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
        flutter::MethodChannel<flutter::EncodableValue> channel(
            g_flutter_controller->engine()->messenger(), "nex.flutter/system_tray_windows",
            static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
        channel.InvokeMethod("tray_click", nullptr);
      }
    } else if (lp == WM_RBUTTONUP) {
      HMENU menu = CreatePopupMenu();
      AppendMenuW(menu, MF_STRING, 1, L"Show");
      AppendMenuW(menu, MF_STRING, 2, L"Quit");
      POINT pt;
      GetCursorPos(&pt);
      SetForegroundWindow(hwnd);
      int cmd = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_NONOTIFY, pt.x, pt.y, 0, hwnd, nullptr);
      DestroyMenu(menu);
      if (cmd == 1 && g_flutter_controller) {
        const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
        flutter::MethodChannel<flutter::EncodableValue> channel(
            g_flutter_controller->engine()->messenger(), "nex.flutter/system_tray_windows",
            static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
        channel.InvokeMethod("tray_restore", nullptr);
      } else if (cmd == 2 && g_flutter_controller) {
        const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
        flutter::MethodChannel<flutter::EncodableValue> channel(
            g_flutter_controller->engine()->messenger(), "nex.flutter/system_tray_windows",
            static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
        channel.InvokeMethod("tray_quit", nullptr);
      }
    }
  }
  return DefWindowProc(hwnd, msg, wp, lp);
}

void CreateMessageWindow() {
  WNDCLASSW wc = {0};
  wc.lpfnWndProc = MessageWindowProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.lpszClassName = L"LitchiViewerTrayHelper";
  RegisterClassW(&wc);
  g_message_window = CreateWindowW(L"LitchiViewerTrayHelper", L"", 0, 0, 0, 0, 0, nullptr, nullptr, wc.hInstance, nullptr);
}

void HandleSingleInstance(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "ensureSingleInstance") {
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

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
  if (call.method_name() == "init") {
    if (!g_message_window) CreateMessageWindow();
    g_tray_icon.cbSize = sizeof(NOTIFYICONDATAW);
    g_tray_icon.hWnd = g_message_window;
    g_tray_icon.uID = 1;
    g_tray_icon.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
    g_tray_icon.uCallbackMessage = WM_TRAYICON;
    g_tray_icon.hIcon = LoadAppIcon();
    wcscpy_s(g_tray_icon.szTip, L"LitchiViewer");
    g_tray_created = Shell_NotifyIconW(NIM_ADD, &g_tray_icon) != 0;
    result->Success();
  } else if (call.method_name() == "show") {
    if (g_tray_created || !g_message_window) {
      if (!g_message_window) CreateMessageWindow();
      g_tray_icon.cbSize = sizeof(NOTIFYICONDATAW);
      g_tray_icon.hWnd = g_message_window;
      g_tray_icon.uID = 1;
      g_tray_icon.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
      g_tray_icon.uCallbackMessage = WM_TRAYICON;
      g_tray_icon.hIcon = LoadAppIcon();
      wcscpy_s(g_tray_icon.szTip, L"LitchiViewer");
      g_tray_created = Shell_NotifyIconW(NIM_ADD, &g_tray_icon) != 0;
    }
    result->Success();
  } else if (call.method_name() == "hide") {
    if (g_tray_created) {
      Shell_NotifyIconW(NIM_DELETE, &g_tray_icon);
      g_tray_created = false;
    }
    result->Success();
  } else if (call.method_name() == "destroy") {
    if (g_tray_created) {
      Shell_NotifyIconW(NIM_DELETE, &g_tray_icon);
      g_tray_created = false;
    }
    result->Success();
  } else if (call.method_name() == "toggle") {
    result->Success();
  } else {
    result->NotImplemented();
  }
}

}  // namespace

void NativeMethodChannel::Register(flutter::FlutterViewController* controller) {
  const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
  auto messenger = controller->engine()->messenger();
  g_flutter_controller = controller;

  flutter::MethodChannel<flutter::EncodableValue> single_instance_channel(
      messenger, "nex.flutter/single_instance",
      static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
  single_instance_channel.SetMethodCallHandler(HandleSingleInstance);

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
