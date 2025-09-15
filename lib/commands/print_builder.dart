import 'dart:convert';
import 'dart:typed_data';
import '../models/paper_size.dart';
import 'esc_pos_commands.dart';
import 'image_processor.dart';
import 'package:image/image.dart' as img;
class PrintBuilder {
  final PaperSize paperSize;
  final List<int> _bytes = [];

  PrintBuilder(this.paperSize) {
    _initialize();
  }

  void _initialize() {
    _bytes.addAll(ESCPOSCommands.init);
    _bytes.addAll(ESCPOSCommands.setPrintWidth(paperSize));
    _bytes.addAll(ESCPOSCommands.setLeftMargin(0));
  }

  // ========== EXISTING TEXT METHODS ==========

  PrintBuilder text(
      String text, {
        AlignPos align = AlignPos.left,
        FontSize fontSize = FontSize.normal,
        bool bold = false,
        bool underline = false,
      }) {
    // Set alignment
    switch (align) {
      case AlignPos.left:
        _bytes.addAll(ESCPOSCommands.alignLeft);
        break;
      case AlignPos.center:
        _bytes.addAll(ESCPOSCommands.alignCenter);
        break;
      case AlignPos.right:
        _bytes.addAll(ESCPOSCommands.alignRight);
        break;
    }

    // Set font size
    switch (fontSize) {
      case FontSize.normal:
        _bytes.addAll(ESCPOSCommands.fontNormal);
        break;
      case FontSize.compressed:
        _bytes.addAll(ESCPOSCommands.fontCompressed);
        break;
      case FontSize.doubleWidth:
        _bytes.addAll(ESCPOSCommands.fontDoubleWidth);
        break;
      case FontSize.doubleHeight:
        _bytes.addAll(ESCPOSCommands.fontDoubleHeight);
        break;
      case FontSize.big:
        _bytes.addAll(ESCPOSCommands.fontBig);
        break;
    }

    // Set styling
    if (bold) _bytes.addAll(ESCPOSCommands.boldOn);
    if (underline) _bytes.addAll(ESCPOSCommands.underlineOn);

    // Add text
    _bytes.addAll(utf8.encode(text));
    _bytes.add(0x0A); // Line feed

    // Reset styling
    if (bold) _bytes.addAll(ESCPOSCommands.boldOff);
    if (underline) _bytes.addAll(ESCPOSCommands.underlineOff);

    return this;
  }

  PrintBuilder row(List<String> columns, List<int> widths, {FontSize fontSize = FontSize.normal}) {
    if (columns.length != widths.length) {
      throw ArgumentError('Columns and widths must have the same length');
    }

    int totalWidth = widths.fold(0, (sum, width) => sum + width);
    if (totalWidth != 100) {
      throw ArgumentError('Total width must equal 100%');
    }

    int maxChars = paperSize.getMaxChars(fontSize);
    String line = '';

    for (int i = 0; i < columns.length; i++) {
      int colWidth = (maxChars * widths[i] / 100).floor();
      String column = columns[i];

      if (column.length > colWidth) {
        column = '${column.substring(0, colWidth - 2)}..';
      } else {
        column = column.padRight(colWidth);
      }
      line += column;
    }

    return text(line, fontSize: fontSize);
  }

  PrintBuilder line({String char = '-', FontSize fontSize = FontSize.normal}) {
    int maxChars = paperSize.getMaxChars(fontSize);
    String lineStr = char * maxChars;
    return text(lineStr, fontSize: fontSize);
  }

  PrintBuilder feed(int lines) {
    _bytes.addAll(ESCPOSCommands.feedLines(lines));
    return this;
  }

  PrintBuilder cut({bool partial = false}) {
    _bytes.addAll(ESCPOSCommands.feedLines(5));
    _bytes.addAll(partial ? ESCPOSCommands.cutPartial : ESCPOSCommands.cutFull);
    return this;
  }

  // ========== NEW: IMAGE METHODS ==========

  /// Print image from bytes
  PrintBuilder imageFromBytes(
      Uint8List imageBytes, {
        AlignPos align = AlignPos.center,
        int? maxWidth,
      }) {
    // Set alignment
    switch (align) {
      case AlignPos.left:
        _bytes.addAll(ESCPOSCommands.alignLeft);
        break;
      case AlignPos.center:
        _bytes.addAll(ESCPOSCommands.alignCenter);
        break;
      case AlignPos.right:
        _bytes.addAll(ESCPOSCommands.alignRight);
        break;
    }

    // Process image and add to bytes
    final processedImage = ImageProcessor.processImageForPrinting(
      imageBytes,
      paperSize: paperSize,
      maxWidth: maxWidth,
    );

    _bytes.addAll(processedImage);

    // Reset alignment
    _bytes.addAll(ESCPOSCommands.alignLeft);

    return this;
  }

  /// Print image from UI Image
  PrintBuilder imageFromUIImage(
      img.Image image, {
        AlignPos align = AlignPos.center,
        int? maxWidth,
      }) {
    // Convert UI Image to bytes and process
    final imageBytes = ImageProcessor.convertUIImageToBytes(image);
    return imageFromBytes(imageBytes, align: align, maxWidth: maxWidth);
  }
  void addRawBytes(List<int> bytes) {
    _bytes.addAll(bytes);
  }
  // ========== NEW: BARCODE METHODS ==========

  /// Print Code 128 barcode
  PrintBuilder barcode128(
      String data, {
        AlignPos align = AlignPos.center,
        int height = 162,
        int width = 2,
        HRIPosition hriPosition = HRIPosition.below,
        HRIFont hriFont = HRIFont.fontA,
      }) {
    // Set alignment
    switch (align) {
      case AlignPos.left:
        _bytes.addAll(ESCPOSCommands.alignLeft);
        break;
      case AlignPos.center:
        _bytes.addAll(ESCPOSCommands.alignCenter);
        break;
      case AlignPos.right:
        _bytes.addAll(ESCPOSCommands.alignRight);
        break;
    }

    // Set barcode parameters
    _bytes.addAll(ESCPOSCommands.setBarcodeHeight(height));
    _bytes.addAll(ESCPOSCommands.setBarcodeWidth(width));
    _bytes.addAll(ESCPOSCommands.setHRIPosition(hriPosition));
    _bytes.addAll(ESCPOSCommands.setHRIFont(hriFont));

    // Print barcode
    _bytes.addAll(ESCPOSCommands.printCode128(data));

    // Reset alignment
    _bytes.addAll(ESCPOSCommands.alignLeft);

    return this;
  }

  /// Print Code 39 barcode
  PrintBuilder barcode39(
      String data, {
        AlignPos align = AlignPos.center,
        int height = 162,
        int width = 2,
        HRIPosition hriPosition = HRIPosition.below,
        HRIFont hriFont = HRIFont.fontA,
      }) {
    // Set alignment
    switch (align) {
      case AlignPos.left:
        _bytes.addAll(ESCPOSCommands.alignLeft);
        break;
      case AlignPos.center:
        _bytes.addAll(ESCPOSCommands.alignCenter);
        break;
      case AlignPos.right:
        _bytes.addAll(ESCPOSCommands.alignRight);
        break;
    }

    // Set barcode parameters
    _bytes.addAll(ESCPOSCommands.setBarcodeHeight(height));
    _bytes.addAll(ESCPOSCommands.setBarcodeWidth(width));
    _bytes.addAll(ESCPOSCommands.setHRIPosition(hriPosition));
    _bytes.addAll(ESCPOSCommands.setHRIFont(hriFont));

    // Print barcode
    _bytes.addAll(ESCPOSCommands.printCode39(data));

    // Reset alignment
    _bytes.addAll(ESCPOSCommands.alignLeft);

    return this;
  }

  /// Print EAN13 barcode
  PrintBuilder barcodeEAN13(
      String data, {
        AlignPos align = AlignPos.center,
        int height = 162,
        int width = 2,
        HRIPosition hriPosition = HRIPosition.below,
        HRIFont hriFont = HRIFont.fontA,
      }) {
    if (data.length != 12) {
      throw ArgumentError('EAN13 data must be exactly 12 digits');
    }

    // Set alignment
    switch (align) {
      case AlignPos.left:
        _bytes.addAll(ESCPOSCommands.alignLeft);
        break;
      case AlignPos.center:
        _bytes.addAll(ESCPOSCommands.alignCenter);
        break;
      case AlignPos.right:
        _bytes.addAll(ESCPOSCommands.alignRight);
        break;
    }

    // Set barcode parameters
    _bytes.addAll(ESCPOSCommands.setBarcodeHeight(height));
    _bytes.addAll(ESCPOSCommands.setBarcodeWidth(width));
    _bytes.addAll(ESCPOSCommands.setHRIPosition(hriPosition));
    _bytes.addAll(ESCPOSCommands.setHRIFont(hriFont));

    // Print barcode
    _bytes.addAll(ESCPOSCommands.printEAN13(data));

    // Reset alignment
    _bytes.addAll(ESCPOSCommands.alignLeft);

    return this;
  }

  // ========== NEW: QR CODE METHODS ==========

  /// Print QR code
  PrintBuilder qrCode(
      String data, {
        AlignPos align = AlignPos.center,
        QRSize size = QRSize.size4,
        QRCorrection correction = QRCorrection.M,
      }) {
    // Set alignment
    switch (align) {
      case AlignPos.left:
        _bytes.addAll(ESCPOSCommands.alignLeft);
        break;
      case AlignPos.center:
        _bytes.addAll(ESCPOSCommands.alignCenter);
        break;
      case AlignPos.right:
        _bytes.addAll(ESCPOSCommands.alignRight);
        break;
    }

    // Print QR code
    _bytes.addAll(ESCPOSCommands.printQRCode(data, size: size, correction: correction));

    // Reset alignment
    _bytes.addAll(ESCPOSCommands.alignLeft);

    return this;
  }

  PrintBuilder rowRightAligned(List<String> columns, List<int> widths, {FontSize fontSize = FontSize.normal}) {
    if (columns.length != widths.length) {
      throw ArgumentError('Columns and widths must have the same length');
    }

    int totalWidth = widths.fold(0, (sum, width) => sum + width);
    if (totalWidth != 100) {
      throw ArgumentError('Total width must equal 100%');
    }

    int maxChars = paperSize.getMaxChars(fontSize);
    String line = '';

    for (int i = 0; i < columns.length; i++) {
      int colWidth = (maxChars * widths[i] / 100).floor();
      String column = columns[i];

      if (column.length > colWidth) {
        column = '${column.substring(0, colWidth - 2)}..';
      }

      // Right-align the last column, others as specified
      if (i == columns.length - 1) {
        // Last column - right align
        column = column.padLeft(colWidth);
      } else {
        // Other columns - left align but with proper spacing
        column = column.padRight(colWidth);
      }

      line += column;
    }

    return text(line, fontSize: fontSize);
  }

  /// Enhanced text method with default right alignment option
  PrintBuilder textRightAligned(
      String text, {
        AlignPos align = AlignPos.right, // Default to right
        FontSize fontSize = FontSize.normal,
        bool bold = false,
        bool underline = false,
      }) {
    return this.text(text, align: align, fontSize: fontSize, bold: bold, underline: underline);
  }

  Uint8List build() {
    return Uint8List.fromList(_bytes);
  }
}