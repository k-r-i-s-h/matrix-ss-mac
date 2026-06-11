# Matrix Screen Saver for macOS

A Swift macOS screen saver that recreates a Matrix-inspired digital-rain effect: dense green glyph columns, bright leading characters, soft glow, randomized Japanese/kana/Latin/numeric symbols, and independent falling speeds per column.

> Note: this project is an original Matrix-style implementation; it does not include film assets or copied proprietary code.

## Project layout

- `Sources/MatrixRainCore/RainEngine.swift` contains the deterministic animation engine and glyph generation logic.
- `Sources/MatrixScreenSaver/MatrixSaverView.swift` contains the macOS `ScreenSaverView` drawing implementation.
- `Resources/Info.plist` contains the bundle metadata used by macOS.
- `scripts/build-saver.sh` builds a `.saver` bundle on macOS.
- `scripts/install-saver.sh` installs the bundle into `~/Library/Screen Savers/` and opens System Settings.
- `scripts/uninstall-saver.sh` removes the installed user-level bundle.

## Easy install on macOS

Run one command from the project folder:

```bash
make install
```

This builds the `.saver`, copies it into your user Screen Savers folder, ad-hoc signs the local bundle when `codesign` is available, and opens **System Settings → Screen Saver**. Choose **Matrix Screen Saver** from the list. No `sudo` is required.

If you do not want to use `make`, run the installer directly:

```bash
./scripts/install-saver.sh
```

## Build only on macOS

```bash
make build
# or: ./scripts/build-saver.sh
```

The generated bundle is written to:

```text
.build/macos/MatrixScreenSaver.saver
```

## Uninstall

```bash
make uninstall
# or: ./scripts/uninstall-saver.sh
```

## Test the core animation engine

```bash
swift test
```
