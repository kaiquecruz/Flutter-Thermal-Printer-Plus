import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_thermal_printer_plus_platform_interface.dart';

/// An implementation of [FlutterThermalPrinterPlusPlatform] that uses method channels.
class MethodChannelFlutterThermalPrinterPlus extends FlutterThermalPrinterPlusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_thermal_printer_plus');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}