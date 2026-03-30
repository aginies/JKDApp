#!/bin/bash

# Configuration
FLUTTER_PATH="/home/aginies/devel/flutter/bin/flutter"
DART_PATH="/home/aginies/devel/flutter/bin/dart"
DB_PATH=".dart_tool/sqflite_common_ffi/databases/jkd_notes.db"

# OS Detection
IS_MACOS=false
IS_WINDOWS=false
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MACOS=true
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    IS_WINDOWS=true
fi

function show_help() {
    echo "JKD App Build & Verify Script"
    echo "Usage: ./build_and_verify.sh [command1] [command2] ..."
    echo ""
    echo "Available commands:"
    echo "  run               - Run the app (Linux desktop)"
    echo "  reset_db          - Delete the local database (trigger fresh seed)"
    echo "  cleanup           - Remove build artifacts (flutter clean)"
    echo "  update_deps       - Update flutter dependencies (pub get)"
    echo "  format_code       - Format all dart files"
    echo "  format_check      - Check if dart files are formatted"
    echo "  quality_checks    - Run format check and analyze"
    echo "  build_apk         - Build release APK"
    echo "  build_macos       - Build release macOS (macOS only)"
    echo "  build_windows     - Build release Windows (Windows only)"
    echo "  build_linux       - Build release Linux (standard bundle)"
    echo "  build_appimage    - Build Linux AppImage (requires appimage-builder)"
    echo "  all               - Run full pipeline (Cleanup, Deps, Quality, Build APK)"
    echo "  help              - Show this help message"
}

function run() {
    echo "[INFO] Running JKD App..."
    $FLUTTER_PATH run -d linux
}

function reset_db() {
    if [ -f "$DB_PATH" ]; then
        echo "[INFO] Deleting database at $DB_PATH..."
        rm "$DB_PATH"
        echo "[SUCCESS] Database deleted."
    else
        echo "[WARNING] Database file not found at $DB_PATH"
    fi
}

function cleanup() {
    echo "[INFO] Cleaning up previous builds..."
    $FLUTTER_PATH clean
}

function update_deps() {
    echo "[INFO] Updating Flutter dependencies..."
    $FLUTTER_PATH pub get
}

function format_code() {
    echo "[INFO] Formatting code..."
    $DART_PATH format .
}

function format_check() {
    echo "[INFO] Checking code formatting..."
    $DART_PATH format --output=none --set-exit-if-changed . || { echo "[ERROR] Code not formatted. Run './build_and_verify.sh format_code'."; exit 1; }
}

function quality_checks() {
    format_check
    echo "[INFO] Running static analysis..."
    $FLUTTER_PATH analyze || { echo "[ERROR] Analysis failed. Fix issues before building."; exit 1; }
    echo "[SUCCESS] Quality checks passed."
}

function build_apk() {
    echo "[INFO] Building Release APK..."
    $FLUTTER_PATH build apk --release
}

function build_macos() {
    if [ "$IS_MACOS" = false ]; then
        echo "[ERROR] macOS build requires macOS environment."
        exit 1
    fi
    echo "[INFO] Building Release macOS..."
    $FLUTTER_PATH build macos --release
}

function build_windows() {
    if [ "$IS_WINDOWS" = false ]; then
        echo "[ERROR] Windows build requires Windows environment."
        exit 1
    fi
    echo "[INFO] Building Release Windows..."
    $FLUTTER_PATH build windows --release
}

function build_linux() {
    echo "[INFO] Building Release Linux..."
    $FLUTTER_PATH build linux --release
}

function build_appimage() {
    echo "[INFO] Starting AppImage build process..."
    
    # 1. Build standard linux release
    build_linux
    
    # 2. Check for appimage-builder
    if ! command -v appimage-builder &> /dev/null; then
        echo "[ERROR] appimage-builder not found. Install it first: https://appimage-builder.readthedocs.io/"
        exit 1
    fi

    # 3. Create a minimal AppImage-builder recipe if it doesn't exist
    if [ ! -f "AppImageBuilder.yml" ]; then
        echo "[INFO] Creating AppImageBuilder.yml recipe..."
        cat <<EOF > AppImageBuilder.yml
version: 1
AppDir:
  path: build/linux/x64/release/bundle
  app_info:
    id: org.ginies.jkd_app
    name: jkd_app
    icon: utilities-terminal
    version: 1.0.0
    exec: jkd_app
  apt:
    arch: amd64
    sources:
      - sourceline: deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
    include:
      - libsqlite3-0
      - libcanberra-gtk-module
      - libcanberra-gtk3-module
  runtime:
    env:
      PATH: '\$PATH:\$APPDIR/usr/bin'

AppImage:
  update-information: None
  sign-key: None
  arch: x86_64
EOF
    fi

    echo "[INFO] Running appimage-builder..."
    appimage-builder --recipe AppImageBuilder.yml --skip-test
}

function all() {
    cleanup
    update_deps
    quality_checks
    build_apk
}

if [ $# -eq 0 ]; then
    show_help
else
    for func in "$@"; do
        if [ "$func" == "help" ]; then
            show_help
        elif declare -f "$func" > /dev/null; then
            "$func"
        else
            echo "[ERROR] Function '$func' not found."
            exit 1
        fi
    done
fi
