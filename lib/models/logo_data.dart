import 'dart:typed_data';

/// Model to hold processed logo data ready for printing
class LogoData {
  final Uint8List imageData; // Processed image data (optimized for thermal printing)
  final int width; // Width in dots/pixels
  final int height; // Height in dots/pixels
  final String format; // Image format (BMP, PCX, etc.)
  final double widthMm; // Physical width in millimeters
  final double heightMm; // Physical height in millimeters
  final DateTime processedAt; // When the logo was processed

  LogoData({
    required this.imageData,
    required this.width,
    required this.height,
    required this.format,
    required this.widthMm,
    required this.heightMm,
    DateTime? processedAt,
  }) : processedAt = processedAt ?? DateTime.now();

  // Calculate DPI based on physical size and pixel dimensions
  double get dpiX => (width / widthMm) * 25.4; // Convert mm to inches
  double get dpiY => (height / heightMm) * 25.4;

  // Get aspect ratio
  double get aspectRatio => width / height;

  // Check if the logo data is valid
  bool get isValid => imageData.isNotEmpty && width > 0 && height > 0;

  // Get file size in bytes
  int get fileSizeBytes => imageData.length;

  // Get file size in a human-readable format
  String get fileSizeFormatted {
    const suffixes = ['B', 'KB', 'MB'];
    var size = fileSizeBytes.toDouble();
    var suffixIndex = 0;
    
    while (size > 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }
    
    return '${size.toStringAsFixed(size < 10 && suffixIndex > 0 ? 1 : 0)} ${suffixes[suffixIndex]}';
  }

  @override
  String toString() {
    return 'LogoData(${width}x${height}px, ${widthMm.toStringAsFixed(1)}x${heightMm.toStringAsFixed(1)}mm, '
           '$format, ${fileSizeFormatted})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogoData &&
        other.width == width &&
        other.height == height &&
        other.format == format &&
        other.widthMm == widthMm &&
        other.heightMm == heightMm;
  }

  @override
  int get hashCode {
    return width.hashCode ^
        height.hashCode ^
        format.hashCode ^
        widthMm.hashCode ^
        heightMm.hashCode;
  }
}