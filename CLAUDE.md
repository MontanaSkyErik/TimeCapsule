# Time Capsule

Second version of Height Ritual (`../HeightRitual`), reusing its ideas and code where they fit.
iPhone app in portrait; a Full HD projector (1920 x 1080) lies on its side and shows its own
image through an HDMI adapter (external display scene, same approach as Height Ritual).

## Current state

- Setup, every time the app starts (after the Time Capsule page, starting from the saved
  values), and from Settings (Floor line and 1 m = steps 1-2, Camera = steps 3-4; Back on the first step
  keeps the old values): Up/Down (knob) move a line,
  Enter goes on, Back goes back. 1) projected floor line onto the floor, 2) projected 100 cm line
  onto 1 m (sets the scale), 3)-4) the same two lines in the camera picture on the phone onto the
  projected ones. Stored in `Calibration` / `CameraLines` (`State/Calibration.swift`) and kept
  between launches; for estimating height later: `cm = (floorY - y) * 100 / (floorY - y100)`.
- Phone: shows the Time Capsule page; in camera setup and on Choose family member it is the camera (preview only, no
  recording yet). No touch control.
- Projector: Time Capsule page fades into the setup, then Select mode (Memory, Record, Settings gear). Left/Right
  move the highlight, Confirm opens a placeholder page (Memory and Record open Choose family member: a
  wheel of the family and an add segment; Left/Right turn it, the top segment is larger;
  Confirm on a member does nothing yet; Confirm on the add segment opens New family member: a
  letter wheel A-Z, Å, Ä, Ö and Done; Confirm adds a letter, Back deletes one, Done saves the
  member, kept between launches in `AppState.family`). Gear opens Settings, Back returns to the menu
  (`AppState.handle`). Pages are in `Shared/Pages.swift`, sized for 390 pt and scaled by `u`.
- Controller: for now the Mac keyboard via `Tools/controller.swift` (Bonjour `_timecapsule._tcp`,
  `Input/NetworkControl.swift`), sending Height Ritual's 2-byte packets (1 knob, 14 left,
  15 right, 13 confirm, 23 back; the up/down arrows are the knob) so a Bluetooth controller can replace it.
- The projector image is drawn upright at 1080 x 1920 and turned by
  `AppState.projectorRotation` (-90 = to the left, 90 = to the right). Works on the projector.
- iOS 27 SDK: the projector only gets its own image through the SwiftUI scene accessory
  (`ExternalNonInteractiveAccessory` in `App/TimeCapsuleApp.swift`). The Info.plist entry and
  `ExternalSceneDelegate` (the Height Ritual way) only work on iOS 26 and earlier; on iOS 27 they
  give mirroring.
- Without a projector, a small preview of the projector image sits at the bottom right of the
  phone; launch with `-projectorOnPhone` to see it full size.

## Commands

```
xcodegen
swift Tools/controller.swift            # control the app from the Mac keyboard
swift Tools/controller.swift 127.0.0.1  # control the simulator on this Mac
xcodebuild -project TimeCapsule.xcodeproj -scheme TimeCapsule \
  -destination 'generic/platform=iOS Simulator' build
```

## Rules

- iOS 17+, SwiftUI, `@Observable`, Swift 5 language mode. No third-party packages.
- All input goes through `AppState.handle(_:)`; change the page only through `AppState.go(to:)`.
- The external display cannot be fully tested without a device; the simulator's
  I/O > External Displays > 1920x1080 gets close. Never claim device behaviour untested.
