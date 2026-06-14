#if canImport(ScreenSaver) && canImport(AppKit)
import AppKit
import ScreenSaver
#if canImport(MatrixRainCore)
import MatrixRainCore
#endif

@objc(MatrixSaverView)
public final class MatrixSaverView: ScreenSaverView {
    private var engine: RainEngine
    private var lastFrameDate = Date()
    private let glyphFont: NSFont
    private let glowShadow = NSShadow()
    private let paragraph: NSParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }()

    // One color per trail offset (index 0 is the head), precomputed so the draw
    // loop never has to allocate an NSColor.
    private var colorTable: [NSColor] = []
    // Reused attribute dictionaries. Head glyphs are fully constant; trail glyphs
    // only ever swap their foreground color.
    private var headAttributes: [NSAttributedString.Key: Any] = [:]
    private var trailAttributes: [NSAttributedString.Key: Any] = [:]

    public override init?(frame: NSRect, isPreview: Bool) {
        let scale = isPreview ? 0.72 : 1.0
        let configuration = RainConfiguration(
            fontSize: 20 * scale,
            glyphSpacing: 22 * scale,
            trailLength: isPreview ? 22 : 32,
            minSpeed: 170 * scale,
            maxSpeed: 560 * scale,
            mutationChance: 0.022
        )
        self.engine = RainEngine(width: frame.width, height: frame.height, configuration: configuration)
        self.glyphFont = NSFont.monospacedSystemFont(ofSize: configuration.fontSize, weight: .semibold)
        super.init(frame: frame, isPreview: isPreview)
        configureRendering()
    }

    public required init?(coder: NSCoder) {
        let configuration = RainConfiguration()
        self.engine = RainEngine(width: 1280, height: 720, configuration: configuration)
        self.glyphFont = NSFont.monospacedSystemFont(ofSize: configuration.fontSize, weight: .semibold)
        super.init(coder: coder)
        configureRendering()
    }

    public override var isOpaque: Bool { true }
    public override var hasConfigureSheet: Bool { false }
    public override var configureSheet: NSWindow? { nil }

    public override func startAnimation() {
        super.startAnimation()
        lastFrameDate = Date()
    }

    public override func animateOneFrame() {
        let now = Date()
        let delta = min(now.timeIntervalSince(lastFrameDate), 1.0 / 20.0)
        lastFrameDate = now
        engine.update(deltaTime: delta)
        needsDisplay = true
    }

    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        engine.resize(width: newSize.width, height: newSize.height)
    }

    public override func draw(_ rect: NSRect) {
        NSColor.black.setFill()
        bounds.fill()

        guard !colorTable.isEmpty else { return }

        let spacing = engine.configuration.glyphSpacing
        let halfSpacing = spacing * 0.5
        let viewHeight = bounds.height
        let lastColorIndex = colorTable.count - 1

        engine.forEachVisibleGlyph { character, x, y, offset in
            let drawRect = NSRect(
                x: x - halfSpacing,
                y: viewHeight - y,
                width: spacing,
                height: spacing
            )
            if offset == 0 {
                character.draw(in: drawRect, withAttributes: headAttributes)
            } else {
                trailAttributes[.foregroundColor] = colorTable[min(offset, lastColorIndex)]
                character.draw(in: drawRect, withAttributes: trailAttributes)
            }
        }
    }

    private func configureRendering() {
        animationTimeInterval = 1.0 / 60.0
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor

        glowShadow.shadowColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.27, alpha: 0.9)
        glowShadow.shadowBlurRadius = isPreview ? 4 : 7
        glowShadow.shadowOffset = .zero

        colorTable = engine.glyphOpacities.enumerated().map { offset, opacity in
            offset == 0
                ? NSColor(calibratedRed: 0.88, green: 1.0, blue: 0.88, alpha: opacity)
                : NSColor(calibratedRed: 0.0, green: 0.95, blue: 0.25, alpha: opacity)
        }

        // The bright leading glyph keeps the soft glow; trail glyphs skip the
        // shadow, which is by far the biggest per-frame rendering saving. To
        // restore a full-column glow, add `.shadow: glowShadow` to trailAttributes.
        headAttributes = [
            .font: glyphFont,
            .paragraphStyle: paragraph,
            .foregroundColor: colorTable.first ?? NSColor(calibratedRed: 0.88, green: 1.0, blue: 0.88, alpha: 1),
            .shadow: glowShadow
        ]
        trailAttributes = [
            .font: glyphFont,
            .paragraphStyle: paragraph
        ]
    }
}
#endif
