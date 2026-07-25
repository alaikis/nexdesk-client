# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0-alpha.1] - 2026-07-25

### Added
- **Multi-platform Support**
  - Windows: DXGI Desktop Duplication screen capture + SendInput injection
  - Android: MediaProjection frame capture + input injection
  - macOS: ScreenCaptureKit (SCStream) + CGEvent injection
  - Linux: X11 XShmGetImage + XTest injection (AppImage, .deb, .rpm, Snap, Flatpak)
  - iOS: ReplayKit screen capture (input injection not supported)

- **Security**
  - End-to-end encryption (X25519 + ChaCha20-Poly1305 + Ed25519)
  - Two-factor authentication (TOTP, RFC 6238)
  - Session password protection
  - Device identity signing

- **Core Features**
  - WebRTC P2P connection with STUN/TURN
  - File transfer with progress tracking
  - Clipboard sync (text)
  - Session recording (start/stop/list)
  - Real-time text chat
  - Audio streaming with mute control
  - Quality profiles (auto/low/medium/high)
  - Device favorites, groups, search, recent history
  - Wake-on-LAN support

- **Web Frontend**
  - Real API integration (all pages)
  - Authentication guard
  - Dark mode support
  - Toast notifications
  - Responsive design (mobile/tablet/desktop)
  - SEO metadata with prerender

- **CI/CD**
  - GitHub Actions automated builds
  - Multi-platform release automation
  - Nightly builds
  - PR verification

### Changed
- Migrated from XOR fake encryption to real E2EE
- Improved TOTP implementation to RFC 6238 standard
- Refactored backend routes into separate files

### Fixed
- Registration now returns JWT token for auto-login
- Login error messages no longer expose technical details
- All web pages now use real API instead of mock data

[Unreleased]: https://github.com/alaikis/nexdesk-client/compare/v0.1.0-alpha.1...HEAD
[0.1.0-alpha.1]: https://github.com/alaikis/nexdesk-client/releases/tag/v0.1.0-alpha.1
