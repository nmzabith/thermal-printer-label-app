class ContactInfo {
  String name;
  String address;
  String phoneNumber1;
  String phoneNumber2;

  ContactInfo({
    required this.name,
    this.address = '',                // Make address optional with empty default
    required this.phoneNumber1,
    this.phoneNumber2 = '',
  });

  ContactInfo.empty()
      : name = '',
        address = '',
        phoneNumber1 = '',
        phoneNumber2 = '';

  // Copy constructor
  ContactInfo.from(ContactInfo other)
      : name = other.name,
        address = other.address,
        phoneNumber1 = other.phoneNumber1,
        phoneNumber2 = other.phoneNumber2;

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phoneNumber1': phoneNumber1,
      'phoneNumber2': phoneNumber2,
    };
  }

  // Create from Map
  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      phoneNumber1: map['phoneNumber1'] ?? map['phoneNumber'] ?? '', // Backward compatibility
      phoneNumber2: map['phoneNumber2'] ?? '',
    );
  }

  // Check if contact is empty
  bool isEmpty() {
    return name.isEmpty && address.isEmpty && phoneNumber1.isEmpty && phoneNumber2.isEmpty;
  }

  // Check if contact is complete (at least one phone number required)
  bool isComplete() {
    return name.isNotEmpty && address.isNotEmpty && phoneNumber1.isNotEmpty;
  }

  // Get primary phone number for display
  String get primaryPhone => phoneNumber1;

  // Get all phone numbers as list
  List<String> get phoneNumbers {
    return [phoneNumber1, phoneNumber2].where((phone) => phone.isNotEmpty).toList();
  }

  // Get formatted phone numbers for display
  String get formattedPhones {
    final phones = phoneNumbers;
    if (phones.isEmpty) return '';
    if (phones.length == 1) return phones[0];
    return '${phones[0]} / ${phones[1]}';
  }

  @override
  String toString() {
    return 'ContactInfo(name: $name, address: $address, phoneNumber1: $phoneNumber1, phoneNumber2: $phoneNumber2)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactInfo &&
        other.name == name &&
        other.address == address &&
        other.phoneNumber1 == phoneNumber1 &&
        other.phoneNumber2 == phoneNumber2;
  }

  @override
  int get hashCode {
    return name.hashCode ^ address.hashCode ^ phoneNumber1.hashCode ^ phoneNumber2.hashCode;
  }
}
