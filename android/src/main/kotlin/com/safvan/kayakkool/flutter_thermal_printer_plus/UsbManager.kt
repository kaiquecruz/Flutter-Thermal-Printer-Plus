package com.safvan.kayakkool.flutter_thermal_printer_plus

import android.content.Context
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager as AndroidUsbManager
import io.flutter.plugin.common.MethodChannel.Result

class UsbManager(private val context: Context) {
    private var usbManager: AndroidUsbManager = context.getSystemService(Context.USB_SERVICE) as AndroidUsbManager
    private var connection: UsbDeviceConnection? = null
    private var endpoint: UsbEndpoint? = null
    private var isConnected = false

    fun getDevices(result: Result) {
        val deviceList = usbManager.deviceList
        val devices = mutableListOf<Map<String, Any>>()

        for (device in deviceList.values) {
            val deviceMap = mapOf(
                "name" to device.deviceName,
                "address" to device.deviceName,
                "type" to 2, // USB type
                "isConnected" to false
            )
            devices.add(deviceMap)
        }

        result.success(devices)
    }

    fun connect(deviceName: String, result: Result) {
        val deviceList = usbManager.deviceList
        val device = deviceList[deviceName]

        if (device == null) {
            result.error("DEVICE_NOT_FOUND", "USB device not found", null)
            return
        }

        if (!usbManager.hasPermission(device)) {
            result.error("PERMISSION_DENIED", "USB permission denied", null)
            return
        }

        try {
            connection = usbManager.openDevice(device)
            val usbInterface = device.getInterface(0)
            connection?.claimInterface(usbInterface, true)

            for (i in 0 until usbInterface.endpointCount) {
                val ep = usbInterface.getEndpoint(i)
                if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                    ep.direction == UsbConstants.USB_DIR_OUT) {
                    endpoint = ep
                    break
                }
            }

            if (endpoint != null) {
                isConnected = true
                result.success(true)
            } else {
                result.error("ENDPOINT_NOT_FOUND", "USB endpoint not found", null)
            }
        } catch (e: Exception) {
            result.error("CONNECTION_FAILED", "Failed to connect: ${e.message}", null)
        }
    }

    fun print(bytes: List<Int>, result: Result) {
        if (!isConnected || connection == null || endpoint == null) {
            result.error("NOT_CONNECTED", "USB printer not connected", null)
            return
        }

        try {
            val byteArray = bytes.map { it.toByte() }.toByteArray()
            val transferred = connection?.bulkTransfer(endpoint, byteArray, byteArray.size, 5000)
            result.success((transferred ?: 0) > 0)
        } catch (e: Exception) {
            result.error("PRINT_FAILED", "Failed to print: ${e.message}", null)
        }
    }

    fun isConnected(): Boolean {
        return isConnected && connection != null
    }

    fun cleanup() {
        connection?.close()
        isConnected = false
    }
}