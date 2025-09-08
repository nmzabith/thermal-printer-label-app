/// Label Configuration Model
/// Defines the physical dimensions and spacing for thermal printer labels
class LabelConfig {
  final String name;
  final double widthMm;
  final double heightMm;
  final double spacingMm; // Gap between labels
  final String description;

  const LabelConfig({
    required this.name,
    required this.widthMm,
    required this.heightMm,
    required this.spacingMm,
    required this.description,
  });

  @override
  String toString() => '$name (${widthMm}mm × ${heightMm}mm)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabelConfig &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          widthMm == other.widthMm &&
          heightMm == other.heightMm;

  @override
  int get hashCode => name.hashCode ^ widthMm.hashCode ^ heightMm.hashCode;

  /// Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'widthMm': widthMm,
      'heightMm': heightMm,
      'spacingMm': spacingMm,
      'description': description,
    };
  }

  /// Create from Map
  factory LabelConfig.fromMap(Map<String, dynamic> map) {
    return LabelConfig(
      name: map['name'] ?? '',
      widthMm: (map['widthMm'] ?? 0.0).toDouble(),
      heightMm: (map['heightMm'] ?? 0.0).toDouble(),
      spacingMm: (map['spacingMm'] ?? 2.0).toDouble(),
      description: map['description'] ?? '',
    );
  }
}

/// Predefined label configurations for common thermal printer labels
class LabelConfigs {
  static const List<LabelConfig> presets = [
    LabelConfig(
      name: '80mm × 50mm',
      widthMm: 80,
      heightMm: 50,
      spacingMm: 2,
      description: 'Standard shipping label - compact',
    ),
    LabelConfig(
      name: '80mm × 60mm',
      widthMm: 80,
      heightMm: 60,
      spacingMm: 3,
      description: 'Standard shipping label - medium',
    ),
    LabelConfig(
      name: '80mm × 80mm',
      widthMm: 80,
      heightMm: 80,
      spacingMm: 3,
      description: 'Square shipping label',
    ),
    LabelConfig(
      name: '80mm × 120mm',
      widthMm: 80,
      heightMm: 120,
      spacingMm: 3,
      description: 'Large shipping label',
    ),
    LabelConfig(
      name: '101mm × 152mm',
      widthMm: 101,
      heightMm: 152,
      spacingMm: 4,
      description: '4×6 inch shipping label (US standard)',
    ),
  ];

  /// Get default configuration
  static LabelConfig get defaultConfig => presets[0]; // 80mm × 50mm

  /// Find configuration by name
  static LabelConfig? findByName(String name) {
    try {
      return presets.firstWhere((config) => config.name == name);
    } catch (e) {
      return null;
    }
  }
}
