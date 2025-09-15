package com.safvan.kayakkool.flutter_thermal_printer_plus

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
    private val scope = CoroutineScope(Dispatchers.IO)

    fun scanPrinters(result: Result) {
        // For WiFi printers, manual IP configuration is typically used
        // This could be enhanced with network discovery
        val printers = listOf<Map<String, Any>>()
        result.success(printers)
    }

    fun connect(ip: String, port: Int, result: Result) {
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
        try {
            socket?.close()
        } catch (e: IOException) {
            // Ignore cleanup errors
        }
        isConnected = false
        scope.cancel()
    }
}