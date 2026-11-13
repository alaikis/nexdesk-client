#include "native_method_channel.h"
#include "resource.h"

#include <flutter/flutter_view_controller.h>
#include <flutter/standard_method_codec.h>
#include <flutter/method_channel.h>
#include <flutter/encodable_value.h>

#include <windows.h>
#include <shellapi.h>
#include <d3d11.h>
#include <dxgi1_2.h>
#include <wrl/client.h>

#include <map>
#include <cstdlib>
#include <string>
#include <vector>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

namespace {

flutter::FlutterViewController* g_flutter_controller = nullptr;
HANDLE g_single_instance_mutex = nullptr;
NOTIFYICONDATAW g_tray_icon = {0};
HWND g_message_window = nullptr;
bool g_tray_created = false;

#define WM_TRAYICON (WM_USER + 100)

// Tray menu item ids (kept in one place so the C++ menu and the Dart
// MethodChannel handler agree on numeric ids).
enum TrayCommand {
  TrayShow = 1,
  TrayHide = 2,
  TrayControlCenter = 3,
  TrayAbout = 4,
  TrayQuit = 5,
};

// Fire a named MethodChannel event back into Dart (no args).
void InvokeTrayEvent(const char* name) {
  if (!g_flutter_controller) return;
  const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
  flutter::MethodChannel<flutter::EncodableValue> channel(
      g_flutter_controller->engine()->messenger(), "nex.flutter/system_tray_windows",
      static_cast<const flutter::MethodCodec<flutter::EncodableValue>*>(codec));
  channel.InvokeMethod(name, nullptr);
}

static HICON LoadAppIcon() {
  HINSTANCE hInst = GetModuleHandleW(nullptr);
  return static_cast<HICON>(LoadImageW(hInst, MAKEINTRESOURCEW(IDI_APP_ICON), IMAGE_ICON, 16, 16, LR_DEFAULTCOLOR));
}

LRESULT CALLBACK MessageWindowProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
  if (msg == WM_TRAYICON) {
    if (lp == WM_LBUTTONDBLCLK || lp == WM_LBUTTONUP) {
      InvokeTrayEvent("tray_click");
    } else if (lp == WM_RBUTTONUP) {
      HMENU menu = CreatePopupMenu();
      AppendMenuW(menu, MF_STRING, TrayShow, L"Show");
      AppendMenuW(menu, MF_STRING, TrayHide, L"Hide");
      AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
      AppendMenuW(menu, MF_STRING, TrayControlCenter, L"Open Control Center");
      AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
      AppendMenuW(menu, MF_STRING, TrayAbout, L"About LitchiViewer");
      AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
      AppendMenuW(menu, MF_STRING, TrayQuit, L"Quit");
      POINT pt;
      GetCursorPos(&pt);
      SetForegroundWindow(hwnd);
      int cmd = TrackPopupMenu(menu, TPM_RETURNCMD | TPM_NONOTIFY, pt.x, pt.y, 0, hwnd, nullptr);
      DestroyMenu(menu);
      switch (cmd) {
        case TrayShow: InvokeTrayEvent("tray_restore"); break;
        case TrayHide: InvokeTrayEvent("tray_hide"); break;
        case TrayControlCenter: InvokeTrayEvent("tray_open_control_center"); break;
        case TrayAbout: InvokeTrayEvent("tray_about"); break;
        case TrayQuit: InvokeTrayEvent("tray_quit"); break;
        default: break;
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

// --- Screen capture (DXGI Desktop Duplication) ---

std::string WideToUtf8(const std::wstring& w) {
  if (w.empty()) return {};
  int len = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), -1, nullptr, 0, nullptr, nullptr);
  if (len <= 1) return {};
  std::string s(len - 1, '\0');
  WideCharToMultiByte(CP_UTF8, 0, w.c_str(), -1, s.data(), len - 1, nullptr, nullptr);
  return s;
}

struct MonitorInfo {
  int index = 0;
  std::wstring name;
  int x = 0, y = 0, width = 0, height = 0;
  float scale = 1.0f;
};

struct CaptureContext {
  ID3D11Device* device = nullptr;
  ID3D11DeviceContext* context = nullptr;
  IDXGIOutputDuplication* duplication = nullptr;
  ID3D11Texture2D* staging = nullptr;
  int width = 0;
  int height = 0;
  int displayIndex = -1;
  bool privacy = false;
};

struct WindowCapture {
  int width = 0;
  int height = 0;
  std::vector<uint8_t> pixels;
};

std::map<int, CaptureContext> g_captures;
std::map<int, WindowCapture> g_windowCaptures;
int g_nextTextureId = 1;
std::vector<MonitorInfo> g_monitors;
bool g_monitorsEnumerated = false;

BOOL CALLBACK MonitorEnumProc(HMONITOR hMon, HDC, LPRECT, LPARAM) {
  MONITORINFOEXW mi;
  mi.cbSize = sizeof(mi);
  if (GetMonitorInfoW(hMon, &mi)) {
    MonitorInfo info;
    info.index = static_cast<int>(g_monitors.size());
    info.name = mi.szDevice;
    info.x = mi.rcMonitor.left;
    info.y = mi.rcMonitor.top;
    info.width = mi.rcMonitor.right - mi.rcMonitor.left;
    info.height = mi.rcMonitor.bottom - mi.rcMonitor.top;
    HDC hdc = CreateDCW(nullptr, mi.szDevice, nullptr, nullptr);
    int dpi = hdc ? GetDeviceCaps(hdc, LOGPIXELSX) : 96;
    if (hdc) DeleteDC(hdc);
    info.scale = dpi / 96.0f;
    g_monitors.push_back(info);
  }
  return TRUE;
}

void EnsureMonitors() {
  if (g_monitorsEnumerated) return;
  g_monitors.clear();
  EnumDisplayMonitors(nullptr, nullptr, MonitorEnumProc, 0);
  g_monitorsEnumerated = true;
}

HRESULT CreateD3DDevice(ID3D11Device** outDevice, ID3D11DeviceContext** outContext) {
  D3D_FEATURE_LEVEL levels[] = {D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_1, D3D_FEATURE_LEVEL_10_0};
  D3D_FEATURE_LEVEL obtained;
  return D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0, levels,
                           static_cast<UINT>(sizeof(levels) / sizeof(levels[0])), D3D11_SDK_VERSION, outDevice,
                           &obtained, outContext);
}

HRESULT GetOutputForRect(IDXGIAdapter* adapter, const MonitorInfo& mon, IDXGIOutput** outOutput) {
  for (UINT i = 0;; i++) {
    IDXGIOutput* output = nullptr;
    if (adapter->EnumOutputs(i, &output) == DXGI_ERROR_NOT_FOUND) break;
    DXGI_OUTPUT_DESC desc;
    output->GetDesc(&desc);
    RECT r = desc.DesktopCoordinates;
    if (r.left == mon.x && r.top == mon.y) {
      *outOutput = output;
      return S_OK;
    }
    output->Release();
  }
  return E_FAIL;
}

int StartCapture(int displayIndex) {
  EnsureMonitors();
  if (displayIndex < 0 || displayIndex >= static_cast<int>(g_monitors.size())) return -1;
  const MonitorInfo mon = g_monitors[displayIndex];

  ID3D11Device* device = nullptr;
  ID3D11DeviceContext* context = nullptr;
  if (FAILED(CreateD3DDevice(&device, &context))) return -1;

  IDXGIDevice* dxgiDevice = nullptr;
  IDXGIAdapter* adapter = nullptr;
  IDXGIOutput* output = nullptr;
  IDXGIOutput1* output1 = nullptr;
  IDXGIOutputDuplication* dup = nullptr;
  ID3D11Texture2D* staging = nullptr;
  int texId = -1;

  if (SUCCEEDED(device->QueryInterface(__uuidof(IDXGIDevice), reinterpret_cast<void**>(&dxgiDevice))) &&
      SUCCEEDED(dxgiDevice->GetAdapter(&adapter)) &&
      SUCCEEDED(GetOutputForRect(adapter, mon, &output)) &&
      SUCCEEDED(output->QueryInterface(__uuidof(IDXGIOutput1), reinterpret_cast<void**>(&output1))) &&
      SUCCEEDED(output1->DuplicateOutput(device, &dup))) {
    D3D11_TEXTURE2D_DESC desc = {};
    desc.Width = mon.width;
    desc.Height = mon.height;
    desc.MipLevels = 1;
    desc.ArraySize = 1;
    desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    desc.SampleDesc.Count = 1;
    desc.Usage = D3D11_USAGE_STAGING;
    desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
    if (SUCCEEDED(device->CreateTexture2D(&desc, nullptr, &staging))) {
      texId = g_nextTextureId++;
      CaptureContext ctx;
      ctx.device = device;
      ctx.context = context;
      ctx.duplication = dup;
      ctx.staging = staging;
      ctx.width = mon.width;
      ctx.height = mon.height;
      ctx.displayIndex = displayIndex;
      g_captures[texId] = ctx;
      device = nullptr;
      context = nullptr;
      dup = nullptr;
      staging = nullptr;
    }
  }

  if (dup) dup->Release();
  if (output1) output1->Release();
  if (output) output->Release();
  if (adapter) adapter->Release();
  if (dxgiDevice) dxgiDevice->Release();
  if (device) device->Release();
  if (context) context->Release();
  return texId;
}

bool CaptureFrame(CaptureContext& ctx, std::vector<uint8_t>& outPixels, std::vector<int>& outDirtyRects) {
  if (!ctx.duplication || !ctx.staging || !ctx.context) return false;
  DXGI_OUTDUPL_FRAME_INFO frameInfo = {};
  IDXGIResource* desktopResource = nullptr;
  HRESULT hr = ctx.duplication->AcquireNextFrame(16, &frameInfo, &desktopResource);
  if (FAILED(hr)) return false;  // includes DXGI_ERROR_WAIT_TIMEOUT (no new frame)
  if (desktopResource == nullptr) {
    ctx.duplication->ReleaseFrame();
    return false;
  }

  UINT dirtyBufSize = 0;
  ctx.duplication->GetFrameDirtyRects(0, nullptr, &dirtyBufSize);
  if (dirtyBufSize > 0) {
    std::vector<RECT> dirtyRects(dirtyBufSize / sizeof(RECT));
    UINT written = dirtyBufSize;
    if (SUCCEEDED(ctx.duplication->GetFrameDirtyRects(dirtyBufSize, dirtyRects.data(), &written))) {
      for (const auto& r : dirtyRects) {
        outDirtyRects.push_back(r.left);
        outDirtyRects.push_back(r.top);
        outDirtyRects.push_back(r.right - r.left);
        outDirtyRects.push_back(r.bottom - r.top);
      }
    }
  }

  ID3D11Texture2D* desktopImage = nullptr;
  hr = desktopResource->QueryInterface(__uuidof(ID3D11Texture2D), reinterpret_cast<void**>(&desktopImage));
  if (SUCCEEDED(hr) && desktopImage != nullptr) {
    ctx.context->CopyResource(ctx.staging, desktopImage);
    D3D11_MAPPED_SUBRESOURCE mapped = {};
    if (SUCCEEDED(ctx.context->Map(ctx.staging, 0, D3D11_MAP_READ, 0, &mapped))) {
      int rowSize = ctx.width * 4;
      outPixels.resize(static_cast<size_t>(rowSize) * ctx.height);
      const auto* src = static_cast<const uint8_t*>(mapped.pData);
      for (int y = 0; y < ctx.height; y++) {
        memcpy(outPixels.data() + static_cast<size_t>(y) * rowSize, src + static_cast<size_t>(y) * mapped.RowPitch,
               rowSize);
      }
      ctx.context->Unmap(ctx.staging, 0);
    }
  }

  if (desktopImage) desktopImage->Release();
  desktopResource->Release();
  ctx.duplication->ReleaseFrame();
  return true;
}

struct WindowEnumState {
  std::vector<flutter::EncodableValue> items;
};

BOOL CALLBACK WindowEnumProc(HWND hwnd, LPARAM lParam) {
  if (!IsWindowVisible(hwnd)) return TRUE;
  if (GetWindow(hwnd, GW_OWNER) != nullptr) return TRUE;
  wchar_t title[256];
  int len = GetWindowTextW(hwnd, title, 256);
  if (len == 0) return TRUE;
  RECT r;
  if (!GetWindowRect(hwnd, &r)) return TRUE;
  int w = r.right - r.left;
  int h = r.bottom - r.top;
  if (w <= 0 || h <= 0) return TRUE;
  auto* state = reinterpret_cast<WindowEnumState*>(lParam);
  flutter::EncodableMap m;
  m[flutter::EncodableValue("id")] = flutter::EncodableValue(static_cast<int64_t>(reinterpret_cast<intptr_t>(hwnd)));
  m[flutter::EncodableValue("title")] = flutter::EncodableValue(WideToUtf8(title));
  m[flutter::EncodableValue("x")] = flutter::EncodableValue(r.left);
  m[flutter::EncodableValue("y")] = flutter::EncodableValue(r.top);
  m[flutter::EncodableValue("width")] = flutter::EncodableValue(w);
  m[flutter::EncodableValue("height")] = flutter::EncodableValue(h);
  state->items.push_back(flutter::EncodableValue(m));
  return TRUE;
}

int StartWindowCapture(intptr_t windowId) {
  HWND hwnd = reinterpret_cast<HWND>(windowId);
  if (!IsWindow(hwnd)) return -1;
  RECT r;
  if (!GetWindowRect(hwnd, &r)) return -1;
  int w = r.right - r.left;
  int h = r.bottom - r.top;
  if (w <= 0 || h <= 0) return -1;
  HDC hdcWindow = GetDC(hwnd);
  if (!hdcWindow) return -1;
  HDC hdcMem = CreateCompatibleDC(hdcWindow);
  HBITMAP hBitmap = CreateCompatibleBitmap(hdcWindow, w, h);
  HGDIOBJ old = SelectObject(hdcMem, hBitmap);
  const UINT PW_RENDERFULLCONTENT_ = 0x00000002;
  PrintWindow(hwnd, hdcMem, PW_RENDERFULLCONTENT_);
  BITMAPINFO bmi = {};
  bmi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  bmi.bmiHeader.biWidth = w;
  bmi.bmiHeader.biHeight = -h;
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;
  std::vector<uint8_t> pixels(static_cast<size_t>(w) * h * 4);
  GetDIBits(hdcMem, hBitmap, 0, h, pixels.data(), &bmi, DIB_RGB_COLORS);
  SelectObject(hdcMem, old);
  DeleteObject(hBitmap);
  DeleteDC(hdcMem);
  ReleaseDC(hwnd, hdcWindow);
  int texId = g_nextTextureId++;
  WindowCapture wc;
  wc.width = w;
  wc.height = h;
  wc.pixels = std::move(pixels);
  g_windowCaptures[texId] = wc;
  return texId;
}

void ReleaseCapture(int texId) {
  auto it = g_captures.find(texId);
  if (it != g_captures.end()) {
    CaptureContext& ctx = it->second;
    if (ctx.duplication) ctx.duplication->Release();
    if (ctx.staging) ctx.staging->Release();
    if (ctx.context) ctx.context->Release();
    if (ctx.device) ctx.device->Release();
    g_captures.erase(it);
  }
  g_windowCaptures.erase(texId);
}

void HandleScreenCapture(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* args = call.arguments();
  const flutter::EncodableMap* m = nullptr;
  if (args) m = std::get_if<flutter::EncodableMap>(args);

  const auto get_int = [&](const char* key) -> int {
    if (!m) return 0;
    auto it = m->find(flutter::EncodableValue(key));
    if (it == m->end()) return 0;
    if (const auto* i = std::get_if<int>(&it->second)) return *i;
    if (const auto* l = std::get_if<int64_t>(&it->second)) return static_cast<int>(*l);
    if (const auto* d = std::get_if<double>(&it->second)) return static_cast<int>(*d);
    return 0;
  };
  const auto get_bool = [&](const char* key) -> bool {
    if (!m) return false;
    auto it = m->find(flutter::EncodableValue(key));
    if (it == m->end()) return false;
    if (const auto* b = std::get_if<bool>(&it->second)) return *b;
    return false;
  };

  if (call.method_name() == "isSupported") {
    // DXGI Desktop Duplication is available on Windows 8.1+
    result->Success(flutter::EncodableValue(true));
  } else if (call.method_name() == "enumerateDisplays") {
    EnsureMonitors();
    flutter::EncodableList list;
    for (const auto& mon : g_monitors) {
      flutter::EncodableMap entry;
      entry[flutter::EncodableValue("id")] = flutter::EncodableValue(mon.index);
      entry[flutter::EncodableValue("name")] = flutter::EncodableValue(WideToUtf8(mon.name));
      entry[flutter::EncodableValue("width")] = flutter::EncodableValue(mon.width);
      entry[flutter::EncodableValue("height")] = flutter::EncodableValue(mon.height);
      entry[flutter::EncodableValue("x")] = flutter::EncodableValue(mon.x);
      entry[flutter::EncodableValue("y")] = flutter::EncodableValue(mon.y);
      entry[flutter::EncodableValue("scale")] = flutter::EncodableValue(static_cast<double>(mon.scale));
      list.push_back(flutter::EncodableValue(entry));
    }
    result->Success(flutter::EncodableValue(list));
  } else if (call.method_name() == "startCapture") {
    int displayIndex = get_int("displayIndex");
    result->Success(flutter::EncodableValue(StartCapture(displayIndex)));
  } else if (call.method_name() == "stopCapture") {
    ReleaseCapture(get_int("textureId"));
    result->Success();
  } else if (call.method_name() == "getFrame") {
    int texId = get_int("textureId");
    auto it = g_captures.find(texId);
    if (it != g_captures.end()) {
      std::vector<uint8_t> pixels;
      std::vector<int> dirty;
      if (CaptureFrame(it->second, pixels, dirty) && !pixels.empty()) {
        result->Success(flutter::EncodableValue(pixels));
      } else {
        result->Success();
      }
    } else {
      auto wit = g_windowCaptures.find(texId);
      if (wit != g_windowCaptures.end() && !wit->second.pixels.empty()) {
        result->Success(flutter::EncodableValue(wit->second.pixels));
      } else {
        result->Success();
      }
    }
  } else if (call.method_name() == "getDirtyFrame") {
    int texId = get_int("textureId");
    auto it = g_captures.find(texId);
    if (it != g_captures.end()) {
      std::vector<uint8_t> pixels;
      std::vector<int> dirty;
      if (CaptureFrame(it->second, pixels, dirty) && !pixels.empty()) {
        flutter::EncodableMap map;
        map[flutter::EncodableValue("pixels")] = flutter::EncodableValue(pixels);
        flutter::EncodableList rects;
        for (int v : dirty) rects.push_back(flutter::EncodableValue(v));
        map[flutter::EncodableValue("dirtyRects")] = flutter::EncodableValue(rects);
        result->Success(flutter::EncodableValue(map));
      } else {
        result->Success();
      }
    } else {
      auto wit = g_windowCaptures.find(texId);
      if (wit != g_windowCaptures.end() && !wit->second.pixels.empty()) {
        flutter::EncodableMap map;
        map[flutter::EncodableValue("pixels")] = flutter::EncodableValue(wit->second.pixels);
        map[flutter::EncodableValue("dirtyRects")] =
            flutter::EncodableValue(flutter::EncodableList());
        result->Success(flutter::EncodableValue(map));
      } else {
        result->Success();
      }
    }
  } else if (call.method_name() == "setPrivacyEnabled") {
    bool enabled = get_bool("enabled");
    for (auto& kv : g_captures) kv.second.privacy = enabled;
    result->Success();
  } else if (call.method_name() == "enumerateWindows") {
    WindowEnumState state;
    EnumWindows(WindowEnumProc, reinterpret_cast<LPARAM>(&state));
    result->Success(flutter::EncodableValue(state.items));
  } else if (call.method_name() == "startWindowCapture") {
    auto it = m ? m->find(flutter::EncodableValue("windowId")) : flutter::EncodableMap::const_iterator();
    intptr_t windowId = 0;
    if (m && it != m->end()) {
      if (const auto* s = std::get_if<std::string>(&it->second)) {
        windowId = static_cast<intptr_t>(std::strtoll(s->c_str(), nullptr, 10));
      } else if (const auto* l = std::get_if<int64_t>(&it->second)) {
        windowId = static_cast<intptr_t>(*l);
      }
    }
    result->Success(flutter::EncodableValue(StartWindowCapture(windowId)));
  } else {
    result->NotImplemented();
  }
}

void HandleRemoteInput(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* args = call.arguments();
  const flutter::EncodableMap* m = nullptr;
  if (args) {
    m = std::get_if<flutter::EncodableMap>(args);
  }

  const auto get_int = [&](const char* key) -> int {
    if (!m) return 0;
    auto it = m->find(flutter::EncodableValue(key));
    if (it == m->end()) return 0;
    if (const auto* i = std::get_if<int>(&it->second)) return *i;
    if (const auto* l = std::get_if<int64_t>(&it->second)) return static_cast<int>(*l);
    if (const auto* d = std::get_if<double>(&it->second)) return static_cast<int>(*d);
    return 0;
  };
  const auto get_bool = [&](const char* key) -> bool {
    if (!m) return false;
    auto it = m->find(flutter::EncodableValue(key));
    if (it == m->end()) return false;
    if (const auto* b = std::get_if<bool>(&it->second)) return *b;
    return false;
  };

  if (call.method_name() == "injectMouseMove") {
    if (!m) { result->Success(); return; }
    int x = get_int("x");
    int y = get_int("y");
    bool absolute = get_bool("absolute");
    INPUT in = {};
    in.type = INPUT_MOUSE;
    in.mi.dwFlags = absolute ? MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE : MOUSEEVENTF_MOVE;
    int sw = GetSystemMetrics(SM_CXVIRTUALSCREEN);
    int sh = GetSystemMetrics(SM_CYVIRTUALSCREEN);
    int vx = GetSystemMetrics(SM_XVIRTUALSCREEN);
    int vy = GetSystemMetrics(SM_YVIRTUALSCREEN);
    if (absolute && sw > 0 && sh > 0) {
      in.mi.dx = (x - vx) * 65535 / sw;
      in.mi.dy = (y - vy) * 65535 / sh;
    } else {
      in.mi.dx = x;
      in.mi.dy = y;
    }
    SendInput(1, &in, sizeof(INPUT));
    result->Success();
  } else if (call.method_name() == "injectMouseButton") {
    if (!m) { result->Success(); return; }
    int button = get_int("button");
    bool down = get_bool("down");
    INPUT in = {};
    in.type = INPUT_MOUSE;
    if (button == 0) in.mi.dwFlags = down ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_LEFTUP;
    else if (button == 1) in.mi.dwFlags = down ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_RIGHTUP;
    else in.mi.dwFlags = down ? MOUSEEVENTF_MIDDLEDOWN : MOUSEEVENTF_MIDDLEUP;
    SendInput(1, &in, sizeof(INPUT));
    result->Success();
  } else if (call.method_name() == "injectMouseWheel") {
    if (!m) { result->Success(); return; }
    int delta = get_int("delta");
    INPUT in = {};
    in.type = INPUT_MOUSE;
    in.mi.dwFlags = MOUSEEVENTF_WHEEL;
    in.mi.mouseData = delta * WHEEL_DELTA / 120;
    SendInput(1, &in, sizeof(INPUT));
    result->Success();
  } else if (call.method_name() == "injectKey") {
    if (!m) { result->Success(); return; }
    int scanCode = get_int("scanCode");
    bool down = get_bool("down");
    bool extended = get_bool("extended");
    INPUT in = {};
    in.type = INPUT_KEYBOARD;
    in.ki.wScan = static_cast<WORD>(scanCode & 0xFFFF);
    in.ki.dwFlags = KEYEVENTF_SCANCODE;
    if (extended) in.ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;
    if (!down) in.ki.dwFlags |= KEYEVENTF_KEYUP;
    SendInput(1, &in, sizeof(INPUT));
    result->Success();
  } else if (call.method_name() == "injectUnicode") {
    if (!m) { result->Success(); return; }
    auto it = m->find(flutter::EncodableValue("text"));
    if (it == m->end()) { result->Success(); return; }
    const auto* str = std::get_if<std::string>(&it->second);
    if (!str) { result->Success(); return; }
    int len = MultiByteToWideChar(CP_UTF8, 0, str->c_str(), -1, nullptr, 0);
    if (len <= 0) { result->Success(); return; }
    std::wstring wstr(len, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, str->c_str(), -1, wstr.data(), len);
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
    if (!m) { result->Success(); return; }
    struct Mod {
      const char* key;
      WORD vk;
    } mods[] = {
        {"ctrl", VK_CONTROL},
        {"alt", VK_MENU},
        {"shift", VK_SHIFT},
        {"win", VK_LWIN},
    };
    INPUT inputs[4];
    int n = 0;
    for (auto& mo : mods) {
      bool want = get_bool(mo.key);
      bool isDown = (GetAsyncKeyState(mo.vk) & 0x8000) != 0;
      if (want != isDown && n < 4) {
        inputs[n] = {};
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
