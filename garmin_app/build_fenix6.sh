#!/bin/bash

# Configuration
SDK_BIN="/home/aginies/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b/bin"
# Use relative path from script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"
PROJECT_DIR="$SCRIPT_DIR/JKDApp"

# Extract version from root pubspec.yaml (X.X.X part only)
VERSION=$(grep "^version: " "$ROOT_DIR/pubspec.yaml" | cut -d ' ' -f 2 | cut -d '+' -f 1)

# Cleanup option
if [ "$1" == "clean" ] || [ "$1" == "--clean" ]; then
    echo "Cleaning up build artifacts..."
    rm -rf "$SCRIPT_DIR/bin"
    rm -rf "$PROJECT_DIR/bin"
    echo "Cleanup complete."
    exit 0
fi

# Determine devices to build
if [ "$1" == "all" ]; then
    DEVICES=$(grep "<iq:product id=" "$PROJECT_DIR/manifest.xml" | sed 's/.*id="\([^"]*\)".*/\1/')
    echo "Building JKDApp for ALL supported devices..."
elif [ -n "$1" ]; then
    DEVICES="$1"
    echo "Building JKDApp for $DEVICES..."
else
    DEVICES="fenix6spro"
    echo "Building JKDApp for default device: $DEVICES..."
fi

# Ensure output directory exists
mkdir -p "$SCRIPT_DIR/bin"

# Build function
build_device() {
    local DEVICE=$1
    local OUTPUT_FILE="$SCRIPT_DIR/bin/JKDApp-${VERSION}_${DEVICE}.prg"
    
    echo "--------------------------------------"
    echo "Building for: $DEVICE"
    
    "$SDK_BIN/monkeyc" \
        -o "$OUTPUT_FILE" \
        -f "$PROJECT_DIR/monkey.jungle" \
        -y "$PROJECT_DIR/developer_key" \
        -d "$DEVICE" \
        --optimization p \
        -r

    if [ $? -eq 0 ]; then
        echo "SUCCESS: $OUTPUT_FILE"
    else
        echo "FAILED: $DEVICE"
        return 1
    fi
}

# Loop through devices
FAILED_DEVICES=""
for DEV in $DEVICES; do
    build_device "$DEV" || FAILED_DEVICES="$FAILED_DEVICES $DEV"
done

if [ -n "$FAILED_DEVICES" ]; then
    echo "--------------------------------------"
    echo "BUILD COMPLETED WITH ERRORS!"
    echo "Failed devices:$FAILED_DEVICES"
    exit 1
else
    echo "--------------------------------------"
    echo "ALL BUILDS SUCCESSFUL!"
    echo "Output directory: $SCRIPT_DIR/bin/"
    exit 0
fi
