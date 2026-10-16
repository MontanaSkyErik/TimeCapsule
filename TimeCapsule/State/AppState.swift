import SwiftUI

/// The pages on the projector.
enum Page: Hashable {
    case splash
    /// Projector and camera setup: every time the app starts, or from Settings.
    case setup(SetupStep)
    case menu
    /// Memory and Record start here: choose a family member. Holds the mode it was opened from.
    case chooseMember(MenuItem)
    /// Spell the name of a new family member. Holds the mode the wheel was opened from.
    case addMember(MenuItem)
    case settings
}

/// The setup steps, in order. Up / Down move the active line, Confirm goes on, Back goes back.
enum SetupStep: Int, CaseIterable, Hashable {
    /// Projected floor line onto the real floor.
    case wallFloor
    /// Projected 100 cm line onto 1 m above the floor; sets the scale.
    case wall100
    /// Line in the camera picture onto the projected floor line.
    case cameraFloor
    /// Line in the camera picture onto the projected 100 cm line.
    case camera100

    var usesCamera: Bool { self == .cameraFloor || self == .camera100 }
}

/// A segment on the family wheel.
enum WheelItem: Hashable {
    case member(String)
    case add
}

/// The choices on the Select mode menu, in the order Left / Right move through them.
enum MenuItem: CaseIterable, Hashable {
    case memory, record, settings

    var title: String {
        switch self {
        case .memory: return "Memory"
        case .record: return "Record"
        case .settings: return "Settings"
        }
    }
}

/// The choices on the Settings page.
enum SettingsItem: CaseIterable, Hashable {
    /// Setup steps 1 and 2: the floor line and the 1 m scale.
    case wall
    /// Setup steps 3 and 4: the lines in the camera picture.
    case camera

    var title: String {
        switch self {
        case .wall: return "Floor line and 1m line"
        case .camera: return "Camera"
        }
    }

    var steps: [SetupStep] {
        switch self {
        case .wall: return [.wallFloor, .wall100]
        case .camera: return [.cameraFloor, .camera100]
        }
    }
}

/// The letter wheel on the add family member page: letters, then Done.
enum LetterItem: Hashable {
    case letter(Character)
    case done

    static let all: [LetterItem] = "ABCDEFGHIJKLMNOPQRSTUVWXYZÅÄÖ".map(LetterItem.letter) + [.done]
}

@Observable
@MainActor
final class AppState {
    static let shared = AppState()

    var page: Page = .splash
    /// The menu choice that Confirm opens.
    var highlighted: MenuItem = .memory
    /// The family, clockwise on the wheel. Kept between launches.
    var family = Saved.load([String].self, "family") ?? ["Mamma", "Erik", "Pappa", "Sofia"]
    /// The wheel: the family, then the segment that adds a new member.
    var wheel: [WheelItem] { family.map(WheelItem.member) + [.add] }
    /// Steps the wheel has turned. Not wrapped, so the wheel always turns the short way.
    var wheelStep = 0
    /// The segment at the top of the wheel, about to be chosen.
    var wheelSelected: WheelItem {
        let n = wheel.count
        return wheel[((wheelStep % n) + n) % n]
    }
    /// The highlighted choice on the Settings page.
    var settingsHighlighted: SettingsItem = .wall
    /// The name being spelled on the add family member page.
    var newName = ""
    /// Steps the letter wheel has turned; the letter at the top is the one Confirm adds.
    var letterStep = 0
    var letterSelected: LetterItem {
        let n = LetterItem.all.count
        return LetterItem.all[((letterStep % n) + n) % n]
    }
    static let maxNameLength = 12
    /// Where the floor and 1 m are on the projected image. Kept between launches.
    var wall = Saved.load(Calibration.self, "wall") ?? Calibration()
    /// Where the floor and 1 m lines are in the camera picture. Kept between launches.
    var cameraLines = Saved.load(CameraLines.self, "cameraLines") ?? CameraLines()
    var externalDisplayConnected = false
    var controllerConnected = false
    /// The projector lies on its side, so the portrait image is turned to fit its 1920 x 1080
    /// output. -90 turns it to the left (counterclockwise); use 90 to turn it to the right.
    var projectorRotation: Double = -90

    static let fade = Animation.easeInOut(duration: 0.9)

    let camera = Camera()
    private let control = NetworkControl()
    private var splashTask: Task<Void, Never>?
    /// The setup steps being run, and where to go when they are done or left.
    private var setupSteps = SetupStep.allCases
    private var afterSetup: Page = .menu

    init() {
        control.onEvent = { [weak self] in self?.handle($0) }
        control.onConnectedChange = { [weak self] in self?.controllerConnected = $0 }
        control.start()
        scheduleSplashFade()
    }

    /// All controller input arrives here.
    func handle(_ event: ControlEvent) {
        // Outside setup the knob works like Left / Right.
        var event = event
        if case .knob(let steps) = event, !isSetup { event = steps > 0 ? .right : .left }

        switch page {
        case .splash:
            leaveSplash()
        case .setup(let step):
            handleSetup(event, step)
        case .menu:
            switch event {
            case .left: withAnimation(.snappy) { highlighted = Self.cycle(MenuItem.allCases, highlighted, -1) }
            case .right: withAnimation(.snappy) { highlighted = Self.cycle(MenuItem.allCases, highlighted, 1) }
            case .confirm: go(to: highlighted == .settings ? .settings : .chooseMember(highlighted))
            case .cancel, .knob: break
            }
        case .chooseMember(let mode):
            switch event {
            case .left: withAnimation(.snappy) { wheelStep -= 1 }
            case .right: withAnimation(.snappy) { wheelStep += 1 }
            case .cancel: go(to: .menu)
            case .confirm:
                if wheelSelected == .add {
                    newName = ""
                    letterStep = 0
                    go(to: .addMember(mode))
                }
            case .knob: break
            }
        case .addMember(let mode):
            handleAddMember(event, mode)
        case .settings:
            switch event {
            case .left: withAnimation(.snappy) { settingsHighlighted = Self.cycle(SettingsItem.allCases, settingsHighlighted, -1) }
            case .right: withAnimation(.snappy) { settingsHighlighted = Self.cycle(SettingsItem.allCases, settingsHighlighted, 1) }
            case .confirm: startSetup(settingsHighlighted.steps, then: .settings)
            case .cancel: go(to: .menu)
            case .knob: break
            }
        }
    }

    private static func cycle<T: Equatable>(_ items: [T], _ current: T, _ by: Int) -> T {
        let index = items.firstIndex(of: current) ?? 0
        return items[(index + by + items.count) % items.count]
    }

    private var isSetup: Bool {
        if case .setup = page { return true }
        return false
    }

    /// After the Time Capsule page: the full setup, every time the app starts. It begins from
    /// the saved values, so if nothing has moved, Enter four times goes straight on.
    private func leaveSplash() {
        startSetup(SetupStep.allCases, then: .menu)
    }

    private func startSetup(_ steps: [SetupStep], then: Page) {
        setupSteps = steps
        afterSetup = then
        go(to: .setup(steps[0]))
    }

    private func handleSetup(_ event: ControlEvent, _ step: SetupStep) {
        // Right / Left move the line too (one step up / down).
        var event = event
        if event == .right { event = .knob(1) }
        if event == .left { event = .knob(-1) }
        let index = setupSteps.firstIndex(of: step) ?? 0
        switch event {
        case .knob(let steps):
            let n = Double(steps)
            switch step {
            case .wallFloor:
                wall.floorPt = min(max(wall.floorPt + n * Calibration.step, 0), 1500)
            case .wall100:
                // Move the 100 cm line by one step; the floor line stays.
                let y100 = wall.ptPerCM * 100 + n * Calibration.step
                wall.ptPerCM = min(max(y100, 200), 1900 - wall.floorPt) / 100
            case .cameraFloor:
                cameraLines.floorY = min(max(cameraLines.floorY - n * CameraLines.step,
                                             cameraLines.y100 + 0.05), 1)
            case .camera100:
                cameraLines.y100 = min(max(cameraLines.y100 - n * CameraLines.step, 0),
                                       cameraLines.floorY - 0.05)
            }
        case .confirm:
            if index + 1 < setupSteps.count {
                go(to: .setup(setupSteps[index + 1]))
            } else {
                Saved.store(wall, "wall")
                Saved.store(cameraLines, "cameraLines")
                go(to: afterSetup)
            }
        case .cancel:
            if index > 0 {
                go(to: .setup(setupSteps[index - 1]))
            } else if afterSetup == .settings {
                // Leaving a recalibration from Settings keeps the old values.
                wall = Saved.load(Calibration.self, "wall") ?? Calibration()
                cameraLines = Saved.load(CameraLines.self, "cameraLines") ?? CameraLines()
                go(to: .settings)
            }
        case .left, .right:
            break
        }
    }

    /// Left / Right turn the letter wheel; Confirm adds the letter at the top, or on Done saves
    /// the new member; Back deletes the last letter, or with no letters goes back to the wheel.
    private func handleAddMember(_ event: ControlEvent, _ mode: MenuItem) {
        switch event {
        case .left: withAnimation(.snappy) { letterStep -= 1 }
        case .right: withAnimation(.snappy) { letterStep += 1 }
        case .confirm:
            switch letterSelected {
            case .letter(let c):
                guard newName.count < Self.maxNameLength else { return }
                newName.append(newName.isEmpty ? c : Character(String(c).lowercased()))
            case .done:
                guard !newName.isEmpty else { return }
                family.append(newName)
                Saved.store(family, "family")
                // The new member comes to the top of the wheel.
                wheelStep = family.count - 1
                go(to: .chooseMember(mode))
            }
        case .cancel:
            if newName.isEmpty { go(to: .chooseMember(mode)) } else { newName.removeLast() }
        case .knob: break
        }
    }

    func go(to page: Page) {
        splashTask?.cancel()
        withAnimation(Self.fade) { self.page = page }
        // The phone is the camera in Record and while the camera is set up.
        var usesCamera = page == .chooseMember(.record)
        if case .setup(let step) = page, step.usesCamera { usesCamera = true }
        if usesCamera { camera.start() } else { camera.stop() }
    }

    /// The Time Capsule page fades into the next page by itself.
    private func scheduleSplashFade() {
        splashTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled, let self, self.page == .splash else { return }
            self.leaveSplash()
        }
    }
}
