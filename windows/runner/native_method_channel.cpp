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
    // DXGI Desktop Duplication is available on Windows 8.1+
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

void HandleRemoteInput(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& args = call.arguments();
  const auto as_map = [&](const flutter::EncodableValue& v) -> const flutter::EncodableMap* {
    return std::get_if<flutter::EncodableMap>(&v);
  };
  const auto get_int = [&](const flutter::EncodableMap& m, const char* key) -> int {
    auto it = m.find(flutter::EncodableValue(key));
    if (it == m.end()) return 0;
    if (const auto* i = std::get_if<int>(&it->second)) return *i;
    if (const auto* l = std::get_if<int64_t>(&it->second)) return static_cast<int>(*l);
    if (const auto* d = std::get_if<double>(&it->second)) return static_cast<int>(*d);
    return 0;
  };
  const auto get_bool = [&](const flutter::EncodableMap& m, const char* key) -> bool {
    auto it = m.find(flutter::EncodableValue(key));
    if (it == m.end()) return false;
    return std::get<bool>(it->second);
  };

  if (call.method_name() == "injectMouseMove") {
    const auto* m = as_map(args);
    if (!m) { result->Success(); return; }
    int x = get_int(*m, "x");
    int y = get_int(*m, "y");
    bool absolute = get_bool(*m, "absolute");
    INPUT in = {};
    in.type = INPUT_MOUSE;
    in.mi.dwFlags = absolute ? MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE : MOUSEEVENTF_MOVE;
    // Normalize to absolute virtual-screen coords if needed
    int sw = GetSystemMetrics(SM_CXVIRTUALSCREEN);
    int sh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
    int vx = GetSystemMetrics(SM_XVIRTUALSCREEN);
    int vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
    if (absolute) {
      in.mi.dx = (x - vx) * 65535 / sw;
      in.mi.dy = (y - vy) * 65535 / sh;
    } else {
      in.mi.dx = x;
      in.mi.dy = y;
    }
    SendInput(1, &in, sizeof(INPUT));
    result->Success();
  } else if (call.method_name() == "injectMouseButton") {
    const auto* m = as_map(args);
    if (!m) { result->Success(); return; }
    int button = get_int(*m, "button");
    bool down = get_bool(*m, "down");
    INPUT in = {};
    in.type = INPUT_MOUSE;
    in.mi.dwFlags = 0;
    if (button == 0) in.mi.dwFlags = down ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_LEFTUP;
    else if (button == 1) in.mi.dwFlags = down ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_RIGHTUP;
    else in.mi.dwFlags = down ? MOUSEEVENTF_MIDDLEDOWN : MOUSEEVENTF_MIDDLEUP;
    SendInput(1, &in, sizeof(INPUT));
    result->Success();
  } else if (call.method_name() == "injectMouseWheel") {
    const auto* m = as_map(args);
    if (!m) { result->Success(); return; }
    int delta = get_int(*m, "delta");
    INPUT in = {};
    in.type = INPUT_MOUSE;
    in.mi.dwFlags = MOUSEEVENTF_WHEEL;
    in.mi.mouseData = delta * WHEEL_DELTA / 120;
    SendInput(1, &in, sizeof(INPUT));
    result->Success();
  } else if (call.method_name() == "injectKey") {
    const auto* m = as_map(args);
    if (!m) { result->Success(); return; }
    int scanCode = get_int(*m, "scanCode");
    bool down = get_bool(*m, "down");
    bool extended = get_bool(*m, "extended");
    INPUT in = {};
    in.type = INPUT_KEYBOARD;
    in.ki.wScan = static_cast<WORD>(scanCode & 0xFFFF);
    in.ki.dwFlags = KEYEVENTF_SCANCODE;
    if (extended) in.ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;
    if (!down) in.ki.dwFlags |= KEYEVENTF_KEYUP;
    SendInput(1, &in, sizeof(INPUT));
    result->Success();
  } else if (call.method_name() == "injectUnicode") {
    const auto* m = as_map(args);
    if (!m) { result->Success(); return; }
    auto it = m->find(flutter::EncodableValue("text"));
    if (it == m->end()) { result->Success(); return; }
    const auto& str = std::get<std::string>(it->second);
    // Convert UTF-8 to UTF-16 for SendInput Unicode
    int len = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, nullptr, 0);
    std::wstring wstr(len, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, wstr.data(), len);
    // Send each char as Unicode down + up pair
    for (size_t i = 0; i < wstr.size(); i++) {
      if (wstr[i] == L'\0') continue;
      INPUT inputs[2] = {};
      inputs[0].type = INPUT_KEYBOARD;
      inputs[0].ki.wScan = static_cast<WORD>(wstr[i]);
      inputs[0].ki.dwFlags = KEYEVENTF_UNICODE;
      inputs[1].type = INPUT_KEYBOARD;
      inputs[1].ki.wScan = static_cast<WORD>(wstr[i]);
      inputs[1].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
      SendInput(2, inputs, sizeof(INPUT));
    }
    result->Success();
  } else if (call.method_name() == "setModifiers") {
    const auto* m = as_map(args);
    if (!m) { result->Success(); return; }
    // Set current modifier state via keybd_event / SendInput
    // Simple approach: send key-down for active modifiers, key-up for inactive
    struct Mod {
      const char* key;
      WORD vk;
    } mods[] = {
        {"ctrl", VK_CONTROL},
        {"alt", VK_MENU},
        {"shift", VK_SHIFT},
        {"win", VK_LWIN},
    };
    // Read current GetAsyncKeyState for each and only send deltas
    INPUT inputs[4];
    int n = 0;
    for (auto& mo : mods) {
      bool want = get_bool(*m, mo.key);
      bool isDown = (GetAsyncKeyState(mo.vk) & 0x8000) != 0;
      if (want != isDown && n < 4) {
        inputs[n].type = INPUT_KEYBOARD;
        inputs[n].ki.wVk = mo.vk;
        inputs[n].ki.dwFlags = want ? 0 : KEYEVENTF_KEYUP;
        n++;
      }
    }
    if (n > 0) {
      SendInput(n, inputs, sizeof(INPUT));
    }
    result->Success();
  } else {
    result->NotImplemented();
  }
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
      messenger, "nex.flutter/input_inject_windows",
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
