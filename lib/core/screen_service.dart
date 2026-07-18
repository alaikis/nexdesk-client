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
