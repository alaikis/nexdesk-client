# NEX Remote Desktop Client

Flutter multi-platform client for [NEX](https://github.com/elstella/nex.elstella.com).

Supported platforms:
- Windows (x64)
- macOS (arm64/x64)
- Linux (x64)
- Android (arm64-v8a)

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Build Release

```bash
# Desktop
flutter build linux --release
flutter build macos --release
flutter build windows --release

# Android
flutter build apk --release
flutter build appbundle --release
```

## Platform-Specific Notes

### Android
- Release signing uses `android/keystore.properties` (git-ignored).
- Foreground service for screen capture is declared in `AndroidManifest.xml`.
- ProGuard rules are in `android/app/proguard-rules.pro`.

### iOS
- Add `ios/Runner/Info.plist` with `NSCameraUsageDescription` and screen-capture usage descriptions before App Store submission.
- Xcode release signing and provisioning profiles are configured per Apple Developer account.

### macOS
- Enable "Hardened Runtime" and notarization in Xcode before distributing outside the App Store.
- See Apple documentation: [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime).

### Windows
- Update `windows/runner/resources/app_icon.ico` and version info in `windows/runner/Runner.rc` before release.
- Consider MSIX packaging for Microsoft Store distribution.

## GitHub Actions

Push a tag matching `v*` (e.g. `v0.1.0`) to trigger automated builds and GitHub Release creation.
