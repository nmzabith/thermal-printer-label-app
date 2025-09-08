import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_info.dart';

class FromContactService {
  static const String _fromContactsKey = 'from_contacts';
  
  // Save FROM contact for future use
  Future<void> saveFromContact(ContactInfo contact) async {
    if (!contact.isComplete()) return;
    
    try {
      final contacts = await getFromContacts();
      
      // Check if contact already exists (by name or phone)
      final existingIndex = contacts.indexWhere((c) => 
        c.name.toLowerCase() == contact.name.toLowerCase() ||
        c.phoneNumber1 == contact.phoneNumber1
      );
      
      if (existingIndex != -1) {
        // Update existing contact
        contacts[existingIndex] = contact;
      } else {
        // Add new contact
        contacts.add(contact);
      }
      
      // Keep only last 20 contacts
      if (contacts.length > 20) {
        contacts.removeRange(0, contacts.length - 20);
      }
      
      await _saveContacts(contacts);
    } catch (e) {
      print('Error saving FROM contact: $e');
    }
  }
  
  // Get all saved FROM contacts
  Future<List<ContactInfo>> getFromContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsString = prefs.getString(_fromContactsKey);
      
      if (contactsString == null) return [];
      
      final contactsList = jsonDecode(contactsString) as List;
      return contactsList
          .map((contactMap) => ContactInfo.fromMap(contactMap))
          .toList();
    } catch (e) {
      print('Error loading FROM contacts: $e');
      return [];
    }
  }
  
  // Search contacts by name
  Future<List<ContactInfo>> searchByName(String query) async {
    final contacts = await getFromContacts();
    if (query.isEmpty) return contacts;
    
    final lowercaseQuery = query.toLowerCase();
    return contacts.where((contact) => 
      contact.name.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
  
  // Search contacts by phone number
  Future<List<ContactInfo>> searchByPhone(String query) async {
    final contacts = await getFromContacts();
    if (query.isEmpty) return contacts;
    
    return contacts.where((contact) => 
      contact.phoneNumber1.contains(query) || 
      contact.phoneNumber2.contains(query)
    ).toList();
  }
  
  // Get contact by exact name match
  Future<ContactInfo?> getContactByName(String name) async {
    final contacts = await getFromContacts();
    try {
      return contacts.firstWhere((contact) => 
        contact.name.toLowerCase() == name.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }
  
  // Get contact by phone number
  Future<ContactInfo?> getContactByPhone(String phone) async {
    final contacts = await getFromContacts();
    try {
      return contacts.firstWhere((contact) => 
        contact.phoneNumber1 == phone || contact.phoneNumber2 == phone
      );
    } catch (e) {
      return null;
    }
  }
  
  // Delete a FROM contact
  Future<void> deleteFromContact(ContactInfo contact) async {
    try {
      final contacts = await getFromContacts();
      contacts.removeWhere((c) => 
        c.name == contact.name && c.phoneNumber1 == contact.phoneNumber1
      );
      await _saveContacts(contacts);
    } catch (e) {
      print('Error deleting FROM contact: $e');
    }
  }
  
  // Clear all FROM contacts
  Future<void> clearAllFromContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fromContactsKey);
    } catch (e) {
      print('Error clearing FROM contacts: $e');
    }
  }
  
  // Private method to save contacts list
  Future<void> _saveContacts(List<ContactInfo> contacts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = contacts.map((contact) => contact.toMap()).toList();
      await prefs.setString(_fromContactsKey, jsonEncode(contactsJson));
    } catch (e) {
      print('Error saving contacts: $e');
    }
  }
  
  // Get most recently used FROM contacts (for quick access)
  Future<List<ContactInfo>> getRecentFromContacts({int limit = 5}) async {
    final contacts = await getFromContacts();
    // Reverse to get most recent first (since we add to the end)
    return contacts.reversed.take(limit).toList();
  }
}
