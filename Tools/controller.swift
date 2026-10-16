// Controls Time Capsule from the Mac's keyboard, standing in for the Bluetooth controller.
// The phone and the Mac must be on the same Wi-Fi. Run:  swift Tools/controller.swift
// It connects to the first phone running Time Capsule it finds (not the simulator). To pick
// one, give its address:
//   swift Tools/controller.swift 127.0.0.1        (the simulator on this Mac)
// On the iPhone's Personal Hotspot it falls back to the phone's address, 172.20.10.1.
//
//   Left / Right arrow  Left / Right
//   Up / Down arrow     Knob +1 / -1 (moves lines in setup; like Right / Left in menus)
//   Return or Space     Confirm    (open)
//   Backspace or B      Back
//   Q                   Quit
//
// Sends the same 2-byte packets [controlId, value] as Height Ritual's controller.

import Foundation
import Network

let packets: [String: [UInt8]] = [
    "Left": [14, 0], "Right": [15, 0], "Confirm": [13, 0], "Back": [23, 0],
    "Up": [1, 1], "Down": [1, 0xFF],   // knob +1 / -1
]
let queue = DispatchQueue(label: "controller")
var connection: NWConnection?
var connected = false

func say(_ text: String) { print(text, terminator: "\r\n"); fflush(stdout) }

let hostArgument = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : nil
var browser: NWBrowser?
var triedHotspot = false

func connect(to endpoint: NWEndpoint) {
    let c = NWConnection(to: endpoint, using: .tcp)
    c.stateUpdateHandler = { state in
        switch state {
        case .ready:
            connected = true
            browser?.cancel()
            say("Connected to Time Capsule (\(endpoint)).")
        case .waiting, .failed:
            // Refused or gone, e.g. the app is not open: look again in a second.
            if connected { say("Lost the connection; looking again...") }
            connected = false
            c.cancel()
        case .cancelled:
            connected = false
            if connection === c {
                connection = nil
                queue.asyncAfter(deadline: .now() + 1) { if connection == nil { find() } }
            }
        default: break
        }
    }
    connection = c
    c.start(queue: queue)
}

/// Connects to the address given on the command line, or else searches for a phone running
/// Time Capsule (the simulator is skipped), falling back to the iPhone hotspot address.
func find() {
    if let hostArgument {
        connect(to: .hostPort(host: NWEndpoint.Host(hostArgument), port: 52800))
        return
    }
    browser?.cancel()
    let b = NWBrowser(for: .bonjour(type: "_timecapsule._tcp", domain: nil), using: .tcp)
    b.browseResultsChangedHandler = { results, _ in
        guard connection == nil else { return }
        let phones = results.filter { result in
            if case .service(let name, _, _, _) = result.endpoint { return !name.contains("Simulator") }
            return true
        }
        if let phone = phones.first { connect(to: phone.endpoint) }
    }
    browser = b
    b.start(queue: queue)
    // On the iPhone's own Personal Hotspot the phone is not found by searching, but it always
    // has this address.
    queue.asyncAfter(deadline: .now() + 3) {
        guard connection == nil else { return }
        if !triedHotspot { say("Not found by searching; also trying the iPhone hotspot address 172.20.10.1...") }
        triedHotspot = true
        connect(to: .hostPort(host: "172.20.10.1", port: 52800))
    }
}

func send(_ name: String) {
    guard let packet = packets[name], let c = connection, connected else {
        say("Not connected (is Time Capsule open and on screen on the phone?)")
        return
    }
    c.send(content: Data(packet), completion: .contentProcessed { _ in })
    say(name)
}

queue.async { find() }

// Read single key presses from the terminal.
var original = termios()
tcgetattr(STDIN_FILENO, &original)
var raw = original
raw.c_lflag &= ~tcflag_t(ICANON | ECHO)
tcsetattr(STDIN_FILENO, TCSANOW, &raw)
func restore() { tcsetattr(STDIN_FILENO, TCSANOW, &original) }
atexit { restore() }

say("Searching for Time Capsule on the network...")
say("Arrows: move   Return: confirm   Backspace: back   Q: quit")

Thread {
    var escape: [UInt8] = []
    while true {
        var byte: UInt8 = 0
        let n = read(STDIN_FILENO, &byte, 1)
        if n == 0 { sleep(1); restore(); exit(0) }   // input ended (piped keys)
        if n < 0 { continue }
        if !escape.isEmpty || byte == 27 {
            escape.append(byte)
            if escape.count == 3 {
                switch escape[2] {
                case 68: send("Left")
                case 67: send("Right")
                case 65: send("Up")
                case 66: send("Down")
                default: break
                }
                escape = []
            }
            continue
        }
        switch byte {
        case 10, 13, 32: send("Confirm")
        case 127, 8, 98, 66: send("Back")
        case 113, 81: restore(); exit(0)
        default: break
        }
    }
}.start()

dispatchMain()
