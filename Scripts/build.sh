#!/bin/bash

# Build script for Punto macOS app
# Creates a universal binary (arm64 + x86_64) and packages it as .app bundle

set -e

# Configuration
APP_NAME="Punto"
BUNDLE_ID="com.rshagiev.Punto"
VERSION="1.0.0"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/.build"
RELEASE_DIR="$PROJECT_DIR/Release"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"

echo "Building $APP_NAME v$VERSION..."
echo "Project directory: $PROJECT_DIR"

# Clean previous build
rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR"

# Build for arm64
echo "Building for arm64..."
cd "$PROJECT_DIR"
swift build -c release --arch arm64

# Build for x86_64
echo "Building for x86_64..."
swift build -c release --arch x86_64

# Create universal binary
echo "Creating universal binary..."
BINARY_ARM64="$BUILD_DIR/arm64-apple-macosx/release/Punto"
BINARY_X86="$BUILD_DIR/x86_64-apple-macosx/release/Punto"
UNIVERSAL_BINARY="$BUILD_DIR/universal/Punto"

mkdir -p "$BUILD_DIR/universal"

if [ -f "$BINARY_ARM64" ] && [ -f "$BINARY_X86" ]; then
    lipo -create -output "$UNIVERSAL_BINARY" "$BINARY_ARM64" "$BINARY_X86"
    echo "Universal binary created successfully"
elif [ -f "$BINARY_ARM64" ]; then
    echo "Only arm64 binary available, using it..."
    cp "$BINARY_ARM64" "$UNIVERSAL_BINARY"
elif [ -f "$BINARY_X86" ]; then
    echo "Only x86_64 binary available, using it..."
    cp "$BINARY_X86" "$UNIVERSAL_BINARY"
else
    echo "Error: No binary found!"
    exit 1
fi

# Create .app bundle structure
echo "Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$UNIVERSAL_BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Copy entitlements (for reference, used during signing)
cp "$PROJECT_DIR/Resources/Punto.entitlements" "$APP_BUNDLE/Contents/"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Copy resources if they exist
if [ -d "$PROJECT_DIR/Resources/Assets.xcassets" ]; then
    # Try to compile asset catalog with xcrun actool (requires full Xcode)
    if xcrun --find actool &> /dev/null; then
        echo "Compiling asset catalog..."
        xcrun actool --compile "$APP_BUNDLE/Contents/Resources" \
               --platform macosx \
               --minimum-deployment-target 12.0 \
               --app-icon AppIcon \
               --output-partial-info-plist /tmp/assetcatalog_generated_info.plist \
               "$PROJECT_DIR/Resources/Assets.xcassets" 2>/dev/null || true
    else
        echo "actool not found (requires full Xcode), copying PNG files directly..."
        # Copy menu bar icon
        cp "$PROJECT_DIR/Resources/Assets.xcassets/MenuBarIcon.imageset/MenuBarIcon.png" \
           "$APP_BUNDLE/Contents/Resources/"
        cp "$PROJECT_DIR/Resources/Assets.xcassets/MenuBarIcon.imageset/MenuBarIcon@2x.png" \
           "$APP_BUNDLE/Contents/Resources/"
        # Copy app icon PNGs and generate .icns for Settings/Login Items.
        cp "$PROJECT_DIR/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon_128x128.png" \
           "$APP_BUNDLE/Contents/Resources/AppIcon.png"
        cp "$PROJECT_DIR/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon_256x256.png" \
           "$APP_BUNDLE/Contents/Resources/AppIcon@2x.png"
        ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
        ICON_SOURCE="$PROJECT_DIR/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon_512x512@2x.png"
        if [ -f "$ICON_SOURCE" ] && command -v iconutil >/dev/null 2>&1; then
            rm -rf "$ICONSET_DIR"
            mkdir -p "$ICONSET_DIR"
            sips -z 16 16 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
            sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
            sips -z 32 32 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
            sips -z 64 64 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
            sips -z 128 128 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
            sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
            sips -z 256 256 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
            sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
            sips -z 512 512 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
            sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
            iconutil -c icns "$ICONSET_DIR" -o "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
        fi
    fi
fi

# Sign the app (ad-hoc signing for local use)
echo "Signing app bundle..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || echo "Warning: Code signing failed (this is OK for local use)"

# Copy to Applications
echo "Installing to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
cp -r "$APP_BUNDLE" "/Applications/"

# Verify the build
echo ""
echo "Build complete!"
echo "App bundle: $APP_BUNDLE"
echo "Installed to: /Applications/$APP_NAME.app"
echo ""

# Show binary info
file "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo ""
echo "To run the app:"
echo "  open /Applications/$APP_NAME.app"
