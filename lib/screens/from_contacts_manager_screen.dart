import 'package:flutter/material.dart';
import '../models/contact_info.dart';
import '../services/from_contact_service.dart';

class FromContactsManagerScreen extends StatefulWidget {
  const FromContactsManagerScreen({super.key});

  @override
  State<FromContactsManagerScreen> createState() => _FromContactsManagerScreenState();
}

class _FromContactsManagerScreenState extends State<FromContactsManagerScreen> {
  final FromContactService _fromContactService = FromContactService();
  List<ContactInfo> _fromContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFromContacts();
  }

  Future<void> _loadFromContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final contacts = await _fromContactService.getFromContacts();
      setState(() {
        _fromContacts = contacts.reversed.toList(); // Most recent first
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading FROM contacts: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteContact(ContactInfo contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete FROM Contact'),
        content: Text('Are you sure you want to delete: ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _fromContactService.deleteFromContact(contact);
        await _loadFromContacts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('FROM contact deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting contact: $e')),
          );
        }
      }
    }
  }

  Future<void> _clearAllContacts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All FROM Contacts'),
        content: const Text('Are you sure you want to delete all saved FROM contacts? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _fromContactService.clearAllFromContacts();
        await _loadFromContacts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All FROM contacts cleared')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing contacts: $e')),
          );
        }
      }
    }
  }

  void _showContactDetails(ContactInfo contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Address:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(contact.address),
            const SizedBox(height: 8),
            const Text('Phone Numbers:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (contact.phoneNumber1.isNotEmpty)
              Text('Primary: ${contact.phoneNumber1}'),
            if (contact.phoneNumber2.isNotEmpty)
              Text('Secondary: ${contact.phoneNumber2}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FROM Contacts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_fromContacts.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_all') {
                  _clearAllContacts();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear All'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _fromContacts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.contact_phone_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No FROM contacts saved',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'FROM contact information will be automatically saved when you create labels',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Info card
                    Card(
                      margin: const EdgeInsets.all(8.0),
                      color: Colors.blue.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'These contacts are automatically saved when you enter FROM information and will appear as suggestions for future labels.',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Contacts list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadFromContacts,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _fromContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _fromContacts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                title: Text(contact.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      contact.formattedPhones,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'details':
                                        _showContactDetails(contact);
                                        break;
                                      case 'delete':
                                        _deleteContact(contact);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'details',
                                      child: Row(
                                        children: [
                                          Icon(Icons.info),
                                          SizedBox(width: 8),
                                          Text('Details'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _showContactDetails(contact),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
