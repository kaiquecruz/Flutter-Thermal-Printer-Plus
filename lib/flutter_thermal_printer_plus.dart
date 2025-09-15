library;

import 'package:flutter_thermal_printer_plus/platform/thermal_printer_platform.dart';

import 'commands/print_builder.dart';
import 'models/printer_info.dart';

class FlutterThermalPrinterPlus {
  // Bluetooth operations
  static Future<List<PrinterInfo>> scanBluetoothDevices() {
    return ThermalPrinterPlatform.scanBluetoothDevices();
  }

  // Stop Bluetooth scanning
  static Future<bool> stopBluetoothScan() {
    return ThermalPrinterPlatform.stopBluetoothScan();
  }

  static Future<bool> connectBluetooth(String address) {
    return ThermalPrinterPlatform.connectBluetooth(address);
  }

  static Future<bool> disconnectBluetooth() {
    return ThermalPrinterPlatform.disconnectBluetooth();
  }

  // WiFi operations
  static Future<List<PrinterInfo>> scanWifiPrinters() {
    return ThermalPrinterPlatform.scanWifiPrinters();
  }

  // Stop WiFi scanning
  static Future<bool> stopWifiScan() {
    return ThermalPrinterPlatform.stopWifiScan();
  }

  static Future<bool> connectWifi(String ip, int port) {
    return ThermalPrinterPlatform.connectWifi(ip, port);
  }

  static Future<bool> disconnectWifi() {
    return ThermalPrinterPlatform.disconnectWifi();
  }

  // USB operations
  static Future<List<PrinterInfo>> getUsbDevices() {
    return ThermalPrinterPlatform.getUsbDevices();
  }

  static Future<bool> connectUsb(String deviceName) {
    return ThermalPrinterPlatform.connectUsb(deviceName);
  }

  // Print operations
  static Future<bool> print(PrintBuilder builder) {
    return ThermalPrinterPlatform.printBytes(builder.build().toList());
  }

  static Future<bool> isConnected() {
    return ThermalPrinterPlatform.isConnected();
  }

  // Scanning status and control
  static Future<bool> isScanning() {
    return ThermalPrinterPlatform.isScanning();
  }

  // Stop all scanning
  static Future<bool> stopAllScanning() {
    return ThermalPrinterPlatform.stopAllScanning();
  }
}