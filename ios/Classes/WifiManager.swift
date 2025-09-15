import Foundation
import Network

class WifiManager {
    private var connection: NWConnection?
    private var connected = false
    private var isCurrentlyScanning = false //  Track scanning state
    private var scanTimer: Timer? //Scan timeout timer

    func scanPrinters(result: @escaping FlutterResult) {
        // Stop any existing scan
        if isCurrentlyScanning {
            stopScanInternal()
        }

        isCurrentlyScanning = true

        // WiFi printer discovery would go here
        // For now, return empty list after timeout
        scanTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            self?.isCurrentlyScanning = false
            result([])
        }
    }

    //  Stop scanning method
    func stopScan(result: @escaping FlutterResult) {
        stopScanInternal()
        result(true)
    }

    //  Internal stop scan method
    func stopScanInternal() {
        scanTimer?.invalidate()
        scanTimer = nil
        isCurrentlyScanning = false
    }

    //  Check if scanning
    func isScanning() -> Bool {
        return isCurrentlyScanning
    }

    func connect(ip: String, port: Int, result: @escaping FlutterResult) {
        // Stop scanning before connecting
        if isCurrentlyScanning {
            stopScanInternal()
        }

        let host = NWEndpoint.Host(ip)
        let portEndpoint = NWEndpoint.Port(rawValue: UInt16(port))!

        connection = NWConnection(host: host, port: portEndpoint, using: .tcp)

        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.connected = true
                result(true)
            case .failed(let error):
                result(FlutterError(code: "CONNECTION_FAILED", message: error.localizedDescription, details: nil))
            default:
                break
            }
        }

        connection?.start(queue: .main)
    }

    func disconnect(result: @escaping FlutterResult) {
        connection?.cancel()
        connected = false
        result(true)
    }

    func print(bytes: [Int], result: @escaping FlutterResult) {
        guard let connection = connection, connected else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }

        let data = Data(bytes.map { UInt8($0) })
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                result(FlutterError(code: "PRINT_FAILED", message: error.localizedDescription, details: nil))
            } else {
                result(true)
            }
        })
    }

    func isConnected() -> Bool {
        return connected
    }

    // Cleanup method
    deinit {
        stopScanInternal()
    }
}