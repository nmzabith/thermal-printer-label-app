import '../models/label_element.dart';
import '../models/label_config.dart';

/// Model for custom label designs created in the visual designer
class CustomLabelDesign {
  final String id;
  final String name;
  final String description;
  final LabelConfig labelConfig; // Label size and configuration
  final List<LabelElement> elements; // All draggable elements
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;
  final String? previewImagePath;

  const CustomLabelDesign({
    required this.id,
    required this.name,
    required this.description,
    required this.labelConfig,
    required this.elements,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.previewImagePath,
  });

  /// Convenience getter for last modification time
  DateTime get lastModified => updatedAt;

  CustomLabelDesign copyWith({
    String? id,
    String? name,
    String? description,
    LabelConfig? labelConfig,
    List<LabelElement>? elements,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDefault,
    String? previewImagePath,
  }) {
    return CustomLabelDesign(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      labelConfig: labelConfig ?? this.labelConfig,
      elements: elements ?? this.elements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDefault: isDefault ?? this.isDefault,
      previewImagePath: previewImagePath ?? this.previewImagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'labelConfig': labelConfig.toJson(),
      'elements': elements.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
      'previewImagePath': previewImagePath,
    };
  }

  factory CustomLabelDesign.fromJson(Map<String, dynamic> json) {
    return CustomLabelDesign(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      labelConfig: LabelConfig.fromJson(json['labelConfig']),
      elements: (json['elements'] as List)
          .map((e) => LabelElement.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isDefault: json['isDefault'] ?? false,
      previewImagePath: json['previewImagePath'],
    );
  }

  /// Create a default design based on label config
  factory CustomLabelDesign.createDefault(LabelConfig labelConfig) {
    final now = DateTime.now();
    final List<LabelElement> defaultElements = [];

    // Convert mm to dots (8 dots per mm for 203 DPI)
    final labelWidthDots = labelConfig.widthMm * 8;
    final labelHeightDots = labelConfig.heightMm * 8;

    double yPos = 20; // Start position
    const leftMargin = 20.0;

    // Label Title (if large enough label)
    if (labelConfig.heightMm >= 80) {
      defaultElements.add(LabelElement(
        id: 'title',
        type: LabelElementType.labelTitle,
        content: 'SHIPPING LABEL',
        x: labelWidthDots / 2, // Center
        y: yPos,
        fontSize: 5,
        isBold: true,
      ));
      yPos += 60;
    }

    // TO section
    defaultElements.add(LabelElement(
      id: 'to_header',
      type: LabelElementType.toHeader,
      content: 'TO:',
      x: leftMargin,
      y: yPos,
      fontSize: 4,
      isBold: true,
    ));
    yPos += 40;

    defaultElements.add(LabelElement(
      id: 'to_name',
      type: LabelElementType.toName,
      content: '[TO NAME]',
      x: leftMargin,
      y: yPos,
      fontSize: 3,
      isBold: false,
    ));
    yPos += 35;

    defaultElements.add(LabelElement(
      id: 'to_address',
      type: LabelElementType.toAddress,
      content: '[TO ADDRESS]',
      x: leftMargin,
      y: yPos,
      fontSize: 2,
      isBold: false,
    ));
    yPos += 60;

    defaultElements.add(LabelElement(
      id: 'to_phone',
      type: LabelElementType.toPhone,
      content: '[TO PHONE]',
      x: leftMargin,
      y: yPos,
      fontSize: 2,
      isBold: false,
    ));
    yPos += 50;

    // FROM section (if there's space)
    if (yPos + 120 < labelHeightDots) {
      defaultElements.add(LabelElement(
        id: 'from_header',
        type: LabelElementType.fromHeader,
        content: 'FROM:',
        x: leftMargin,
        y: yPos,
        fontSize: 4,
        isBold: true,
      ));
      yPos += 40;

      defaultElements.add(LabelElement(
        id: 'from_name',
        type: LabelElementType.fromName,
        content: '[FROM NAME]',
        x: leftMargin,
        y: yPos,
        fontSize: 3,
        isBold: false,
      ));
      yPos += 35;

      if (yPos + 30 < labelHeightDots) {
        defaultElements.add(LabelElement(
          id: 'from_phone',
          type: LabelElementType.fromPhone,
          content: '[FROM PHONE]',
          x: leftMargin,
          y: yPos,
          fontSize: 2,
          isBold: false,
        ));
      }
    }

    return CustomLabelDesign(
      id: 'default_${labelConfig.id}',
      name: 'Default ${labelConfig.name}',
      description: 'Default layout for ${labelConfig.name} labels',
      labelConfig: labelConfig,
      elements: defaultElements,
      createdAt: now,
      updatedAt: now,
      isDefault: true,
    );
  }
}
