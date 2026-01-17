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
    # Compile asset catalog if actool is available
    if command -v actool &> /dev/null; then
        echo "Compiling asset catalog..."
        actool --compile "$APP_BUNDLE/Contents/Resources" \
               --platform macosx \
               --minimum-deployment-target 12.0 \
               "$PROJECT_DIR/Resources/Assets.xcassets" 2>/dev/null || true
    fi
fi

# Sign the app (ad-hoc signing for local use)
echo "Signing app bundle..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || echo "Warning: Code signing failed (this is OK for local use)"

# Verify the build
echo ""
echo "Build complete!"
echo "App bundle: $APP_BUNDLE"
echo ""

# Show binary info
file "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo ""
echo "To run the app:"
echo "  open $APP_BUNDLE"
echo ""
echo "Or copy to Applications:"
echo "  cp -r $APP_BUNDLE /Applications/"
