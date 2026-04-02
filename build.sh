#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building Tick..."

SOURCES=$(find Sources/Tick -name "*.swift")
SDK=$(xcrun --show-sdk-path)

swiftc \
    $SOURCES \
    -o Tick_binary \
    -sdk "$SDK" \
    -target arm64-apple-macosx13.0 \
    -framework SwiftUI \
    -framework AppKit \
    -framework UserNotifications \
    -O

APP="/Applications/Tick.app"
APP_DIR="$APP/Contents/MacOS"
RES_DIR="$APP/Contents/Resources"
mkdir -p "$APP_DIR" "$RES_DIR"

cp Tick_binary "$APP_DIR/Tick"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Icon
if [ -f AppIcon.icns ]; then
    cp AppIcon.icns "$RES_DIR/AppIcon.icns"
fi

rm -f Tick_binary

echo "Build complete: $APP"
echo "Run: open /Applications/Tick.app"
