#ifndef RUNNER_WINDOWS_SCREEN_CAPTURE_H_
#define RUNNER_WINDOWS_SCREEN_CAPTURE_H_

#include <windows.h>
#include <dxgi1_2.h>
#include <d3d11.h>
#include <mutex>
#include <string>
#include <vector>
#include <map>

struct ScreenCaptureState {
  int display_index = 0;
  ID3D11Device* device = nullptr;
  ID3D11DeviceContext* context = nullptr;
  IDXGIOutputDuplication* duplication = nullptr;
  ID3D11Texture2D* staging_texture = nullptr;
  int width = 0;
  int height = 0;
  bool capture_window = false;
  int window_x = 0;
  int window_y = 0;
  int window_width = 0;
  int window_height = 0;
};

extern std::mutex g_capture_mutex;
extern std::map<int, ScreenCaptureState> g_captures;
extern int g_next_capture_id;

bool InitDXGICapture(int display_index, ScreenCaptureState& state);
bool CaptureFrame(ScreenCaptureState& state, std::vector<uint8_t>& pixels);
bool CaptureDirtyRects(ScreenCaptureState& state, std::vector<uint8_t>& pixels,
                       std::vector<int>& dirty_rects);
void CleanupCapture(ScreenCaptureState& state);

#endif  // RUNNER_WINDOWS_SCREEN_CAPTURE_H_
