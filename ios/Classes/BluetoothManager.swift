import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var discoveredPeripherals: [CBPeripheral] = []
    private var scanResult: FlutterResult?
    private var connectResult: FlutterResult?
    private var isCurrentlyScanning = false // Track scanning state
    private var scanTimer: Timer? //Scan timeout timer
    private var connected = false

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func scanDevices(result: @escaping FlutterResult) {
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
            result(FlutterError(code: "BLUETOOTH_DISABLED", message: "Bluetooth is not powered on", details: nil))
            return
        }

        // Stop any existing scan first
        if isCurrentlyScanning {
            stopScanInternal()
        }

        scanResult = result
        discoveredPeripherals.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        isCurrentlyScanning = true

        // AUTO STOP: Stop scanning after 10 seconds to prevent battery drain
        scanTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.stopScanInternal()
            self?.completeScan()
        }
    }

    // NEW: Stop scanning method
    func stopScan(result: @escaping FlutterResult) {
        stopScanInternal()
        result(true)
    }

    //Internal stop scan method
    func stopScanInternal() {
        guard isCurrentlyScanning else { return }

        centralManager?.stopScan()
        scanTimer?.invalidate()
        scanTimer = nil
        isCurrentlyScanning = false
    }

    // Complete scan and return results
    private func completeScan() {
        if let result = scanResult {
            let devices = discoveredPeripherals.map { peripheral in
                return [
                    "name": peripheral.name ?? "Unknown",
                    "address": peripheral.identifier.uuidString,
                    "type": 0, // Bluetooth
                    "isConnected": false
                ] as [String : Any]
            }
            result(devices)
            scanResult = nil
        }
    }

    // Check if scanning
    func isScanning() -> Bool {
        return isCurrentlyScanning
    }

    func connect(address: String, result: @escaping FlutterResult) {
        // Stop scanning before connecting
        if isCurrentlyScanning {
            stopScanInternal()
        }

        connectResult = result

        for peripheral in discoveredPeripherals {
            if peripheral.identifier.uuidString == address {
                centralManager?.connect(peripheral, options: nil)
                return
            }
        }

        result(FlutterError(code: "DEVICE_NOT_FOUND", message: "Device not found", details: nil))
    }

    func disconnect(result: @escaping FlutterResult) {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        connected = false
        result(true)
    }

    func print(bytes: [Int], result: @escaping FlutterResult) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic else {
            result(FlutterError(code: "NOT_CONNECTED", message: "Printer not connected", details: nil))
            return
        }

        let data = Data(bytes.map { UInt8($0) })
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        result(true)
    }

    func isConnected() -> Bool {
        return connected && connectedPeripheral?.state == .connected
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle state updates
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        connected = true
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let result = connectResult {
            result(FlutterError(code: "CONNECTION_FAILED", message: error?.localizedDescription ?? "Connection failed", details: nil))
            connectResult = nil
        }
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) {
                writeCharacteristic = characteristic
                if let result = connectResult {
                    result(true)
                    connectResult = nil
                }
                break
            }
        }
    }

    // Cleanup method
    deinit {
        stopScanInternal()
    }
}