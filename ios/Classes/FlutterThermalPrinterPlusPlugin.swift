import Flutter
import UIKit

public class FlutterThermalPrinterPlugin: NSObject, FlutterPlugin {
    private let bluetoothManager = BluetoothManager()
    private let usbManager = UsbManager()
    private let wifiManager = WifiManager()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_thermal_printer_plus", binaryMessenger: registrar.messenger())
        let instance = FlutterThermalPrinterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        // Bluetooth methods
        case "scanBluetooth":
            bluetoothManager.scanDevices(result: result)
        case "connectBluetooth":
            if let args = call.arguments as? [String: Any],
               let address = args["address"] as? String {
                bluetoothManager.connect(address: address, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Address is required", details: nil))
            }
        case "disconnectBluetooth":
            bluetoothManager.disconnect(result: result)

        // WiFi methods
        case "scanWifi":
            wifiManager.scanPrinters(result: result)
        case "connectWifi":
            if let args = call.arguments as? [String: Any],
               let ip = args["ip"] as? String {
                let port = args["port"] as? Int ?? 9100
                wifiManager.connect(ip: ip, port: port, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "IP is required", details: nil))
            }
        case "disconnectWifi":
            wifiManager.disconnect(result: result)

        // USB methods
        case "getUsbDevices":
            usbManager.getDevices(result: result)
        case "connectUsb":
            if let args = call.arguments as? [String: Any],
               let deviceName = args["deviceName"] as? String {
                usbManager.connect(deviceName: deviceName, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Device name is required", details: nil))
            }

        // Print method
        case "print":
            if let args = call.arguments as? [String: Any],
               let bytes = args["bytes"] as? [Int] {
                printBytes(bytes: bytes, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Bytes are required", details: nil))
            }

        // Connection status
        case "isConnected":
            result(isAnyConnectionActive())

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func printBytes(bytes: [Int], result: @escaping FlutterResult) {
        if bluetoothManager.isConnected() {
            bluetoothManager.print(bytes: bytes, result: result)
        } else if wifiManager.isConnected() {
            wifiManager.print(bytes: bytes, result: result)
        } else if usbManager.isConnected() {
            usbManager.print(bytes: bytes, result: result)
        } else {
            result(FlutterError(code: "NOT_CONNECTED", message: "No printer connected", details: nil))
        }
    }

    private func isAnyConnectionActive() -> Bool {
        return bluetoothManager.isConnected() ||
               wifiManager.isConnected() ||
               usbManager.isConnected()
    }
}