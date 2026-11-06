#include "windows_screen_capture.h"

#include <dxgi1_2.h>
#include <d3d11.h>
#include <algorithm>

#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3d11.lib")

std::mutex g_capture_mutex;
std::map<int, ScreenCaptureState> g_captures;
int g_next_capture_id = 0;

bool InitDXGICapture(int display_index, ScreenCaptureState& state) {
  D3D_FEATURE_LEVEL feature_levels[] = { D3D_FEATURE_LEVEL_11_0 };
  D3D_FEATURE_LEVEL feature_level;

  if (FAILED(D3D11CreateDevice(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, 0,
                               feature_levels, _countof(feature_levels),
                               D3D11_SDK_VERSION, &state.device, &feature_level,
                               &state.context))) {
    return false;
  }

  IDXGIDevice* dxgi_device = nullptr;
  if (FAILED(state.device->QueryInterface(__uuidof(IDXGIDevice), (void**)&dxgi_device))) {
    return false;
  }

  IDXGIAdapter* adapter = nullptr;
  if (FAILED(dxgi_device->GetParent(__uuidof(IDXGIAdapter), (void**)&adapter))) {
    dxgi_device->Release();
    return false;
  }

  IDXGIOutput* output = nullptr;
  if (FAILED(adapter->EnumOutputs(display_index, &output))) {
    adapter->Release();
    dxgi_device->Release();
    return false;
  }

  IDXGIOutput1* output1 = nullptr;
  if (FAILED(output->QueryInterface(__uuidof(IDXGIOutput1), (void**)&output1))) {
    output->Release();
    adapter->Release();
    dxgi_device->Release();
    return false;
  }

  if (FAILED(output1->DuplicateOutput(state.device, &state.duplication))) {
    output1->Release();
    output->Release();
    adapter->Release();
    dxgi_device->Release();
    return false;
  }

  DXGI_OUTDUPL_DESC desc;
  state.duplication->GetDesc(&desc);
  state.width = desc.ModeDesc.Width;
  state.height = desc.ModeDesc.Height;
  state.display_index = display_index;

  D3D11_TEXTURE2D_DESC tex_desc = {};
  tex_desc.Width = state.width;
  tex_desc.Height = state.height;
  tex_desc.MipLevels = 1;
  tex_desc.ArraySize = 1;
  tex_desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  tex_desc.SampleDesc.Count = 1;
  tex_desc.Usage = D3D11_USAGE_STAGING;
  tex_desc.CPUAccessFlags = D3D11_CPU_ACCESS_READ;
  tex_desc.BindFlags = 0;

  if (FAILED(state.device->CreateTexture2D(&tex_desc, nullptr, &state.staging_texture))) {
    state.duplication->Release();
    output1->Release();
    output->Release();
    adapter->Release();
    dxgi_device->Release();
    return false;
  }

  output1->Release();
  output->Release();
  adapter->Release();
  dxgi_device->Release();
  return true;
}

bool CaptureFrame(ScreenCaptureState& state, std::vector<uint8_t>& pixels) {
  if (!state.duplication || !state.staging_texture) return false;

  IDXGIResource* resource = nullptr;
  DXGI_OUTDUPL_FRAME_INFO frame_info;
  HRESULT hr = state.duplication->AcquireNextFrame(0, &frame_info, &resource);

  if (FAILED(hr)) {
    return false;
  }

  ID3D11Texture2D* acquired_texture = nullptr;
  if (FAILED(resource->QueryInterface(__uuidof(ID3D11Texture2D), (void**)&acquired_texture))) {
    resource->Release();
    state.duplication->ReleaseFrame();
    return false;
  }

  state.context->CopyResource(state.staging_texture, acquired_texture);

  D3D11_MAPPED_SUBRESOURCE mapped;
  if (FAILED(state.context->Map(state.staging_texture, 0, D3D11_MAP_READ, 0, &mapped))) {
    acquired_texture->Release();
    resource->Release();
    state.duplication->ReleaseFrame();
    return false;
  }

  int pitch = mapped.RowPitch;
  int width = std::min(state.width, pitch / 4);
  pixels.resize(state.height * width * 4);
  for (int y = 0; y < state.height; ++y) {
    memcpy(pixels.data() + y * width * 4, (uint8_t*)mapped.pData + y * pitch, width * 4);
  }

  state.context->Unmap(state.staging_texture, 0);
  acquired_texture->Release();
  resource->Release();
  state.duplication->ReleaseFrame();
  return true;
}

bool CaptureDirtyRects(ScreenCaptureState& state, std::vector<uint8_t>& pixels,
                       std::vector<int>& dirty_rects) {
  if (!CaptureFrame(state, pixels)) return false;
  dirty_rects.clear();
  dirty_rects.push_back(0);
  dirty_rects.push_back(0);
  dirty_rects.push_back(state.width);
  dirty_rects.push_back(state.height);
  return true;
}

void CleanupCapture(ScreenCaptureState& state) {
  if (state.staging_texture) {
    state.staging_texture->Release();
    state.staging_texture = nullptr;
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
}
