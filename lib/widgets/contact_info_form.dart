import 'package:flutter/material.dart';
import '../models/contact_info.dart';
import '../services/from_contact_service.dart';

class ContactInfoForm extends StatefulWidget {
  final ContactInfo contactInfo;
  final String title;
  final ValueChanged<ContactInfo> onChanged;
  final bool isFromContact;

  const ContactInfoForm({
    super.key,
    required this.contactInfo,
    required this.title,
    required this.onChanged,
    this.isFromContact = false,
  });

  @override
  State<ContactInfoForm> createState() => _ContactInfoFormState();
}

class _ContactInfoFormState extends State<ContactInfoForm> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phone1Controller;
  late TextEditingController _phone2Controller;
  
  final FromContactService _fromContactService = FromContactService();
  List<ContactInfo> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contactInfo.name);
    _addressController = TextEditingController(text: widget.contactInfo.address);
    _phone1Controller = TextEditingController(text: widget.contactInfo.phoneNumber1);
    _phone2Controller = TextEditingController(text: widget.contactInfo.phoneNumber2);

    _nameController.addListener(_onTextChanged);
    _addressController.addListener(_onTextChanged);
    _phone1Controller.addListener(_onTextChanged);
    _phone2Controller.addListener(_onTextChanged);

    // Add listeners for auto-complete (only for FROM contacts)
    if (widget.isFromContact) {
      _nameController.addListener(_onNameChanged);
      _phone1Controller.addListener(_onPhoneChanged);
    }
  }

  void _onTextChanged() {
    final updatedInfo = ContactInfo(
      name: _nameController.text,
      address: _addressController.text,
      phoneNumber1: _phone1Controller.text,
      phoneNumber2: _phone2Controller.text,
    );
    widget.onChanged(updatedInfo);
  }

  void _onNameChanged() async {
    if (!widget.isFromContact) return;
    
    final query = _nameController.text.trim();
    if (query.length >= 2) {
      final suggestions = await _fromContactService.searchByName(query);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _onPhoneChanged() async {
    if (!widget.isFromContact) return;
    
    final query = _phone1Controller.text.trim();
    if (query.length >= 3) {
      final suggestions = await _fromContactService.searchByPhone(query);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _selectSuggestion(ContactInfo suggestion) {
    setState(() {
      _nameController.text = suggestion.name;
      _addressController.text = suggestion.address;
      _phone1Controller.text = suggestion.phoneNumber1;
      _phone2Controller.text = suggestion.phoneNumber2;
      _showSuggestions = false;
      _suggestions = [];
    });
    _onTextChanged();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.isFromContact)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Name Field with Auto-complete
            Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: widget.isFromContact && _showSuggestions
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _showSuggestions = false;
                                _suggestions = [];
                              });
                            },
                          )
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                
                // Suggestions dropdown
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.history, size: 16),
                          title: Text(suggestion.name),
                          subtitle: Text(
                            '${suggestion.formattedPhones}\n${suggestion.address}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Address Field
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: widget.isFromContact ? 'Address (Optional)' : 'Address',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                helperText: widget.isFromContact ? 'Address is optional for sender' : null,
              ),
              maxLines: 3,
              validator: (value) {
                // Address is optional for FROM contacts, required for TO contacts
                if (!widget.isFromContact && (value == null || value.isEmpty)) {
                  return 'Please enter an address';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 12),
            
            // Phone Number 1 (Required)
            Column(
              children: [
                TextFormField(
                  controller: _phone1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number 1 *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    helperText: 'Primary phone number (required)',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                
                // Phone suggestions (only show if searching by phone)
                if (_showSuggestions && _suggestions.isNotEmpty && _phone1Controller.text.length >= 3)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 150),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.phone, size: 16),
                          title: Text(suggestion.name),
                          subtitle: Text(suggestion.formattedPhones),
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Phone Number 2 (Optional)
            TextFormField(
              controller: _phone2Controller,
              decoration: const InputDecoration(
                labelText: 'Phone Number 2 (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_outlined),
                helperText: 'Additional phone number',
              ),
              keyboardType: TextInputType.phone,
            ),
            
            // Show recent FROM contacts for quick selection
            if (widget.isFromContact)
              FutureBuilder<List<ContactInfo>>(
                future: _fromContactService.getRecentFromContacts(limit: 3),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Recent FROM contacts:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          children: snapshot.data!.map((contact) {
                            return ActionChip(
                              avatar: const Icon(Icons.history, size: 16),
                              label: Text(
                                contact.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () => _selectSuggestion(contact),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }
}
