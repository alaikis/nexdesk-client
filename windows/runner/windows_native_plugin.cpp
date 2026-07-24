// Windows native implementation - DXGI Desktop Duplication + SendInput
// Full production implementation
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/plugin_registrar_windows.h>

#include <windows.h>
#include <d3d11.h>
#include <dxgi1_2.h>
#include <wrl/client.h>
#include <memory>
#include <vector>
#include <string>
#include <unordered_map>

#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "dxgi.lib")

using Microsoft::WRL::ComPtr;

namespace {

struct DisplayInfo {
  int index;
  std::wstring name;
  int width;
  int height;
  bool is_primary;
};

class DuplicationCapture {
 public:
  ~DuplicationCapture() { Cleanup(); }

  std::vector<DisplayInfo> EnumerateDisplays() {
    std::vector<DisplayInfo> displays;

    ComPtr<IDXGIFactory1> factory;
    HRESULT hr = CreateDXGIFactory1(IID_PPV_ARGS(&factory));
    if (FAILED(hr)) return displays;

    UINT adapterIndex = 0;
    ComPtr<IDXGIAdapter1> adapter;
    while (factory->EnumAdapters1(adapterIndex, &adapter) != DXGI_ERROR_NOT_FOUND) {
      UINT outputIndex = 0;
      ComPtr<IDXGIOutput> output;
      while (adapter->EnumOutputs(outputIndex, &output) != DXGI_ERROR_NOT_FOUND) {
        DXGI_OUTPUT_DESC desc;
        if (SUCCEEDED(output->GetDesc(&desc))) {
          DisplayInfo info;
          info.index = adapterIndex * 100 + outputIndex;
          info.name = desc.DeviceName;
          info.width = desc.DesktopCoordinates.right - desc.DesktopCoordinates.left;
          info.height = desc.DesktopCoordinates.bottom - desc.DesktopCoordinates.top;
          info.is_primary = (desc.DesktopCoordinates.left == 0 && desc.DesktopCoordinates.top == 0);
          displays.push_back(info);
        }
        output.Reset();
        outputIndex++;
      }
      adapter.Reset();
      adapterIndex++;
    }
    return displays;
  }

  bool StartCapture(int displayIndex) {
    Cleanup();

    // Create D3D11 device
    D3D_FEATURE_LEVEL featureLevel;
    HRESULT hr = D3D11CreateDevice(
        nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr,
        D3D11_CREATE_DEVICE_BGRA_SUPPORT,
        nullptr, 0, D3D11_SDK_VERSION,
        &device_, &featureLevel, &context_);
    if (FAILED(hr)) {
      // Try WARP software adapter
      hr = D3D11CreateDevice(
          nullptr, D3D_DRIVER_TYPE_WARP, nullptr,
          D3D11_CREATE_DEVICE_BGRA_SUPPORT,
          nullptr, 0, D3D11_SDK_VERSION,
          &device_, &featureLevel, &context_);
      if (FAILED(hr)) return false;
    }

    ComPtr<IDXGIDevice> dxgiDevice;
    hr = device_.As(&dxgiDevice);
    if (FAILED(hr)) return false;

    ComPtr<IDXGIAdapter> adapter;
    hr = dxgiDevice->GetAdapter(&adapter);
    if (FAILED(hr)) return false;

    UINT outputIndex = static_cast<UINT>(displayIndex % 100);
    ComPtr<IDXGIOutput> output;
    hr = adapter->EnumOutputs(outputIndex, &output);
    if (FAILED(hr)) return false;

    ComPtr<IDXGIOutput1> output1;
    hr = output.As(&output1);
    if (FAILED(hr)) return false;

    hr = output1->DuplicateOutput(device_.Get(), &duplication_);
    if (FAILED(hr)) return false;

    // Get output description for dimensions
    DXGI_OUTPUT_DESC desc;
    output->GetDesc(&desc);
    width_ = desc.DesktopCoordinates.right - desc.DesktopCoordinates.left;
    height_ = desc.DesktopCoordinates.bottom - desc.DesktopCoordinates.top;

    return true;
  }

  struct Frame {
    std::vector<uint8_t> data;
    int width;
    int height;
    bool acquired;
  };

  Frame GetFrame() {
    Frame frame;
    frame.width = width_;
    frame.height = height_;
    frame.acquired = false;

    if (!duplication_) return frame;

    ComPtr<IDXGIResource> resource;
    DXGI_OUTDUPL_FRAME_INFO frameInfo;
    HRESULT hr = duplication_->AcquireNextFrame(100, &frameInfo, &resource);

    if (hr == DXGI_ERROR_WAIT_TIMEOUT) {
      return frame;
    }
    if (FAILED(hr)) {
      return frame;
    }

    frame.acquired = true;

    // Get the texture
    ComPtr<ID3D11Texture2D> texture;
    hr = resource.As(&texture);
    if (SUCCEEDED(hr)) {
      // Map texture to read pixels
      D3D11_MAPPED_SUBRESOURCE mapped;
      hr = context_->Map(texture.Get(), 0, D3D11_MAP_READ, 0, &mapped);
      if (SUCCEEDED(hr)) {
        // Copy frame data (BGRA format)
        size_t dataSize = static_cast<size_t>(width_) * height_ * 4;
        frame.data.resize(dataSize);
        if (mapped.RowPitch == width_ * 4) {
          memcpy(frame.data.data(), mapped.pData, dataSize);
        } else {
          // Row by row copy (handle padding)
          for (int y = 0; y < height_; y++) {
            memcpy(frame.data.data() + y * width_ * 4,
                   static_cast<uint8_t*>(mapped.pData) + y * mapped.RowPitch,
                   width_ * 4);
          }
        }
        context_->Unmap(texture.Get(), 0);
      }
    }

    duplication_->ReleaseFrame();
    return frame;
  }

  void StopCapture() { Cleanup(); }

  int width() const { return width_; }
  int height() const { return height_; }

 private:
  void Cleanup() {
    duplication_.Reset();
    context_.Reset();
    device_.Reset();
  }

  ComPtr<ID3D11Device> device_;
  ComPtr<ID3D11DeviceContext> context_;
  ComPtr<IDXGIOutputDuplication> duplication_;
  int width_ = 0;
  int height_ = 0;
};

// Global capture instance
std::unique_ptr<DuplicationCapture> g_capture;

// SendInput helpers
void InjectMouseMove(int x, int y, bool absolute) {
  INPUT input = {};
  input.type = INPUT_MOUSE;
  if (absolute) {
    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);
    input.mi.dx = static_cast<LONG>((x * 65535) / (screenWidth > 0 ? screenWidth : 1));
    input.mi.dy = static_cast<LONG>((y * 65535) / (screenHeight > 0 ? screenHeight : 1));
    input.mi.dwFlags = MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE;
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
  }
  SendInput(1, &input, sizeof(INPUT));
}

void InjectMouseWheel(int delta) {
  INPUT input = {};
  input.type = INPUT_MOUSE;
  input.mi.dwFlags = MOUSEEVENTF_WHEEL;
  input.mi.mouseData = delta;
  SendInput(1, &input, sizeof(INPUT));
}

void InjectKey(WORD scanCode, bool down, bool extended) {
  INPUT input = {};
  input.type = INPUT_KEYBOARD;
  input.ki.wScan = scanCode;
  input.ki.dwFlags = KEYEVENTF_SCANCODE;
  if (extended) input.ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;
  if (!down) input.ki.dwFlags |= KEYEVENTF_KEYUP;
  SendInput(1, &input, sizeof(INPUT));
}

void InjectUnicode(const std::wstring& text) {
  std::vector<INPUT> inputs(text.size() * 2);
  int idx = 0;
  for (wchar_t ch : text) {
    inputs[idx].type = INPUT_KEYBOARD;
    inputs[idx].ki.wScan = ch;
    inputs[idx].ki.dwFlags = KEYEVENTF_UNICODE;
    idx++;
    inputs[idx].type = INPUT_KEYBOARD;
    inputs[idx].ki.wScan = ch;
    inputs[idx].ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
    idx++;
  }
  SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
}

// Method channel handler
void HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto& method = call.method_name();

  if (method == "enumerateDisplays") {
    if (!g_capture) g_capture = std::make_unique<DuplicationCapture>();
    auto displays = g_capture->EnumerateDisplays();
    flutter::EncodableList result_list;
    for (const auto& d : displays) {
      flutter::EncodableMap display;
      display["index"] = d.index;
      display["name"] = std::string(d.name.begin(), d.name.end());
      display["width"] = d.width;
      display["height"] = d.height;
      display["isPrimary"] = d.is_primary;
      result_list.push_back(display);
    }
    result->Success(result_list);
  } else if (method == "startCapture") {
    if (!g_capture) g_capture = std::make_unique<DuplicationCapture>();
    auto* idx = std::get_if<int>(call.arguments());
    if (idx) {
      bool ok = g_capture->StartCapture(*idx);
      result->Success(ok ? 1 : -1);
    } else {
      result->Success(-1);
    }
  } else if (method == "stopCapture") {
    if (g_capture) g_capture->StopCapture();
    result->Success();
  } else if (method == "getFrame") {
    if (!g_capture) {
      result->Success();
      return;
    }
    auto frame = g_capture->GetFrame();
    if (!frame.acquired || frame.data.empty()) {
      result->Success();
      return;
    }
    result->Success(flutter::EncodableValue(frame.data));
  } else if (method == "isSupported") {
    result->Success(true);
  } else if (method == "injectMouseMove") {
    auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args) {
      int x = 0, y = 0;
      bool absolute = true;
      auto it = args->find(flutter::EncodableValue("x"));
      if (it != args->end()) x = std::get<int>(it->second);
      it = args->find(flutter::EncodableValue("y"));
      if (it != args->end()) y = std::get<int>(it->second);
      it = args->find(flutter::EncodableValue("absolute"));
      if (it != args->end()) absolute = std::get<bool>(it->second);
      InjectMouseMove(x, y, absolute);
    }
    result->Success();
  } else if (method == "injectMouseButton") {
    auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args) {
      int button = 0;
      bool down = true;
      auto it = args->find(flutter::EncodableValue("button"));
      if (it != args->end()) button = std::get<int>(it->second);
      it = args->find(flutter::EncodableValue("down"));
      if (it != args->end()) down = std::get<bool>(it->second);
      InjectMouseButton(button, down);
    }
    result->Success();
  } else if (method == "injectMouseWheel") {
    auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args) {
      int delta = 0;
      auto it = args->find(flutter::EncodableValue("delta"));
      if (it != args->end()) delta = std::get<int>(it->second);
      InjectMouseWheel(delta);
    }
    result->Success();
  } else if (method == "injectKey") {
    auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args) {
      int scanCode = 0;
      bool down = true;
      bool extended = false;
      auto it = args->find(flutter::EncodableValue("scanCode"));
      if (it != args->end()) scanCode = std::get<int>(it->second);
      it = args->find(flutter::EncodableValue("down"));
      if (it != args->end()) down = std::get<bool>(it->second);
      it = args->find(flutter::EncodableValue("extended"));
      if (it != args->end()) extended = std::get<bool>(it->second);
      InjectKey(static_cast<WORD>(scanCode), down, extended);
    }
    result->Success();
  } else if (method == "injectUnicode") {
    auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (args) {
      std::string text;
      auto it = args->find(flutter::EncodableValue("text"));
      if (it != args->end()) text = std::get<std::string>(it->second);
      InjectUnicode(std::wstring(text.begin(), text.end()));
    }
    result->Success();
  } else if (method == "setModifiers") {
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void RegisterWindowsNativePlugins(flutter::PluginRegistrarWindows* registrar) {
  auto screen_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "nex.flutter/screen_capture_windows",
          &flutter::StandardMethodCodec::GetInstance());

  screen_channel->SetMessageHandler([](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });

  auto input_channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "nex.flutter/input_inject_windows",
          &flutter::StandardMethodCodec::GetInstance());

  input_channel->SetMessageHandler([](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });
}

}  // namespace

void InitWindowsNative(flutter::PluginRegistrarWindows* registrar) {
  RegisterWindowsNativePlugins(registrar);
}
