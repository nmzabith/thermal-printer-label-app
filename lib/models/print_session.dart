import 'shipping_label.dart';

class PrintSession {
  String id;
  String name;
  List<ShippingLabel> labels;
  DateTime createdAt;
  DateTime updatedAt;

  PrintSession({
    required this.id,
    required this.name,
    required this.labels,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create empty session
  PrintSession.empty({String? sessionName})
      : id = _generateId(),
        name = sessionName ?? 'Session ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        labels = [],
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  // Generate unique ID
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Update session timestamp
  void updateTimestamp() {
    updatedAt = DateTime.now();
  }

  // Add a new label to session
  void addLabel(ShippingLabel label) {
    labels.add(label);
    updateTimestamp();
  }

  // Remove label from session
  void removeLabel(String labelId) {
    labels.removeWhere((label) => label.id == labelId);
    updateTimestamp();
  }

  // Update existing label
  void updateLabel(ShippingLabel updatedLabel) {
    final index = labels.indexWhere((label) => label.id == updatedLabel.id);
    if (index != -1) {
      labels[index] = updatedLabel;
      updateTimestamp();
    }
  }

  // Get label by ID
  ShippingLabel? getLabelById(String labelId) {
    try {
      return labels.firstWhere((label) => label.id == labelId);
    } catch (e) {
      return null;
    }
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'labels': labels.map((label) => label.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from Map
  factory PrintSession.fromMap(Map<String, dynamic> map) {
    return PrintSession(
      id: map['id'] ?? _generateId(),
      name: map['name'] ?? 'Unnamed Session',
      labels: (map['labels'] as List? ?? [])
          .map((labelMap) => ShippingLabel.fromMap(labelMap))
          .toList(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // Get total label count
  int get totalLabels => labels.length;

  // Get ready to print labels count
  int get readyToPrintCount => labels.where((label) => label.isReadyToPrint()).length;

  // Check if session has any labels ready to print
  bool get hasReadyLabels => readyToPrintCount > 0;

  // Check if all labels are ready to print
  bool get allLabelsReady => labels.isNotEmpty && readyToPrintCount == totalLabels;

  // Get display name for session
  String getDisplayName() {
    return name;
  }

  // Get session status text
  String getStatusText() {
    if (labels.isEmpty) return 'No labels';
    if (allLabelsReady) return '$totalLabels labels ready';
    return '$readyToPrintCount/$totalLabels ready';
  }

  @override
  String toString() {
    return 'PrintSession(id: $id, name: $name, labels: ${labels.length})';
  }
}
