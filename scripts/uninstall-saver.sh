#!/usr/bin/env bash
set -euo pipefail

BUNDLE_NAME="MatrixScreenSaver.saver"
INSTALL_DIR="${SCREEN_SAVER_INSTALL_DIR:-$HOME/Library/Screen Savers}"
INSTALLED_BUNDLE="$INSTALL_DIR/$BUNDLE_NAME"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Matrix Screen Saver can only be uninstalled from macOS." >&2
  exit 2
fi

if [[ -d "$INSTALLED_BUNDLE" ]]; then
  rm -rf "$INSTALLED_BUNDLE"
  echo "Removed: $INSTALLED_BUNDLE"
else
  echo "Nothing to remove: $INSTALLED_BUNDLE"
fi
