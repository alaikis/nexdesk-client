import 'dart:typed_data';
import 'package:flutter/services.dart';

/// Windows desktop screen capture via DXGI Desktop Duplication
class WindowsScreenCapture {
  static const _channel = MethodChannel('nex.flutter/screen_capture_windows');

  /// Enumerate all displays
  static Future<List<Map<String, dynamic>>> enumerateDisplays() async {
    final result = await _channel.invokeMethod<List<dynamic>>('enumerateDisplays');
    return result?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Start capturing a specific display
  /// Returns a texture ID for rendering
  static Future<int> startCapture(int displayIndex) async {
    final result = await _channel.invokeMethod<int>('startCapture', {
      'displayIndex': displayIndex,
    });
    return result ?? -1;
  }

  /// Stop capturing
  static Future<void> stopCapture(int textureId) async {
    await _channel.invokeMethod('stopCapture', {'textureId': textureId});
  }

  /// Get the latest frame as raw pixels (for WebRTC encoding)
  static Future<Uint8List?> getFrame(int textureId) async {
    final result = await _channel.invokeMethod<Uint8List>('getFrame', {
      'textureId': textureId,
    });
    return result;
  }

  /// Get dirty rectangles since last frame
  /// Returns map with 'pixels' (full frame) and 'dirtyRects' (x,y,w,h list)
  static Future<Map<String, dynamic>?> getDirtyFrame(int textureId) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getDirtyFrame', {
      'textureId': textureId,
    });
    if (result == null) return null;
    return {
      'pixels': result['pixels'] as Uint8List?,
      'dirtyRects': (result['dirtyRects'] as List<dynamic>?)?.cast<int>() ?? [],
    };
  }

  /// Check if screen capture is supported
  static Future<bool> isSupported() async {
    final result = await _channel.invokeMethod<bool>('isSupported');
    return result ?? false;
  }
}
