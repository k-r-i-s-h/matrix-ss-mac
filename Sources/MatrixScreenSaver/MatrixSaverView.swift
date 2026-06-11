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
    private var glyphFont: NSFont
    private let glowShadow = NSShadow()

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
        animationTimeInterval = 1.0 / 60.0
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        glowShadow.shadowColor = NSColor(calibratedRed: 0.0, green: 1.0, blue: 0.27, alpha: 0.9)
        glowShadow.shadowBlurRadius = isPreview ? 4 : 7
        glowShadow.shadowOffset = .zero
    }

    public required init?(coder: NSCoder) {
        let configuration = RainConfiguration()
        self.engine = RainEngine(width: 1280, height: 720, configuration: configuration)
        self.glyphFont = NSFont.monospacedSystemFont(ofSize: configuration.fontSize, weight: .semibold)
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 60.0
    }

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

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        for glyph in engine.snapshot() {
            draw(glyph: glyph, paragraph: paragraph)
        }
    }

    private func draw(glyph: RainGlyph, paragraph: NSParagraphStyle) {
        let color: NSColor
        if glyph.isHead {
            color = NSColor(calibratedRed: 0.88, green: 1.0, blue: 0.88, alpha: glyph.opacity)
        } else {
            color = NSColor(calibratedRed: 0.0, green: 0.95, blue: 0.25, alpha: glyph.opacity)
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: glyphFont,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .shadow: glowShadow
        ]

        let drawRect = NSRect(
            x: glyph.x - engine.configuration.glyphSpacing * 0.5,
            y: bounds.height - glyph.y,
            width: engine.configuration.glyphSpacing,
            height: engine.configuration.glyphSpacing
        )
        glyph.character.draw(in: drawRect, withAttributes: attributes)
    }
}
#endif
