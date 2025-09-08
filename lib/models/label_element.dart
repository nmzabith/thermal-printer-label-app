/// Model for draggable label elements in the visual designer
class LabelElement {
  final String id;
  final LabelElementType type;
  String content;
  double x;          // Position in dots
  double y;          // Position in dots
  int fontSize;
  bool isBold;
  bool isVisible;
  String? iconPath;  // For image/icon elements
  double? iconWidth;
  double? iconHeight;

  LabelElement({
    required this.id,
    required this.type,
    required this.content,
    required this.x,
    required this.y,
    this.fontSize = 3,
    this.isBold = false,
    this.isVisible = true,
    this.iconPath,
    this.iconWidth,
    this.iconHeight,
  });

  LabelElement copyWith({
    String? id,
    LabelElementType? type,
    String? content,
    double? x,
    double? y,
    int? fontSize,
    bool? isBold,
    bool? isVisible,
    String? iconPath,
    double? iconWidth,
    double? iconHeight,
  }) {
    return LabelElement(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isVisible: isVisible ?? this.isVisible,
      iconPath: iconPath ?? this.iconPath,
      iconWidth: iconWidth ?? this.iconWidth,
      iconHeight: iconHeight ?? this.iconHeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'content': content,
      'x': x,
      'y': y,
      'fontSize': fontSize,
      'isBold': isBold,
      'isVisible': isVisible,
      'iconPath': iconPath,
      'iconWidth': iconWidth,
      'iconHeight': iconHeight,
    };
  }

  factory LabelElement.fromJson(Map<String, dynamic> json) {
    return LabelElement(
      id: json['id'],
      type: LabelElementType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => LabelElementType.text,
      ),
      content: json['content'],
      x: json['x'].toDouble(),
      y: json['y'].toDouble(),
      fontSize: json['fontSize'] ?? 3,
      isBold: json['isBold'] ?? false,
      isVisible: json['isVisible'] ?? true,
      iconPath: json['iconPath'],
      iconWidth: json['iconWidth']?.toDouble(),
      iconHeight: json['iconHeight']?.toDouble(),
    );
  }
}

enum LabelElementType {
  toHeader,      // "TO:" label
  fromHeader,    // "FROM:" label
  toName,        // TO name
  fromName,      // FROM name
  toAddress,     // TO address
  fromAddress,   // FROM address
  toPhone,       // TO phone
  fromPhone,     // FROM phone
  text,          // Custom text
  icon,          // Icon/Image
  separator,     // Line separator
  labelTitle,    // Main label title
}

extension LabelElementTypeExtension on LabelElementType {
  String get displayName {
    switch (this) {
      case LabelElementType.toHeader:
        return 'TO Header';
      case LabelElementType.fromHeader:
        return 'FROM Header';
      case LabelElementType.toName:
        return 'TO Name';
      case LabelElementType.fromName:
        return 'FROM Name';
      case LabelElementType.toAddress:
        return 'TO Address';
      case LabelElementType.fromAddress:
        return 'FROM Address';
      case LabelElementType.toPhone:
        return 'TO Phone';
      case LabelElementType.fromPhone:
        return 'FROM Phone';
      case LabelElementType.text:
        return 'Custom Text';
      case LabelElementType.icon:
        return 'Icon/Image';
      case LabelElementType.separator:
        return 'Separator';
      case LabelElementType.labelTitle:
        return 'Label Title';
    }
  }

  String get icon {
    switch (this) {
      case LabelElementType.toHeader:
      case LabelElementType.fromHeader:
        return '📋';
      case LabelElementType.toName:
      case LabelElementType.fromName:
        return '👤';
      case LabelElementType.toAddress:
      case LabelElementType.fromAddress:
        return '🏠';
      case LabelElementType.toPhone:
      case LabelElementType.fromPhone:
        return '📞';
      case LabelElementType.text:
        return '📝';
      case LabelElementType.icon:
        return '🖼️';
      case LabelElementType.separator:
        return '➖';
      case LabelElementType.labelTitle:
        return '🏷️';
    }
  }
}
