#include "native_method_channel.h"

#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/standard_message_codec.h>

#include <windows.h>
#include <ole2.h>
#include <dxgi1_2.h>
#include <d3d11.h>
#include <vector>
#include <mutex>
#include <map>
#include <memory>
#include <string>
#include <shellapi.h>

#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")

#include "resource.h"

namespace {

enum DragDropStatus {
  kDragDropStatusIdle = 0,
  kDragDropStatusDragging = 1,
};

class DropTarget : public IDropTarget {
 public:
  DropTarget(HWND hwnd) : hwnd_(hwnd), ref_(1) {}

  ULONG __stdcall AddRef() override { return ++ref_; }
  ULONG __stdcall Release() override {
    ULONG r = --ref_;
    if (r == 0) delete this;
    return r;
  }
  HRESULT __stdcall QueryInterface(REFIID iid, void** ppvObject) override {
    if (iid == IID_IDropTarget || iid == IID_IUnknown) {
      *ppvObject = this;
      AddRef();
      return S_OK;
    }
    *ppvObject = nullptr;
    return E_NOINTERFACE;
  }

  HRESULT __stdcall DragEnter(IDataObject* pDataObj, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect) override {
    *pdwEffect = DROPEFFECT_COPY;
    NativeMethodChannel::InvokeDragDropStatus(kDragDropStatusDragging);
    return S_OK;
  }

  HRESULT __stdcall DragOver(DWORD grfKeyState, POINTL pt, DWORD* pdwEffect) override {
    *pdwEffect = DROPEFFECT_COPY;
    return S_OK;
  }

  HRESULT __stdcall DragLeave() override {
    NativeMethodChannel::InvokeDragDropStatus(kDragDropStatusIdle);
    return S_OK;
  }

  HRESULT __stdcall Drop(IDataObject* pDataObj, DWORD grfKeyState, POINTL pt, DWORD* pdwEffect) override {
    *pdwEffect = DROPEFFECT_COPY;

    FORMATETC fmt = { CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL };
    STGMEDIUM stg = {};
    if (SUCCEEDED(pDataObj->GetData(&fmt, &stg))) {
      HDROP drop = static_cast<HDROP>(GlobalLock(stg.hGlobal));
      if (drop) {
        UINT fileCount = DragQueryFile(drop, 0xFFFFFFFF, nullptr, 0);
        std::vector<std::string> files;
        int totalSize = 0;
        for (UINT i = 0; i < fileCount; ++i) {
          wchar_t path[MAX_PATH] = {0};
          if (DragQueryFile(drop, i, path, MAX_PATH)) {
            int utf8Size = WideCharToMultiByte(CP_UTF8, 0, path, -1, nullptr, 0, nullptr, nullptr);
            if (utf8Size > 0) {
              std::string utf8Path(utf8Size - 1, 0);
              WideCharToMultiByte(CP_UTF8, 0, path, -1, &utf8Path[0], utf8Size, nullptr, nullptr);
              files.push_back(utf8Path);
              WIN32_FILE_ATTRIBUTE_DATA fad;
              if (GetFileAttributesEx(path, GetFileExInfoStandard, &fad)) {
                ULARGE_INTEGER size;
                size.HighPart = fad.nFileSizeHigh;
                size.LowPart = fad.nFileSizeLow;
                totalSize += static_cast<int>(size.QuadPart);
              }
            }
          }
        }
        GlobalUnlock(stg.hGlobal);
        if (!files.empty()) {
          NativeMethodChannel::InvokeDragDrop(files, totalSize);
        }
      }
      ReleaseStgMedium(&stg);
    }

    NativeMethodChannel::InvokeDragDropStatus(kDragDropStatusIdle);
    return S_OK;
  }

 private:
  HWND hwnd_;
  LONG ref_;
};

flutter::FlutterViewController* g_flutter_controller = nullptr;
NativeMethodChannel::DropTarget* g_drop_target = nullptr;

// Window enumeration helpers
namespace {
BOOL CALLBACK EnumWindowsProc(HWND hwnd, LPARAM lParam) {
  if (!IsWindowVisible(hwnd)) return TRUE;
  int length = GetWindowTextLength(hwnd);
  if (length == 0) return TRUE;

  std::wstring title(length + 1, L'\0');
  GetWindowText(hwnd, &title[0], length + 1);
  title.resize(length);

  RECT rect;
  if (!GetWindowRect(hwnd, &rect)) return TRUE;
  int w = rect.right - rect.left;
  int h = rect.bottom - rect.top;
  if (w <= 0 || h <= 0) return TRUE;

  DWORD pid = 0;
  GetWindowThreadProcessId(hwnd, &pid);

  auto& windows = *reinterpret_cast<std::vector<flutter::EncodableValue>*>(lParam);
  flutter::EncodableMap win;
  win[flutter::EncodableValue("hwnd")] = flutter::EncodableValue(reinterpret_cast<int64_t>(hwnd));
  win[flutter::EncodableValue("title")] = flutter::EncodableValue(std::string(title.begin(), title.end()));
  win[flutter::EncodableValue("processId")] = flutter::EncodableValue(static_cast<int32_t>(pid));
  flutter::EncodableMap bounds;
  bounds[flutter::EncodableValue("x")] = flutter::EncodableValue(rect.left);
  bounds[flutter::EncodableValue("y")] = flutter::EncodableValue(rect.top);
  bounds[flutter::EncodableValue("width")] = flutter::EncodableValue(w);
  bounds[flutter::EncodableValue("height")] = flutter::EncodableValue(h);
  win[flutter::EncodableValue("bounds")] = flutter::EncodableValue(bounds);
  windows.push_back(flutter::EncodableValue(win));
  return TRUE;
}
}  // namespace

// System tray state
namespace {
NOTIFYICONDATA g_tray_data = {};
UINT g_tray_message_id = WM_USER + 100;
bool g_tray_initialized = false;
HWND g_tray_hwnd = nullptr;
}  // namespace

namespace {
flutter::FlutterViewController* g_flutter_controller = nullptr;
}  // namespace

void NativeMethodChannel::Register(flutter::FlutterViewController* controller) {
  const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
  auto messenger = controller->engine()->messenger();
  g_flutter_controller = controller;
  // Screen capture channel
  {
    flutter::MethodChannel<flutter::EncodableValue> channel(
        messenger,
        "nex.flutter/screen_capture_windows",
        static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
    channel.SetMethodCallHandler([](const flutter::MethodCall<flutter::EncodableValue>& call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
      if (call.method_name() == "enumerateDisplays") {
        // Return basic display info; full enumeration requires DXGI adapter walking.
        result->Success(flutter::EncodableValue(std::vector<flutter::EncodableValue>{
            flutter::EncodableValue(flutter::EncodableMap{
                {"index", flutter::EncodableValue(0)},
                {"name", flutter::EncodableValue("Primary Display")},
                {"width", flutter::EncodableValue(GetSystemMetrics(SM_CXSCREEN))},
                {"height", flutter::EncodableValue(GetSystemMetrics(SM_CYSCREEN))},
            })}));
      } else if (call.method_name() == "startCapture") {
        std::lock_guard<std::mutex> lock(g_capture_mutex);
        int displayIndex = 0;
        if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          auto it = args.find(flutter::EncodableValue("displayIndex"));
          if (it != args.end()) displayIndex = std::get<int32_t>(it->second);
        }
        ScreenCaptureState state;
        if (InitDXGICapture(displayIndex, state)) {
          int id = g_next_capture_id++;
          g_captures[id] = state;
          result->Success(flutter::EncodableValue(id));
        } else {
          result->Success(flutter::EncodableValue(-1));
        }
      } else if (call.method_name() == "stopCapture") {
        std::lock_guard<std::mutex> lock(g_capture_mutex);
        int textureId = -1;
        if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          auto it = args.find(flutter::EncodableValue("textureId"));
          if (it != args.end()) textureId = std::get<int32_t>(it->second);
        }
        auto it = g_captures.find(textureId);
        if (it != g_captures.end()) {
          CleanupCapture(it->second);
          g_captures.erase(it);
        }
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "getFrame") {
        std::lock_guard<std::mutex> lock(g_capture_mutex);
        int textureId = -1;
        if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          auto it = args.find(flutter::EncodableValue("textureId"));
          if (it != args.end()) textureId = std::get<int32_t>(it->second);
        }
        auto it = g_captures.find(textureId);
        if (it != g_captures.end()) {
          std::vector<uint8_t> pixels;
          if (CaptureFrame(it->second, pixels)) {
            result->Success(flutter::EncodableValue(flutter::EncodableList(
                pixels.begin(), pixels.end())));
            return;
          }
        }
        result->Success(flutter::EncodableValue(flutter::EncodableList()));
      } else if (call.method_name() == "getDirtyFrame") {
        std::lock_guard<std::mutex> lock(g_capture_mutex);
        int textureId = -1;
        if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          auto it = args.find(flutter::EncodableValue("textureId"));
          if (it != args.end()) textureId = std::get<int32_t>(it->second);
        }
        auto it = g_captures.find(textureId);
        if (it != g_captures.end()) {
          std::vector<uint8_t> pixels;
          std::vector<int> dirtyRects;
          if (CaptureDirtyRects(it->second, pixels, dirtyRects)) {
            flutter::EncodableMap response;
            response["pixels"] = flutter::EncodableValue(flutter::EncodableList(
                pixels.begin(), pixels.end()));
            response["dirtyRects"] = flutter::EncodableValue(flutter::EncodableList(
                dirtyRects.begin(), dirtyRects.end()));
            result->Success(flutter::EncodableValue(response));
            return;
          }
        }
        result->Success(flutter::EncodableValue(flutter::EncodableMap()));
      } else if (call.method_name() == "isSupported") {
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "enumerateWindows") {
        std::vector<flutter::EncodableValue> windows;
        EnumWindows(EnumWindowsProc, reinterpret_cast<LPARAM>(&windows));
        result->Success(flutter::EncodableValue(windows));
      } else if (call.method_name() == "startWindowCapture") {
        std::lock_guard<std::mutex> lock(g_capture_mutex);
        int displayIndex = 0;
        std::string windowId;
        int wx = 0, wy = 0, ww = 0, wh = 0;
        if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          auto itd = args.find(flutter::EncodableValue("displayIndex"));
          if (itd != args.end()) displayIndex = std::get<int32_t>(itd->second);
          auto itw = args.find(flutter::EncodableValue("windowId"));
          if (itw != args.end()) windowId = std::get<std::string>(itw->second);
          auto itx = args.find(flutter::EncodableValue("x"));
          if (itx != args.end()) wx = std::get<int32_t>(itx->second);
          auto ity = args.find(flutter::EncodableValue("y"));
          if (ity != args.end()) wy = std::get<int32_t>(ity->second);
          auto itww = args.find(flutter::EncodableValue("width"));
          if (itww != args.end()) ww = std::get<int32_t>(itww->second);
          auto ith = args.find(flutter::EncodableValue("height"));
          if (ith != args.end()) wh = std::get<int32_t>(ith->second);
        }
        ScreenCaptureState state;
        if (InitDXGICapture(displayIndex, state)) {
          if (!windowId.empty() && ww > 0 && wh > 0) {
            state.captureWindow = true;
            state.windowX = wx;
            state.windowY = wy;
            state.windowWidth = ww;
            state.windowHeight = wh;
            state.width = ww;
            state.height = wh;
            D3D11_TEXTURE2D_DESC texDesc = {};
            texDesc.Width = ww;
            texDesc.Height = wh;
            texDesc.MipLevels = 1;
            texDesc.ArraySize = 1;
            texDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
            texDesc.SampleDesc.Count = 1;
            texDesc.Usage = D3D11_USAGE_STAGING;
            texDesc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
            texDesc.BindFlags = 0;
            state.device->CreateTexture2D(&texDesc, nullptr, &state.stagingTexture);
          }
          int id = g_next_capture_id++;
          g_captures[id] = state;
          result->Success(flutter::EncodableValue(id));
        } else {
          result->Success(flutter::EncodableValue(-1));
        }
      } else {
        result->NotImplemented();
      }
    });
  }

  // Input injection channel
  {
    flutter::MethodChannel<flutter::EncodableValue> channel(
        messenger,
        "nex.flutter/remote_input_windows",
        static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
    channel.SetMethodCallHandler([](const flutter::MethodCall<flutter::EncodableValue>& call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
      if (call.method_name() == "injectMouseMove") {
        int x = 0, y = 0;
        bool absolute = true;
        if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          auto itx = args.find(flutter::EncodableValue("x"));
          auto ity = args.find(flutter::EncodableValue("y"));
          auto ita = args.find(flutter::EncodableValue("absolute"));
          if (itx != args.end()) x = std::get<int32_t>(itx->second);
          if (ity != args.end()) y = std::get<int32_t>(ity->second);
          if (ita != args.end()) absolute = std::get<bool>(ita->second);
        }
        InjectMouseMove(x, y, absolute);
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "injectMouseButton") {
        int button = 0;
        bool down = false;
        if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          auto itb = args.find(flutter::EncodableValue("button"));
          auto itd = args.find(flutter::EncodableValue("down"));
          if (itb != args.end()) button = std::get<int32_t>(itb->second);
          if (itd != args.end()) down = std::get<bool>(itd->second);
        }
        InjectMouseButton(button, down);
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "injectMouseWheel") {
        int delta = 0;
        if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          auto it = args.find(flutter::EncodableValue("delta"));
          if (it != args.end()) delta = std::get<int32_t>(it->second);
        }
        InjectMouseWheel(delta);
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "injectKey") {
        int scanCode = 0;
        bool down = true;
        bool extended = false;
        if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          auto itk = args.find(flutter::EncodableValue("scanCode"));
          auto itd = args.find(flutter::EncodableValue("down"));
          auto ite = args.find(flutter::EncodableValue("extended"));
          if (itk != args.end()) scanCode = std::get<int32_t>(itk->second);
          if (itd != args.end()) down = std::get<bool>(itd->second);
          if (ite != args.end()) extended = std::get<bool>(ite->second);
        }
        InjectKey(scanCode, down, extended);
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "injectUnicode") {
        std::string text;
        if (call.arguments() && std::holds_alternative<flutter::EncodableMap>(*call.arguments())) {
          const auto& args = std::get<flutter::EncodableMap>(*call.arguments());
          auto it = args.find(flutter::EncodableValue("text"));
          if (it != args.end()) text = std::get<std::string>(it->second);
        }
        if (!text.empty()) {
          int len = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
          if (len > 0) {
            std::wstring wtext(len, 0);
            MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, &wtext[0], len);
            InjectUnicode(wtext);
          }
        }
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "setModifiers") {
        // Modifier state is handled at Dart layer by sending individual key events.
        result->Success(flutter::EncodableValue(true));
      } else {
        result->NotImplemented();
      }
    });
  }

  // System tray channel
  {
    flutter::MethodChannel<flutter::EncodableValue> channel(
        messenger,
        "nex.flutter/system_tray_windows",
        static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
    channel.SetMethodCallHandler([controller](const flutter::MethodCall<flutter::EncodableValue>& call,
                                    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
      if (call.method_name() == "init") {
        HWND flutter_hwnd = FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", nullptr);
        if (!flutter_hwnd) {
          flutter_hwnd = controller->view()->GetNativeWindow();
        }
        g_tray_hwnd = flutter_hwnd;
        ZeroMemory(&g_tray_data, sizeof(g_tray_data));
        g_tray_data.cbSize = sizeof(NOTIFYICONDATA);
        g_tray_data.hWnd = flutter_hwnd;
        g_tray_data.uID = 1;
        g_tray_data.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
        g_tray_data.uCallbackMessage = g_tray_message_id;
        g_tray_data.hIcon = LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_APP_ICON));
        wcscpy_s(g_tray_data.szTip, L"NEX");
        Shell_NotifyIcon(NIM_ADD, &g_tray_data);
        g_tray_initialized = true;
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "show") {
        if (g_tray_hwnd) {
          ShowWindow(g_tray_hwnd, SW_SHOW);
          SetForegroundWindow(g_tray_hwnd);
        }
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "hide") {
        if (g_tray_hwnd) {
          ShowWindow(g_tray_hwnd, SW_HIDE);
        }
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "toggle") {
        if (g_tray_hwnd) {
          bool visible = IsWindowVisible(g_tray_hwnd) != 0;
          ShowWindow(g_tray_hwnd, visible ? SW_HIDE : SW_SHOW);
          if (!visible) SetForegroundWindow(g_tray_hwnd);
        }
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "destroy") {
        if (g_tray_initialized) {
          Shell_NotifyIcon(NIM_DELETE, &g_tray_data);
          g_tray_initialized = false;
        }
        result->Success(flutter::EncodableValue(true));
      } else {
        result->NotImplemented();
      }
    });
  }

  if (controller->view()) {
    HWND hwnd = controller->view()->GetNativeWindow();
    if (hwnd) {
      g_drop_target = new DropTarget(hwnd);
      RegisterDragDrop(hwnd, g_drop_target);
    }
  }
}

void NativeMethodChannel::InvokeDragDrop(const std::vector<std::string>& files, int totalSize) {
  if (!g_flutter_controller) return;
  const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
  flutter::MethodChannel<flutter::EncodableValue> channel(
      g_flutter_controller->engine()->messenger(),
      "nex.flutter/drag_drop",
      static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));

  flutter::EncodableList fileList;
  for (const auto& f : files) {
    fileList.push_back(flutter::EncodableValue(f));
  }

  flutter::EncodableMap args;
  args[flutter::EncodableValue("files")] = flutter::EncodableValue(fileList);
  args[flutter::EncodableValue("totalSize")] = flutter::EncodableValue(totalSize);

  channel.InvokeMethod("onFilesDropped", args);
}

void NativeMethodChannel::InvokeDragDropStatus(int status) {
  if (!g_flutter_controller) return;
  const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
  flutter::MethodChannel<flutter::EncodableValue> channel(
      g_flutter_controller->engine()->messenger(),
      "nex.flutter/drag_drop",
      static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));

  channel.InvokeMethod(status == kDragDropStatusDragging ? "onDragEnter" : "onDragLeave", nullptr);
}
