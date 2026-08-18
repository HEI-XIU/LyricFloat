#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="LyricFloat"
VERSION="1.0.0"
BUILD="build"
APP="$BUILD/$APP_NAME.app"
DMG="LyricFloat-$VERSION.dmg"

SDK="${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk}"
SWIFT_FLAGS=(-swift-version 5 -sdk "$SDK" -Xcc -fmodules-cache-path=/tmp/swift-modcache)

# Clean old build
rm -rf "$BUILD" 2>/dev/null; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "==> 编译 Swift 源码"
swiftc -O -framework AppKit "${SWIFT_FLAGS[@]}" \
  Sources/main.swift Sources/AppDelegate.swift Sources/NowPlaying.swift \
  Sources/LyricsFetcher.swift Sources/LRC.swift Sources/QQMusic.swift \
  -o "$APP/Contents/MacOS/$APP_NAME"

echo "==> 生成应用图标"
swiftc "${SWIFT_FLAGS[@]}" -framework CoreGraphics -framework CoreText -framework ImageIO \
  tools/makeicon.swift -o "$BUILD/makeicon" 2>/dev/null
"$BUILD/makeicon" "$BUILD/AppIcon.iconset" 2>/dev/null
sips -s format icns "$BUILD/AppIcon.iconset/icon_512x512.png" \
  --out "$APP/Contents/Resources/AppIcon.icns" 2>/dev/null && echo "图标已生成"

echo "==> 写入 Info.plist"
cp Info.plist "$APP/Contents/Info.plist"

echo "==> 签名"
codesign --force --deep -s - "$APP"

echo "==> 制作 DMG（支持拖拽到 Applications 安装）"
STAGE="$BUILD/dmgroot"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/LyricFloat.app"
ln -sf /Applications "$STAGE/Applications" 2>/dev/null || true
rm -f "$BUILD/pkg.iso" "$DMG"
hdiutil makehybrid -iso -joliet -o "$BUILD/pkg.iso" "$STAGE"
hdiutil convert -format UDZO "$BUILD/pkg.iso" -o "$DMG"
echo "==> 完成: $DMG ($(du -h "$DMG" | cut -f1))"
