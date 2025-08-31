#!/bin/bash

# Download Whisper model for voice dictation
# This script downloads the base English model (142MB)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODEL_DIR="$PROJECT_ROOT/data/models"
MODEL_FILE="$MODEL_DIR/ggml-base.en.bin"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "Whisper Model Downloader"
echo "========================"
echo ""

# Create model directory if it doesn't exist
mkdir -p "$MODEL_DIR"

# Check if model already exists
if [ -f "$MODEL_FILE" ]; then
    echo -e "${GREEN}✓ Model already exists at: $MODEL_FILE${NC}"
    echo ""
    read -p "Re-download? (y/n): " REDOWNLOAD
    if [ "$REDOWNLOAD" != "y" ]; then
        echo "Keeping existing model."
        exit 0
    fi
    echo "Removing old model..."
    rm -f "$MODEL_FILE"
fi

echo "Downloading Whisper base.en model (142MB)..."
echo "This is a one-time download."
echo ""

# Download with wget or curl
if command -v wget &> /dev/null; then
    wget -O "$MODEL_FILE" "$MODEL_URL" --show-progress
elif command -v curl &> /dev/null; then
    curl -L -o "$MODEL_FILE" "$MODEL_URL" --progress-bar
else
    echo -e "${RED}Error: Neither wget nor curl found. Please install one.${NC}"
    exit 1
fi

# Verify download
if [ -f "$MODEL_FILE" ]; then
    SIZE=$(stat -c%s "$MODEL_FILE" 2>/dev/null || stat -f%z "$MODEL_FILE" 2>/dev/null)
    SIZE_MB=$((SIZE / 1024 / 1024))
    
    if [ "$SIZE_MB" -lt 100 ]; then
        echo -e "${RED}Error: Downloaded file is too small (${SIZE_MB}MB). Download may have failed.${NC}"
        rm -f "$MODEL_FILE"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✓ Model downloaded successfully!${NC}"
    echo "  Location: $MODEL_FILE"
    echo "  Size: ${SIZE_MB}MB"
    echo ""
    echo "You can now use voice dictation!"
else
    echo -e "${RED}Error: Download failed${NC}"
    exit 1
fi