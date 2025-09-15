import 'package:flutter/services.dart';
import '../models/printer_info.dart';

class ThermalPrinterPlatform {
  static const MethodChannel _channel = MethodChannel('flutter_thermal_printer_plus');

  // Bluetooth methods
  static Future<List<PrinterInfo>> scanBluetoothDevices() async {
    try {
      final List<dynamic> devices = await _channel.invokeMethod('scanBluetooth');
      return devices.map((device) => PrinterInfo.fromMap(Map<String, dynamic>.from(device))).toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to scan Bluetooth devices: ${e.message}');
    }
  }

  static Future<bool> connectBluetooth(String address) async {
    try {
      return await _channel.invokeMethod('connectBluetooth', {'address': address});
    } on PlatformException catch (e) {
      throw Exception('Failed to connect Bluetooth: ${e.message}');
    }
  }

  static Future<bool> disconnectBluetooth() async {
    try {
      return await _channel.invokeMethod('disconnectBluetooth');
    } on PlatformException catch (e) {
      throw Exception('Failed to disconnect Bluetooth: ${e.message}');
    }
  }

  // WiFi methods
  static Future<List<PrinterInfo>> scanWifiPrinters() async {
    try {
      final List<dynamic> printers = await _channel.invokeMethod('scanWifi');
      return printers.map((printer) => PrinterInfo.fromMap(Map<String, dynamic>.from(printer))).toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to scan WiFi printers: ${e.message}');
    }
  }

  static Future<bool> connectWifi(String ip, int port) async {
    try {
      return await _channel.invokeMethod('connectWifi', {'ip': ip, 'port': port});
    } on PlatformException catch (e) {
      throw Exception('Failed to connect WiFi: ${e.message}');
    }
  }

  static Future<bool> disconnectWifi() async {
    try {
      return await _channel.invokeMethod('disconnectWifi');
    } on PlatformException catch (e) {
      throw Exception('Failed to disconnect WiFi: ${e.message}');
    }
  }

  // USB methods
  static Future<List<PrinterInfo>> getUsbDevices() async {
    try {
      final List<dynamic> devices = await _channel.invokeMethod('getUsbDevices');
      return devices.map((device) => PrinterInfo.fromMap(Map<String, dynamic>.from(device))).toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to get USB devices: ${e.message}');
    }
  }

  static Future<bool> connectUsb(String deviceName) async {
    try {
      return await _channel.invokeMethod('connectUsb', {'deviceName': deviceName});
    } on PlatformException catch (e) {
      throw Exception('Failed to connect USB: ${e.message}');
    }
  }

  // Print method
  static Future<bool> printBytes(List<int> bytes) async {
    try {
      return await _channel.invokeMethod('print', {'bytes': bytes});
    } on PlatformException catch (e) {
      throw Exception('Failed to print: ${e.message}');
    }
  }

  // Connection status
  static Future<bool> isConnected() async {
    try {
      return await _channel.invokeMethod('isConnected');
    } on PlatformException catch (e) {
      throw Exception('Failed to check connection: ${e.message}');
    }
  }
}