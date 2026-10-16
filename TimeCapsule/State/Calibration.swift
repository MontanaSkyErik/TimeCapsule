import Foundation

/// Where the floor and 1 m are on the projected image, in points of the upright 1080 x 1920
/// projector canvas. Same idea as Height Ritual's wall calibration.
struct Calibration: Codable, Equatable {
    /// Distance from the bottom edge of the projected image to the floor line.
    var floorPt: Double = 40
    /// How many points one real centimetre takes on the wall.
    var ptPerCM: Double = 9

    /// One Up / Down press moves a line this many points.
    static let step: Double = 2

    /// Height of `cm` above the floor, from the top of an image `imageHeight` tall.
    func y(cm: Double, imageHeight: Double) -> Double {
        imageHeight - floorPt - cm * ptPerCM
    }
}

/// Where the projected floor and 1 m lines are in the upright camera picture, as fractions of
/// its height (0 = top). With these, a height in the picture can be turned into centimetres:
/// `cm = (floorY - y) * 100 / (floorY - y100)` (Height Ritual's estimate).
struct CameraLines: Codable, Equatable {
    var floorY: Double = 0.85
    var y100: Double = 0.45

    /// One Up / Down press moves a line this much (about 2 pixels of a 1920 pixel frame).
    static let step: Double = 0.001
}

/// Values kept between launches.
enum Saved {
    static func load<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func store<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
