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

## GitHub Actions

Push a tag matching `v*` (e.g. `v0.1.0`) to trigger automated builds and GitHub Release creation.
