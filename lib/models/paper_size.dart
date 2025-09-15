enum PaperSize {
  mm58(width: 384, maxChars: 32, maxCharsCompressed: 42),
  mm72(width: 512, maxChars: 42, maxCharsCompressed: 56),
  mm80(width: 576, maxChars: 48, maxCharsCompressed: 64),
  mm110(width: 832, maxChars: 69, maxCharsCompressed: 92);

  const PaperSize({
    required this.width,
    required this.maxChars,
    required this.maxCharsCompressed,
  });

  final int width;
  final int maxChars;
  final int maxCharsCompressed;

  int getMaxChars(FontSize fontSize) {
    switch (fontSize) {
      case FontSize.compressed:
        return maxCharsCompressed;
      case FontSize.normal:
        return maxChars;
      case FontSize.doubleWidth:
        return maxChars ~/ 2;
      case FontSize.big:
        return maxChars ~/ 2;
      default:
        return maxChars;
    }
  }
}

enum FontSize { normal, compressed, doubleWidth, doubleHeight, big }
enum AlignPos { left, center, right }
enum ConnectionType { bluetooth, wifi, usb }