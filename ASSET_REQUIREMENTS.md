# App Icon & Splash Screen Requirements

## Current State

- **Android**: Default Flutter `ic_launcher.png` is present in all `mipmap-*` densities.
- **iOS**: `Assets.xcassets/AppIcon.appiconset/` directory is missing.
- **macOS**: Custom icons (`app_icon_*.png`) already exist in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`.
- **Windows**: Default `app_icon.ico` is present in `windows/runner/resources/`.
- **Linux**: No custom icon directory configured.

## Required Assets

| Platform | Sizes | Path |
|----------|-------|------|
| Android | mdpi (48), hdpi (72), xhdpi (96), xxhdpi (144), xxxhdpi (192) | `android/app/src/main/res/mipmap-*/ic_launcher.png` |
| iOS | 16x16 to 1024x1024 (see Contents.json) | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` |
| macOS | 16x16 to 1024x1024 | `macos/Runner/Assets.xcassets/AppIcon.appiconset/` (already present) |
| Windows | 16x16, 32x32, 48x48, 64x64, 128x128, 256x256 | `windows/runner/resources/app_icon.ico` |
| Linux | 64x64, 128x128, 256x256, 512x512 | `linux/flutter/` (configure in CMakeLists.txt) |

## Action

Replace default icons with NEX-branded assets before release. Splash screen is not configured; add via `flutter_native_splash` package if needed.
