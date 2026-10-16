import SwiftUI

/// The projected image. It is drawn upright at 1080 x 1920 (a portrait picture) and, on the
/// projector, turned to fill its 1920 x 1080 output, because the projector lies on its side.
/// On the phone (the preview) it is drawn upright and scaled down.
struct ProjectorRootView: View {
    var isExternal: Bool
    @Environment(AppState.self) private var state

    static let canvas = CGSize(width: 1080, height: 1920)

    var body: some View {
        GeometryReader { geo in
            let c = Self.canvas
            let box = isExternal ? CGSize(width: geo.size.height, height: geo.size.width) : geo.size
            // On the projector, fill the whole output (no black borders, at most a sliver is
            // cropped if its shape is not exactly 16:9). The phone preview fits instead.
            let scale = isExternal ? max(box.width / c.width, box.height / c.height)
                                   : min(box.width / c.width, box.height / c.height)
            ZStack {
                ProjectorPage(page: state.page, highlighted: state.highlighted, state: state)
                    .id(state.page)
                    .transition(.opacity)
            }
            .frame(width: c.width, height: c.height)
            .clipped()
            .scaleEffect(scale)
            .frame(width: box.width, height: box.height)
            .rotationEffect(.degrees(isExternal ? state.projectorRotation : 0))
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}

private struct ProjectorPage: View {
    let page: Page
    let highlighted: MenuItem
    let state: AppState

    var body: some View {
        switch page {
        case .splash: TimeCapsulePage()
        case .setup(let step): ProjectorSetupPage(step: step, wall: state.wall)
        case .menu: SelectModePage(highlighted: highlighted)
        case .chooseMember: ChooseMemberPage(wheel: state.wheel, step: state.wheelStep,
                                             selected: state.wheelSelected)
        case .addMember: AddMemberPage(name: state.newName, step: state.letterStep,
                                       selected: state.letterSelected)
        case .settings: SettingsPage(highlighted: state.settingsHighlighted)
        }
    }
}
