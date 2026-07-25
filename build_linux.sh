#!/bin/bash
# Linux Multi-Format Package Builder for NEX
# Supports: AppImage, .deb, .rpm, Snap, Flatpak
#
# Usage: ./build_linux.sh [appimage|deb|rpm|snap|flatpak|all]

set -e

APP_NAME="nex"
APP_ID="com.elstella.nex"
VERSION="1.0.0"
DESCRIPTION="NEX - Secure WebRTC Remote Desktop"
AUTHOR="NEX Team"
BUILD_DIR="build/linux"
OUTPUT_DIR="dist/linux"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[BUILD]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Build Flutter Linux app first
build_flutter() {
    log "Building Flutter Linux release..."
    flutter build linux --release
    log "Flutter build complete"
}

# Build AppImage
build_appimage() {
    log "Building AppImage..."
    
    local appdir="${BUILD_DIR}/AppDir"
    rm -rf "$appdir"
    
    # Create AppDir structure
    mkdir -p "${appdir}/usr/bin"
    mkdir -p "${appdir}/usr/lib"
    mkdir -p "${appdir}/usr/share/applications"
    mkdir -p "${appdir}/usr/share/icons/hicolor/256x256/apps"
    mkdir -p "${appdir}/usr/share/metainfo"
    
    # Copy Flutter build
    cp -r build/linux/x64/release/bundle/* "${appdir}/usr/bin/"
    
    # Create desktop entry
    cat > "${appdir}/usr/share/applications/${APP_ID}.desktop" << EOF
[Desktop Entry]
Name=NEX
Comment=${DESCRIPTION}
Exec=${APP_NAME}
Icon=${APP_NAME}
Type=Application
Categories=Network;RemoteAccess;
StartupNotify=true
Keywords=remote;desktop;webrtc;
EOF
    
    # Copy icon (placeholder - replace with actual icon)
    cp assets/icons/app_icon_256.png "${appdir}/usr/share/icons/hicolor/256x256/apps/${APP_NAME}.png" 2>/dev/null || \
        warn "App icon not found, using placeholder"
    
    # Create AppImage using linuxdeploy
    if command -v linuxdeploy &> /dev/null; then
        linuxdeploy --appdir "$appdir" --output appimage
        mkdir -p "$OUTPUT_DIR"
        mv *.AppImage "${OUTPUT_DIR}/${APP_NAME}-${VERSION}-x86_64.AppImage"
        log "AppImage built: ${OUTPUT_DIR}/${APP_NAME}-${VERSION}-x86_64.AppImage"
    else
        warn "linuxdeploy not found, creating portable archive instead"
        mkdir -p "$OUTPUT_DIR"
        tar -czf "${OUTPUT_DIR}/${APP_NAME}-${VERSION}-linux-portable.tar.gz" -C build/linux/x64/release/bundle .
        log "Portable archive built: ${OUTPUT_DIR}/${APP_NAME}-${VERSION}-linux-portable.tar.gz"
    fi
    
    rm -rf "$appdir"
}

# Build .deb package
build_deb() {
    log "Building .deb package..."
    
    local debdir="${BUILD_DIR}/deb"
    rm -rf "$debdir"
    
    # Create DEBIAN control
    mkdir -p "${debdir}/DEBIAN"
    cat > "${debdir}/DEBIAN/control" << EOF
Package: ${APP_NAME}
Version: ${VERSION}
Section: net
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libblkid1, liblzma5, libzstd1, libxxhash0, libglib2.0-0, libdbus-1-3, libgl1, libx11-6, libxtst6, libjpeg62
Maintainer: ${AUTHOR}
Description: ${DESCRIPTION}
 Secure WebRTC-based remote desktop application
 with end-to-end encryption and cross-platform support.
EOF
    
    # Create install directory
    mkdir -p "${debdir}/usr/bin"
    mkdir -p "${debdir}/usr/lib/${APP_NAME}"
    mkdir -p "${debdir}/usr/share/applications"
    mkdir -p "${debdir}/usr/share/icons/hicolor/256x256/apps"
    
    # Copy Flutter build
    cp -r build/linux/x64/release/bundle/* "${debdir}/usr/lib/${APP_NAME}/"
    
    # Create launcher script
    cat > "${debdir}/usr/bin/${APP_NAME}" << 'EOF'
#!/bin/bash
exec /usr/lib/nex/flutter_app "$@"
EOF
    chmod +x "${debdir}/usr/bin/${APP_NAME}"
    
    # Create desktop entry
    cat > "${debdir}/usr/share/applications/${APP_ID}.desktop" << EOF
[Desktop Entry]
Name=NEX
Comment=${DESCRIPTION}
Exec=${APP_NAME}
Icon=${APP_NAME}
Type=Application
Categories=Network;RemoteAccess;
StartupNotify=true
EOF
    
    # Build .deb
    mkdir -p "$OUTPUT_DIR"
    dpkg-deb --build "${debdir}" "${OUTPUT_DIR}/${APP_NAME}-${VERSION}-amd64.deb"
    log ".deb built: ${OUTPUT_DIR}/${APP_NAME}-${VERSION}-amd64.deb"
    
    rm -rf "$debdir"
}

# Build .rpm package
build_rpm() {
    log "Building .rpm package..."
    
    if ! command -v rpmbuild &> /dev/null; then
        warn "rpmbuild not found, skipping .rpm"
        return
    fi
    
    local rpmdir="${BUILD_DIR}/rpm"
    rm -rf "$rpmdir"
    
    # Create RPM build structure
    mkdir -p "${rpmdir}"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
    
    # Create spec file
    cat > "${rpmdir}/SPECS/${APP_NAME}.spec" << EOF
Name:           ${APP_NAME}
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        ${DESCRIPTION}
License:        MIT
BuildArch:      x86_64

%description
Secure WebRTC-based remote desktop application
with end-to-end encryption and cross-platform support.

%install
mkdir -p %{buildroot}/usr/lib/${APP_NAME}
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/share/applications
cp -r build/linux/x64/release/bundle/* %{buildroot}/usr/lib/${APP_NAME}/
cat > %{buildroot}/usr/bin/${APP_NAME} << 'EOF'
#!/bin/bash
exec /usr/lib/nex/flutter_app "$@"
EOF
chmod +x %{buildroot}/usr/bin/${APP_NAME}
cat > %{buildroot}/usr/share/applications/${APP_ID}.desktop << EOF
[Desktop Entry]
Name=NEX
Comment=${DESCRIPTION}
Exec=${APP_NAME}
Icon=${APP_NAME}
Type=Application
Categories=Network;RemoteAccess;
EOF

%files
/usr/lib/${APP_NAME}/*
/usr/bin/${APP_NAME}
/usr/share/applications/${APP_ID}.desktop
EOF
    
    # Build RPM
    mkdir -p "$OUTPUT_DIR"
    rpmbuild --define "_topdir ${rpmdir}" -bb "${rpmdir}/SPECS/${APP_NAME}.spec"
    mv "${rpmdir}/RPMS/x86_64/"*.rpm "${OUTPUT_DIR}/"
    log ".rpm built: ${OUTPUT_DIR}/${APP_NAME}-${VERSION}-1.x86_64.rpm"
    
    rm -rf "$rpmdir"
}

# Build Snap package
build_snap() {
    log "Building Snap package..."
    
    if ! command -v snapcraft &> /dev/null; then
        warn "snapcraft not found, skipping Snap"
        return
    fi
    
    local snapdir="${BUILD_DIR}/snap"
    rm -rf "$snapdir"
    mkdir -p "$snapdir"
    
    # Create snapcraft.yaml
    cat > "${snapdir}/snapcraft.yaml" << EOF
name: ${APP_NAME}
version: '${VERSION}'
summary: ${DESCRIPTION}
description: |
  Secure WebRTC-based remote desktop application
  with end-to-end encryption and cross-platform support.
grade: stable
confinement: strict
base: core22

apps:
  ${APP_NAME}:
    command: flutter_app
    extensions: [gnome]
    plugs:
      - home
      - network
      - network-bind
      - desktop
      - desktop-legacy
      - x11
      - wayland
      - opengl
      - pulseaudio
      - camera
      - screen-inhibit-control
      - login-session-observe

parts:
  ${APP_NAME}:
    source: build/linux/x64/release/bundle
    plugin: dump
    organize:
      '*': usr/lib/${APP_NAME}/
    stage-packages:
      - libgtk-3-0
      - libblkid1
      - liblzma5
      - libzstd1
      - libxxhash0
      - libglib2.0-0
      - libdbus-1-3
      - libgl1
      - libx11-6
      - libxtst6
      - libjpeg62
EOF
    
    # Build Snap
    cd "$snapdir"
    snapcraft
    mkdir -p "../../${OUTPUT_DIR}"
    mv *.snap "../../${OUTPUT_DIR}/${APP_NAME}-${VERSION}.snap"
    cd ../..
    
    log "Snap built: ${OUTPUT_DIR}/${APP_NAME}-${VERSION}.snap"
    rm -rf "$snapdir"
}

# Build Flatpak
build_flatpak() {
    log "Building Flatpak..."
    
    if ! command -v flatpak-builder &> /dev/null; then
        warn "flatpak-builder not found, skipping Flatpak"
        return
    fi
    
    local fpdir="${BUILD_DIR}/flatpak"
    rm -rf "$fpdir"
    mkdir -p "$fpdir"
    
    # Create Flatpak manifest
    cat > "${fpdir}/${APP_ID}.yaml" << EOF
app-id: ${APP_ID}
runtime: org.freedesktop.Platform
runtime-version: '23.08'
sdk: org.freedesktop.Sdk
command: flutter_app

finish-args:
  --share=ipc
  --socket=fallback-x11
  --socket=wayland
  --socket=pulseaudio
  --share=network
  --device=dri
  --talk-name=org.freedesktop.Notifications
  --filesystem=home

modules:
  - name: ${APP_NAME}
    buildsystem: simple
    build-commands:
      - install -D flutter_app /app/bin/flutter_app
      - cp -r data /app/bin/data
      - cp -r lib /app/lib
      - install -D ${APP_ID}.desktop /app/share/applications/${APP_ID}.desktop
    sources:
      - type: dir
        path: ../../build/linux/x64/release/bundle
EOF
    
    # Build Flatpak
    mkdir -p "$OUTPUT_DIR"
    flatpak-builder --force-clean --repo="${fpdir}/repo" "$fpdir/build" "${fpdir}/${APP_ID}.yaml"
    flatpak build-bundle "${fpdir}/repo" "${OUTPUT_DIR}/${APP_NAME}-${VERSION}.flatpak" ${APP_ID}
    log "Flatpak built: ${OUTPUT_DIR}/${APP_NAME}-${VERSION}.flatpak"
    
    rm -rf "$fpdir"
}

# Main
main() {
    local target="${1:-all}"
    
    log "Building Linux packages for ${APP_NAME} v${VERSION}"
    log "Target: ${target}"
    
    mkdir -p "$OUTPUT_DIR"
    
    build_flutter
    
    case "$target" in
        appimage) build_appimage ;;
        deb) build_deb ;;
        rpm) build_rpm ;;
        snap) build_snap ;;
        flatpak) build_flatpak ;;
        all)
            build_appimage
            build_deb
            build_rpm
            build_snap
            build_flatpak
            ;;
        *) error "Unknown target: $target. Use: appimage|deb|rpm|snap|flatpak|all" ;;
    esac
    
    log "Build complete! Packages in ${OUTPUT_DIR}/"
    ls -la "$OUTPUT_DIR/"
}

main "$@"
