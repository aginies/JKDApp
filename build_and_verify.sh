#!/bin/bash

# Configuration
FLUTTER_PATH=$(command -v flutter || echo "/home/aginies/devel/flutter/bin/flutter")
DART_PATH=$(command -v dart || echo "/home/aginies/devel/flutter/bin/dart")
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
    echo "  run_tests         - Run flutter tests"
    echo "  quality_checks    - Run format check, analyze and tests"
    echo "  update_version    - Update app version in all files (usage: ./build_and_verify.sh update_version 1.5.1+3)"
    echo "  build_apk         - Build release APK"
    echo "  build_wearos      - Build Wear OS APK"
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

function run_tests() {
    echo "[INFO] Running tests..."
    $FLUTTER_PATH test || { echo "[ERROR] Tests failed. Fix issues before building."; exit 1; }
}

function quality_checks() {
    format_check
    echo "[INFO] Running static analysis..."
    $FLUTTER_PATH analyze || { echo "[ERROR] Analysis failed. Fix issues before building."; exit 1; }
    run_tests
    echo "[SUCCESS] Quality checks passed."
}

function update_version() {
    local INPUT_VERSION=$1
    if [ -z "$INPUT_VERSION" ]; then
        echo "[ERROR] Please provide a new version number (e.g., 1.5.1+3)"
        exit 1
    fi

    # Strip any leading 'v' from the input to normalize it
    local CLEAN_VERSION=$(echo $INPUT_VERSION | sed 's/^v//')

    echo "[INFO] Updating version to $CLEAN_VERSION..."

    # 1. Update pubspec.yaml (Must NOT have 'v' prefix)
    sed -i "s/^version: .*/version: $CLEAN_VERSION/" pubspec.yaml

    # 2. Update settings_screen.dart (Should have 'v' prefix for UI)
    # Match pattern vX.X.X+X or vX.X.X (v is optional in the search)
    sed -i "s/v\?[0-9]\+\.[0-9]\+\.[0-9]\+\(+[0-9]\+\)\?/v$CLEAN_VERSION/g" lib/screens/settings_screen.dart

    # 3. Update logging_service.dart
    sed -i "s/appVersion = \".*\"/appVersion = \"$CLEAN_VERSION\"/" lib/services/logging_service.dart

    # 4. Update README.md (Should have 'v' prefix)
    sed -i "s/Recent Updates (v.*)/Recent Updates (v$CLEAN_VERSION)/" README.md

    echo "[SUCCESS] Version updated to $CLEAN_VERSION in all files."
}

function build_apk() {
    echo "[INFO] Building Release APK..."
    $FLUTTER_PATH build apk --release
}

function build_wearos() {
    echo "[INFO] Building Wear OS APK..."
    cd wear_os_app && $FLUTTER_PATH build apk --release --split-per-abi && cd ..
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
    while [ $# -gt 0 ]; do
        func=$1
        if [ "$func" == "help" ]; then
            show_help
            shift
        elif [ "$func" == "update_version" ]; then
            update_version "$2"
            shift 2
        elif declare -f "$func" > /dev/null; then
            "$func"
            shift
        else
            echo "[ERROR] Function '$func' not found."
            exit 1
        fi
    done
fi
