import Foundation
import Network
import UIKit

/// Stand-in for the Bluetooth controller: listens on the local network (Bonjour service
/// `_timecapsule._tcp`) for the 2-byte packets sent by `Tools/controller.swift` on the Mac.
@MainActor
final class NetworkControl {
    static let serviceType = "_timecapsule._tcp"
    /// Fixed so the script can also connect by address (`swift Tools/controller.swift <host>`).
    static let port: NWEndpoint.Port = 52800

    var onEvent: ((ControlEvent) -> Void)?
    var onConnectedChange: ((Bool) -> Void)?

    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private let queue = DispatchQueue(label: "network.control")

    init() {
        // iOS stops the listener while the app is in the background or the phone is locked;
        // start a fresh one whenever the app is back on screen.
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.restart() }
        }
    }

    func restart() {
        listener?.cancel()
        listener = nil
        start()
    }

    func start() {
        guard listener == nil else { return }
        do {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = true
            let listener = try NWListener(using: parameters, on: Self.port)
            #if targetEnvironment(simulator)
            let name = "Time Capsule Simulator"   // skipped by the script unless asked for
            #else
            let name = "Time Capsule"
            #endif
            listener.service = NWListener.Service(name: name, type: Self.serviceType)
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in self?.accept(connection) }
            }
            listener.stateUpdateHandler = { [weak self, weak listener] state in
                print("[TimeCapsule] control listener:", state)
                if case .failed = state {
                    // Try again shortly, e.g. after the port was still in use.
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(1))
                        guard let self, self.listener === listener else { return }
                        self.restart()
                    }
                }
            }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            print("[TimeCapsule] control listener failed:", error)
        }
    }

    private func accept(_ connection: NWConnection) {
        connections.append(connection)
        connection.stateUpdateHandler = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                switch state {
                case .ready:
                    self.onConnectedChange?(true)
                case .failed, .cancelled:
                    self.connections.removeAll { $0 === connection }
                    self.onConnectedChange?(!self.connections.isEmpty)
                default: break
                }
            }
        }
        connection.start(queue: queue)
        receive(on: connection)
    }

    private func receive(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 2, maximumLength: 2) { [weak self] data, _, done, error in
            Task { @MainActor in
                guard let self else { return }
                if let data, data.count == 2,
                   let event = ControlEvent.from(id: data[0], value: Int8(bitPattern: data[1])) {
                    self.onEvent?(event)
                }
                if done || error != nil {
                    connection.cancel()
                } else {
                    self.receive(on: connection)
                }
            }
        }
    }
}
