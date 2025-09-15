import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_thermal_printer_plus/flutter_thermal_printer_plus.dart';
import 'package:flutter_thermal_printer_plus/flutter_thermal_printer_plus_platform_interface.dart';
import 'package:flutter_thermal_printer_plus/flutter_thermal_printer_plus_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterThermalPrinterPlatform
    with MockPlatformInterfaceMixin
    implements FlutterThermalPrinterPlusPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterThermalPrinterPlusPlatform initialPlatform = FlutterThermalPrinterPlusPlatform.instance;

  test('$MethodChannelFlutterThermalPrinterPlus is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterThermalPrinterPlus>());
  });

  test('getPlatformVersion', () async {
    FlutterThermalPrinterPlus flutterThermalPrinterPlugin = FlutterThermalPrinterPlus();
    MockFlutterThermalPrinterPlatform fakePlatform = MockFlutterThermalPrinterPlatform();
    FlutterThermalPrinterPlusPlatform.instance = fakePlatform;

    // expect(await flutterThermalPrinterPlugin.getPlatformVersion(), '42');
  });
}