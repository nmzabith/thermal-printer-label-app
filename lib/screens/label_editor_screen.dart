import 'package:flutter/material.dart';
import '../models/shipping_label.dart';
import '../models/contact_info.dart';
import '../widgets/contact_info_form.dart';
import '../services/from_contact_service.dart';
import '../widgets/material3_components.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isNew ? 'New Label' : 'Edit Label'),
          backgroundColor: colorScheme.surface,
          scrolledUnderElevation: 3,
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const VisualLabelDesignerScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.design_services_outlined),
              tooltip: 'Visual Designer',
            ),
            TextButton(
              onPressed: _saveLabel,
              child: Text(
                'SAVE',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Label Info Card
                if (!widget.isNew)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Material3Components.enhancedCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Label Information',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow(Icons.fingerprint, 'ID: ${_label.id}',
                                colorScheme, textTheme),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                                Icons.calendar_today,
                                'Created: ${_formatDate(_label.createdAt)}',
                                colorScheme,
                                textTheme),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                                _label.isReadyToPrint()
                                    ? Icons.check_circle
                                    : Icons.warning,
                                'Status: ${_label.isReadyToPrint() ? "Ready to Print" : "Incomplete"}',
                                colorScheme,
                                textTheme,
                                iconColor: _label.isReadyToPrint()
                                    ? Colors.green
                                    : Colors.orange),
                          ],
                        ),
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
                Material3Components.enhancedCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_outlined,
                                color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Cash on Delivery (COD)',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Enable COD'),
                          subtitle: const Text('Customer will pay on delivery'),
                          value: _label.codEnabled,
                          onChanged: (value) {
                            setState(() {
                              _label.codEnabled = value;
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
                          activeColor: colorScheme.primary,
                        ),
                        if (_label.codEnabled) ...[
                          const SizedBox(height: 16),
                          Material3Components.enhancedTextField(
                            controller: _codAmountController,
                            label: 'COD Amount',
                            hint: '0.00',
                            prefixIcon: const Icon(Icons
                                .currency_rupee), // Using generic currency or Rupee icon as requested
                            helperText:
                                'Enter amount in LKR (Sri Lankan Rupee)',
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
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer
                                  .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: colorScheme.tertiaryContainer),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: colorScheme.onTertiaryContainer,
                                    size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _label.codAmount > 0
                                        ? 'COD Amount: Rs ${_formatCodAmount(_label.codAmount)} will be printed.'
                                        : 'Enter the amount to be collected.',
                                    style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onTertiaryContainer),
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
                Material3Components.enhancedCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.image_outlined,
                                color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Logo Settings',
                              style: textTheme.titleMedium?.copyWith(
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
                          activeColor: colorScheme.primary,
                        ),
                        if (_label.includeLogo) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.surfaceVariant.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Logo will be added from your default logo settings.',
                                    style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant),
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

                // Thanks Message Card
                Material3Components.enhancedCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite_border,
                                color: colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Thanks Message',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Include Thanks Message'),
                          subtitle:
                              const Text('Show message at bottom of label'),
                          value: _label.includeThanksMessage,
                          onChanged: (value) {
                            setState(() {
                              _label.includeThanksMessage = value;
                              _hasChanges = true;
                            });
                          },
                          secondary: const Icon(Icons.message_outlined),
                          contentPadding: EdgeInsets.zero,
                          activeColor: colorScheme.primary,
                        ),
                        if (_label.includeThanksMessage) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.surfaceVariant.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Message will be centered at the bottom of the label.',
                                    style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant),
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

                // Beta Features Card (for testing only)
                Material3Components.enhancedCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.science_outlined, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'Beta Features',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'TESTING',
                                style: textTheme.labelSmall?.copyWith(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Delivery Label Format'),
                          subtitle: const Text(
                              'Use alternative layout with logo header, dividers, and SHIP FROM/TO sections'),
                          value: _label.useBetaDeliveryFormat,
                          onChanged: (value) {
                            setState(() {
                              _label.useBetaDeliveryFormat = value;
                              _hasChanges = true;
                            });
                          },
                          secondary: const Icon(Icons.local_shipping_outlined),
                          contentPadding: EdgeInsets.zero,
                          activeColor: Colors.orange,
                        ),
                        if (_label.useBetaDeliveryFormat) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.orange.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Will print with CF Sri Lanka Online Store header, logo, and SHIP FROM/TO layout.',
                                    style: textTheme.bodySmall?.copyWith(
                                        color: Colors.orange.shade700),
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

                const SizedBox(height: 32),

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
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: colorScheme.outline),
                        ),
                        child: Text('Cancel',
                            style: TextStyle(color: colorScheme.onSurface)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Material3Components.enhancedButton(
                        onPressed: _saveLabel,
                        label: widget.isNew ? 'Add Label' : 'Save Changes',
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon, String text, ColorScheme colorScheme, TextTheme textTheme,
      {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          text,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
