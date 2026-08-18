#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="LyricFloat"
VERSION="1.0.0"
BUILD="build"
APP="$BUILD/$APP_NAME.app"
DMG="LyricFloat-$VERSION.dmg"
VOLNAME="LyricFloat"

SDK="${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX26.5.sdk}"
SWIFT_FLAGS=(-swift-version 5 -sdk "$SDK" -Xcc -fmodules-cache-path=/tmp/swift-modcache)

# 清理旧的构建产物
rm -rf "$BUILD" "$DMG" 2>/dev/null || true
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

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

# 组装 DMG 源目录（App + Applications 快捷方式）
STAGE="$BUILD/stage"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/$APP_NAME.app"
ln -sf /Applications "$STAGE/Applications"

echo "==> 制作 DMG（支持拖拽安装）"
# 方案 A：标准做法（需内核磁盘访问，用户本机可正常执行）
if hdiutil create -volname "$VOLNAME" -srcfolder "$STAGE" -ov -format UDZO "$BUILD/raw.dmg" 2>/dev/null; then
  mv "$BUILD/raw.dmg" "$DMG"
  echo "使用标准 hdiutil create 生成 $DMG"
else
  # 方案 B：沙盒无内核访问时，用 makehybrid -hfs 保留符号链接，再压缩
  mv "$BUILD/raw.dmg" /tmp/old-raw.dmg 2>/dev/null || true
  hdiutil makehybrid -o "$BUILD/hybrid.iso" -hfs -hfs-volume-name "$VOLNAME" "$STAGE"
  hdiutil convert -format UDZO "$BUILD/hybrid.iso.dmg" -o "$DMG"
  echo "使用 HFS hybrid 方法完成 $DMG（保存符号链接）"
fi

echo "==> 完成: $DMG ($(du -h "$DMG" | cut -f1))"
