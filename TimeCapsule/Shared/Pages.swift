import SwiftUI

/// "Time Capsule": the phone's own page, and the first page on the projector.
struct TimeCapsulePage: View {
    var body: some View {
        Bands { l in
            Text("Time\nCapsule")
                .font(Theme.serif(52 * l.u))
                .foregroundStyle(Theme.title)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 24 * l.u)
                .frame(maxWidth: .infinity, alignment: .leading)
                .place(in: l.rect(1).insetBy(dx: 0, dy: -20 * l.u))
        }
    }
}

/// Select mode: Memory and Record side by side, Settings (the gear) below. The highlighted
/// choice is larger and outlined; Confirm opens it.
struct SelectModePage: View {
    let highlighted: MenuItem

    var body: some View {
        Bands { l in
            Text("Select mode")
                .font(Theme.serif(34 * l.u))
                .foregroundStyle(Theme.ink)
                .padding(.top, 50 * l.u)
                .place(in: l.rect(0))

            HStack(spacing: 0) {
                ZStack {
                    Theme.memoryOuter
                    Theme.memoryInner.padding(14 * l.u)
                    Theme.memoryCore.frame(width: 44 * l.u, height: 44 * l.u)
                    Text("Memory").font(Theme.serif(26 * l.u)).foregroundStyle(Theme.ink)
                }
                .overlay(Rectangle().stroke(Theme.ink, lineWidth: 4 * l.u)
                    .opacity(highlighted == .memory ? 1 : 0))
                .highlight(highlighted == .memory)

                ZStack {
                    Circle().fill(Theme.record)
                        .overlay(Circle().stroke(Theme.ink, lineWidth: 4 * l.u)
                            .opacity(highlighted == .record ? 1 : 0))
                        .padding(12 * l.u)
                    Text("Record").font(Theme.serif(22 * l.u)).foregroundStyle(Theme.ink)
                }
                .highlight(highlighted == .record)
            }
            .place(in: l.rect(2))

            Image(systemName: "gearshape.fill")
                .font(.system(size: 30 * l.u))
                .foregroundStyle(Theme.ink)
                .frame(width: 60 * l.u, height: 60 * l.u)
                .overlay(Circle().stroke(Theme.ink.opacity(highlighted == .settings ? 1 : 0.3),
                                         lineWidth: (highlighted == .settings ? 4 : 1) * l.u))
                .highlight(highlighted == .settings)
                .place(in: l.rect(3))
        }
    }
}

private extension View {
    func highlight(_ on: Bool) -> some View {
        scaleEffect(on ? 1.08 : 1).zIndex(on ? 1 : 0)
    }
}

/// Memory and Record: choose a family member. The wheel turns with Left / Right; the segment at the top is the
/// one about to be chosen and is drawn larger. The last segment adds a new family member.
struct ChooseMemberPage: View {
    let wheel: [WheelItem]
    let step: Int
    let selected: WheelItem

    var body: some View {
        Bands { l in
            BackButton(u: l.u)
                .padding(16 * l.u)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .place(in: l.rect(0))

            Text("Choose family\nmember")
                .font(Theme.serif(40 * l.u))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .place(in: CGRect(x: 0, y: l.rect(0).midY, width: l.size.width,
                                  height: l.rect(1).midY - l.rect(0).midY + 20 * l.u))

            let d = 360 * l.u
            FamilyWheel(wheel: wheel, step: step, selected: selected, u: l.u)
                .frame(width: d, height: d)
                .place(in: CGRect(x: (l.size.width - d) / 2, y: l.rect(2).maxY - d / 2,
                                  width: d, height: d))
        }
    }
}

struct BackButton: View {
    let u: CGFloat

    var body: some View {
        Label("Back", systemImage: "chevron.left")
            .font(Theme.serif(18 * u))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 14 * u)
            .padding(.vertical, 8 * u)
            .overlay(Capsule().stroke(Theme.ink, lineWidth: 1.5 * u))
    }
}

private struct FamilyWheel: View {
    let wheel: [WheelItem]
    let step: Int
    let selected: WheelItem
    let u: CGFloat

    var body: some View {
        let angle = 360 / Double(wheel.count)
        let length = 92 * u, inner = 50 * u
        ZStack {
            Circle().fill(Theme.table)
            ForEach(wheel.indices, id: \.self) { i in
                let item = wheel[i]
                WheelSegment(item: item, u: u)
                    .frame(width: 104 * u, height: length)
                    .scaleEffect(item == selected ? 1.35 : 1, anchor: .bottom)
                    .offset(y: -(inner + length / 2))
                    .rotationEffect(.degrees(Double(i) * angle))
            }
        }
        .rotationEffect(.degrees(-Double(step) * angle))
    }
}

private struct WheelSegment: View {
    let item: WheelItem
    let u: CGFloat

    var body: some View {
        ZStack {
            SegmentShape().fill(Theme.segment)
            SegmentShape().stroke(Theme.ink, lineWidth: 1.5 * u)
            switch item {
            case .member(let name):
                Text(name)
                    .font(Theme.serif(19 * u))
                    .foregroundStyle(Theme.ink)
                    .offset(y: -14 * u)
            case .add:
                Image(systemName: "plus.circle")
                    .font(.system(size: 26 * u, weight: .light))
                    .foregroundStyle(Theme.ink)
                    .offset(y: -14 * u)
            }
        }
    }
}

/// A slightly wobbly trapezoid, wide end outwards, like the hand-drawn segments.
private struct SegmentShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.02),
                       control: CGPoint(x: r.midX, y: r.minY + r.height * 0.05))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.26, y: r.maxY - r.height * 0.03))
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.25, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.03))
        p.closeSubpath()
        return p
    }
}

/// Settings: recalibrate the floor line and 1 m, or the camera. Left / Right move the
/// highlight, Confirm starts that part of the setup, Back returns to Select mode.
struct SettingsPage: View {
    let highlighted: SettingsItem

    var body: some View {
        Bands { l in
            BackButton(u: l.u)
                .padding(16 * l.u)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .place(in: l.rect(0))

            Text("Settings")
                .font(Theme.serif(34 * l.u))
                .foregroundStyle(Theme.ink)
                .padding(.top, 50 * l.u)
                .place(in: l.rect(0))

            Text("Recalibrate")
                .font(Theme.serif(22 * l.u))
                .foregroundStyle(Theme.ink.opacity(0.7))
                .place(in: l.rect(1))

            ForEach(Array(SettingsItem.allCases.enumerated()), id: \.element) { i, item in
                let on = item == highlighted
                Text(item.title)
                    .font(Theme.serif(24 * l.u))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 280 * l.u, height: 64 * l.u)
                    .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 14 * l.u))
                    .overlay(RoundedRectangle(cornerRadius: 14 * l.u)
                        .stroke(Theme.ink, lineWidth: (on ? 4 : 1) * l.u)
                        .opacity(on ? 1 : 0.3))
                    .scaleEffect(on ? 1.06 : 1)
                    .place(in: l.rect(2 + i))
            }
        }
    }
}

/// A new family member: the name so far, and a wheel of letters. Left / Right turn the wheel,
/// Confirm adds the letter at the top (or saves on Done), Back deletes a letter.
struct AddMemberPage: View {
    let name: String
    let step: Int
    let selected: LetterItem

    var body: some View {
        Bands { l in
            BackButton(u: l.u)
                .padding(16 * l.u)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .place(in: l.rect(0))

            Text("New family\nmember")
                .font(Theme.serif(40 * l.u))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .place(in: CGRect(x: 0, y: l.rect(0).midY, width: l.size.width,
                                  height: l.rect(1).midY - l.rect(0).midY + 20 * l.u))

            // The name as it is spelled.
            HStack(spacing: 2 * l.u) {
                Text(name.isEmpty ? " " : name)
                Rectangle().fill(Theme.ink).frame(width: 2 * l.u, height: 26 * l.u)
            }
            .font(Theme.serif(28 * l.u))
            .foregroundStyle(Theme.ink)
            .frame(width: 230 * l.u, height: 52 * l.u)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8 * l.u))
            .overlay(RoundedRectangle(cornerRadius: 8 * l.u).stroke(Theme.ink, lineWidth: 1.5 * l.u))
            .place(in: CGRect(x: 0, y: l.rect(1).maxY - 40 * l.u, width: l.size.width, height: 52 * l.u))

            let d = 330 * l.u
            LetterWheel(step: step, selected: selected, u: l.u)
                .frame(width: d, height: d)
                .place(in: CGRect(x: (l.size.width - d) / 2, y: l.rect(3).midY - d / 2 + 10 * l.u,
                                  width: d, height: d))
        }
    }
}

private struct LetterWheel: View {
    let step: Int
    let selected: LetterItem
    let u: CGFloat

    var body: some View {
        let items = LetterItem.all
        let angle = 360 / Double(items.count)
        GeometryReader { geo in
            let r = geo.size.width / 2
            ZStack {
                Circle().fill(Theme.table)
                ForEach(items.indices, id: \.self) { i in
                    let item = items[i]
                    let on = item == selected
                    Group {
                        switch item {
                        case .letter(let c): Text(String(c)).font(Theme.serif(22 * u))
                        case .done: Image(systemName: "checkmark").font(.system(size: 20 * u, weight: .semibold))
                        }
                    }
                    .foregroundStyle(Theme.ink)
                    .frame(width: 34 * u, height: 34 * u)
                    .background(Circle().fill(on ? Theme.segment : .clear))
                    .overlay(Circle().stroke(Theme.ink, lineWidth: 1.5 * u).opacity(on ? 1 : 0))
                    .scaleEffect(on ? 1.5 : 1)
                    .offset(y: -(r - 26 * u))
                    .rotationEffect(.degrees(Double(i) * angle))
                }
            }
            .rotationEffect(.degrees(-Double(step) * angle))
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
