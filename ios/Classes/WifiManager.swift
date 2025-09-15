import Foundation
import Network

class WifiManager {
    private var connection: NWConnection?
    private var connected = false

    func scanPrinters(result: @escaping FlutterResult) {
        // WiFi printer discovery would go here
        result([])
    }

    func connect(ip: String, port: Int, result: @escaping FlutterResult) {
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
}