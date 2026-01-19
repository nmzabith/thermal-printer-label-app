import 'package:flutter/material.dart';
import '../models/label_config.dart';
import '../services/label_config_service.dart';
import '../widgets/material3_components.dart';

class LabelSettingsScreen extends StatefulWidget {
  const LabelSettingsScreen({super.key});

  @override
  State<LabelSettingsScreen> createState() => _LabelSettingsScreenState();
}

class _LabelSettingsScreenState extends State<LabelSettingsScreen> {
  final LabelConfigService _configService = LabelConfigService.instance;
  LabelConfig? _currentConfig;
  List<LabelConfig> _availableConfigs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
  }

  /// Load current configuration and available options
  Future<void> _loadConfigurations() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final currentConfig = await _configService.getCurrentConfig();
      final availableConfigs = await _configService.getAllConfigs();

      if (mounted) {
        setState(() {
          _currentConfig = currentConfig;
          _availableConfigs = availableConfigs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading configurations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Save selected configuration
  Future<void> _saveConfiguration(LabelConfig config) async {
    try {
      bool success = await _configService.saveCurrentConfig(config);

      if (success && mounted) {
        setState(() {
          _currentConfig = config;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Label size updated to ${config.name}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save label configuration'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving configuration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Reset to default configuration
  Future<void> _resetToDefault() async {
    try {
      bool success = await _configService.resetToDefault();

      if (success) {
        await _loadConfigurations(); // Reload configurations

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Reset to default label size'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error resetting configuration: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Label Settings', style: textTheme.titleLarge),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateCustomLabelDialog,
            tooltip: 'Create Custom Label',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfigurations,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _showResetDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore,
                        size: 20, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('Reset to Default', style: textTheme.bodyLarge),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: Material3Components.enhancedProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Configuration Card
                  Material3Components.enhancedCard(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.label,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current Label Configuration',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_currentConfig != null) ...[
                            _buildConfigDetails(_currentConfig!),
                          ] else ...[
                            Text('No configuration loaded',
                                style: textTheme.bodyLarge),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Available Configurations
                  Text(
                    'Available Label Sizes',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),

                  ..._availableConfigs.map((config) {
                    final isSelected = _currentConfig?.name == config.name;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Material3Components.enhancedListTile(
                        leading: Icon(
                          Icons.label_outline,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          size: 28,
                        ),
                        title: config.name,
                        subtitle:
                            '${config.description}\nSize: ${config.widthMm}mm × ${config.heightMm}mm | Gap: ${config.spacingMm}mm',
                        isSelected: isSelected,
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: colorScheme.primary)
                            : Icon(Icons.arrow_forward_ios,
                                size: 16, color: colorScheme.onSurfaceVariant),
                        onTap: () {
                          if (!isSelected) {
                            _showConfirmDialog(config);
                          }
                        },
                      ),
                    );
                  }),

                  // Help Text
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.secondaryContainer),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: colorScheme.secondary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Label Configuration Help',
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Select label size that matches your physical thermal labels\n'
                          '• Smaller labels (50mm height) use compact layout\n'
                          '• Larger labels (80mm+ height) include full header and details\n'
                          '• Gap setting controls spacing between printed labels\n'
                          '• Changes apply to all new prints immediately',
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Build configuration details widget
  Widget _buildConfigDetails(LabelConfig config) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                config.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ACTIVE',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(config.description, style: textTheme.bodyMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDetailChip('Width', '${config.widthMm}mm'),
              _buildDetailChip('Height', '${config.heightMm}mm'),
              _buildDetailChip('Gap', '${config.spacingMm}mm'),
            ],
          ),
        ],
      ),
    );
  }

  /// Build detail chip widget
  Widget _buildDetailChip(String label, String value) {
    return Material3Components.enhancedChip(
      label: '$label: $value',
      isSelected: false,
    );
  }

  /// Show confirmation dialog before changing configuration
  void _showConfirmDialog(LabelConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Label Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch to ${config.name}?',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              config.description,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Text(
              'Dimensions: ${config.widthMm}mm × ${config.heightMm}mm',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Label spacing: ${config.spacingMm}mm',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Material3Components.enhancedButton(
            label: 'Apply',
            onPressed: () {
              Navigator.of(context).pop();
              _saveConfiguration(config);
            },
          ),
        ],
      ),
    );
  }

  /// Show reset to default dialog
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Default'),
        content: const Text(
          'This will reset the label configuration to the default size (80mm × 50mm). Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Material3Components.enhancedButton(
            label: 'Reset',
            onPressed: () {
              Navigator.of(context).pop();
              _resetToDefault();
            },
            isPrimary: false,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// Show create custom label dialog
  void _showCreateCustomLabelDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomLabelDialog(
        onSaved: (config) {
          _saveConfiguration(config);
          _loadConfigurations(); // Reload to show the new custom config
        },
      ),
    );
  }
}

/// Dialog for creating custom label configurations
class CustomLabelDialog extends StatefulWidget {
  final Function(LabelConfig) onSaved;

  const CustomLabelDialog({super.key, required this.onSaved});

  @override
  State<CustomLabelDialog> createState() => _CustomLabelDialogState();
}

class _CustomLabelDialogState extends State<CustomLabelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _spacingController = TextEditingController(text: '2.0');

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _spacingController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomLabel() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final width = double.parse(_widthController.text);
    final height = double.parse(_heightController.text);
    final spacing = double.parse(_spacingController.text);

    // Check if name already exists
    final exists = await LabelConfigService.instance.customConfigExists(name);
    if (exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('A label with this name already exists'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final config = LabelConfig(
      name: name,
      description: description,
      widthMm: width,
      heightMm: height,
      spacingMm: spacing,
    );

    final success = await LabelConfigService.instance.saveCustomConfig(config);

    if (success && mounted) {
      Navigator.of(context).pop();
      widget.onSaved(config);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Custom label "$name" created successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to create custom label'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_box, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Create Custom Label'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material3Components.enhancedTextField(
                label: 'Label Name',
                hint: 'e.g., Custom 75x40',
                controller: _nameController,
                prefixIcon: const Icon(Icons.label_outline),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a label name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Material3Components.enhancedTextField(
                label: 'Description',
                hint: 'Optional description',
                controller: _descriptionController,
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Material3Components.enhancedTextField(
                      label: 'Width (mm)',
                      hint: '80',
                      controller: _widthController,
                      prefixIcon: const Icon(Icons.straighten),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final width = double.tryParse(value);
                        if (width == null || width <= 0) {
                          return 'Invalid';
                        }
                        if (width > 105) {
                          return 'Max 105mm';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Material3Components.enhancedTextField(
                      label: 'Height (mm)',
                      hint: '50',
                      controller: _heightController,
                      prefixIcon: const Icon(Icons.height),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height <= 0) {
                          return 'Invalid';
                        }
                        if (height > 200) {
                          return 'Max 200mm';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Material3Components.enhancedTextField(
                label: 'Gap (mm)',
                hint: '2.0',
                controller: _spacingController,
                prefixIcon: const Icon(Icons.space_bar),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final spacing = double.tryParse(value);
                  if (spacing == null || spacing < 0) {
                    return 'Invalid';
                  }
                  if (spacing > 10) {
                    return 'Max 10mm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.tertiaryContainer),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: colorScheme.tertiary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Size Constraints',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.tertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Maximum width: 105mm\n'
                      '• Maximum height: 200mm\n'
                      '• Gap range: 0-10mm',
                      style: TextStyle(
                          fontSize: 11, color: colorScheme.onTertiaryContainer),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Material3Components.enhancedButton(
          label: 'Create',
          onPressed: _saveCustomLabel,
        ),
      ],
    );
  }
}
