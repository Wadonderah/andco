#!/bin/bash

# AndCo School Transport - App Icon Generator
# This script generates app icons for Android and iOS from a source image

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SOURCE_ICON="assets/images/app_icon_source.png"
ANDROID_ICON_DIR="android/app/src/main/res"
IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  AndCo - App Icon Generator${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check ImageMagick
    if ! command -v convert &> /dev/null; then
        print_error "ImageMagick is not installed. Install with:"
        print_error "  macOS: brew install imagemagick"
        print_error "  Ubuntu: sudo apt-get install imagemagick"
        exit 1
    fi
    
    # Check source icon
    if [ ! -f "$SOURCE_ICON" ]; then
        print_error "Source icon not found: $SOURCE_ICON"
        print_info "Please provide a 1024x1024 PNG image at $SOURCE_ICON"
        exit 1
    fi
    
    # Verify source icon dimensions
    local dimensions=$(identify -format "%wx%h" "$SOURCE_ICON")
    if [ "$dimensions" != "1024x1024" ]; then
        print_warning "Source icon is $dimensions, recommended size is 1024x1024"
    fi
    
    print_success "Prerequisites check passed"
}

# Generate Android icons
generate_android_icons() {
    print_info "Generating Android app icons..."
    
    # Android icon sizes and directories
    declare -A android_sizes=(
        ["mipmap-mdpi"]=48
        ["mipmap-hdpi"]=72
        ["mipmap-xhdpi"]=96
        ["mipmap-xxhdpi"]=144
        ["mipmap-xxxhdpi"]=192
    )
    
    # Create directories and generate icons
    for dir in "${!android_sizes[@]}"; do
        local size=${android_sizes[$dir]}
        local output_dir="$ANDROID_ICON_DIR/$dir"
        
        mkdir -p "$output_dir"
        
        # Generate regular icon
        convert "$SOURCE_ICON" -resize ${size}x${size} "$output_dir/ic_launcher.png"
        
        # Generate round icon (Android 7.1+)
        convert "$SOURCE_ICON" -resize ${size}x${size} \
            \( +clone -threshold 50% -negate -fill white -draw "circle $((size/2)),$((size/2)) $((size/2)),0" \) \
            -alpha off -compose copy_opacity -composite \
            "$output_dir/ic_launcher_round.png"
        
        print_success "Generated Android icons for $dir (${size}x${size})"
    done
    
    # Generate adaptive icon components (Android 8.0+)
    local adaptive_dir="$ANDROID_ICON_DIR/mipmap-anydpi-v26"
    mkdir -p "$adaptive_dir"
    
    # Create adaptive icon XML
    cat > "$adaptive_dir/ic_launcher.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
EOF
    
    cat > "$adaptive_dir/ic_launcher_round.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
EOF
    
    # Generate adaptive icon components
    local drawable_dir="$ANDROID_ICON_DIR/drawable"
    mkdir -p "$drawable_dir"
    
    # Background (solid color or simple design)
    cat > "$drawable_dir/ic_launcher_background.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#2196F3"
        android:pathData="M0,0h108v108h-108z"/>
</vector>
EOF
    
    # Foreground (main icon)
    convert "$SOURCE_ICON" -resize 108x108 -background transparent \
        -gravity center -extent 108x108 "$drawable_dir/ic_launcher_foreground.png"
    
    print_success "Generated Android adaptive icons"
}

# Generate iOS icons
generate_ios_icons() {
    print_info "Generating iOS app icons..."
    
    # Create iOS icon directory
    mkdir -p "$IOS_ICON_DIR"
    
    # iOS icon sizes
    declare -A ios_sizes=(
        ["Icon-App-20x20@1x"]=20
        ["Icon-App-20x20@2x"]=40
        ["Icon-App-20x20@3x"]=60
        ["Icon-App-29x29@1x"]=29
        ["Icon-App-29x29@2x"]=58
        ["Icon-App-29x29@3x"]=87
        ["Icon-App-40x40@1x"]=40
        ["Icon-App-40x40@2x"]=80
        ["Icon-App-40x40@3x"]=120
        ["Icon-App-60x60@2x"]=120
        ["Icon-App-60x60@3x"]=180
        ["Icon-App-76x76@1x"]=76
        ["Icon-App-76x76@2x"]=152
        ["Icon-App-83.5x83.5@2x"]=167
        ["Icon-App-1024x1024@1x"]=1024
    )
    
    # Generate icons
    for name in "${!ios_sizes[@]}"; do
        local size=${ios_sizes[$name]}
        convert "$SOURCE_ICON" -resize ${size}x${size} "$IOS_ICON_DIR/${name}.png"
        print_success "Generated iOS icon: ${name}.png (${size}x${size})"
    done
    
    # Create Contents.json for iOS
    cat > "$IOS_ICON_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@3x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60",
      "filename" : "Icon-App-60x60@2x.png"
    },
    {
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60",
      "filename" : "Icon-App-60x60@3x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20",
      "filename" : "Icon-App-20x20@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29",
      "filename" : "Icon-App-29x29@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40",
      "filename" : "Icon-App-40x40@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76",
      "filename" : "Icon-App-76x76@1x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76",
      "filename" : "Icon-App-76x76@2x.png"
    },
    {
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5",
      "filename" : "Icon-App-83.5x83.5@2x.png"
    },
    {
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024",
      "filename" : "Icon-App-1024x1024@1x.png"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    
    print_success "Generated iOS app icons and Contents.json"
}

# Generate splash screens
generate_splash_screens() {
    print_info "Generating splash screens..."
    
    # Android splash screen
    local android_splash_dir="$ANDROID_ICON_DIR/drawable"
    mkdir -p "$android_splash_dir"
    
    # Create a simple splash screen with logo
    convert -size 1080x1920 xc:"#2196F3" \
        \( "$SOURCE_ICON" -resize 200x200 \) \
        -gravity center -composite \
        "$android_splash_dir/splash_screen.png"
    
    # iOS splash screen (LaunchScreen.storyboard handles this)
    # But we can create launch images for older iOS versions
    local ios_splash_dir="ios/Runner/Assets.xcassets/LaunchImage.launchimage"
    mkdir -p "$ios_splash_dir"
    
    # iPhone splash screens
    declare -A ios_splash_sizes=(
        ["Default@2x"]=640x960
        ["Default-568h@2x"]=640x1136
        ["Default-667h"]=750x1334
        ["Default-736h"]=1242x2208
        ["Default-Landscape-736h"]=2208x1242
        ["Default-1792h"]=828x1792
        ["Default-2436h"]=1125x2436
        ["Default-Landscape-2436h"]=2436x1125
    )
    
    for name in "${!ios_splash_sizes[@]}"; do
        local size=${ios_splash_sizes[$name]}
        local width=$(echo $size | cut -d'x' -f1)
        local height=$(echo $size | cut -d'x' -f2)
        
        convert -size ${width}x${height} xc:"#2196F3" \
            \( "$SOURCE_ICON" -resize 150x150 \) \
            -gravity center -composite \
            "$ios_splash_dir/${name}.png"
    done
    
    print_success "Generated splash screens"
}

# Create app icon documentation
create_documentation() {
    cat > "docs/app_icons.md" << EOF
# App Icons and Splash Screens

This document describes the app icons and splash screens generated for AndCo School Transport.

## Source Image
- **File**: $SOURCE_ICON
- **Required Size**: 1024x1024 pixels
- **Format**: PNG with transparency support

## Android Icons

### Standard Icons
- **mipmap-mdpi**: 48x48px
- **mipmap-hdpi**: 72x72px
- **mipmap-xhdpi**: 96x96px
- **mipmap-xxhdpi**: 144x144px
- **mipmap-xxxhdpi**: 192x192px

### Adaptive Icons (Android 8.0+)
- **Background**: Solid color or simple design
- **Foreground**: Main app icon
- **Size**: 108x108dp

### Round Icons (Android 7.1+)
- Circular versions of standard icons
- Same sizes as standard icons

## iOS Icons

### iPhone Icons
- **20pt**: 40x40px (@2x), 60x60px (@3x)
- **29pt**: 58x58px (@2x), 87x87px (@3x)
- **40pt**: 80x80px (@2x), 120x120px (@3x)
- **60pt**: 120x120px (@2x), 180x180px (@3x)

### iPad Icons
- **20pt**: 20x20px (@1x), 40x40px (@2x)
- **29pt**: 29x29px (@1x), 58x58px (@2x)
- **40pt**: 40x40px (@1x), 80x80px (@2x)
- **76pt**: 76x76px (@1x), 152x152px (@2x)
- **83.5pt**: 167x167px (@2x)

### App Store Icon
- **1024x1024px**: For App Store listing

## Splash Screens

### Android
- **File**: android/app/src/main/res/drawable/splash_screen.png
- **Size**: 1080x1920px (can be scaled)

### iOS
- Uses LaunchScreen.storyboard for modern iOS versions
- Launch images provided for older iOS versions

## Regenerating Icons

To regenerate all icons from a new source image:

1. Replace the source image at: $SOURCE_ICON
2. Run the generation script: ./scripts/generate_app_icons.sh

## Design Guidelines

### Android
- Follow Material Design guidelines
- Use adaptive icons for Android 8.0+
- Ensure icons work on various backgrounds

### iOS
- Follow Apple Human Interface Guidelines
- Use consistent visual style across all sizes
- Avoid transparency in app icons
- Ensure readability at small sizes

## Testing

Test icons on various devices and screen densities:
- Android: Test on different launchers and Android versions
- iOS: Test on different device sizes and iOS versions
EOF
    
    print_success "Created app icon documentation"
}

# Main script
main() {
    print_header
    
    # Create docs directory
    mkdir -p docs
    
    check_prerequisites
    generate_android_icons
    generate_ios_icons
    generate_splash_screens
    create_documentation
    
    print_success "App icon generation completed successfully!"
    print_info "Icons generated for Android and iOS"
    print_info "Documentation created at docs/app_icons.md"
}

# Help function
show_help() {
    echo "Usage: $0"
    echo
    echo "This script generates app icons and splash screens for Android and iOS"
    echo "from a source image located at: $SOURCE_ICON"
    echo
    echo "Prerequisites:"
    echo "  - ImageMagick (convert command)"
    echo "  - Source icon: 1024x1024 PNG at $SOURCE_ICON"
    echo
    echo "Generated files:"
    echo "  - Android icons: $ANDROID_ICON_DIR/mipmap-*/"
    echo "  - iOS icons: $IOS_ICON_DIR/"
    echo "  - Documentation: docs/app_icons.md"
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
