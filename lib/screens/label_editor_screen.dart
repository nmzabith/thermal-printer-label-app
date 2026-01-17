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
  final TextEditingController _codAmountController = TextEditingController();
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _label = widget.label;

    // Initialize COD amount controller with formatted value
    if (_label.codAmount > 0) {
      _codAmountController.text = _formatCodAmount(_label.codAmount);
    }

    // If this is a new label with pre-filled data (e.g., from AI extraction),
    // mark it as having changes so it can be saved
    if (widget.isNew &&
        (!_label.toInfo.isEmpty() || !_label.fromInfo.isEmpty())) {
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

  // Format COD amount for display (Rs #####.##)
  String _formatCodAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  // Parse COD amount from input
  double _parseCodAmount(String text) {
    // Remove any non-numeric characters except decimal point
    String cleanText = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanText) ?? 0.0;
  }

  @override
  void dispose() {
    _codAmountController.dispose();
    super.dispose();
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
        content: const Text(
            'You have unsaved changes. Do you want to discard them?'),
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
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text('ID: ${_label.id}'),
                          Text('Created: ${_formatDate(_label.createdAt)}'),
                          Text(
                              'Status: ${_label.isReadyToPrint() ? "Ready to Print" : "Incomplete"}'),
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

                const SizedBox(height: 16),

                // COD Settings Card
                Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.payments, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Cash on Delivery (COD)',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          title: const Text('Enable COD'),
                          subtitle: const Text('Customer will pay on delivery'),
                          value: _label.codEnabled,
                          onChanged: (value) {
                            setState(() {
                              _label.codEnabled = value ?? false;
                              _hasChanges = true;
                              // Clear amount if COD is disabled
                              if (!_label.codEnabled) {
                                _label.codAmount = 0.0;
                                _codAmountController.clear();
                              }
                            });
                          },
                          secondary: const Icon(Icons.check_circle_outline),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_label.codEnabled) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _codAmountController,
                            decoration: const InputDecoration(
                              labelText: 'COD Amount',
                              hintText: '0.00',
                              prefixText: 'Rs ',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money),
                              helperText:
                                  'Enter amount in LKR (Sri Lankan Rupee)',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (_label.codEnabled &&
                                  (value == null || value.isEmpty)) {
                                return 'Please enter COD amount';
                              }
                              if (_label.codEnabled) {
                                double? amount = _parseCodAmount(value!);
                                if (amount <= 0) {
                                  return 'Amount must be greater than 0';
                                }
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _label.codAmount = _parseCodAmount(value);
                                _hasChanges = true;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _label.codAmount > 0
                                        ? 'COD Amount: Rs ${_formatCodAmount(_label.codAmount)} will be printed on the label.'
                                        : 'Enter the amount to be collected on delivery.',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Logo Settings Card
                Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.image, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Logo Settings',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Include Logo'),
                          subtitle:
                              const Text('Add logo to the bottom right corner'),
                          value: _label.includeLogo,
                          onChanged: (value) {
                            setState(() {
                              _label.includeLogo = value;
                              _hasChanges = true;
                            });
                          },
                          secondary: const Icon(Icons.image_outlined),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_label.includeLogo) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Logo will be added from your default logo settings or FROM contact logo configuration.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
                        child:
                            Text(widget.isNew ? 'Add Label' : 'Save Changes'),
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
