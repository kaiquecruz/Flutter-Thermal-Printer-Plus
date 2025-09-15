package com.safwan.kayakkool.flutter_thermal_printer_plus

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterThermalPrinterPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var bluetoothManager: BluetoothManager
    private lateinit var usbManager: UsbManager
    private lateinit var wifiManager: WifiManager

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_thermal_printer")
        channel.setMethodCallHandler(this)

        val context = flutterPluginBinding.applicationContext
        bluetoothManager = BluetoothManager(context)
        usbManager = UsbManager(context)
        wifiManager = WifiManager(context)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            // Bluetooth methods
            "scanBluetooth" -> bluetoothManager.scanDevices(result)
            "stopBluetoothScan" -> bluetoothManager.stopScan(result) // NEW
            "connectBluetooth" -> {
                val address = call.argument<String>("address")
                if (address != null) {
                    bluetoothManager.connect(address, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Address is required", null)
                }
            }
            "disconnectBluetooth" -> bluetoothManager.disconnect(result)

            // WiFi methods
            "scanWifi" -> wifiManager.scanPrinters(result)
            "stopWifiScan" -> wifiManager.stopScan(result) // NEW
            "connectWifi" -> {
                val ip = call.argument<String>("ip")
                val port = call.argument<Int>("port") ?: 9100
                if (ip != null) {
                    wifiManager.connect(ip, port, result)
                } else {
                    result.error("INVALID_ARGUMENT", "IP is required", null)
                }
            }
            "disconnectWifi" -> wifiManager.disconnect(result)

            // USB methods
            "getUsbDevices" -> usbManager.getDevices(result)
            "connectUsb" -> {
                val deviceName = call.argument<String>("deviceName")
                if (deviceName != null) {
                    usbManager.connect(deviceName, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Device name is required", null)
                }
            }

            // Print method
            "print" -> {
                val bytes = call.argument<List<Int>>("bytes")
                if (bytes != null) {
                    printBytes(bytes, result)
                } else {
                    result.error("INVALID_ARGUMENT", "Bytes are required", null)
                }
            }

            // Connection and scanning status
            "isConnected" -> result.success(isAnyConnectionActive())
            "isScanning" -> result.success(isAnyScanning()) // NEW
            "stopAllScanning" -> stopAllScanning(result) // NEW

            else -> result.notImplemented()
        }
    }

    private fun printBytes(bytes: List<Int>, result: Result) {
        when {
            bluetoothManager.isConnected() -> bluetoothManager.print(bytes, result)
            wifiManager.isConnected() -> wifiManager.print(bytes, result)
            usbManager.isConnected() -> usbManager.print(bytes, result)
            else -> result.error("NOT_CONNECTED", "No printer connected", null)
        }
    }

    private fun isAnyConnectionActive(): Boolean {
        return bluetoothManager.isConnected() ||
                wifiManager.isConnected() ||
                usbManager.isConnected()
    }

    // NEW: Check if any scanning is active
    private fun isAnyScanning(): Boolean {
        return bluetoothManager.isScanning() || wifiManager.isScanning()
    }

    // NEW: Stop all scanning
    private fun stopAllScanning(result: Result) {
        var bluetoothStopped = true
        var wifiStopped = true

        if (bluetoothManager.isScanning()) {
            bluetoothManager.stopScanInternal()
        }

        if (wifiManager.isScanning()) {
            wifiManager.stopScanInternal()
        }

        result.success(bluetoothStopped && wifiStopped)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        bluetoothManager.cleanup()
        usbManager.cleanup()
        wifiManager.cleanup()
    }
}