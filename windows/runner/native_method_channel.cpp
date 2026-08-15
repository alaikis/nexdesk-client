#include "native_method_channel.h"

#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/standard_message_codec.h>

#include <windows.h>
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

#include "resource.h"

namespace {

// Screen capture state
struct ScreenCaptureState {
  IDXGIOutputDuplication* duplication = nullptr;
  ID3D11Texture2D* stagingTexture = nullptr;
  ID3D11Device* device = nullptr;
  ID3D11DeviceContext* context = nullptr;
  int width = 0;
  int height = 0;
  int displayIndex = 0;
  bool active = false;
  std::vector<uint8_t> previousFrame;
  bool hasPreviousFrame = false;
  int windowX = 0;
  int windowY = 0;
  int windowWidth = 0;
  int windowHeight = 0;
  bool captureWindow = false;
};

std::mutex g_capture_mutex;
std::map<int, ScreenCaptureState> g_captures;
int g_next_capture_id = 1;

// Input injection helpers
void InjectMouseMove(int x, int y, bool absolute) {
  INPUT input = {};
  input.type = INPUT_MOUSE;
  if (absolute) {
    input.mi.dx = x * 65535 / GetSystemMetrics(SM_CXSCREEN);
    input.mi.dy = y * 65535 / GetSystemMetrics(SM_CYSCREEN);
    input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_VIRTUALDESK;
  } else {
    input.mi.dx = x;
    input.mi.dy = y;
    input.mi.dwFlags = MOUSEEVENTF_MOVE;
  }
  SendInput(1, &input, sizeof(INPUT));
}

void InjectMouseButton(int button, bool down) {
  INPUT input = {};
  input.type = INPUT_MOUSE;
  switch (button) {
    case 0:
      input.mi.dwFlags = down ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_LEFTUP;
      break;
    case 1:
      input.mi.dwFlags = down ? MOUSEEVENTF_RIGHTDOWN : MOUSEEVENTF_RIGHTUP;
      break;
    case 2:
      input.mi.dwFlags = down ? MOUSEEVENTF_MIDDLEDOWN : MOUSEEVENTF_MIDDLEUP;
      break;
    default:
      return;
  }
  SendInput(1, &input, sizeof(INPUT));
}

void InjectMouseWheel(int delta) {
  INPUT input = {};
  input.type = INPUT_MOUSE;
  input.mi.mouseData = delta;
  input.mi.dwFlags = MOUSEEVENTF_WHEEL;
  SendInput(1, &input, sizeof(INPUT));
}

void InjectKey(int scanCode, bool down, bool extended) {
  INPUT input = {};
  input.type = INPUT_KEYBOARD;
  input.ki.wScan = static_cast<WORD>(scanCode);
  input.ki.dwFlags = KEYEVENTF_SCANCODE;
  if (!down) input.ki.dwFlags |= KEYEVENTF_KEYUP;
  if (extended) input.ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;
  SendInput(1, &input, sizeof(INPUT));
}

void InjectUnicode(const std::wstring& text) {
  for (wchar_t ch : text) {
    INPUT input = {};
    input.type = INPUT_KEYBOARD;
    input.ki.wScan = ch;
    input.ki.dwFlags = KEYEVENTF_UNICODE;
    SendInput(1, &input, sizeof(INPUT));
    input.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
    SendInput(1, &input, sizeof(INPUT));
  }
}

bool InitDXGICapture(int displayIndex, ScreenCaptureState& state) {
  D3D_FEATURE_LEVEL featureLevels[] = {D3D_FEATURE_LEVEL_11_0};
  D3D_FEATURE_LEVEL featureLevel;

  HRESULT hr = D3D11CreateDevice(
      nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0,
      featureLevels, ARRAYSIZE(featureLevels),
      D3D11_SDK_VERSION, &state.device, &featureLevel, &state.context);
  if (FAILED(hr)) return false;

  IDXGIDevice* dxgiDevice = nullptr;
  hr = state.device->QueryInterface(__uuidof(IDXGIDevice), (void**)&dxgiDevice);
  if (FAILED(hr)) return false;

  IDXGIAdapter* adapter = nullptr;
  hr = dxgiDevice->GetParent(__uuidof(IDXGIAdapter), (void**)&adapter);
  dxgiDevice->Release();
  if (FAILED(hr)) return false;

  IDXGIOutput* output = nullptr;
  hr = adapter->EnumOutputs(displayIndex, &output);
  adapter->Release();
  if (FAILED(hr)) return false;

  IDXGIOutput1* output1 = nullptr;
  hr = output->QueryInterface(__uuidof(IDXGIOutput1), (void**)&output1);
  output->Release();
  if (FAILED(hr)) return false;

  hr = output1->DuplicateOutput(state.device, &state.duplication);
  output1->Release();
  if (FAILED(hr)) return false;

  DXGI_OUTDUPL_DESC desc;
  state.duplication->GetDesc(&desc);
  state.width = desc.ModeDesc.Width;
  state.height = desc.ModeDesc.Height;

  D3D11_TEXTURE2D_DESC texDesc = {};
  texDesc.Width = state.width;
  texDesc.Height = state.height;
  texDesc.MipLevels = 1;
  texDesc.ArraySize = 1;
  texDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  texDesc.SampleDesc.Count = 1;
  texDesc.Usage = D3D11_USAGE_STAGING;
  texDesc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
  texDesc.BindFlags = 0;

  hr = state.device->CreateTexture2D(&texDesc, nullptr, &state.stagingTexture);
  if (FAILED(hr)) {
    state.duplication->Release();
    state.duplication = nullptr;
    return false;
  }

  state.active = true;
  return true;
}

bool CaptureFrame(ScreenCaptureState& state, std::vector<uint8_t>& outPixels) {
  if (!state.duplication || !state.stagingTexture) return false;

  DXGI_OUTDUPL_FRAME_INFO frameInfo;
  IDXGIResource* desktopResource = nullptr;
  HRESULT hr = state.duplication->AcquireNextFrame(500, &frameInfo, &desktopResource);
  if (FAILED(hr)) return false;

  ID3D11Texture2D* acquiredTexture = nullptr;
  hr = desktopResource->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&acquiredTexture);
  desktopResource->Release();
  if (FAILED(hr)) {
    state.duplication->ReleaseFrame();
    return false;
  }

  if (state.captureWindow) {
    D3D11_BOX srcBox;
    srcBox.left = state.windowX;
    srcBox.top = state.windowY;
    srcBox.right = state.windowX + state.windowWidth;
    srcBox.bottom = state.windowY + state.windowHeight;
    srcBox.front = 0;
    srcBox.back = 1;
    state.context->CopySubresourceRegion(state.stagingTexture, 0, 0, 0, 0, acquiredTexture, 0, &srcBox);
  } else {
    state.context->CopyResource(state.stagingTexture, acquiredTexture);
  }
  acquiredTexture->Release();

  D3D11_TEXTURE2D_DESC desc;
  state.stagingTexture->GetDesc(&desc);
  D3D11_MAPPED_SUBRESOURCE mapped;
  hr = state.context->Map(state.stagingTexture, 0, D3D11_MAP_READ, 0, &mapped);
  if (FAILED(hr)) {
    state.duplication->ReleaseFrame();
    return false;
  }

  outPixels.resize(desc.Width * desc.Height * 4);
  for (UINT y = 0; y < desc.Height; y++) {
    memcpy(outPixels.data() + y * desc.Width * 4,
           reinterpret_cast<uint8_t*>(mapped.pData) + y * mapped.RowPitch,
           desc.Width * 4);
  }

  state.context->Unmap(state.stagingTexture, 0);
  state.duplication->ReleaseFrame();
  return true;
}

bool CaptureDirtyRects(ScreenCaptureState& state, std::vector<uint8_t>& outPixels, std::vector<int>& dirtyRects) {
  std::vector<uint8_t> currentFrame;
  if (!CaptureFrame(state, currentFrame)) {
    return false;
  }

  if (!state.hasPreviousFrame) {
    state.previousFrame = std::move(currentFrame);
    state.hasPreviousFrame = true;
    outPixels = state.previousFrame;
    dirtyRects.push_back(0);
    dirtyRects.push_back(0);
    dirtyRects.push_back(state.width);
    dirtyRects.push_back(state.height);
    return true;
  }

  const int width = state.width;
  const int height = state.height;
  const int stride = width * 4;

  dirtyRects.clear();
  for (int y = 0; y < height; y++) {
    const uint8_t* currRow = currentFrame.data() + y * stride;
    const uint8_t* prevRow = state.previousFrame.data() + y * stride;
    int rectStart = -1;
    for (int x = 0; x < width; x++) {
      bool changed = memcmp(currRow + x * 4, prevRow + x * 4, 4) != 0;
      if (changed && rectStart == -1) {
        rectStart = x;
      } else if (!changed && rectStart != -1) {
        dirtyRects.push_back(rectStart);
        dirtyRects.push_back(y);
        dirtyRects.push_back(x - rectStart);
        dirtyRects.push_back(1);
        rectStart = -1;
      }
    }
    if (rectStart != -1) {
      dirtyRects.push_back(rectStart);
      dirtyRects.push_back(y);
      dirtyRects.push_back(width - rectStart);
      dirtyRects.push_back(1);
    }
  }

  state.previousFrame = std::move(currentFrame);

  if (dirtyRects.empty()) {
    outPixels.clear();
    return true;
  }

  outPixels = state.previousFrame;
  return true;
}

void CleanupCapture(ScreenCaptureState& state) {
  if (state.stagingTexture) {
    state.stagingTexture->Release();
    state.stagingTexture = nullptr;
  }
  if (state.duplication) {
    state.duplication->Release();
    state.duplication = nullptr;
  }
  if (state.context) {
    state.context->Release();
    state.context = nullptr;
  }
  if (state.device) {
    state.device->Release();
    state.device = nullptr;
  }
  state.previousFrame.clear();
  state.hasPreviousFrame = false;
  state.active = false;
}

}  // namespace

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

void NativeMethodChannel::Register(flutter::FlutterViewController* controller) {
  const flutter::StandardMethodCodec* codec = &flutter::StandardMethodCodec::GetInstance();
  auto messenger = controller->engine()->messenger();
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
}
