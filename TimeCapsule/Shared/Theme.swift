import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// Colours from the sketches.
enum Theme {
    /// The five horizontal bands of every phone screen, top to bottom.
    static let bands: [Color] = [
        Color(hex: 0xD6B1B1), // dusty rose
        Color(hex: 0xF0C69C), // peach
        Color(hex: 0xFFD6D9), // light pink
        Color(hex: 0xFFFFFF), // white
        Color(hex: 0xD0E4FA), // light blue
    ]
    /// Relative heights of the bands.
    static let bandWeights: [CGFloat] = [52, 52, 58, 62, 52]

    static let ink = Color(hex: 0x1E1E1E)
    static let title = Color(hex: 0xD0735F)
    static let memoryOuter = Color(hex: 0xC09AE6)
    static let memoryInner = Color(hex: 0x3BC6E8)
    static let memoryCore = Color(hex: 0x9EE3F2)
    static let record = Color(hex: 0x2EE5C3)
    static let table = Color(hex: 0xD9D9F4)
    /// The one colour of every segment on the family wheel.
    static let segment = Color(hex: 0xF0C69C)
    static let panel = Color(hex: 0xFFEFF0)

    /// Background of the projected image.
    static let wall = Color(hex: 0xBC9190)
    static let wallInk = Color(hex: 0x1A1212)
    static let head = Color(hex: 0xD9D9D9)

    static func serif(_ size: CGFloat) -> Font { .system(size: size, design: .serif) }
}
