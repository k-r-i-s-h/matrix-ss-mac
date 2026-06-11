#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE_NAME="MatrixScreenSaver.saver"
BUILT_BUNDLE="$ROOT_DIR/.build/macos/$BUNDLE_NAME"
INSTALL_DIR="${SCREEN_SAVER_INSTALL_DIR:-$HOME/Library/Screen Savers}"
INSTALLED_BUNDLE="$INSTALL_DIR/$BUNDLE_NAME"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Matrix Screen Saver can only be installed on macOS." >&2
  exit 2
fi

"$ROOT_DIR/scripts/build-saver.sh"

mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALLED_BUNDLE"
cp -R "$BUILT_BUNDLE" "$INSTALLED_BUNDLE"

# Ad-hoc sign the locally built bundle when codesign is available. This keeps
# Gatekeeper/System Settings happier without requiring a paid developer cert.
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$INSTALLED_BUNDLE" >/dev/null
fi

cat <<MSG
Installed: $INSTALLED_BUNDLE

System Settings will open now. Choose "Matrix Screen Saver" from the Screen Saver list.
MSG

open "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension" \
  || open "/System/Library/PreferencePanes/DesktopScreenEffectsPref.prefPane" \
  || true
