#!/bin/bash

# Configuration
FLUTTER_PATH=$(command -v flutter || echo "flutter")
DART_PATH=$(command -v dart || echo "dart")

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
    echo "[INFO] Building Wear OS Release APK..."
    # --split-per-abi is recommended for Wear OS to keep APK sizes small
    $FLUTTER_PATH build apk --release --split-per-abi
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
