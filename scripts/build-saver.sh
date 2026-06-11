#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/macos"
BUNDLE_DIR="$BUILD_DIR/MatrixScreenSaver.saver"
CONTENTS_DIR="$BUNDLE_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
MODULE_DIR="$CONTENTS_DIR/Modules"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must be run on macOS because it links AppKit and ScreenSaver.framework." >&2
  exit 2
fi

rm -rf "$BUNDLE_DIR"
mkdir -p "$MACOS_DIR" "$MODULE_DIR"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

swiftc \
  -emit-library \
  -module-name MatrixScreenSaver \
  -emit-module \
  -emit-module-path "$MODULE_DIR/MatrixScreenSaver.swiftmodule" \
  -framework AppKit \
  -framework ScreenSaver \
  -I "$ROOT_DIR/Sources" \
  "$ROOT_DIR/Sources/MatrixRainCore/RainEngine.swift" \
  "$ROOT_DIR/Sources/MatrixScreenSaver/MatrixSaverView.swift" \
  -o "$MACOS_DIR/MatrixScreenSaver"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$BUNDLE_DIR" >/dev/null
fi

cat <<MSG
Built: $BUNDLE_DIR
Install with: ./scripts/install-saver.sh
MSG
