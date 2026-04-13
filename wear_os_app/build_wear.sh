#!/bin/bash

# Configuration
FLUTTER_PATH=$(command -v flutter || echo "flutter")
DART_PATH=$(command -v dart || echo "dart")
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Extract version from root pubspec.yaml (X.X.X part only)
VERSION=$(grep "^version: " "$ROOT_DIR/pubspec.yaml" | cut -d ' ' -f 2 | cut -d '+' -f 1)

function show_help() {
    echo "JKD Wear OS App Build Script"
    echo "Usage: ./build_wear.sh [command1] [command2] ..."
    echo ""
    echo "Available commands:"
    echo "  cleanup           - Remove build artifacts (flutter clean)"
    echo "  update_deps       - Update flutter dependencies (pub get)"
    echo "  format_code       - Format all dart files"
    echo "  analyze           - Run static analysis"
    echo "  build             - Build Wear OS Release APK (split per ABI)"
    echo "  all               - Run full pipeline (Cleanup, Deps, Analyze, Build)"
    echo "  help              - Show this help message"
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

function analyze() {
    echo "[INFO] Running static analysis..."
    $FLUTTER_PATH analyze || { echo "[ERROR] Analysis failed."; exit 1; }
}

function build() {
    echo "[INFO] Building Wear OS Release APK (v$VERSION)..."
    # --split-per-abi is recommended for Wear OS to keep APK sizes small
    $FLUTTER_PATH build apk --release --split-per-abi
    
    # Ensure bin directory exists
    mkdir -p "$SCRIPT_DIR/bin"
    
    # Copy resulting APKs to bin folder with versioning
    echo "[INFO] Organizing binaries in $SCRIPT_DIR/bin/..."
    for apk in build/app/outputs/flutter-apk/app-*-release.apk; do
        if [ -f "$apk" ]; then
            abi=$(basename "$apk" | sed 's/app-//' | sed 's/-release.apk//')
            target_name="JKDApp-WearOS-${VERSION}-${abi}.apk"
            cp "$apk" "$SCRIPT_DIR/bin/$target_name"
            echo "  -> Created: $target_name"
        fi
    done
}

function all() {
    cleanup
    update_deps
    analyze
    build
}

if [ $# -eq 0 ]; then
    show_help
else
    while [ $# -gt 0 ]; do
        func=$1
        if [ "$func" == "help" ]; then
            show_help
            shift
        elif declare -f "$func" > /dev/null; then
            "$func"
            shift
        else
            echo "[ERROR] Function '$func' not found."
            exit 1
        fi
    done
fi
