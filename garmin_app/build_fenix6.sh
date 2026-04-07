#!/bin/bash

# Configuration
SDK_BIN="/home/aginies/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b/bin"
# Use relative path from script location
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$SCRIPT_DIR/JKDApp"
OUTPUT_FILE="$SCRIPT_DIR/bin/JKDApp_fenix6spro.prg"
DEVICE="fenix6spro"

# Cleanup option
if [ "$1" == "clean" ] || [ "$1" == "--clean" ]; then
    echo "Cleaning up build artifacts..."
    rm -rf "$SCRIPT_DIR/bin"
    rm -rf "$PROJECT_DIR/bin"
    echo "Cleanup complete."
    exit 0
fi

echo "Building JKDApp for $DEVICE..."

# Ensure output directory exists
mkdir -p "$SCRIPT_DIR/bin"

# Run the Monkey C compiler
"$SDK_BIN/monkeyc" \
    -o "$OUTPUT_FILE" \
    -f "$PROJECT_DIR/monkey.jungle" \
    -y "$PROJECT_DIR/developer_key" \
    -d "$DEVICE" \
    -r

if [ $? -eq 0 ]; then
    echo "--------------------------------------"
    echo "BUILD SUCCESSFUL!"
    echo "Output: $OUTPUT_FILE"
    echo "--------------------------------------"
    echo "To install: Copy the file to your watch's /GARMIN/APPS folder."
else
    echo "BUILD FAILED!"
    exit 1
fi
