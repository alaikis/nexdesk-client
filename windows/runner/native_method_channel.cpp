#include "native_method_channel.h"

#include <flutter/flutter_view_controller.h>
#include <flutter/method_channel.h>
#include <flutter/standard_message_codec.h>

#include <windows.h>
#include <dxgi1_2.h>
#include <d3d11.h>
#include <vector>
#include <mutex>
#include <map>
#include <memory>

#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3d11.lib")
#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")

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

  state.context->CopyResource(state.stagingTexture, acquiredTexture);
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
  state.active = false;
}

}  // namespace

void NativeMethodChannel::Register(flutter::FlutterViewController* controller) {
  // Method channel registration would go here in a full implementation.
  // For now, the Dart side falls back to platform-specific plugin implementations.
}
