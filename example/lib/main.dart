import 'package:flutter/foundation.dart';
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

  bool isScanning = false; //Track scanning state
  String scanStatus = 'Not scanning'; //  Scan status display

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

  //  Check scanning status
  Future<void> checkScanningStatus() async {
    try {
      final scanning = await FlutterThermalPrinterPlus.isScanning();
      setState(() {
        isScanning = scanning;
        scanStatus = scanning ? 'Scanning...' : 'Not scanning';
      });
    } catch (e) {
      print('Error checking scanning status: $e');
    }
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
        actions: [
          // NEW: Stop scanning button
          if (isScanning)
            IconButton(
              onPressed: stopAllScanning,
              icon: Icon(Icons.stop_circle),
              tooltip: 'Stop Scanning',
            ),
        ],
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
                    onPressed: exampleReceiptWithCustomAlignment,
                    // onPressed: exampleTableWithMixedAlignment,
                    // onPressed: exampleInventoryReport,
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
      setState(() {
        isScanning = true;
        scanStatus = 'Scanning Bluetooth devices...';
      });
// Request permissions first
      bool hasPermissions = await requestBluetoothPermissions();
      if (!hasPermissions) {
        safeShowError('Bluetooth permissions required. Please grant permissions and try again.');
        return;
      }

      safeShowMessage('Scanning for Bluetooth devices...');
      final devices = await FlutterThermalPrinterPlus.scanBluetoothDevices();

      setState(() {
        printers = devices;
        isScanning = false;
        scanStatus = 'Bluetooth scan completed';
      });

      safeShowMessage('Found ${devices.length} Bluetooth devices');

      // Reset scan status after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            scanStatus = 'Not scanning';
          });
        }
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        scanStatus = 'Bluetooth scan failed';
      });
      safeShowError('Bluetooth scan failed: $e');
    }
  }

  Future<void> scanWifi() async {
    try {
      setState(() {
        isScanning = true;
        scanStatus = 'Scanning WiFi printers...';
      });

      safeShowMessage('Scanning for WiFi printers...');
      final devices = await FlutterThermalPrinterPlus.scanWifiPrinters();

      setState(() {
        printers = devices;
        isScanning = false;
        scanStatus = 'WiFi scan completed';
      });

      safeShowMessage('Found ${devices.length} WiFi printers');

      // Reset scan status after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            scanStatus = 'Not scanning';
          });
        }
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        scanStatus = 'WiFi scan failed';
      });
      safeShowError('WiFi scan failed: $e');
    }
  }

  Future<void> getUsbDevices() async {
    try {
      safeShowMessage('Getting USB devices...');
      final devices = await FlutterThermalPrinterPlus.getUsbDevices();
      setState(() {
        printers = devices;
      });
      safeShowMessage('Found ${devices.length} USB devices');
    } catch (e) {
      safeShowError('USB scan failed: $e');
    }
  }

  // NEW: Stop all scanning method
  Future<void> stopAllScanning() async {
    try {
      safeShowMessage('Stopping all scanning...');
      final stopped = await FlutterThermalPrinterPlus.stopAllScanning();

      setState(() {
        isScanning = false;
        scanStatus = stopped ? 'Scanning stopped' : 'Failed to stop scanning';
      });

      if (stopped) {
        safeShowMessage('All scanning stopped successfully');
      } else {
        safeShowError('Failed to stop some scanning operations');
      }

      // Reset scan status after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            scanStatus = 'Not scanning';
          });
        }
      });
    } catch (e) {
      setState(() {
        isScanning = false;
        scanStatus = 'Stop scanning failed';
      });
      safeShowError('Stop scanning failed: $e');
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

  Future<void> exampleReceiptWithCustomAlignment() async{
    final builder = PrintBuilder(PaperSize.mm110)

    // Title
      ..text(
        'MULTI-LINE ROW TEST',
        align: AlignPos.center,
        fontSize: FontSize.big,
        bold: true,
      )
      ..feed(1)
      ..line()

    // Test 1: Basic multi-line in first column
      ..text('1. Multi-line Product Names:', bold: true)
      ..row(
        ['Product', 'Qty', 'Price', 'Total'],
        [45, 15, 20, 20],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right, ColumnAlign.right],
      )
      ..line(char: '-')
      ..row(
        ['Coffee Premium\nWith Extra Foam\nFair Trade', '2', '\$4.50', '\$9.00'],
        [45, 15, 20, 20],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right, ColumnAlign.right],
      )
      ..row(
        ['Tea Green\nOrganic', '1', '\$3.25', '\$3.25'],
        [45, 15, 20, 20],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right, ColumnAlign.right],
      )
      ..feed(1)

    // Test 2: Multi-line in multiple columns
      ..text('2. Multi-line in Multiple Columns:', bold: true)
      ..row(
        ['Description', 'Details', 'Price'],
        [40, 35, 25],
        aligns: [ColumnAlign.left, ColumnAlign.left, ColumnAlign.right],
      )
      ..line(char: '-')
      ..row(
        ['Sandwich\nTurkey Club', 'Fresh bread\nLettuce & tomato\nExtra mayo', '\$12.99'],
        [40, 35, 25],
        aligns: [ColumnAlign.left, ColumnAlign.left, ColumnAlign.right],
      )
      ..feed(1)

    // Test 3: Different alignments with multi-line
      ..text('3. Multi-line with Different Alignments:', bold: true)
      ..row(
        ['Item (Left)', 'Status (Center)', 'Amount (Right)'],
        [33, 34, 33],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right],
      )
      ..line(char: '-')
      ..row(
        ['Premium Service Package Product Name That Will Wrap', 'Active\n&\nRunning', '\$299.99 permonth'],
        [33, 34, 33],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right],
      )
      ..feed(1)

    // Test 4: Advanced row with wrapping control
      ..text('4. Advanced Multi-line Control:', bold: true)
      ..row(
        ['Long Product Name That Will Wrap Product Name That Will Wrap', '34','Short\nMulti\nLine', '\$15.99'],
        [45, 15, 20, 20],
        aligns: [ColumnAlign.left,ColumnAlign.center, ColumnAlign.center, ColumnAlign.right],
        wrapColumns: [false, false,false, false], // Only first column wraps
      )
      ..feed(1)

    // Test 5: Receipt with multi-line items
      ..text('5. Real Receipt Example:', bold: true)
      ..line(char: '=')
      ..row(
        ['Item', 'Qty', 'Price', 'Total'],
        [45, 15, 20, 20],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right, ColumnAlign.right],
      )
      ..line()
      ..row(
        ['Americano\nDouble Shot\nExtra Hot', '2', '\$3.50', '\$7.00'],
        [45, 15, 20, 20],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right, ColumnAlign.right],
      )
      ..row(
        ['Croissant\nButter & Jam', '1', '\$4.25', '\$4.25'],
        [45, 15, 20, 20],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right, ColumnAlign.right],
      )
      ..row(
        ['Muffin Blueberry\nFresh Baked\nGluten Free', '1', '\$5.99', '\$5.99'],
        [45, 15, 20, 20],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right, ColumnAlign.right],
      )
      ..line()
      ..row(
        ['', '', 'TOTAL:', '\$17.24'],
        [45, 15, 20, 20],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right, ColumnAlign.right],
        fontSize: FontSize.big,
      )
      ..line(char: '=')

      ..feed(3)
      ..cut();

    final success = await FlutterThermalPrinterPlus.print(builder);
    if (_isWidgetActive && mounted) {
      if (success) {
        safeShowMessage('test print completed!');
      } else {
        safeShowError('Print failed');
      }
    }
  }

// ========== MORE EXAMPLES ==========

  Future<void> exampleTableWithMixedAlignment() async{
    final builder = PrintBuilder(PaperSize.mm110) // Using 110mm for more space

    // Centered header
      ..text('EMPLOYEE TIMESHEET', align: AlignPos.center, fontSize: FontSize.big, bold: true)
      ..feed(1)
      ..line()

    // Table header with mixed alignment
      ..row(
        ['Employee Name', 'ID', 'Hours', 'Rate', 'Total'],
        [35, 15, 15, 15, 20],
        aligns: [
          ColumnAlign.left,    // Name - left aligned
          ColumnAlign.center,  // ID - centered
          ColumnAlign.right,   // Hours - right aligned
          ColumnAlign.right,   // Rate - right aligned
          ColumnAlign.right,   // Total - right aligned
        ],
        fontSize: FontSize.normal,
      )
      ..line()

    // Data rows
      ..row(
        ['John Smith', 'E001', '40.0', '\$25.00', '\$1,000.00'],
        [35, 15, 15, 15, 20],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right, ColumnAlign.right, ColumnAlign.right],
      )
      ..row(
        ['Jane Doe', 'E002', '35.5', '\$30.00', '\$1,065.00'],
        [35, 15, 15, 15, 20],
        aligns: [ColumnAlign.left, ColumnAlign.center, ColumnAlign.right, ColumnAlign.right, ColumnAlign.right],
      )

      ..line()
      ..cut();
    final success = await FlutterThermalPrinterPlus.print(builder);

  }

  Future<void> exampleInventoryReport()async {
    final builder = PrintBuilder(PaperSize.mm110)

    // Header
      ..text('INVENTORY REPORT', align: AlignPos.center, fontSize: FontSize.big, bold: true)
      ..text('Generated: ${DateTime.now().toString().substring(0, 16)}', align: AlignPos.center)
      ..feed(1)
      ..line()


    // Column headers with specific alignment
      ..row(
        ['Product', 'Stock', 'Status'],
        [50, 25, 25],
        aligns: [ColumnAlign.left, ColumnAlign.right, ColumnAlign.center],
        fontSize: FontSize.normal,
      )
      ..line()

    // Data with status centered, stock right-aligned
      ..row(
        ['Coffee Beans Premium', '150', 'OK'],
        [50, 25, 25],
        aligns: [ColumnAlign.left, ColumnAlign.right, ColumnAlign.center],
      )
      ..row(
        ['Paper Cups Large', '25', 'LOW'],
        [50, 25, 25],
        aligns: [ColumnAlign.left, ColumnAlign.right, ColumnAlign.center],
      )
      ..row(
        ['Sugar Packets', '500', 'OK'],
        [50, 25, 25],
        aligns: [ColumnAlign.left, ColumnAlign.right, ColumnAlign.center],
      )

      ..feed(2)
      ..cut();
    final success = await FlutterThermalPrinterPlus.print(builder);
    if (_isWidgetActive && mounted) {
      if (success) {
        safeShowMessage('test print completed!');
      } else {
        safeShowError('Print failed');
      }
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


  // Safe methods that check widget state before showing messages
  void safeShowMessage(String message) {
    if (kDebugMode) {
      print('Info: $message');
    } // Always log to console

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
        if (kDebugMode) {
          print('Failed to show message: $e');
        }
      }
    }
  }

  void safeShowError(String error) {
    if (kDebugMode) {
      print('Error: $error');
    } // Always log to console

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
        if (kDebugMode) {
          print('Failed to show error: $e');
        }
      }
    }
  }
}