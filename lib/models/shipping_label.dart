import 'contact_info.dart';

class ShippingLabel {
  String id;
  ContactInfo fromInfo;
  ContactInfo toInfo;
  DateTime createdAt;

  ShippingLabel({
    required this.id,
    required this.fromInfo,
    required this.toInfo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create empty label
  ShippingLabel.empty()
      : id = _generateId(),
        fromInfo = ContactInfo.empty(),
        toInfo = ContactInfo.empty(),
        createdAt = DateTime.now();

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
    };
  }

  // Create from Map
  factory ShippingLabel.fromMap(Map<String, dynamic> map) {
    return ShippingLabel(
      id: map['id'] ?? _generateId(),
      fromInfo: ContactInfo.fromMap(map['fromInfo'] ?? {}),
      toInfo: ContactInfo.fromMap(map['toInfo'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Check if label is ready to print
  bool isReadyToPrint() {
    return fromInfo.isComplete() && toInfo.isComplete();
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
