import Foundation

public struct RainConfiguration: Equatable, Sendable {
    public var fontSize: Double
    public var glyphSpacing: Double
    public var trailLength: Int
    public var minSpeed: Double
    public var maxSpeed: Double
    public var mutationChance: Double

    public init(
        fontSize: Double = 20,
        glyphSpacing: Double = 22,
        trailLength: Int = 28,
        minSpeed: Double = 180,
        maxSpeed: Double = 540,
        mutationChance: Double = 0.018
    ) {
        self.fontSize = fontSize
        self.glyphSpacing = glyphSpacing
        self.trailLength = trailLength
        self.minSpeed = minSpeed
        self.maxSpeed = maxSpeed
        self.mutationChance = mutationChance
    }
}

public struct RainGlyph: Equatable, Sendable {
    public var character: String
    public var x: Double
    public var y: Double
    public var opacity: Double
    public var isHead: Bool

    public init(character: String, x: Double, y: Double, opacity: Double, isHead: Bool) {
        self.character = character
        self.x = x
        self.y = y
        self.opacity = opacity
        self.isHead = isHead
    }
}

public struct SeededGenerator: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}

public struct RainEngine: Sendable {
    public private(set) var width: Double
    public private(set) var height: Double
    public private(set) var configuration: RainConfiguration

    private var columns: [RainColumn] = []
    private var random: SeededGenerator
    private let opacities: [Double]

    public init(width: Double, height: Double, configuration: RainConfiguration = RainConfiguration(), seed: UInt64 = 0x4D41_5452_4958) {
        self.width = max(width, configuration.glyphSpacing)
        self.height = max(height, configuration.glyphSpacing)
        self.configuration = configuration
        self.random = SeededGenerator(seed: seed)
        self.opacities = RainEngine.makeOpacities(trailLength: configuration.trailLength)
        rebuildColumns()
    }

    public mutating func resize(width: Double, height: Double) {
        self.width = max(width, configuration.glyphSpacing)
        self.height = max(height, configuration.glyphSpacing)
        rebuildColumns()
    }

    public mutating func update(deltaTime: Double) {
        guard deltaTime.isFinite, deltaTime > 0 else { return }

        let resetThreshold = height + Double(configuration.trailLength) * configuration.glyphSpacing
        for index in columns.indices {
            columns[index].headY += columns[index].speed * deltaTime

            if columns[index].headY > resetThreshold {
                resetColumn(at: index, startAboveScreen: true)
            } else {
                mutateColumnGlyphs(at: index)
            }
        }
    }

    /// Per-offset opacities for a column trail (index 0 is the head). Constant
    /// for the lifetime of the engine, so renderers can precompute colors once.
    public var glyphOpacities: [Double] { opacities }

    /// Visits every on-screen glyph without allocating an intermediate array.
    /// This is the hot path used by the renderer on each frame.
    public func forEachVisibleGlyph(
        _ body: (_ character: String, _ x: Double, _ y: Double, _ offset: Int) -> Void
    ) {
        let spacing = configuration.glyphSpacing
        let lowerBound = -spacing
        let upperBound = height + spacing

        for column in columns {
            let headY = column.headY
            for offset in column.glyphs.indices {
                let y = headY - Double(offset) * spacing
                if y > lowerBound && y < upperBound {
                    body(column.glyphs[offset], column.x, y, offset)
                }
            }
        }
    }

    public func snapshot() -> [RainGlyph] {
        var glyphs: [RainGlyph] = []
        glyphs.reserveCapacity(columns.count * configuration.trailLength)
        forEachVisibleGlyph { character, x, y, offset in
            glyphs.append(
                RainGlyph(
                    character: character,
                    x: x,
                    y: y,
                    opacity: opacities[offset],
                    isHead: offset == 0
                )
            )
        }
        return glyphs
    }

    public var columnCount: Int {
        columns.count
    }

    private mutating func rebuildColumns() {
        let count = max(1, Int(ceil(width / configuration.glyphSpacing)))
        columns = (0..<count).map { index in
            var column = RainColumn(
                x: Double(index) * configuration.glyphSpacing + configuration.glyphSpacing * 0.5,
                headY: -randomDouble(0, height),
                speed: randomDouble(configuration.minSpeed, configuration.maxSpeed),
                glyphs: []
            )
            column.glyphs = (0..<configuration.trailLength).map { _ in randomGlyph() }
            return column
        }
    }

    private mutating func resetColumn(at index: Int, startAboveScreen: Bool) {
        guard columns.indices.contains(index) else { return }
        columns[index].headY = startAboveScreen ? -randomDouble(configuration.glyphSpacing, height * 0.7) : -randomDouble(0, height)
        columns[index].speed = randomDouble(configuration.minSpeed, configuration.maxSpeed)
        columns[index].glyphs = (0..<configuration.trailLength).map { _ in randomGlyph() }
    }

    private mutating func mutateColumnGlyphs(at index: Int) {
        guard columns.indices.contains(index) else { return }
        for glyphIndex in columns[index].glyphs.indices where randomUnit() < configuration.mutationChance {
            columns[index].glyphs[glyphIndex] = randomGlyph()
        }
    }

    private mutating func randomDouble(_ lower: Double, _ upper: Double) -> Double {
        guard upper > lower else { return lower }
        return lower + (upper - lower) * randomUnit()
    }

    private mutating func randomUnit() -> Double {
        Double(random.next()) / Double(UInt64.max)
    }

    private mutating func randomGlyph() -> String {
        MatrixGlyphSet.characters[Int(random.next() % UInt64(MatrixGlyphSet.characters.count))]
    }

    private static func makeOpacities(trailLength: Int) -> [Double] {
        let count = max(trailLength, 0)
        guard count > 0 else { return [] }
        let denominator = Double(max(trailLength, 1))
        return (0..<count).map { offset in
            guard offset > 0 else { return 1 }
            let fade = max(0, 1 - Double(offset) / denominator)
            return pow(fade, 1.7) * 0.86
        }
    }
}

private struct RainColumn: Sendable {
    var x: Double
    var headY: Double
    var speed: Double
    var glyphs: [String]
}

public enum MatrixGlyphSet {
    public static let characters: [String] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン日月火水木金土").map(String.init)
}
