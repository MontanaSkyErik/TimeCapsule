import SwiftUI

/// The projected image during setup: a black wall with the floor line and the 100 cm line,
/// drawn at their calibrated places on the upright 1080 x 1920 canvas.
struct ProjectorSetupPage: View {
    let step: SetupStep
    let wall: Calibration

    private var instruction: String {
        switch step {
        case .wallFloor: return "Move the line\nto the floor"
        case .wall100: return "Move the 100 cm line\nto 1 m above the floor"
        case .cameraFloor, .camera100: return "Line up the camera\non the phone"
        }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                Color.black
                line("0 cm", y: wall.y(cm: 0, imageHeight: h),
                     active: step == .wallFloor, width: geo.size.width)
                line("100 cm", y: wall.y(cm: 100, imageHeight: h),
                     active: step == .wall100, width: geo.size.width)
                VStack(spacing: 30) {
                    Text(instruction)
                        .font(Theme.serif(64))
                        .multilineTextAlignment(.center)
                    if !step.usesCamera {
                        Text("Up / Down to move, Enter when done")
                            .font(Theme.serif(40))
                            .opacity(0.6)
                    }
                }
                .foregroundStyle(.white)
                .frame(width: geo.size.width)
                .padding(.top, 160)
            }
        }
    }

    /// The camera steps show both lines bright, so the camera can find them.
    private func line(_ label: String, y: Double, active: Bool, width: CGFloat) -> some View {
        let color = active ? Theme.title : Color.white
        let bright = active || step.usesCamera
        return ZStack(alignment: .bottomLeading) {
            Rectangle().fill(color)
                .frame(width: width, height: active ? 8 : 4)
            Text(label)
                .font(Theme.serif(44))
                .foregroundStyle(color)
                .padding(.leading, 40)
                .offset(y: -20)
        }
        .opacity(bright ? 1 : 0.4)
        .offset(y: y - (active ? 4 : 2))
    }
}

/// The phone during the camera steps: the camera picture with the two lines. The active line
/// is moved with Up / Down onto the line projected on the wall.
struct CameraSetupView: View {
    let step: SetupStep
    let lines: CameraLines
    let camera: Camera

    var body: some View {
        VStack(spacing: 12) {
            Text(step == .cameraFloor
                 ? "Move the yellow line onto\nthe projected floor line"
                 : "Move the yellow line onto\nthe projected 100 cm line")
                .font(Theme.serif(22))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    CameraView(camera: camera, fill: false)
                    line("Floor", y: lines.floorY, active: step == .cameraFloor, geo: geo.size)
                    line("100 cm", y: lines.y100, active: step == .camera100, geo: geo.size)
                }
            }
            // The whole upright camera frame, so the lines are fractions of the real picture.
            .aspectRatio(9 / 16, contentMode: .fit)
            Text("Up / Down to move, Enter when done")
                .font(Theme.serif(16))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    private func line(_ label: String, y: Double, active: Bool, geo: CGSize) -> some View {
        let color = active ? Color.yellow : Color.white
        return ZStack(alignment: .bottomTrailing) {
            Rectangle().fill(color).frame(width: geo.width, height: active ? 3 : 1.5)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .padding(.trailing, 8)
                .offset(y: -6)
        }
        .opacity(active ? 1 : 0.6)
        .offset(y: y * geo.height - (active ? 1.5 : 0.75))
    }
}
