import 'package:flutter_thermal_printer_plus/models/paper_size.dart';

class PrinterInfo {
  final String name;
  final String address;
  final ConnectionType type;
  final bool isConnected;

  PrinterInfo({
    required this.name,
    required this.address,
    required this.type,
    this.isConnected = false,
  });

  factory PrinterInfo.fromMap(Map<String, dynamic> map) {
    return PrinterInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      type: ConnectionType.values[map['type'] ?? 0],
      isConnected: map['isConnected'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'type': type.index,
      'isConnected': isConnected,
    };
  }
}