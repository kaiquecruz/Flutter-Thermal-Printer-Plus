import 'dart:typed_data';
import 'dart:ui' as ui;
import '../models/paper_size.dart';

class ESCPOSCommands {
  // Existing commands...
  static const List<int> init = [0x1B, 0x40]; // ESC @
  static const List<int> cutFull = [0x1D, 0x56, 0x00]; // GS V
  static const List<int> cutPartial = [0x1D, 0x56, 0x01]; // GS V

  // Alignment
  static const List<int> alignLeft = [0x1B, 0x61, 0x00]; // ESC a
  static const List<int> alignCenter = [0x1B, 0x61, 0x01]; // ESC a
  static const List<int> alignRight = [0x1B, 0x61, 0x02]; // ESC a

  // Font styling
  static const List<int> boldOn = [0x1B, 0x45, 0x01]; // ESC E
  static const List<int> boldOff = [0x1B, 0x45, 0x00]; // ESC E
  static const List<int> underlineOn = [0x1B, 0x2D, 0x01]; // ESC -
  static const List<int> underlineOff = [0x1B, 0x2D, 0x00]; // ESC -

  // Font sizes
  static const List<int> fontNormal = [0x1D, 0x21, 0x00]; // GS !
  static const List<int> fontCompressed = [0x1B, 0x4D, 0x01]; // ESC M
  static const List<int> fontDoubleWidth = [0x1D, 0x21, 0x20]; // GS !
  static const List<int> fontDoubleHeight = [0x1D, 0x21, 0x01]; // GS !
  static const List<int> fontBig = [0x1D, 0x21, 0x11]; // GS !

  // Paper width configuration
  static List<int> setPrintWidth(PaperSize paperSize) {
    switch (paperSize) {
      case PaperSize.mm58:
        return [0x1D, 0x57, 0x80, 0x01]; // 384 dots
      case PaperSize.mm72:
        return [0x1D, 0x57, 0x00, 0x02]; // 512 dots
      case PaperSize.mm80:
        return [0x1D, 0x57, 0x40, 0x02]; // 576 dots
      case PaperSize.mm110:
        return [0x1D, 0x57, 0x40, 0x03]; // 832 dots
    }
  }

  static List<int> setLeftMargin(int margin) {
    return [0x1D, 0x4C, margin & 0xFF, (margin >> 8) & 0xFF]; // GS L
  }

  static List<int> feedLines(int lines) {
    return [0x1B, 0x64, lines]; // ESC d
  }

  // ========== NEW: IMAGE COMMANDS ==========

  /// Print raster image using GS v 0 command
  static List<int> printRasterImage(Uint8List imageData, int width, int height) {
    List<int> command = [];

    // GS v 0 - Print raster bit image
    command.addAll([0x1D, 0x76, 0x30, 0x00]); // GS v 0 m

    // Add width (in bytes)
    int widthBytes = (width + 7) ~/ 8;
    command.addAll([widthBytes & 0xFF, (widthBytes >> 8) & 0xFF]); // xL xH

    // Add height
    command.addAll([height & 0xFF, (height >> 8) & 0xFF]); // yL yH

    // Add image data
    command.addAll(imageData);

    return command;
  }

  /// Print image using ESC * command (column format)
  static List<int> printColumnImage(Uint8List imageData, int width, int height) {
    List<int> command = [];

    // Set line spacing to 0
    command.addAll([0x1B, 0x33, 0x00]); // ESC 3 n

    // ESC * - Select bit-image mode
    command.addAll([0x1B, 0x2A]); // ESC *
    command.add(0x21); // m = 33 (24-dot double-density)

    // Width in dots
    command.addAll([width & 0xFF, (width >> 8) & 0xFF]); // nL nH

    // Image data
    command.addAll(imageData);

    // Line feed
    command.add(0x0A);

    // Reset line spacing
    command.addAll([0x1B, 0x32]); // ESC 2

    return command;
  }

  // ========== NEW: BARCODE COMMANDS ==========

  /// Set barcode height
  static List<int> setBarcodeHeight(int height) {
    return [0x1D, 0x68, height]; // GS h n
  }

  /// Set barcode width
  static List<int> setBarcodeWidth(int width) {
    return [0x1D, 0x77, width]; // GS w n
  }

  /// Set HRI (Human Readable Interpretation) position
  static List<int> setHRIPosition(HRIPosition position) {
    return [0x1D, 0x48, position.value]; // GS H n
  }

  /// Set HRI font
  static List<int> setHRIFont(HRIFont font) {
    return [0x1D, 0x66, font.value]; // GS f n
  }

  /// Print Code 128 barcode
  static List<int> printCode128(String data) {
    List<int> command = [];
    List<int> dataBytes = data.codeUnits;

    // GS k - Print barcode
    command.addAll([0x1D, 0x6B]); // GS k
    command.add(0x49); // m = 73 (Code 128)
    command.add(dataBytes.length); // Length
    command.addAll(dataBytes); // Data

    return command;
  }

  /// Print Code 39 barcode
  static List<int> printCode39(String data) {
    List<int> command = [];
    List<int> dataBytes = data.codeUnits;

    // GS k - Print barcode
    command.addAll([0x1D, 0x6B]); // GS k
    command.add(0x04); // m = 4 (Code 39)
    command.addAll(dataBytes); // Data
    command.add(0x00); // NUL terminator

    return command;
  }

  /// Print EAN13 barcode
  static List<int> printEAN13(String data) {
    List<int> command = [];
    List<int> dataBytes = data.codeUnits;

    // GS k - Print barcode
    command.addAll([0x1D, 0x6B]); // GS k
    command.add(0x02); // m = 2 (EAN13)
    command.addAll(dataBytes); // Data (12 digits, checksum calculated automatically)

    return command;
  }

  // ========== NEW: QR CODE COMMANDS ==========

  /// Print QR code
  static List<int> printQRCode(String data, {QRSize size = QRSize.size4, QRCorrection correction = QRCorrection.M}) {
    List<int> command = [];
    List<int> dataBytes = data.codeUnits;

    // GS ( k - QR code commands
    const List<int> qrHeader = [0x1D, 0x28, 0x6B]; // GS ( k

    // Function 165: Set QR code model
    command.addAll(qrHeader);
    command.addAll([0x04, 0x00]); // pL pH
    command.addAll([0x31, 0x41]); // cn fn
    command.addAll([0x32, 0x00]); // n1 n2 (Model 2)

    // Function 167: Set module size
    command.addAll(qrHeader);
    command.addAll([0x03, 0x00]); // pL pH
    command.addAll([0x31, 0x43]); // cn fn
    command.add(size.value); // n

    // Function 169: Set error correction level
    command.addAll(qrHeader);
    command.addAll([0x03, 0x00]); // pL pH
    command.addAll([0x31, 0x45]); // cn fn
    command.add(correction.value); // n

    // Function 180: Store data
    command.addAll(qrHeader);
    int dataLength = dataBytes.length + 3;
    command.addAll([dataLength & 0xFF, (dataLength >> 8) & 0xFF]); // pL pH
    command.addAll([0x31, 0x50]); // cn fn
    command.add(0x30); // m
    command.addAll(dataBytes); // Data

    // Function 181: Print QR code
    command.addAll(qrHeader);
    command.addAll([0x03, 0x00]); // pL pH
    command.addAll([0x31, 0x51]); // cn fn
    command.add(0x30); // m

    return command;
  }

  // ========== HELPER FUNCTIONS ==========

  /// Convert image to 1-bit black and white
  static Uint8List convertImageToMonochrome(ui.Image image) {
    // This would be implemented with proper image processing
    // For now, return empty data - will be implemented in the image processing section
    return Uint8List(0);
  }

  /// Pack bits into bytes for thermal printer format
  static Uint8List packBitsIntoBytes(List<int> bits) {
    List<int> bytes = [];

    for (int i = 0; i < bits.length; i += 8) {
      int byte = 0;
      for (int j = 0; j < 8 && i + j < bits.length; j++) {
        if (bits[i + j] == 1) {
          byte |= (1 << (7 - j));
        }
      }
      bytes.add(byte);
    }

    return Uint8List.fromList(bytes);
  }
}

// ========== NEW: ENUMS FOR BARCODE AND QR CODE ==========

enum BarcodeType { code128, code39, ean13, ean8, upca, upce }

enum HRIPosition {
  none(0),
  above(1),
  below(2),
  both(3);

  const HRIPosition(this.value);
  final int value;
}

enum HRIFont {
  fontA(0),
  fontB(1);

  const HRIFont(this.value);
  final int value;
}

enum QRSize {
  size1(1),
  size2(2),
  size3(3),
  size4(4),
  size5(5),
  size6(6),
  size7(7),
  size8(8);

  const QRSize(this.value);
  final int value;
}

enum QRCorrection {
  L(48), // ~7% correction
  M(49), // ~15% correction
  Q(50), // ~25% correction
  H(51); // ~30% correction

  const QRCorrection(this.value);
  final int value;
}