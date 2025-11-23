import 'dart:typed_data';

/// Configuration for logo handling in the app
class LogoConfig {
  String? imagePath; // Path to the stored logo image
  Uint8List? imageData; // Raw image data for the logo
  String? originalFileName; // Original filename of the logo
  double width; // Logo width in mm
  double height; // Logo height in mm
  double opacity; // Logo opacity (0.0 to 1.0)
  bool isEnabled; // Whether logo is enabled by default
  DateTime? createdAt; // When the logo was added
  DateTime? updatedAt; // When the logo was last updated

  LogoConfig({
    this.imagePath,
    this.imageData,
    this.originalFileName,
    this.width = 15.0, // Default 15mm width
    this.height = 15.0, // Default 15mm height
    this.opacity = 1.0, // Full opacity by default
    this.isEnabled = false, // Disabled by default
    this.createdAt,
    this.updatedAt,
  }) {
    createdAt ??= DateTime.now();
    updatedAt ??= DateTime.now();
  }

  // Create empty logo config
  LogoConfig.empty()
      : imagePath = null,
        imageData = null,
        originalFileName = null,
        width = 15.0,
        height = 15.0,
        opacity = 1.0,
        isEnabled = false,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  // Copy constructor
  LogoConfig.from(LogoConfig other)
      : imagePath = other.imagePath,
        imageData = other.imageData != null ? Uint8List.fromList(other.imageData!) : null,
        originalFileName = other.originalFileName,
        width = other.width,
        height = other.height,
        opacity = other.opacity,
        isEnabled = other.isEnabled,
        createdAt = other.createdAt,
        updatedAt = DateTime.now();

  // Check if logo is configured and ready to use
  bool get hasLogo => imagePath != null || imageData != null;

  // Check if logo should be shown (has logo and is enabled)
  bool get shouldShowLogo => hasLogo && isEnabled;

  // Convert to Map for storage (excluding imageData for size reasons)
  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'originalFileName': originalFileName,
      'width': width,
      'height': height,
      'opacity': opacity,
      'isEnabled': isEnabled,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Map
  factory LogoConfig.fromMap(Map<String, dynamic> map) {
    return LogoConfig(
      imagePath: map['imagePath'],
      originalFileName: map['originalFileName'],
      width: (map['width'] ?? 15.0).toDouble(),
      height: (map['height'] ?? 15.0).toDouble(),
      opacity: (map['opacity'] ?? 1.0).toDouble(),
      isEnabled: map['isEnabled'] ?? false,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  // Update logo configuration
  LogoConfig copyWith({
    String? imagePath,
    Uint8List? imageData,
    String? originalFileName,
    double? width,
    double? height,
    double? opacity,
    bool? isEnabled,
  }) {
    return LogoConfig(
      imagePath: imagePath ?? this.imagePath,
      imageData: imageData ?? this.imageData,
      originalFileName: originalFileName ?? this.originalFileName,
      width: width ?? this.width,
      height: height ?? this.height,
      opacity: opacity ?? this.opacity,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'LogoConfig(path: $imagePath, filename: $originalFileName, '
           'size: ${width}x${height}mm, opacity: $opacity, enabled: $isEnabled)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogoConfig &&
        other.imagePath == imagePath &&
        other.originalFileName == originalFileName &&
        other.width == width &&
        other.height == height &&
        other.opacity == opacity &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode {
    return imagePath.hashCode ^
        originalFileName.hashCode ^
        width.hashCode ^
        height.hashCode ^
        opacity.hashCode ^
        isEnabled.hashCode;
  }
}