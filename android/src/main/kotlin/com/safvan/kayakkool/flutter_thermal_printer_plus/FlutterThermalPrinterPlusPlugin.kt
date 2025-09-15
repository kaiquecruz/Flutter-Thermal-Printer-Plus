package com.safvan.kayakkool.flutter_thermal_printer_plus

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterThermalPrinterPlusPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var bluetoothManager: BluetoothManager
    private lateinit var usbManager: UsbManager
    private lateinit var wifiManager: WifiManager

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_thermal_printer_plus")
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

            // Connection status
            "isConnected" -> result.success(isAnyConnectionActive())

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

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        bluetoothManager.cleanup()
        usbManager.cleanup()
        wifiManager.cleanup()
    }
}