package com.safwan.kayakkool.flutter_thermal_printer_plus

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.io.OutputStream
import java.util.*

class BluetoothManager(private val context: Context) {
    private var bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var socket: BluetoothSocket? = null
    private var outputStream: OutputStream? = null
    private var isConnected = false
    private var isCurrentlyScanning = false // NEW: Track scanning state

    fun scanDevices(result: Result) {
        if (bluetoothAdapter == null) {
            result.error("BLUETOOTH_NOT_AVAILABLE", "Bluetooth not available", null)
            return
        }

        if (!bluetoothAdapter!!.isEnabled) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is disabled", null)
            return
        }

        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT)
            != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("PERMISSION_DENIED", "Bluetooth permission denied", null)
            return
        }

        // Stop any existing scan first
        if (isCurrentlyScanning) {
            stopScanInternal()
        }

        isCurrentlyScanning = true // NEW: Set scanning flag

        val pairedDevices: Set<BluetoothDevice>? = bluetoothAdapter?.bondedDevices
        val devices = mutableListOf<Map<String, Any>>()

        pairedDevices?.forEach { device ->
            val deviceMap = mapOf(
                "name" to (device.name ?: "Unknown"),
                "address" to device.address,
                "type" to 0, // Bluetooth type
                "isConnected" to false
            )
            devices.add(deviceMap)
        }

        // AUTO STOP: Stop scanning after 10 seconds to prevent battery drain
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            stopScanInternal()
        }, 10000) // 10 seconds

        isCurrentlyScanning = false // Reset flag after returning results
        result.success(devices)
    }

    // NEW: Stop scanning method
    fun stopScan(result: Result) {
        try {
            stopScanInternal()
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_SCAN_FAILED", "Failed to stop scan: ${e.message}", null)
        }
    }

    // NEW: Internal stop scan method
    fun stopScanInternal() {
        if (isCurrentlyScanning) {
            try {
                // Stop any ongoing Bluetooth discovery
                bluetoothAdapter?.cancelDiscovery()
                isCurrentlyScanning = false
            } catch (e: Exception) {
                // Log error but don't crash
                android.util.Log.e("BluetoothManager", "Error stopping scan: ${e.message}")
            }
        }
    }

    // NEW: Check if scanning
    fun isScanning(): Boolean {
        return isCurrentlyScanning
    }

    fun connect(address: String, result: Result) {
        // Stop scanning before connecting
        if (isCurrentlyScanning) {
            stopScanInternal()
        }

        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT)
            != PackageManager.PERMISSION_GRANTED
        ) {
            result.error("PERMISSION_DENIED", "Bluetooth permission denied", null)
            return
        }

        try {
            val device: BluetoothDevice? = bluetoothAdapter?.getRemoteDevice(address)
            val uuid = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
            socket = device?.createRfcommSocketToServiceRecord(uuid)
            socket?.connect()
            outputStream = socket?.outputStream
            isConnected = true
            result.success(true)
        } catch (e: IOException) {
            result.error("CONNECTION_FAILED", "Failed to connect: ${e.message}", null)
        }
    }

    fun disconnect(result: Result) {
        try {
            socket?.close()
            isConnected = false
            result.success(true)
        } catch (e: IOException) {
            result.error("DISCONNECT_FAILED", "Failed to disconnect: ${e.message}", null)
        }
    }

    fun print(bytes: List<Int>, result: Result) {
        if (!isConnected || outputStream == null) {
            result.error("NOT_CONNECTED", "Printer not connected", null)
            return
        }

        try {
            val byteArray = bytes.map { it.toByte() }.toByteArray()
            outputStream?.write(byteArray)
            outputStream?.flush()
            result.success(true)
        } catch (e: IOException) {
            result.error("PRINT_FAILED", "Failed to print: ${e.message}", null)
        }
    }

    fun isConnected(): Boolean {
        return isConnected && socket?.isConnected == true && bluetoothAdapter?.isEnabled == true
    }

    fun cleanup() {
        // Stop scanning first
        stopScanInternal()

        try {
            socket?.close()
        } catch (e: IOException) {
            // Ignore cleanup errors
        }
        isConnected = false
    }
}
