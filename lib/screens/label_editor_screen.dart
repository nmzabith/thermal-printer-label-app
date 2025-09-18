import 'package:flutter/material.dart';
import '../models/shipping_label.dart';
import '../models/contact_info.dart';
import '../widgets/contact_info_form.dart';
import '../services/from_contact_service.dart';
import 'visual_label_designer_screen.dart';

class LabelEditorScreen extends StatefulWidget {
  final ShippingLabel label;
  final bool isNew;

  const LabelEditorScreen({
    super.key,
    required this.label,
    required this.isNew,
  });

  @override
  State<LabelEditorScreen> createState() => _LabelEditorScreenState();
}

class _LabelEditorScreenState extends State<LabelEditorScreen> {
  late ShippingLabel _label;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FromContactService _fromContactService = FromContactService();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _label = widget.label;
    
    // If this is a new label with pre-filled data (e.g., from AI extraction),
    // mark it as having changes so it can be saved
    if (widget.isNew && (!_label.toInfo.isEmpty() || !_label.fromInfo.isEmpty())) {
      _hasChanges = true;
    }
  }

  void _onFromInfoChanged(ContactInfo fromInfo) {
    setState(() {
      _label.fromInfo = fromInfo;
      _hasChanges = true;
    });
  }

  void _onToInfoChanged(ContactInfo toInfo) {
    setState(() {
      _label.toInfo = toInfo;
      _hasChanges = true;
    });
  }

  bool _validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  void _saveLabel() async {
    if (_validateForm() && _hasChanges) {
      // Save FROM contact for future auto-complete
      if (_label.fromInfo.isComplete()) {
        await _fromContactService.saveFromContact(_label.fromInfo);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else if (!_hasChanges) {
      Navigator.of(context).pop(false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isNew ? 'New Label' : 'Edit Label'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VisualLabelDesignerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.design_services),
              tooltip: 'Visual Designer',
            ),
            TextButton(
              onPressed: _saveLabel,
              child: const Text(
                'SAVE',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Label Info Card
                if (!widget.isNew)
                  Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Label Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('ID: ${_label.id}'),
                          Text('Created: ${_formatDate(_label.createdAt)}'),
                          Text('Status: ${_label.isReadyToPrint() ? "Ready to Print" : "Incomplete"}'),
                        ],
                      ),
                    ),
                  ),

                ContactInfoForm(
                  contactInfo: _label.fromInfo,
                  title: 'FROM Information',
                  onChanged: _onFromInfoChanged,
                  isFromContact: true, // Enable auto-complete for FROM
                ),
                
                const SizedBox(height: 16),
                
                ContactInfoForm(
                  contactInfo: _label.toInfo,
                  title: 'TO Information',
                  onChanged: _onToInfoChanged,
                  isFromContact: false, // No auto-complete for TO
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final shouldPop = await _onWillPop();
                          if (shouldPop && mounted) {
                            Navigator.of(context).pop(false);
                          }
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveLabel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(widget.isNew ? 'Add Label' : 'Save Changes'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100), // Space for bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
