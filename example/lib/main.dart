import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer_plus/commands/esc_pos_commands.dart';
import 'package:flutter_thermal_printer_plus/commands/print_builder.dart';
import 'package:flutter_thermal_printer_plus/flutter_thermal_printer_plus.dart';
import 'package:flutter_thermal_printer_plus/models/paper_size.dart';
import 'package:flutter_thermal_printer_plus/models/printer_info.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thermal Printer App',
      home: PrinterScreen(),
    );
  }
}

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  _PrinterScreenState createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  List<PrinterInfo> printers = [];
  bool isConnected = false;

  // Add this to track if the widget is still active
  bool _isWidgetActive = true;

  @override
  void initState() {
    super.initState();
    // Delay the connection check to ensure the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isWidgetActive) {
        checkConnectionStatus();
      }
    });
  }

  @override
  void dispose() {
    _isWidgetActive = false;
    super.dispose();
  }

  Future<void> checkConnectionStatus() async {
    try {
      final connected = await FlutterThermalPrinterPlus.isConnected();
      if (_isWidgetActive && mounted) {
        setState(() {
          isConnected = connected;
        });
      }
    } catch (e) {
      print('Error checking connection: $e');
    }
  }

  // Simplified permission request method
  Future<bool> requestBluetoothPermissions() async {
    try {
      // Request multiple permissions at once
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      // Check if all permissions are granted
      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (status != PermissionStatus.granted) {
          allGranted = false;
          print('Permission ${permission.toString()} denied');
        }
      });

      return allGranted;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Thermal Printer Plus Example'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Connection status
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: isConnected ? Colors.green : Colors.red,
            child: Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  isConnected ? 'Connected to Printer' : 'No Printer Connected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Scan buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: scanBluetooth,
                      icon: Icon(Icons.bluetooth),
                      label: Text('Scan Bluetooth'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: scanWifi,
                      icon: Icon(Icons.wifi),
                      label: Text('Scan WiFi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: getUsbDevices,
                  icon: Icon(Icons.usb),
                  label: Text('Get USB Devices'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Printer list
          Expanded(
            child: printers.isEmpty
                ? Center(
              child: Text(
                'No printers found.\nTap scan buttons to find printers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
                : ListView.builder(
              itemCount: printers.length,
              itemBuilder: (context, index) {
                final printer = printers[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: Icon(
                      printer.type == ConnectionType.bluetooth
                          ? Icons.bluetooth
                          : printer.type == ConnectionType.wifi
                          ? Icons.wifi
                          : Icons.usb,
                      color: Colors.blue,
                    ),
                    title: Text(
                      printer.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(printer.address),
                    trailing: ElevatedButton(
                      onPressed: () => connectToPrinter(printer),
                      child: Text('Connect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Test print buttons
          if (isConnected) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  Text(
                    'Test Print Options',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton(
                        onPressed: () => testPrint(PaperSize.mm58),
                        child: Text('58mm Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => testPrint(PaperSize.mm72),
                        child: Text('72mm Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => testPrint(PaperSize.mm80),
                        child: Text('80mm Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => testPrint(PaperSize.mm110),
                        child: Text('110mm Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: testAdvancedPrint,
                    icon: Icon(Icons.print),
                    label: Text('Advanced Receipt Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> scanBluetooth() async {
    try {
      safeShowMessage('Requesting permissions...');

      // Request permissions first
      bool hasPermissions = await requestBluetoothPermissions();
      if (!hasPermissions) {
        safeShowError('Bluetooth permissions required. Please grant permissions and try again.');
        return;
      }

      safeShowMessage('Scanning for Bluetooth devices...');
      final devices = await FlutterThermalPrinterPlus.scanBluetoothDevices();

      if (_isWidgetActive && mounted) {
        setState(() {
          printers = devices;
        });
        safeShowMessage('Found ${devices.length} Bluetooth devices');
      }
    } catch (e) {
      safeShowError('Bluetooth scan failed: $e');
    }
  }

  Future<void> scanWifi() async {
    try {
      safeShowMessage('Scanning for WiFi printers...');
      final devices = await FlutterThermalPrinterPlus.scanWifiPrinters();
      if (_isWidgetActive && mounted) {
        setState(() {
          printers = devices;
        });
        safeShowMessage('Found ${devices.length} WiFi printers');
      }
    } catch (e) {
      safeShowError('WiFi scan failed: $e');
    }
  }

  Future<void> getUsbDevices() async {
    try {
      safeShowMessage('Getting USB devices...');
      final devices = await FlutterThermalPrinterPlus.getUsbDevices();
      if (_isWidgetActive && mounted) {
        setState(() {
          printers = devices;
        });
        safeShowMessage('Found ${devices.length} USB devices');
      }
    } catch (e) {
      safeShowError('USB scan failed: $e');
    }
  }

  Future<void> connectToPrinter(PrinterInfo printer) async {
    try {
      safeShowMessage('Connecting to ${printer.name}...');
      bool success = false;

      switch (printer.type) {
        case ConnectionType.bluetooth:
          success = await FlutterThermalPrinterPlus.connectBluetooth(printer.address);
          break;
        case ConnectionType.wifi:
          success = await FlutterThermalPrinterPlus.connectWifi(printer.address, 9100);
          break;
        case ConnectionType.usb:
          success = await FlutterThermalPrinterPlus.connectUsb(printer.address);
          break;
      }

      if (_isWidgetActive && mounted) {
        if (success) {
          setState(() {
            isConnected = true;
          });
          safeShowMessage('Successfully connected to ${printer.name}');
        } else {
          safeShowError('Failed to connect to ${printer.name}');
        }
      }
    } catch (e) {
      safeShowError('Connection failed: $e');
    }
  }

  Future<void> testPrint(PaperSize paperSize) async {
    try {
      safeShowMessage('Printing ${paperSize.name} test...');

      final builder = PrintBuilder(PaperSize.mm80)
        ..text(
          'THERMAL PRINT DEMO',
          align: AlignPos.center,
          fontSize: FontSize.big,
          bold: true,
        )
        ..text(
          'Complete Feature Test',
          align: AlignPos.center,
          fontSize: FontSize.normal,
        )
        ..feed(1)
        ..line(char: '=')

      // Receipt details
        ..text('Receipt #: 2025091301', bold: true)
        ..text('Date: ${DateTime.now().toString().substring(0, 19)}')
        ..text('Cashier: John Doe')
        ..line()

      // Items table
        ..row(['Item', 'Qty', 'Price', 'Total'], [40, 15, 20, 25])
        ..line()
        ..row(['Coffee', '2', '\$3.50', '\$7.00'], [40, 15, 20, 25])
        ..row(['Sandwich', '1', '\$8.99', '\$8.99'], [40, 15, 20, 25])
        ..row(['Cookie', '3', '\$2.25', '\$6.75'], [40, 15, 20, 25])
        ..line()

      // Totals
        ..text('Subtotal: \$22.74', align: AlignPos.right)
        ..text('Tax (8.5%): \$1.93', align: AlignPos.right)
        ..text(
          'TOTAL: \$24.67',
          align: AlignPos.right,
          bold: true,
          fontSize: FontSize.big,
        )
        ..line(char: '=')

      // QR Code for digital receipt
        ..text('Digital Receipt:', align: AlignPos.center, bold: true)
        ..qrCode('https://receipt.example.com/2025091301', size: QRSize.size4)

      // Barcode for tracking
        ..text('Tracking Code:', align: AlignPos.center, bold: true)
        ..barcode128('2025091301',align: AlignPos.center)

        ..text(
          'Thank you for your purchase!',
          align: AlignPos.center,
          bold: true,
        )
        ..text(
          'Visit us again soon!',
          align: AlignPos.center,
        )
        ..feed(3)
        ..cut();
      final success = await FlutterThermalPrinterPlus.print(builder);

      if (_isWidgetActive && mounted) {
        if (success) {
          safeShowMessage('${paperSize.name} test print completed!');
        } else {
          safeShowError('Print failed');
        }
      }
    } catch (e) {
      safeShowError('Print error: $e');
    }
  }

  Future<void> testAdvancedPrint() async {
    try {
      safeShowMessage('Printing advanced receipt...');

      final builder = PrintBuilder(PaperSize.mm80) // Default to 80mm
        ..text(
          'RESTAURANT NAME',
          align: AlignPos.center,
          fontSize: FontSize.big,
          bold: true,
        )
        ..text(
          '123 Main Street',
          align: AlignPos.center,
        )
        ..text(
          'Phone: (555) 123-4567',
          align: AlignPos.center,
        )
        ..feed(1)
        ..line()
        ..text(
          'RECEIPT #12345',
          align: AlignPos.center,
          bold: true,
        )
        ..text(
          'Date: ${DateTime.now().toString().substring(0, 19)}',
          align: AlignPos.center,
        )
        ..line()
        ..row(['Item', 'Qty', 'Price', 'Total'], [40, 15, 20, 25])
        ..line()
        ..row(['Burger Deluxe', '2', '\$12.99', '\$25.98'], [40, 15, 20, 25])
        ..row(['French Fries', '2', '\$4.99', '\$9.98'], [40, 15, 20, 25])
        ..row(['Soft Drink', '2', '\$2.99', '\$5.98'], [40, 15, 20, 25])
        ..line()
        ..text(
          'Subtotal: \$41.94',
          align: AlignPos.right,
        )
        ..text(
          'Tax (8.5%): \$3.56',
          align: AlignPos.right,
        )
        ..text(
          'TOTAL: \$45.50',
          align: AlignPos.right,
          bold: true,
          fontSize: FontSize.big,
        )
        ..feed(2)
        ..line(char: '=')
        ..text(
          'Thank you for your visit!',
          align: AlignPos.center,
          bold: true,
        )
        ..text(
          'Please come again!',
          align: AlignPos.center,
        )
        ..feed(3)
        ..cut();

      final success = await FlutterThermalPrinterPlus.print(builder);

      if (_isWidgetActive && mounted) {
        if (success) {
          safeShowMessage('Advanced receipt printed successfully!');
        } else {
          safeShowError('Print failed');
        }
      }
    } catch (e) {
      safeShowError('Print error: $e');
    }
  }

  // Safe methods that check widget state before showing messages
  void safeShowMessage(String message) {
    print('Info: $message'); // Always log to console

    if (_isWidgetActive && mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        print('Failed to show message: $e');
      }
    }
  }

  void safeShowError(String error) {
    print('Error: $error'); // Always log to console

    if (_isWidgetActive && mounted) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        print('Failed to show error: $e');
      }
    }
  }
}