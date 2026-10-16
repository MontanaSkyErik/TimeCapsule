import SwiftUI
import UIKit

/// Drives the projector on iOS 26 and earlier (iOS 27 uses the scene accessory in
/// `TimeCapsuleApp`). iOS creates this scene when an HDMI adapter is connected. The projector
/// then shows its own image while the phone keeps its own screen.
private struct ExternalProjector: View {
    @State private var state = AppState.shared
    var body: some View {
        ProjectorRootView(isExternal: true)
            .environment(state)
    }
}

final class ExternalSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        print("[TimeCapsule] projector scene created, screen:", windowScene.screen.bounds)
        windowScene.screen.useFullPicture()
        let window = UIWindow(windowScene: windowScene)
        let host = UIHostingController(rootView: ExternalProjector())
        host.view.backgroundColor = .black
        window.rootViewController = host
        window.isHidden = false
        self.window = window
        MainActor.assumeIsolated { AppState.shared.externalDisplayConnected = true }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        MainActor.assumeIsolated { AppState.shared.externalDisplayConnected = false }
        window = nil
    }
}
