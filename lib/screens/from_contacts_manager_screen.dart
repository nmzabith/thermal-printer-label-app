import 'package:flutter/material.dart';
import '../models/contact_info.dart';
import '../services/from_contact_service.dart';
import '../widgets/material3_components.dart';

class FromContactsManagerScreen extends StatefulWidget {
  const FromContactsManagerScreen({super.key});

  @override
  State<FromContactsManagerScreen> createState() =>
      _FromContactsManagerScreenState();
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
          SnackBar(
            content: Text('Error loading FROM contacts: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteContact(ContactInfo contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete FROM Contact',
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
        content: Text('Are you sure you want to delete: ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          Material3Components.enhancedButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Delete',
            isPrimary: false,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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
            SnackBar(
              content: const Text('FROM contact deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting contact: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllContacts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All FROM Contacts',
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
        content: const Text(
            'Are you sure you want to delete all saved FROM contacts? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          Material3Components.enhancedButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Clear All',
            isPrimary: false,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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
            SnackBar(
              content: const Text('All FROM contacts cleared'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error clearing contacts: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showContactDetails(ContactInfo contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact.name,
            style: Theme.of(context).textTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address:', style: Theme.of(context).textTheme.titleSmall),
            Text(contact.address,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text('Phone Numbers:',
                style: Theme.of(context).textTheme.titleSmall),
            if (contact.phoneNumber1.isNotEmpty)
              Text('Primary: ${contact.phoneNumber1}',
                  style: Theme.of(context).textTheme.bodyMedium),
            if (contact.phoneNumber2.isNotEmpty)
              Text('Secondary: ${contact.phoneNumber2}',
                  style: Theme.of(context).textTheme.bodyMedium),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('FROM Contacts', style: textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 3,
        actions: [
          if (_fromContacts.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
              onSelected: (value) {
                if (value == 'clear_all') {
                  _clearAllContacts();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Text('Clear All',
                          style: TextStyle(color: colorScheme.error)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: Material3Components.enhancedProgressIndicator())
          : _fromContacts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.contact_phone_outlined,
                          size: 64,
                          color: colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No FROM contacts saved',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'FROM contact information will be automatically saved when you create labels',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Info card
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              colorScheme.secondaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: colorScheme.secondaryContainer),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: colorScheme.secondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'These contacts are automatically saved when you enter FROM information and will appear as suggestions for future labels.',
                                style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer),
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
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, bottom: 16),
                          itemCount: _fromContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _fromContacts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Material3Components.enhancedListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Icon(Icons.person,
                                      color: colorScheme.onPrimaryContainer),
                                ),
                                title: contact.name,
                                subtitle:
                                    '${contact.address}\n${contact.formattedPhones}',
                                trailing: PopupMenuButton<String>(
                                  icon: Icon(Icons.more_vert,
                                      color: colorScheme.onSurfaceVariant),
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
                                          Icon(Icons.info_outline),
                                          SizedBox(width: 8),
                                          Text('Details'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline,
                                              color: colorScheme.error),
                                          const SizedBox(width: 8),
                                          Text('Delete',
                                              style: TextStyle(
                                                  color: colorScheme.error)),
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
