import 'contact_info.dart';

class ShippingLabel {
  String id;
  ContactInfo fromInfo;
  ContactInfo toInfo;
  DateTime createdAt;
  bool includeLogo; // Whether to include logo on this specific label
  bool codEnabled; // Whether Cash on Delivery is enabled
  double codAmount; // COD amount in LKR (Sri Lankan Rupee)
  bool includeThanksMessage; // Whether to include thanks message on this label

  ShippingLabel({
    required this.id,
    required this.fromInfo,
    required this.toInfo,
    DateTime? createdAt,
    this.includeLogo = false, // Default to false (unticked)
    this.codEnabled = false, // Default to false
    this.codAmount = 0.0, // Default to 0
    this.includeThanksMessage = true, // Default to true (enabled)
  }) : createdAt = createdAt ?? DateTime.now();

  // Create empty label
  ShippingLabel.empty()
      : id = _generateId(),
        fromInfo = ContactInfo.empty(),
        toInfo = ContactInfo.empty(),
        createdAt = DateTime.now(),
        includeLogo = false,
        codEnabled = false,
        codAmount = 0.0,
        includeThanksMessage = true;

  // Generate unique ID
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromInfo': fromInfo.toMap(),
      'toInfo': toInfo.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'includeLogo': includeLogo,
      'codEnabled': codEnabled,
      'codAmount': codAmount,
      'includeThanksMessage': includeThanksMessage,
    };
  }

  // Create from Map
  factory ShippingLabel.fromMap(Map<String, dynamic> map) {
    return ShippingLabel(
      id: map['id'] ?? _generateId(),
      fromInfo: ContactInfo.fromMap(map['fromInfo'] ?? {}),
      toInfo: ContactInfo.fromMap(map['toInfo'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      includeLogo: map['includeLogo'] as bool? ?? false,
      codEnabled: map['codEnabled'] as bool? ?? false,
      codAmount: (map['codAmount'] as num?)?.toDouble() ?? 0.0,
      includeThanksMessage: map['includeThanksMessage'] as bool? ?? true,
    );
  }

  // Check if label is ready to print
  // FROM info is optional, only TO info is required
  bool isReadyToPrint() {
    return toInfo.isComplete();
  }

  // Get display name for label
  String getDisplayName() {
    String fromName = fromInfo.name.isNotEmpty ? fromInfo.name : 'Unknown';
    String toName = toInfo.name.isNotEmpty ? toInfo.name : 'Unknown';
    return '$fromName → $toName';
  }

  @override
  String toString() {
    return 'ShippingLabel(id: $id, from: ${fromInfo.name}, to: ${toInfo.name})';
  }
}
