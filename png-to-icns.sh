#!/bin/bash

# PNG to ICNS Converter Script
# Converts a PNG image to ICNS format with all required sizes
# Usage: ./png-to-icns.sh input.png [output.icns]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_info() {
    echo -e "${YELLOW}$1${NC}"
}

# Check if input file is provided
if [ $# -lt 1 ]; then
    print_error "Usage: $0 <input.png> [output.icns]"
    echo "Example: $0 icon.png icon.icns"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${2:-${INPUT_FILE%.*}.icns}"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    print_error "Input file not found: $INPUT_FILE"
    exit 1
fi

# Check if input is a PNG file
if [[ ! "$INPUT_FILE" =~ \.(png|PNG)$ ]]; then
    print_error "Input file must be a PNG image"
    exit 1
fi

# Create temporary iconset directory
ICONSET_NAME="${OUTPUT_FILE%.*}.iconset"
TEMP_DIR=$(mktemp -d)
ICONSET_DIR="$TEMP_DIR/$ICONSET_NAME"

print_info "Creating iconset directory: $ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Function to resize image using sips
resize_image() {
    local size=$1
    local output=$2
    local scale=$3
    
    if [ -z "$scale" ]; then
        sips -z "$size" "$size" "$INPUT_FILE" --out "$output" > /dev/null 2>&1
    else
        local actual_size=$((size * scale))
        sips -z "$actual_size" "$actual_size" "$INPUT_FILE" --out "$output" > /dev/null 2>&1
    fi
}

print_info "Generating icon sizes..."

# Generate all required ICNS sizes
# Standard sizes
resize_image 16 "$ICONSET_DIR/icon_16x16.png"
resize_image 32 "$ICONSET_DIR/icon_16x16@2x.png" 2
resize_image 32 "$ICONSET_DIR/icon_32x32.png"
resize_image 64 "$ICONSET_DIR/icon_32x32@2x.png" 2
resize_image 128 "$ICONSET_DIR/icon_128x128.png"
resize_image 256 "$ICONSET_DIR/icon_128x128@2x.png" 2
resize_image 256 "$ICONSET_DIR/icon_256x256.png"
resize_image 512 "$ICONSET_DIR/icon_256x256@2x.png" 2
resize_image 512 "$ICONSET_DIR/icon_512x512.png"
resize_image 1024 "$ICONSET_DIR/icon_512x512@2x.png" 2

print_success "All icon sizes generated"

# Convert iconset to ICNS using iconutil
print_info "Converting iconset to ICNS format..."
if iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_FILE" 2>/dev/null; then
    print_success "ICNS file created successfully: $OUTPUT_FILE"
    
    # Get file size
    FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
    print_info "File size: $FILE_SIZE"
else
    print_error "Failed to create ICNS file"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Clean up temporary directory
rm -rf "$TEMP_DIR"

print_success "Done!"


