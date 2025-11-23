#!/bin/bash

# ICNS to Xcode AppIcon Asset Converter
# Extracts an ICNS file and creates/updates Xcode AppIcon.appiconset
# Usage: ./icns-to-xcode-asset.sh [input.icns] [path/to/Assets.xcassets/AppIcon.appiconset]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_step() {
    echo -e "${BLUE}$1${NC}"
}

# Default paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ICNS="$SCRIPT_DIR/icon.icns"
DEFAULT_APPSET="$SCRIPT_DIR/swift/Stickers/Stickers/Assets.xcassets/AppIcon.appiconset"

# Parse arguments
INPUT_ICNS="${1:-$DEFAULT_ICNS}"
APPSET_DIR="${2:-$DEFAULT_APPSET}"

# Check if input ICNS file exists
if [ ! -f "$INPUT_ICNS" ]; then
    print_error "ICNS file not found: $INPUT_ICNS"
    echo "Usage: $0 [input.icns] [path/to/AppIcon.appiconset]"
    exit 1
fi

# Check if AppIcon.appiconset directory exists
if [ ! -d "$APPSET_DIR" ]; then
    print_error "AppIcon.appiconset directory not found: $APPSET_DIR"
    exit 1
fi

print_step "Extracting ICNS file: $INPUT_ICNS"

# Create temporary directory for extraction
TEMP_DIR=$(mktemp -d)
EXTRACT_DIR="$TEMP_DIR/extracted.iconset"

# Extract ICNS to iconset
if ! iconutil -c iconset "$INPUT_ICNS" -o "$EXTRACT_DIR" 2>/dev/null; then
    print_error "Failed to extract ICNS file"
    rm -rf "$TEMP_DIR"
    exit 1
fi

print_success "ICNS extracted successfully"

# Function to copy and rename icon file
copy_icon() {
    local source=$1
    local dest=$2
    if [ -f "$source" ]; then
        cp "$source" "$dest"
        print_info "  ✓ Copied $(basename "$source") → $(basename "$dest")"
        return 0
    else
        print_info "  ⚠ Missing: $(basename "$source")"
        return 1
    fi
}

# Function to generate missing icon from a larger one
generate_icon() {
    local size=$1
    local dest=$2
    local source=$3
    
    if [ -f "$source" ]; then
        sips -z "$size" "$size" "$source" --out "$dest" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_info "  ✓ Generated $(basename "$dest") from $(basename "$source")"
            return 0
        fi
    fi
    return 1
}

print_step "Copying icons to AppIcon.appiconset..."

# Copy all icon sizes to AppIcon.appiconset
# iOS icons (1024x1024)
if [ -f "$EXTRACT_DIR/icon_512x512@2x.png" ]; then
    cp "$EXTRACT_DIR/icon_512x512@2x.png" "$APPSET_DIR/AppIcon-1024.png"
    print_info "  ✓ Created AppIcon-1024.png (iOS)"
elif [ -f "$EXTRACT_DIR/icon_512x512.png" ]; then
    generate_icon 1024 "$APPSET_DIR/AppIcon-1024.png" "$EXTRACT_DIR/icon_512x512.png"
fi

# macOS icons - copy existing, generate missing
copy_icon "$EXTRACT_DIR/icon_16x16.png" "$APPSET_DIR/AppIcon-16.png" || \
    generate_icon 16 "$APPSET_DIR/AppIcon-16.png" "$EXTRACT_DIR/icon_32x32.png" || \
    generate_icon 16 "$APPSET_DIR/AppIcon-16.png" "$EXTRACT_DIR/icon_512x512.png"

copy_icon "$EXTRACT_DIR/icon_16x16@2x.png" "$APPSET_DIR/AppIcon-16@2x.png" || \
    generate_icon 32 "$APPSET_DIR/AppIcon-16@2x.png" "$EXTRACT_DIR/icon_32x32.png" || \
    generate_icon 32 "$APPSET_DIR/AppIcon-16@2x.png" "$EXTRACT_DIR/icon_512x512.png"

copy_icon "$EXTRACT_DIR/icon_32x32.png" "$APPSET_DIR/AppIcon-32.png" || \
    generate_icon 32 "$APPSET_DIR/AppIcon-32.png" "$EXTRACT_DIR/icon_128x128.png" || \
    generate_icon 32 "$APPSET_DIR/AppIcon-32.png" "$EXTRACT_DIR/icon_512x512.png"

copy_icon "$EXTRACT_DIR/icon_32x32@2x.png" "$APPSET_DIR/AppIcon-32@2x.png" || \
    generate_icon 64 "$APPSET_DIR/AppIcon-32@2x.png" "$EXTRACT_DIR/icon_128x128.png" || \
    generate_icon 64 "$APPSET_DIR/AppIcon-32@2x.png" "$EXTRACT_DIR/icon_512x512.png"

copy_icon "$EXTRACT_DIR/icon_128x128.png" "$APPSET_DIR/AppIcon-128.png" || \
    generate_icon 128 "$APPSET_DIR/AppIcon-128.png" "$EXTRACT_DIR/icon_256x256.png" || \
    generate_icon 128 "$APPSET_DIR/AppIcon-128.png" "$EXTRACT_DIR/icon_512x512.png"

copy_icon "$EXTRACT_DIR/icon_128x128@2x.png" "$APPSET_DIR/AppIcon-128@2x.png" || \
    generate_icon 256 "$APPSET_DIR/AppIcon-128@2x.png" "$EXTRACT_DIR/icon_256x256.png" || \
    generate_icon 256 "$APPSET_DIR/AppIcon-128@2x.png" "$EXTRACT_DIR/icon_512x512.png"

copy_icon "$EXTRACT_DIR/icon_256x256.png" "$APPSET_DIR/AppIcon-256.png" || \
    generate_icon 256 "$APPSET_DIR/AppIcon-256.png" "$EXTRACT_DIR/icon_512x512.png"

copy_icon "$EXTRACT_DIR/icon_256x256@2x.png" "$APPSET_DIR/AppIcon-256@2x.png" || \
    generate_icon 512 "$APPSET_DIR/AppIcon-256@2x.png" "$EXTRACT_DIR/icon_512x512.png"

copy_icon "$EXTRACT_DIR/icon_512x512.png" "$APPSET_DIR/AppIcon-512.png" || \
    generate_icon 512 "$APPSET_DIR/AppIcon-512.png" "$EXTRACT_DIR/icon_512x512@2x.png"

copy_icon "$EXTRACT_DIR/icon_512x512@2x.png" "$APPSET_DIR/AppIcon-512@2x.png" || \
    generate_icon 1024 "$APPSET_DIR/AppIcon-512@2x.png" "$EXTRACT_DIR/icon_512x512.png"

print_step "Updating Contents.json..."

# Build Contents.json dynamically based on what files exist
cat > "$APPSET_DIR/Contents.json" << 'JSON_START'
{
  "images" : [
JSON_START

# iOS 1024x1024 (required)
if [ -f "$APPSET_DIR/AppIcon-1024.png" ]; then
    cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "tinted"
        }
      ],
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    },
JSON_IO
fi

# macOS icons - only add if file exists
[ -f "$APPSET_DIR/AppIcon-16.png" ] && cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
JSON_IO

[ -f "$APPSET_DIR/AppIcon-16@2x.png" ] && cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
JSON_IO

[ -f "$APPSET_DIR/AppIcon-32.png" ] && cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
JSON_IO

[ -f "$APPSET_DIR/AppIcon-32@2x.png" ] && cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
JSON_IO

[ -f "$APPSET_DIR/AppIcon-128.png" ] && cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
JSON_IO

[ -f "$APPSET_DIR/AppIcon-128@2x.png" ] && cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
JSON_IO

[ -f "$APPSET_DIR/AppIcon-256.png" ] && cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
JSON_IO

[ -f "$APPSET_DIR/AppIcon-256@2x.png" ] && cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
JSON_IO

[ -f "$APPSET_DIR/AppIcon-512.png" ] && cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
JSON_IO

[ -f "$APPSET_DIR/AppIcon-512@2x.png" ] && cat >> "$APPSET_DIR/Contents.json" << 'JSON_IO'
    {
      "filename" : "AppIcon-512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    },
JSON_IO

# Remove trailing comma and close JSON
sed -i '' '$ s/,$//' "$APPSET_DIR/Contents.json" 2>/dev/null || sed -i '$ s/,$//' "$APPSET_DIR/Contents.json" 2>/dev/null

cat >> "$APPSET_DIR/Contents.json" << 'EOF'
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

print_success "Contents.json updated"

# Clean up temporary directory
rm -rf "$TEMP_DIR"

print_success "✓ AppIcon asset created successfully!"
print_info "Location: $APPSET_DIR"
print_info ""
print_info "Next steps:"
print_info "1. Open your Xcode project"
print_info "2. Select Assets.xcassets in the project navigator"
print_info "3. Click on AppIcon to view the icons"
print_info "4. Verify all icon sizes are present"

