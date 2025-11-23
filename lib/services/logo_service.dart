import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/logo_config.dart';
import '../models/logo_data.dart';

/// Service for managing logo functionality
/// Handles image picking, processing, storage, and thermal printer optimization
class LogoService {
  static final LogoService _instance = LogoService._internal();
  factory LogoService() => _instance;
  LogoService._internal();

  static const String _logoConfigKey = 'default_logo_config';
  static const String _logoDirectoryName = 'logos';
  static const double _maxLogoSizeMm = 25.0; // Maximum logo size in mm
  static const int _maxImageSizeBytes = 500 * 1024; // 500KB max file size
  static const int _thermalPrinterDpi = 203; // Typical thermal printer DPI

  /// Get the current default logo configuration
  Future<LogoConfig> getDefaultLogoConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configString = prefs.getString(_logoConfigKey);
      
      if (configString == null) {
        return LogoConfig.empty();
      }
      
      final config = LogoConfig.fromMap(jsonDecode(configString));
      
      // Load image data if path exists
      if (config.imagePath != null) {
        final imageFile = File(config.imagePath!);
        if (await imageFile.exists()) {
          config.imageData = await imageFile.readAsBytes();
        } else {
          // File no longer exists, clear the config
          config.imagePath = null;
          config.originalFileName = null;
          config.isEnabled = false;
        }
      }
      
      return config;
    } catch (e) {
      print('Error loading default logo config: $e');
      return LogoConfig.empty();
    }
  }

  /// Save the default logo configuration
  Future<void> saveDefaultLogoConfig(LogoConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_logoConfigKey, jsonEncode(config.toMap()));
    } catch (e) {
      print('Error saving default logo config: $e');
      throw Exception('Failed to save logo configuration');
    }
  }

  /// Pick an image from gallery
  Future<LogoConfig?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      
      if (image == null) return null;
      
      final imageData = await image.readAsBytes();
      return await _processPickedImage(imageData, image.name);
    } catch (e) {
      print('Error picking image from gallery: $e');
      throw Exception('Failed to pick image from gallery');
    }
  }

  /// Pick an image from camera
  Future<LogoConfig?> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
      
      if (image == null) return null;
      
      final imageData = await image.readAsBytes();
      return await _processPickedImage(imageData, image.name);
    } catch (e) {
      print('Error picking image from camera: $e');
      throw Exception('Failed to pick image from camera');
    }
  }

  /// Pick an image file using file picker
  Future<LogoConfig?> pickImageFile() async {
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
      
      return await _processPickedImage(file.bytes!, file.name);
    } catch (e) {
      print('Error picking image file: $e');
      throw Exception('Failed to pick image file');
    }
  }

  /// Process picked image and create logo config
  Future<LogoConfig> _processPickedImage(Uint8List imageData, String fileName) async {
    try {
      // Validate file size
      if (imageData.length > _maxImageSizeBytes) {
        throw Exception('Image file is too large. Maximum size is ${(_maxImageSizeBytes / 1024).toInt()}KB');
      }

      // Decode image
      final image = img.decodeImage(imageData);
      if (image == null) {
        throw Exception('Failed to decode image. Please select a valid image file.');
      }

      // Process image for thermal printing
      final processedImage = await _optimizeForThermalPrinting(image);
      
      // Save processed image to storage
      final savedPath = await _saveImageToStorage(processedImage, fileName);
      
      // Calculate appropriate size in mm
      final sizeMm = _calculateOptimalSize(processedImage);
      
      return LogoConfig(
        imagePath: savedPath,
        imageData: img.encodePng(processedImage),
        originalFileName: fileName,
        width: sizeMm.width,
        height: sizeMm.height,
        opacity: 1.0,
        isEnabled: true,
      );
    } catch (e) {
      print('Error processing picked image: $e');
      rethrow;
    }
  }

  /// Optimize image for thermal printing
  Future<img.Image> _optimizeForThermalPrinting(img.Image originalImage) async {
    try {
      img.Image processedImage = img.Image.from(originalImage);
      
      // Convert to grayscale for better thermal printing
      processedImage = img.grayscale(processedImage);
      
      // Resize if too large (max 25mm at 203 DPI = ~200 pixels)
      const maxPixels = 200;
      if (processedImage.width > maxPixels || processedImage.height > maxPixels) {
        if (processedImage.width > processedImage.height) {
          processedImage = img.copyResize(processedImage, width: maxPixels);
        } else {
          processedImage = img.copyResize(processedImage, height: maxPixels);
        }
      }
      
      // Apply high contrast for better thermal printing
      processedImage = img.contrast(processedImage, contrast: 150);
      
      // Apply slight sharpening
      processedImage = img.convolution(processedImage, [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
      ]);
      
      // Ensure image is binary (black and white) for thermal printing
      processedImage = img.threshold(processedImage, threshold: 128);
      
      return processedImage;
    } catch (e) {
      print('Error optimizing image for thermal printing: $e');
      rethrow;
    }
  }

  /// Calculate optimal size in mm for the logo
  ({double width, double height}) _calculateOptimalSize(img.Image image) {
    const double maxSize = _maxLogoSizeMm;
    final aspectRatio = image.width / image.height;
    
    double width, height;
    
    if (image.width > image.height) {
      // Landscape
      width = maxSize;
      height = maxSize / aspectRatio;
    } else {
      // Portrait or square
      height = maxSize;
      width = maxSize * aspectRatio;
    }
    
    // Ensure minimum size
    const double minSize = 5.0;
    if (width < minSize) width = minSize;
    if (height < minSize) height = minSize;
    
    return (width: width, height: height);
  }

  /// Save image to app storage
  Future<String> _saveImageToStorage(img.Image image, String originalFileName) async {
    try {
      final directory = await _getLogoDirectory();
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getFileExtension(originalFileName);
      final fileName = 'logo_${timestamp}$extension';
      
      final file = File('${directory.path}/$fileName');
      
      // Save as PNG for best quality
      final pngData = img.encodePng(image);
      await file.writeAsBytes(pngData);
      
      return file.path;
    } catch (e) {
      print('Error saving image to storage: $e');
      throw Exception('Failed to save image to storage');
    }
  }

  /// Get or create logo directory
  Future<Directory> _getLogoDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final logoDir = Directory('${appDir.path}/$_logoDirectoryName');
    
    if (!await logoDir.exists()) {
      await logoDir.create(recursive: true);
    }
    
    return logoDir;
  }

  /// Get file extension from filename
  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot);
    }
    return '.png'; // Default extension
  }

  /// Process logo for thermal printing
  Future<LogoData?> processLogoForPrinting(LogoConfig config) async {
    if (!config.hasLogo) return null;
    
    try {
      Uint8List? imageData;
      
      // Get image data
      if (config.imageData != null) {
        imageData = config.imageData!;
      } else if (config.imagePath != null) {
        final file = File(config.imagePath!);
        if (await file.exists()) {
          imageData = await file.readAsBytes();
        }
      }
      
      if (imageData == null) return null;
      
      // Decode image
      final image = img.decodeImage(imageData);
      if (image == null) return null;
      
      // Convert to format suitable for thermal printer (monochrome BMP)
      final processedImage = await _convertToThermalFormat(image, config);
      
      return LogoData(
        imageData: processedImage,
        width: image.width,
        height: image.height,
        format: 'BMP',
        widthMm: config.width,
        heightMm: config.height,
      );
    } catch (e) {
      print('Error processing logo for printing: $e');
      return null;
    }
  }

  /// Convert image to thermal printer format
  Future<Uint8List> _convertToThermalFormat(img.Image image, LogoConfig config) async {
    try {
      // Apply opacity if needed
      if (config.opacity < 1.0) {
        final opacity = (config.opacity * 255).round();
        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            final newPixel = img.ColorRgb8(
              pixel.r,
              pixel.g,
              pixel.b,
            );
            image.setPixel(x, y, newPixel);
          }
        }
      }
      
      // Convert to monochrome BMP for thermal printer
      final monoImage = img.threshold(image, threshold: 128);
      final bmpData = img.encodeBmp(monoImage);
      
      return Uint8List.fromList(bmpData);
    } catch (e) {
      print('Error converting to thermal format: $e');
      rethrow;
    }
  }

  /// Delete logo and clean up files
  Future<void> deleteLogo(LogoConfig config) async {
    try {
      if (config.imagePath != null) {
        final file = File(config.imagePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Clear from preferences if it's the default logo
      final defaultConfig = await getDefaultLogoConfig();
      if (defaultConfig.imagePath == config.imagePath) {
        await saveDefaultLogoConfig(LogoConfig.empty());
      }
    } catch (e) {
      print('Error deleting logo: $e');
      throw Exception('Failed to delete logo');
    }
  }

  /// Clean up old logo files (keep only current default)
  Future<void> cleanupOldLogos() async {
    try {
      final logoDir = await _getLogoDirectory();
      final defaultConfig = await getDefaultLogoConfig();
      
      if (await logoDir.exists()) {
        final files = logoDir.listSync();
        for (final file in files) {
          if (file is File) {
            final isCurrentLogo = defaultConfig.imagePath == file.path;
            if (!isCurrentLogo) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old logos: $e');
    }
  }

  /// Validate image file
  Future<bool> validateImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final imageData = await file.readAsBytes();
      if (imageData.length > _maxImageSizeBytes) return false;
      
      final image = img.decodeImage(imageData);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  /// Get supported image formats
  List<String> get supportedFormats => [
    'jpg', 'jpeg', 'png', 'bmp', 'gif', 'webp'
  ];

  /// Get maximum logo size in mm
  double get maxLogoSizeMm => _maxLogoSizeMm;

  /// Get maximum file size in bytes
  int get maxFileSizeBytes => _maxImageSizeBytes;
}