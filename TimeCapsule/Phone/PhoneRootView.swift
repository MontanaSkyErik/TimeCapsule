import SwiftUI

/// The phone shows the Time Capsule page, and is the camera in Record (from choosing a member).
/// Everything is controlled from the controller (for now the computer); see `AppState.handle`.
struct PhoneRootView: View {
    @Environment(AppState.self) private var state

    /// `-projectorOnPhone` shows the projector image full size on the phone, for screenshots.
    private let projectorOnPhone = ProcessInfo.processInfo.arguments.contains("-projectorOnPhone")

    var body: some View {
        if projectorOnPhone {
            ProjectorRootView(isExternal: false)
        } else {
            phone
        }
    }

    private var phone: some View {
        ZStack {
            if case .setup(let step) = state.page, step.usesCamera {
                CameraSetupView(step: step, lines: state.cameraLines, camera: state.camera)
                    .transition(.opacity)
            } else if state.page == .chooseMember(.record) {
                CameraView(camera: state.camera)
                    .transition(.opacity)
            } else {
                TimeCapsulePage()
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottomTrailing) {
            // Without a projector, a small copy of the projected image helps testing.
            if !state.externalDisplayConnected && !showsCamera {
                ProjectorRootView(isExternal: false)
                    .frame(width: 72, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black.opacity(0.2)))
                    .padding(12)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if !showsCamera { controllerLabel }
        }
    }

    /// The camera picture is kept clear of the test overlays.
    private var showsCamera: Bool {
        if case .setup(let step) = state.page { return step.usesCamera }
        return state.page == .chooseMember(.record)
    }

    private var controllerLabel: some View {
        Label(state.controllerConnected ? "Controller" : "No controller",
              systemImage: state.controllerConnected ? "keyboard.fill" : "keyboard")
            .font(.caption)
            .foregroundStyle(Theme.ink.opacity(0.6))
            .padding(16)
    }
}
