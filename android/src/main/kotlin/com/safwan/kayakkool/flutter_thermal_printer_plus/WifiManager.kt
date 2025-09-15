package com.safwan.kayakkool.flutter_thermal_printer_plus

import android.content.Context
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import java.io.IOException
import java.io.OutputStream
import java.net.Socket

class WifiManager(private val context: Context) {
    private var socket: Socket? = null
    private var outputStream: OutputStream? = null
    private var isConnected = false
    private var isCurrentlyScanning = false //Track scanning state
    private var scanJob: Job? = null // Track scan job
    private val scope = CoroutineScope(Dispatchers.IO)

    fun scanPrinters(result: Result) {
        // Stop any existing scan
        if (isCurrentlyScanning) {
            stopScanInternal()
        }

        isCurrentlyScanning = true

        // For WiFi printers, manual IP configuration is typically used
        // This could be enhanced with network discovery
        scanJob = scope.launch {
            try {
                // Simulate network discovery or return empty list
                // In real implementation, you might scan common printer ports
                val printers = listOf<Map<String, Any>>()

                // AUTO STOP: Complete scan after timeout
                delay(5000) // 5 seconds for WiFi scan

                withContext(Dispatchers.Main) {
                    isCurrentlyScanning = false
                    result.success(printers)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    isCurrentlyScanning = false
                    result.error("SCAN_FAILED", "WiFi scan failed: ${e.message}", null)
                }
            }
        }
    }

    // Stop scanning method
    fun stopScan(result: Result) {
        try {
            stopScanInternal()
            result.success(true)
        } catch (e: Exception) {
            result.error("STOP_SCAN_FAILED", "Failed to stop WiFi scan: ${e.message}", null)
        }
    }


    // Internal stop scan method
    fun stopScanInternal() {
        if (isCurrentlyScanning) {
            scanJob?.cancel()
            isCurrentlyScanning = false
        }
    }

    // Check if scanning
    fun isScanning(): Boolean {
        return isCurrentlyScanning
    }

    fun connect(ip: String, port: Int, result: Result) {

        // Stop scanning before connecting
        if (isCurrentlyScanning) {
            stopScanInternal()
        }

        scope.launch {
            try {
                socket = Socket(ip, port)
                outputStream = socket?.outputStream
                isConnected = true
                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: IOException) {
                withContext(Dispatchers.Main) {
                    result.error("CONNECTION_FAILED", "Failed to connect: ${e.message}", null)
                }
            }
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

        scope.launch {
            try {
                val byteArray = bytes.map { it.toByte() }.toByteArray()
                outputStream?.write(byteArray)
                outputStream?.flush()
                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: IOException) {
                withContext(Dispatchers.Main) {
                    result.error("PRINT_FAILED", "Failed to print: ${e.message}", null)
                }
            }
        }
    }

    fun isConnected(): Boolean {
        return isConnected && socket?.isConnected == true
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
        scope.cancel()
    }
}