import Foundation

/// What the controller reports. The controller never knows which page is open; AppState decides
/// what each event means. For now the computer sends these (`Tools/controller.swift`); later the
/// Bluetooth controller will, with the same packet codes as Height Ritual.
enum ControlEvent: Equatable {
    case knob(Int)      // steps, + = clockwise (the up arrow on the Mac)
    case left
    case right
    case confirm
    case cancel

    /// Maps a 2-byte packet `[controlId, value]`; ids match Height Ritual's controller.
    static func from(id: UInt8, value: Int8) -> ControlEvent? {
        switch id {
        case 1: return value == 0 ? nil : .knob(Int(value))
        case 13: return .confirm
        case 23: return .cancel
        case 14: return .left
        case 15: return .right
        default: return nil
        }
    }
}
