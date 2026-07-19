# flutter_webrtc Upgrade Path: 0.11.x → 1.5.x

## Current State
- Version: `flutter_webrtc 0.11.7`
- API: `RTCVideoView`, `MediaStream`, `RTCPeerConnection`
- Plugin registrant: old generated registrant

## Target State
- Version: `flutter_webrtc 1.5.2`
- API: `RTCVideoView` (unchanged surface), `MediaStream` (streams now via `getUserMedia`)
- Plugin registrant: new generated registrant

## Breaking Changes
1. `flutter_webrtc` 1.x separates platform view binding
2. `getUserMedia` constraints schema updated
3. `WebRTC.platformViewRegistry` registration required for Android

## Migration Plan
1. Bump `pubspec.yaml` to `1.5.2`
2. Run `flutter pub upgrade`
3. Regenerate platform plugin registrants (`flutter pub get`)
4. Update `MainActivity.kt` to register platform view factory
5. Verify `RTCVideoView` renderer binding
6. Run widget tests + manual screen-share test

## Risks
- Android platform view factory registration differs by embedding version
- `getUserMedia` constraint changes may affect camera selection

## Open Questions
- Does `flutter_webrtc 1.5.x` support desktop (Linux/Windows/macOS) equally?
- Any TURN/STUN behavioral changes in wrapped `libwebrtc`?
