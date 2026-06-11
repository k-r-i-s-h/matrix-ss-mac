import Testing
@testable import MatrixRainCore

@Test func createsColumnsForScreenWidth() {
    let engine = RainEngine(width: 220, height: 120, configuration: RainConfiguration(glyphSpacing: 22))
    #expect(engine.columnCount == 10)
}

@Test func snapshotKeepsGlyphsWithinVisibleMargin() {
    var engine = RainEngine(width: 120, height: 90, configuration: RainConfiguration(glyphSpacing: 18, trailLength: 10), seed: 42)
    engine.update(deltaTime: 0.5)

    let glyphs = engine.snapshot()

    #expect(!glyphs.isEmpty)
    #expect(glyphs.allSatisfy { $0.y > -18 && $0.y < 108 })
    #expect(glyphs.allSatisfy { $0.opacity >= 0 && $0.opacity <= 1 })
}

@Test func sameSeedProducesSameAnimation() {
    var first = RainEngine(width: 160, height: 100, seed: 12345)
    var second = RainEngine(width: 160, height: 100, seed: 12345)

    first.update(deltaTime: 0.25)
    second.update(deltaTime: 0.25)

    #expect(first.snapshot() == second.snapshot())
}
