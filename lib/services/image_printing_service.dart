import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/label_config.dart';

/// Service for handling image sticker printing
/// Processes images to fit label dimensions and generates TSPL print commands
class ImagePrintingService {
  static final ImagePrintingService _instance =
      ImagePrintingService._internal();
  factory ImagePrintingService() => _instance;
  ImagePrintingService._internal();

  static const double _dotsPerMm = 8.0; // Approximate: 203 DPI ≈ 8 dots/mm

  img.Image? _currentImage;
  String? _currentImageName;

  /// Get the currently loaded image
  img.Image? get currentImage => _currentImage;

  /// Get the current image name
  String? get currentImageName => _currentImageName;

  /// Check if an image is loaded
  bool get hasImage => _currentImage != null;

  /// Pick image from gallery
  Future<img.Image?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );

      if (image == null) return null;

      final imageData = await image.readAsBytes();
      _currentImageName = image.name;
      return await _loadImage(imageData);
    } catch (e) {
      print('Error picking image from gallery: $e');
      throw Exception('Failed to pick image from gallery');
    }
  }

  /// Pick image from camera
  Future<img.Image?> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );

      if (image == null) return null;

      final imageData = await image.readAsBytes();
      _currentImageName = image.name;
      return await _loadImage(imageData);
    } catch (e) {
      print('Error picking image from camera: $e');
      throw Exception('Failed to pick image from camera');
    }
  }

  /// Pick image file using file picker
  Future<img.Image?> pickImageFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      if (file.bytes == null) {
        throw Exception('Failed to read image file data');
      }

      _currentImageName = file.name;
      return await _loadImage(file.bytes!);
    } catch (e) {
      print('Error picking image file: $e');
      throw Exception('Failed to pick image file');
    }
  }

  /// Load and decode image from bytes
  Future<img.Image?> _loadImage(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) {
        throw Exception(
            'Failed to decode image. Please select a valid image file.');
      }

      _currentImage = image;
      return image;
    } catch (e) {
      print('Error loading image: $e');
      rethrow;
    }
  }

  /// Clear the currently loaded image
  void clearImage() {
    _currentImage = null;
    _currentImageName = null;
  }

  /// Process image for printing on specified label size
  /// Returns processed image data ready for printing
  Future<ProcessedImageData> processImageForLabel(
    img.Image image,
    LabelConfig labelConfig,
  ) async {
    try {
      // Calculate maximum image dimensions in dots
      // Leave margins: 5mm on each side
      final maxWidthMm = labelConfig.widthMm - 10; // 5mm margin on each side
      final maxHeightMm = labelConfig.heightMm - 10;

      final maxWidthDots = (maxWidthMm * _dotsPerMm).toInt();
      final maxHeightDots = (maxHeightMm * _dotsPerMm).toInt();

      // Resize image to fit within label dimensions while maintaining aspect ratio
      img.Image resizedImage = _resizeToFit(image, maxWidthDots, maxHeightDots);

      // Convert to monochrome for thermal printing
      img.Image monochromeImage = _convertToMonochrome(resizedImage);

      // Convert to TSPL bitmap format (bitpacked)
      Uint8List bitmapData = _convertToTSPLBitmap(monochromeImage);

      // Calculate centering position on label
      final xPosDots =
          ((labelConfig.widthMm * _dotsPerMm) - monochromeImage.width) ~/ 2;
      final yPosDots =
          ((labelConfig.heightMm * _dotsPerMm) - monochromeImage.height) ~/ 2;

      return ProcessedImageData(
        bitmapData: bitmapData,
        width: monochromeImage.width,
        height: monochromeImage.height,
        xPosition: xPosDots.clamp(0, 9999),
        yPosition: yPosDots.clamp(0, 9999),
        previewImage: monochromeImage,
      );
    } catch (e) {
      print('Error processing image for label: $e');
      rethrow;
    }
  }

  /// Resize image to fit within max dimensions while maintaining aspect ratio
  img.Image _resizeToFit(img.Image image, int maxWidth, int maxHeight) {
    if (image.width <= maxWidth && image.height <= maxHeight) {
      return image; // Already fits
    }

    final widthRatio = maxWidth / image.width;
    final heightRatio = maxHeight / image.height;
    final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

    final newWidth = (image.width * ratio).toInt();
    final newHeight = (image.height * ratio).toInt();

    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Convert image to monochrome (black and white) for thermal printing
  img.Image _convertToMonochrome(img.Image image) {
    // Convert to grayscale first
    img.Image grayscale = img.grayscale(image);

    // Apply high contrast for better thermal printing
    grayscale = img.adjustColor(grayscale, contrast: 2.0);

    // Apply threshold to create pure black and white
    // Threshold at 128: pixels < 128 become black, >= 128 become white
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        final pixel = grayscale.getPixel(x, y);
        final luminance = img.getLuminance(pixel);

        // Set to pure black or pure white using setPixelRgba
        if (luminance < 128) {
          grayscale.setPixelRgba(x, y, 0, 0, 0, 255); // Black
        } else {
          grayscale.setPixelRgba(x, y, 255, 255, 255, 255); // White
        }
      }
    }

    return grayscale;
  }

  /// Convert image to TSPL bitmap format
  /// Returns raw bits: 0 for black, 1 for white, MSB first, padded to bytes
  Uint8List _convertToTSPLBitmap(img.Image image) {
    final width = image.width;
    final height = image.height;
    final bytesPerRow = (width + 7) ~/ 8; // Round up to nearest byte

    // Initialize with all 1s (white), then set 0s for black pixels
    final bitmapData = Uint8List(bytesPerRow * height);
    for (int i = 0; i < bitmapData.length; i++) {
      bitmapData[i] = 0xFF; // All white initially
    }

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminance(pixel);

        // Threshold: < 128 = black (0), >= 128 = white (1)
        if (luminance < 128) {
          final byteIndex = (y * bytesPerRow) + (x ~/ 8);
          final bitIndex = 7 - (x % 8); // MSB first
          bitmapData[byteIndex] &= ~(1 << bitIndex); // Clear bit for black
        }
      }
    }

    return bitmapData;
  }

  /// Generate TSPL commands for printing image sticker
  List<String> generatePrintCommands(
    ProcessedImageData imageData,
    LabelConfig labelConfig,
  ) {
    List<String> commands = [];

    // Setup commands
    commands.add(
        'SIZE ${labelConfig.widthMm.toInt()} mm, ${labelConfig.heightMm.toInt()} mm');
    commands.add('GAP ${labelConfig.spacingMm.toInt()} mm, 0 mm');
    commands.add('DIRECTION 0,0');
    commands.add('REFERENCE 0,0');
    commands.add('OFFSET 0 mm');
    commands.add('SET PEEL OFF');
    commands.add('SET CUTTER OFF');
    commands.add('SET PARTIAL_CUTTER OFF');
    commands.add('SET TEAR ON');
    commands.add('CLS');

    // Calculate bitmap width in bytes
    final widthBytes = (imageData.width + 7) ~/ 8;

    // BITMAP command: BITMAP x, y, width_bytes, height, mode, data
    // Mode 0 = overwrite mode
    commands.add(
        'BITMAP ${imageData.xPosition},${imageData.yPosition},$widthBytes,${imageData.height},0,');

    return commands;
  }

  /// Get image dimensions info for display
  Map<String, dynamic> getImageInfo(
      img.Image? image, LabelConfig? labelConfig) {
    if (image == null) {
      return {
        'hasImage': false,
        'width': 0,
        'height': 0,
        'widthMm': 0.0,
        'heightMm': 0.0,
      };
    }

    final widthMm = image.width / _dotsPerMm;
    final heightMm = image.height / _dotsPerMm;

    bool fitsInLabel = true;
    if (labelConfig != null) {
      fitsInLabel = widthMm <= (labelConfig.widthMm - 10) &&
          heightMm <= (labelConfig.heightMm - 10);
    }

    return {
      'hasImage': true,
      'width': image.width,
      'height': image.height,
      'widthMm': widthMm,
      'heightMm': heightMm,
      'fitsInLabel': fitsInLabel,
      'name': _currentImageName ?? 'Unknown',
    };
  }
}

/// Data class for processed image ready for printing
class ProcessedImageData {
  final Uint8List bitmapData;
  final int width;
  final int height;
  final int xPosition;
  final int yPosition;
  final img.Image previewImage;

  ProcessedImageData({
    required this.bitmapData,
    required this.width,
    required this.height,
    required this.xPosition,
    required this.yPosition,
    required this.previewImage,
  });
}
