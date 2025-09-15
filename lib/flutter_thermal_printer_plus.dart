library;


import 'package:flutter_thermal_printer_plus/platform/thermal_printer_platform.dart';

import 'commands/print_builder.dart';
import 'models/printer_info.dart';

class FlutterThermalPrinterPlus {
  // Bluetooth operations
  static Future<List<PrinterInfo>> scanBluetoothDevices() {
    return ThermalPrinterPlatform.scanBluetoothDevices();
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
}