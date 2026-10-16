import SwiftUI

@main
struct TimeCapsuleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var state = AppState.shared

    var body: some Scene {
        WindowGroup {
            PhoneRootView()
                .environment(state)
                .modifier(ProjectorAccessory(state: state))
                .preferredColorScheme(.light)
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                    print("[TimeCapsule] screens:", UIScreen.screens.count,
                          "scenes:", UIApplication.shared.connectedScenes.map(\.session.role.rawValue))
                }
        }
    }
}

/// Since iOS 27, an app built with the iOS 27 SDK only gets its own external display scene if it
/// registers a scene accessory; otherwise the projector mirrors the phone. Older iOS versions
/// still use the Info.plist entry and `ExternalSceneDelegate` below.
private struct ProjectorAccessory: ViewModifier {
    let state: AppState

    func body(content: Content) -> some View {
        if #available(iOS 27.0, *) {
            content.sceneAccessory {
                ExternalNonInteractiveAccessory {
                    ProjectorRootView(isExternal: true)
                        .environment(state)
                        .onAppear { useFullProjectorPicture() }
                }
                .onAvailabilityChange { available in
                    print("[TimeCapsule] projector accessory available:", available)
                    state.externalDisplayConnected = available
                }
            }
        } else {
            content
        }
    }

    /// Use the projector's full resolution, and stop iOS from shrinking the picture to allow
    /// for TV overscan, which leaves a black border around it.
    private func useFullProjectorPicture() {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes
        where scene.session.role == .windowExternalDisplayNonInteractive {
            scene.screen.useFullPicture()
        }
    }
}

extension UIScreen {
    func useFullPicture() {
        if let best = availableModes.max(by: {
            $0.size.width * $0.size.height < $1.size.width * $1.size.height
        }) {
            currentMode = best
        }
        overscanCompensation = .none
    }
}

/// With the SwiftUI lifecycle the Info.plist entry for the external display may not be used, and
/// the projector would mirror the phone. Returning the configuration here makes sure the
/// projector gets its own scene with only the projector image. (Same as Height Ritual.)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting session: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("[TimeCapsule] scene connecting, role:", session.role.rawValue)
        let configuration = UISceneConfiguration(name: nil, sessionRole: session.role)
        // On iOS 27 SwiftUI's scene accessory handles the projector scene itself.
        if #unavailable(iOS 27.0), session.role == .windowExternalDisplayNonInteractive {
            configuration.delegateClass = ExternalSceneDelegate.self
        }
        return configuration
    }
}
