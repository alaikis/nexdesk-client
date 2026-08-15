import 'dart:ui';

class ScreenInfo {
  final int id;
  final String name;
  final int width;
  final int height;
  final double scaleFactor;
  final bool isPrimary;

  ScreenInfo({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.scaleFactor,
    required this.isPrimary,
  });

  @override
  String toString() => 'Screen($name, $width×$height)';
}

class WindowInfo {
  final String id;
  final String title;
  final int processId;
  final int x;
  final int y;
  final int width;
  final int height;

  WindowInfo({
    required this.id,
    required this.title,
    required this.processId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() => {
    'window_id': id,
    'title': title,
    'process_id': processId,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory WindowInfo.fromJson(Map<String, dynamic> json) => WindowInfo(
    id: json['window_id'] as String? ?? json['hwnd'] as String? ?? json['windowId'] as String? ?? '',
    title: json['title'] as String? ?? '',
    processId: json['process_id'] as int? ?? json['processId'] as int? ?? 0,
    x: json['x'] as int? ?? json['bounds']?['x'] as int? ?? 0,
    y: json['y'] as int? ?? json['bounds']?['y'] as int? ?? 0,
    width: json['width'] as int? ?? json['bounds']?['width'] as int? ?? 0,
    height: json['height'] as int? ?? json['bounds']?['height'] as int? ?? 0,
  );
}

class ScreenService {
  static final ScreenService _instance = ScreenService._internal();
  factory ScreenService() => _instance;
  ScreenService._internal();

  List<ScreenInfo> _screens = [];
  bool _initialized = false;

  List<ScreenInfo> get screens => List.unmodifiable(_screens);

  Future<void> init() async {
    if (_initialized) return;

    try {
      final displays = PlatformDispatcher.instance.displays.toList();
      _screens = [];
      for (var i = 0; i < displays.length; i++) {
        final display = displays[i];
        final size = display.size;
        _screens.add(ScreenInfo(
          id: i,
          name: 'Display ${i + 1}',
          width: size.width.toInt(),
          height: size.height.toInt(),
          scaleFactor: display.devicePixelRatio,
          isPrimary: i == 0,
        ));
      }

      if (_screens.isEmpty) {
        _screens = [ScreenInfo(id: 0, name: 'Default Display', width: 1920, height: 1080, scaleFactor: 1.0, isPrimary: true)];
      }
      _initialized = true;
    } catch (e) {
      _screens = [ScreenInfo(id: 0, name: 'Default Display', width: 1920, height: 1080, scaleFactor: 1.0, isPrimary: true)];
    }
  }

  ScreenInfo getPrimary() => _screens.firstWhere((s) => s.isPrimary, orElse: () => _screens.first);
}
