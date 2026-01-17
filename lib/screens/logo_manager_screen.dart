import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/logo_config.dart';
import '../services/logo_service.dart';
import '../widgets/material3_components.dart';

class LogoManagerScreen extends StatefulWidget {
  const LogoManagerScreen({super.key});

  @override
  State<LogoManagerScreen> createState() => _LogoManagerScreenState();
}

class _LogoManagerScreenState extends State<LogoManagerScreen> {
  final LogoService _logoService = LogoService();
  LogoConfig _currentLogoConfig = LogoConfig.empty();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentLogo();
  }

  Future<void> _loadCurrentLogo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final config = await _logoService.getDefaultLogoConfig();
      setState(() {
        _currentLogoConfig = config;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading logo configuration: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLogo(LogoConfig config) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _logoService.saveDefaultLogoConfig(config);
      setState(() {
        _currentLogoConfig = config;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Logo configuration saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving logo: $e')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final config = await _logoService.pickImageFromGallery();
      if (config != null) {
        await _saveLogo(config);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final config = await _logoService.pickImageFromCamera();
      if (config != null) {
        await _saveLogo(config);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromFiles() async {
    try {
      final config = await _logoService.pickImageFile();
      if (config != null) {
        await _saveLogo(config);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Logo Source',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading:
                        const Icon(Icons.photo_library, color: Colors.blue),
                    title: const Text('Photo Gallery'),
                    subtitle: const Text('Choose from your photos'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: Colors.green),
                    title: const Text('Camera'),
                    subtitle: const Text('Take a new photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder, color: Colors.orange),
                    title: const Text('File Browser'),
                    subtitle: const Text('Choose an image file'),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromFiles();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteLogo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Logo'),
        content: const Text(
            'Are you sure you want to delete the current logo? This action cannot be undone.'),
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
        await _logoService.deleteLogo(_currentLogoConfig);
        await _saveLogo(LogoConfig.empty());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting logo: $e')),
          );
        }
      }
    }
  }

  void _showLogoSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => LogoSettingsSheet(
        config: _currentLogoConfig,
        onSave: _saveLogo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logo Manager'),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 3,
        actions: [
          if (_currentLogoConfig.hasLogo)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: _showLogoSettings,
              tooltip: 'Logo Settings',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentLogo,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Material3Components.enhancedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Configure your default logo that will appear on the bottom right corner of your shipping labels.',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Logo Section
                  Text(
                    'Current Logo',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logo Display
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(16),
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    child: _currentLogoConfig.hasLogo
                        ? _buildLogoPreview()
                        : _buildNoLogoPlaceholder(),
                  ),
                  const SizedBox(height: 16),

                  // Logo Info
                  if (_currentLogoConfig.hasLogo) ...[
                    Material3Components.enhancedCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.image, color: colorScheme.secondary),
                                const SizedBox(width: 8),
                                Text(
                                  'Logo Information',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                                'File Name',
                                _currentLogoConfig.originalFileName ??
                                    'Unknown'),
                            _buildInfoRow('Size',
                                '${_currentLogoConfig.width.toStringAsFixed(1)} x ${_currentLogoConfig.height.toStringAsFixed(1)} mm'),
                            _buildInfoRow('Opacity',
                                '${(_currentLogoConfig.opacity * 100).toInt()}%'),
                            _buildInfoRow(
                                'Status',
                                _currentLogoConfig.isEnabled
                                    ? 'Enabled'
                                    : 'Disabled'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Enable/Disable Toggle
                    Material3Components.enhancedCard(
                      child: SwitchListTile(
                        title: const Text('Enable Logo by Default'),
                        subtitle: const Text(
                            'New labels will include the logo by default'),
                        value: _currentLogoConfig.isEnabled,
                        onChanged: _isSaving
                            ? null
                            : (value) {
                                final updatedConfig = _currentLogoConfig
                                    .copyWith(isEnabled: value);
                                _saveLogo(updatedConfig);
                              },
                        secondary: const Icon(Icons.visibility_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Thanks Message Section (always visible)
                  Text(
                    'Thanks Message',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Material3Components.enhancedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.favorite, color: Colors.pink.shade300),
                              const SizedBox(width: 8),
                              Text(
                                'Message at Bottom of Labels',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Enable Thanks Message'),
                            subtitle: const Text(
                                'Show message on all labels by default'),
                            value: _currentLogoConfig.thanksMessageEnabled,
                            onChanged: _isSaving
                                ? null
                                : (value) {
                                    final updatedConfig =
                                        _currentLogoConfig.copyWith(
                                      thanksMessageEnabled: value,
                                    );
                                    _saveLogo(updatedConfig);
                                  },
                            secondary: const Icon(Icons.message_outlined),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_currentLogoConfig.thanksMessageEnabled) ...[
                            const SizedBox(height: 16),
                            Material3Components.enhancedTextField(
                              label: 'Message',
                              hint: 'Thanks for shopping with us.',
                              initialValue: _currentLogoConfig.thanksMessage,
                              onChanged: (value) {
                                final updatedConfig =
                                    _currentLogoConfig.copyWith(
                                  thanksMessage: value.trim(),
                                );
                                _saveLogo(updatedConfig);
                              },
                              maxLines: 2,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This message will be centered at the bottom of each label',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Text(
                    'Actions',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add/Replace Logo Button
                  SizedBox(
                    width: double.infinity,
                    child: Material3Components.enhancedButton(
                      onPressed: _isSaving ? null : _showImageSourceDialog,
                      icon: Icon(_currentLogoConfig.hasLogo
                          ? Icons.refresh
                          : Icons.add_photo_alternate_outlined),
                      label: _currentLogoConfig.hasLogo
                          ? 'Replace Logo'
                          : 'Add Logo',
                      isPrimary: true,
                    ),
                  ),

                  if (_currentLogoConfig.hasLogo) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Material3Components.enhancedButton(
                        onPressed: _isSaving ? null : _deleteLogo,
                        icon: const Icon(Icons.delete_outline),
                        label: 'Delete Logo',
                        isPrimary: false,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Usage Guidelines
                  Material3Components.enhancedCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Tips for Best Results',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildTipRow(
                              'Use high contrast images (black on white works best)'),
                          _buildTipRow(
                              'Square or rectangular logos work better'),
                          _buildTipRow('Maximum file size: 500KB'),
                          _buildTipRow(
                              'Supported formats: JPG, PNG, BMP, GIF, WebP'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildTipRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildLogoPreview() {
    if (_currentLogoConfig.imageData != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _currentLogoConfig.imageData!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildNoLogoPlaceholder();
          },
        ),
      );
    } else {
      return _buildNoLogoPlaceholder();
    }
  }

  Widget _buildNoLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.image_outlined,
          size: 64,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 16),
        Text(
          'No logo configured',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap "Add Logo" to get started',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

// Logo Settings Sheet
class LogoSettingsSheet extends StatefulWidget {
  final LogoConfig config;
  final Function(LogoConfig) onSave;

  const LogoSettingsSheet({
    super.key,
    required this.config,
    required this.onSave,
  });

  @override
  State<LogoSettingsSheet> createState() => _LogoSettingsSheetState();
}

class _LogoSettingsSheetState extends State<LogoSettingsSheet> {
  late double _width;
  late double _height;
  late double _opacity;
  late bool _isEnabled;
  late String _thanksMessage;
  late bool _thanksMessageEnabled;
  bool _maintainAspectRatio = true;
  late double _originalAspectRatio;
  final TextEditingController _thanksMessageController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _width = widget.config.width;
    _height = widget.config.height;
    _opacity = widget.config.opacity;
    _isEnabled = widget.config.isEnabled;
    _thanksMessage = widget.config.thanksMessage;
    _thanksMessageEnabled = widget.config.thanksMessageEnabled;
    _thanksMessageController.text = _thanksMessage;
    _originalAspectRatio = _width / _height;
  }

  @override
  void dispose() {
    _thanksMessageController.dispose();
    super.dispose();
  }

  void _save() {
    final updatedConfig = widget.config.copyWith(
      width: _width,
      height: _height,
      opacity: _opacity,
      isEnabled: _isEnabled,
      thanksMessage: _thanksMessageController.text.trim(),
      thanksMessageEnabled: _thanksMessageEnabled,
    );
    widget.onSave(updatedConfig);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Logo Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Size Settings
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Size (mm)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Maintain Aspect Ratio Toggle
                            CheckboxListTile(
                              title: const Text('Maintain aspect ratio'),
                              value: _maintainAspectRatio,
                              onChanged: (value) {
                                setState(() {
                                  _maintainAspectRatio = value ?? true;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),

                            // Width Slider
                            Text('Width: ${_width.toStringAsFixed(1)} mm'),
                            Slider(
                              value: _width,
                              min: 5.0,
                              max: 25.0,
                              divisions: 40,
                              onChanged: (value) {
                                setState(() {
                                  _width = value;
                                  if (_maintainAspectRatio) {
                                    _height = _width / _originalAspectRatio;
                                    if (_height > 25.0) {
                                      _height = 25.0;
                                      _width = _height * _originalAspectRatio;
                                    }
                                  }
                                });
                              },
                            ),

                            // Height Slider
                            Text('Height: ${_height.toStringAsFixed(1)} mm'),
                            Slider(
                              value: _height,
                              min: 5.0,
                              max: 25.0,
                              divisions: 40,
                              onChanged: (value) {
                                setState(() {
                                  _height = value;
                                  if (_maintainAspectRatio) {
                                    _width = _height * _originalAspectRatio;
                                    if (_width > 25.0) {
                                      _width = 25.0;
                                      _height = _width / _originalAspectRatio;
                                    }
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Opacity Settings
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Opacity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('Opacity: ${(_opacity * 100).toInt()}%'),
                            Slider(
                              value: _opacity,
                              min: 0.1,
                              max: 1.0,
                              divisions: 9,
                              onChanged: (value) {
                                setState(() {
                                  _opacity = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Enable/Disable
                    Card(
                      child: SwitchListTile(
                        title: const Text('Enable by Default'),
                        subtitle:
                            const Text('New labels will include this logo'),
                        value: _isEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isEnabled = value;
                          });
                        },
                        secondary: const Icon(Icons.visibility),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Thanks Message Settings
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Thanks Message',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text('Show Thanks Message'),
                              subtitle: const Text(
                                  'Display message at bottom of labels'),
                              value: _thanksMessageEnabled,
                              onChanged: (value) {
                                setState(() {
                                  _thanksMessageEnabled = value;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_thanksMessageEnabled) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _thanksMessageController,
                                decoration: const InputDecoration(
                                  labelText: 'Message',
                                  hintText: 'Thanks for shopping with us.',
                                  border: OutlineInputBorder(),
                                  helperText:
                                      'This message will be centered at the bottom of each label',
                                ),
                                maxLines: 2,
                                maxLength: 100,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
