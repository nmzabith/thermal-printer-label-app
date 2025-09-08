/// Font settings model for thermal printer configuration
class FontSettings {
  // Header fonts (TO/FROM labels)
  final int headerFontSize;        // For "TO:" and "FROM:" text
  final bool headerBold;
  
  // Name fonts (recipient and sender names)
  final int nameFontSize;          // For names under TO: and FROM:
  final bool nameBold;
  
  // Address fonts (address lines)
  final int addressFontSize;       // For address lines
  final bool addressBold;
  
  // Phone fonts (telephone numbers)
  final int phoneFontSize;         // For TEL: lines
  final bool phoneBold;
  
  // Label title font (optional header like "SHIPPING LABEL")
  final int labelTitleFontSize;    // For main label title
  final bool labelTitleBold;
  
  final double lineSpacingFactor;
  final bool enableAutoSizing;
  final int maxLinesAddress;

  const FontSettings({
    this.headerFontSize = 4,         // TO:/FROM: headers
    this.headerBold = true,
    this.nameFontSize = 3,           // Names
    this.nameBold = false,
    this.addressFontSize = 2,        // Address lines
    this.addressBold = false,
    this.phoneFontSize = 2,          // Phone numbers
    this.phoneBold = false,
    this.labelTitleFontSize = 5,     // Main title
    this.labelTitleBold = true,
    this.lineSpacingFactor = 1.2,
    this.enableAutoSizing = true,
    this.maxLinesAddress = 3,
  });

  /// Default font settings
  static const FontSettings defaultSettings = FontSettings();

  /// Small label optimized settings
  static const FontSettings smallLabel = FontSettings(
    headerFontSize: 3,              // TO:/FROM: smaller
    headerBold: true,
    nameFontSize: 2,                // Names smaller
    nameBold: false,
    addressFontSize: 2,             // Address same as names
    addressBold: false,
    phoneFontSize: 1,               // Phone numbers smallest
    phoneBold: false,
    labelTitleFontSize: 3,          // Title smaller
    labelTitleBold: true,
    lineSpacingFactor: 1.0,
    enableAutoSizing: true,
    maxLinesAddress: 2,
  );

  /// Large label optimized settings  
  static const FontSettings largeLabel = FontSettings(
    headerFontSize: 5,              // TO:/FROM: larger
    headerBold: true,
    nameFontSize: 4,                // Names larger
    nameBold: true,
    addressFontSize: 3,             // Address larger
    addressBold: false,
    phoneFontSize: 2,               // Phone numbers larger
    phoneBold: false,
    labelTitleFontSize: 6,          // Title largest
    labelTitleBold: true,
    lineSpacingFactor: 1.3,
    enableAutoSizing: true,
    maxLinesAddress: 4,
  );

  /// Copy with modifications
  FontSettings copyWith({
    int? headerFontSize,
    bool? headerBold,
    int? nameFontSize,
    bool? nameBold,
    int? addressFontSize,
    bool? addressBold,
    int? phoneFontSize,
    bool? phoneBold,
    int? labelTitleFontSize,
    bool? labelTitleBold,
    double? lineSpacingFactor,
    bool? enableAutoSizing,
    int? maxLinesAddress,
  }) {
    return FontSettings(
      headerFontSize: headerFontSize ?? this.headerFontSize,
      headerBold: headerBold ?? this.headerBold,
      nameFontSize: nameFontSize ?? this.nameFontSize,
      nameBold: nameBold ?? this.nameBold,
      addressFontSize: addressFontSize ?? this.addressFontSize,
      addressBold: addressBold ?? this.addressBold,
      phoneFontSize: phoneFontSize ?? this.phoneFontSize,
      phoneBold: phoneBold ?? this.phoneBold,
      labelTitleFontSize: labelTitleFontSize ?? this.labelTitleFontSize,
      labelTitleBold: labelTitleBold ?? this.labelTitleBold,
      lineSpacingFactor: lineSpacingFactor ?? this.lineSpacingFactor,
      enableAutoSizing: enableAutoSizing ?? this.enableAutoSizing,
      maxLinesAddress: maxLinesAddress ?? this.maxLinesAddress,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'headerFontSize': headerFontSize,
      'headerBold': headerBold,
      'nameFontSize': nameFontSize,
      'nameBold': nameBold,
      'addressFontSize': addressFontSize,
      'addressBold': addressBold,
      'phoneFontSize': phoneFontSize,
      'phoneBold': phoneBold,
      'labelTitleFontSize': labelTitleFontSize,
      'labelTitleBold': labelTitleBold,
      'lineSpacingFactor': lineSpacingFactor,
      'enableAutoSizing': enableAutoSizing,
      'maxLinesAddress': maxLinesAddress,
    };
  }

  /// Create from JSON
  factory FontSettings.fromJson(Map<String, dynamic> json) {
    return FontSettings(
      headerFontSize: json['headerFontSize'] ?? json['subtitleFontSize'] ?? 4,        // backward compatibility
      headerBold: json['headerBold'] ?? json['subtitleBold'] ?? true,
      nameFontSize: json['nameFontSize'] ?? json['contentFontSize'] ?? 3,             // backward compatibility
      nameBold: json['nameBold'] ?? json['contentBold'] ?? false,
      addressFontSize: json['addressFontSize'] ?? json['contentFontSize'] ?? 2,       // backward compatibility
      addressBold: json['addressBold'] ?? json['contentBold'] ?? false,
      phoneFontSize: json['phoneFontSize'] ?? json['smallFontSize'] ?? 2,             // backward compatibility
      phoneBold: json['phoneBold'] ?? json['smallBold'] ?? false,
      labelTitleFontSize: json['labelTitleFontSize'] ?? json['titleFontSize'] ?? 5,   // backward compatibility
      labelTitleBold: json['labelTitleBold'] ?? json['titleBold'] ?? true,
      lineSpacingFactor: json['lineSpacingFactor']?.toDouble() ?? 1.2,
      enableAutoSizing: json['enableAutoSizing'] ?? true,
      maxLinesAddress: json['maxLinesAddress'] ?? 3,
    );
  }

  /// Get font size and bold format for TSC TEXT command
  /// Now uses clear element-based font types:
  /// - 'header' for TO:/FROM: labels
  /// - 'name' for recipient/sender names  
  /// - 'address' for address lines
  /// - 'phone' for telephone numbers
  /// - 'labeltitle' for main label title
  String getTscFontCommand(String fontType) {
    int size;
    bool bold;
    
    switch (fontType.toLowerCase()) {
      case 'header':           // TO:/FROM: headers
        size = headerFontSize;
        bold = headerBold;
        break;
      case 'name':             // Names
        size = nameFontSize;
        bold = nameBold;
        break;
      case 'address':          // Address lines
        size = addressFontSize;
        bold = addressBold;
        break;
      case 'phone':            // Phone numbers
        size = phoneFontSize;
        bold = phoneBold;
        break;
      case 'labeltitle':       // Main label title
        size = labelTitleFontSize;
        bold = labelTitleBold;
        break;
      // Backward compatibility with old names
      case 'title':
        size = labelTitleFontSize;
        bold = labelTitleBold;
        break;
      case 'subtitle':
        size = headerFontSize;
        bold = headerBold;
        break;
      case 'content':
        size = nameFontSize;     // Default to name font
        bold = nameBold;
        break;
      case 'small':
        size = phoneFontSize;
        bold = phoneBold;
        break;
      default:
        size = nameFontSize;
        bold = nameBold;
    }
    
    // TSC font format: "font",rotation,x_magnification,y_magnification
    // For TEXT command: TEXT x,y,"font",rotation,x_mag,y_mag,"content"
    // Bold is handled through magnification (2 for bold, 1 for normal)
    int magnification = bold ? 2 : 1;
    return '"$size",0,$magnification,$magnification';
  }

  /// Get approximate text dimensions for layout calculations
  Map<String, int> getTextDimensions(String fontType) {
    int size;
    
    switch (fontType.toLowerCase()) {
      case 'header':           // TO:/FROM: headers
        size = headerFontSize;
        break;
      case 'name':             // Names
        size = nameFontSize;
        break;
      case 'address':          // Address lines
        size = addressFontSize;
        break;
      case 'phone':            // Phone numbers
        size = phoneFontSize;
        break;
      case 'labeltitle':       // Main label title
        size = labelTitleFontSize;
        break;
      // Backward compatibility
      case 'title':
        size = labelTitleFontSize;
        break;
      case 'subtitle':
        size = headerFontSize;
        break;
      case 'content':
        size = nameFontSize;
        break;
      case 'small':
        size = phoneFontSize;
        break;
      default:
        size = nameFontSize;
    }
    
    // Approximate dimensions in dots (8 dots per mm for 203 DPI)
    // These are rough estimates - actual may vary by printer
    Map<int, Map<String, int>> fontDimensions = {
      1: {'width': 8, 'height': 12},
      2: {'width': 12, 'height': 16},
      3: {'width': 16, 'height': 24},
      4: {'width': 24, 'height': 32},
      5: {'width': 32, 'height': 48},
      6: {'width': 40, 'height': 56},
      7: {'width': 48, 'height': 64},
      8: {'width': 56, 'height': 72},
    };
    
    return fontDimensions[size] ?? fontDimensions[2]!;
  }

  @override
  String toString() {
    return 'FontSettings(header: $headerFontSize/${headerBold ? "B" : "N"}, '
           'name: $nameFontSize/${nameBold ? "B" : "N"}, '
           'address: $addressFontSize/${addressBold ? "B" : "N"}, '
           'phone: $phoneFontSize/${phoneBold ? "B" : "N"}, '
           'labelTitle: $labelTitleFontSize/${labelTitleBold ? "B" : "N"}, '
           'spacing: ${lineSpacingFactor}x, '
           'autoSize: $enableAutoSizing, '
           'maxLines: $maxLinesAddress)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FontSettings &&
        other.headerFontSize == headerFontSize &&
        other.headerBold == headerBold &&
        other.nameFontSize == nameFontSize &&
        other.nameBold == nameBold &&
        other.addressFontSize == addressFontSize &&
        other.addressBold == addressBold &&
        other.phoneFontSize == phoneFontSize &&
        other.phoneBold == phoneBold &&
        other.labelTitleFontSize == labelTitleFontSize &&
        other.labelTitleBold == labelTitleBold &&
        other.lineSpacingFactor == lineSpacingFactor &&
        other.enableAutoSizing == enableAutoSizing &&
        other.maxLinesAddress == maxLinesAddress;
  }

  @override
  int get hashCode {
    return headerFontSize.hashCode ^
        headerBold.hashCode ^
        nameFontSize.hashCode ^
        nameBold.hashCode ^
        addressFontSize.hashCode ^
        addressBold.hashCode ^
        phoneFontSize.hashCode ^
        phoneBold.hashCode ^
        labelTitleFontSize.hashCode ^
        labelTitleBold.hashCode ^
        lineSpacingFactor.hashCode ^
        enableAutoSizing.hashCode ^
        maxLinesAddress.hashCode;
  }
}
