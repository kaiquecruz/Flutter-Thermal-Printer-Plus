import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_thermal_printer_plus_method_channel.dart';

abstract class FlutterThermalPrinterPlusPlatform extends PlatformInterface {
  /// Constructs a FlutterThermalPrinterPlatform.
  FlutterThermalPrinterPlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterThermalPrinterPlusPlatform _instance = MethodChannelFlutterThermalPrinterPlus();

  /// The default instance of [FlutterThermalPrinterPlusPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterThermalPrinterPlus].
  static FlutterThermalPrinterPlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterThermalPrinterPlusPlatform] when
  /// they register themselves.
  static set instance(FlutterThermalPrinterPlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}