#!/usr/bin/env bash
set -euo pipefail

# Double-clickable installer for the Matrix Screen Saver.
# Builds the .saver bundle from source and installs it into your personal
# Screen Savers folder. No sudo required.

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "== Matrix Screen Saver installer =="
echo ""

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This installer only runs on macOS." >&2
  exit 2
fi

# macOS flags files downloaded from the internet as quarantined. Clear the flag
# on this project folder so the build can run without Gatekeeper getting in the way.
xattr -dr com.apple.quarantine . >/dev/null 2>&1 || true
chmod +x scripts/*.sh "${BASH_SOURCE[0]}" >/dev/null 2>&1 || true

if ! command -v swiftc >/dev/null 2>&1; then
  echo "The Swift compiler was not found."
  echo "Installing Apple's Command Line Tools - accept the dialog that appears,"
  echo "let it finish, then double-click this installer again."
  xcode-select --install || true
  echo ""
  read -n 1 -s -r -p "Press any key to close..."
  exit 1
fi

./scripts/install-saver.sh

echo ""
echo "If the previous animation still shows, run:  killall legacyScreenSaver"
echo ""
read -n 1 -s -r -p "Done. Press any key to close this window..."
echo ""
