import 'package:flutter/material.dart';
import '../models/font_settings.dart';
import '../services/font_settings_service.dart';

class FontSettingsScreen extends StatefulWidget {
  const FontSettingsScreen({super.key});

  @override
  State<FontSettingsScreen> createState() => _FontSettingsScreenState();
}

class _FontSettingsScreenState extends State<FontSettingsScreen> {
  FontSettings _currentSettings = FontSettings.defaultSettings;
  String? _currentPreset;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await FontSettingsService.instance.getCurrentSettings();
      final preset = await FontSettingsService.instance.getCurrentPreset();
      
      setState(() {
        _currentSettings = settings;
        _currentPreset = preset;
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      print('Error loading font settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!FontSettingsService.instance.validateSettings(_currentSettings)) {
      _showErrorDialog('Invalid Settings', 'Please check your font size values (1-8) and other parameters.');
      return;
    }

    setState(() => _isLoading = true);
    
    final success = await FontSettingsService.instance.saveSettings(_currentSettings);
    
    setState(() => _isLoading = false);
    
    if (success) {
      setState(() {
        _hasChanges = false;
        _currentPreset = null; // Custom settings
      });
      _showSuccessDialog('Settings saved successfully!');
    } else {
      _showErrorDialog('Error', 'Failed to save font settings.');
    }
  }

  Future<void> _applyPreset(String presetName) async {
    setState(() => _isLoading = true);
    
    final success = await FontSettingsService.instance.applyPreset(presetName); // Don't convert to lowercase here
    
    if (success) {
      await _loadSettings();
      _showSuccessDialog('Preset "$presetName" applied successfully!');
    } else {
      setState(() => _isLoading = false);
      _showErrorDialog('Error', 'Failed to apply preset.');
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await _showConfirmDialog(
      'Reset to Default',
      'Are you sure you want to reset all font settings to default values?',
    );
    
    if (confirmed) {
      setState(() => _isLoading = true);
      
      final success = await FontSettingsService.instance.resetToDefault();
      
      if (success) {
        await _loadSettings();
        _showSuccessDialog('Settings reset to default successfully!');
      } else {
        setState(() => _isLoading = false);
        _showErrorDialog('Error', 'Failed to reset settings.');
      }
    }
  }

  void _updateSettings(FontSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
      _hasChanges = true;
      _currentPreset = null;
    });
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Settings'),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveSettings,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPresetSection(),
                  const SizedBox(height: 24),
                  _buildFontSection('TO/FROM Headers', 'header', _currentSettings.headerFontSize, _currentSettings.headerBold),
                  const SizedBox(height: 16),
                  _buildFontSection('Names', 'name', _currentSettings.nameFontSize, _currentSettings.nameBold),
                  const SizedBox(height: 16),
                  _buildFontSection('Address Lines', 'address', _currentSettings.addressFontSize, _currentSettings.addressBold),
                  const SizedBox(height: 16),
                  _buildFontSection('Phone Numbers', 'phone', _currentSettings.phoneFontSize, _currentSettings.phoneBold),
                  const SizedBox(height: 16),
                  _buildFontSection('Label Title', 'labeltitle', _currentSettings.labelTitleFontSize, _currentSettings.labelTitleBold),
                  const SizedBox(height: 24),
                  _buildAdvancedSection(),
                  const SizedBox(height: 24),
                  _buildPreviewSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildPresetSection() {
    final presets = FontSettingsService.instance.getAvailablePresets();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Presets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_currentPreset != null)
              Chip(
                label: Text('Current: $_currentPreset'),
                backgroundColor: Colors.blue.shade100,
              ),
            if (_currentPreset == null && _hasChanges)
              const Chip(
                label: Text('Custom (unsaved changes)'),
                backgroundColor: Colors.orange,
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              children: presets.entries.map((entry) {
                final isActive = _currentPreset == entry.key;
                return ElevatedButton(
                  onPressed: _isLoading ? null : () => _applyPreset(entry.key),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.blue : null,
                    foregroundColor: isActive ? Colors.white : null,
                  ),
                  child: Text(entry.key),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSection(String title, String fontType, int fontSize, bool isBold) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Size: $fontSize'),
                      Slider(
                        value: fontSize.toDouble(),
                        min: 1,
                        max: 8,
                        divisions: 7,
                        label: fontSize.toString(),
                        onChanged: (value) {
                          final newSize = value.round();
                          FontSettings newSettings;
                          
                          switch (fontType) {
                            case 'header':
                              newSettings = _currentSettings.copyWith(headerFontSize: newSize);
                              break;
                            case 'name':
                              newSettings = _currentSettings.copyWith(nameFontSize: newSize);
                              break;
                            case 'address':
                              newSettings = _currentSettings.copyWith(addressFontSize: newSize);
                              break;
                            case 'phone':
                              newSettings = _currentSettings.copyWith(phoneFontSize: newSize);
                              break;
                            case 'labeltitle':
                              newSettings = _currentSettings.copyWith(labelTitleFontSize: newSize);
                              break;
                            // Backward compatibility
                            case 'title':
                              newSettings = _currentSettings.copyWith(labelTitleFontSize: newSize);
                              break;
                            case 'subtitle':
                              newSettings = _currentSettings.copyWith(headerFontSize: newSize);
                              break;
                            case 'content':
                              newSettings = _currentSettings.copyWith(nameFontSize: newSize);
                              break;
                            case 'small':
                              newSettings = _currentSettings.copyWith(phoneFontSize: newSize);
                              break;
                            default:
                              return;
                          }
                          
                          _updateSettings(newSettings);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: SwitchListTile(
                    title: const Text('Bold'),
                    value: isBold,
                    onChanged: (value) {
                      FontSettings newSettings;
                      
                      switch (fontType) {
                        case 'header':
                          newSettings = _currentSettings.copyWith(headerBold: value);
                          break;
                        case 'name':
                          newSettings = _currentSettings.copyWith(nameBold: value);
                          break;
                        case 'address':
                          newSettings = _currentSettings.copyWith(addressBold: value);
                          break;
                        case 'phone':
                          newSettings = _currentSettings.copyWith(phoneBold: value);
                          break;
                        case 'labeltitle':
                          newSettings = _currentSettings.copyWith(labelTitleBold: value);
                          break;
                        // Backward compatibility
                        case 'title':
                          newSettings = _currentSettings.copyWith(labelTitleBold: value);
                          break;
                        case 'subtitle':
                          newSettings = _currentSettings.copyWith(headerBold: value);
                          break;
                        case 'content':
                          newSettings = _currentSettings.copyWith(nameBold: value);
                          break;
                        case 'small':
                          newSettings = _currentSettings.copyWith(phoneBold: value);
                          break;
                        default:
                          return;
                      }
                      
                      _updateSettings(newSettings);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Line Spacing
            Text('Line Spacing Factor: ${_currentSettings.lineSpacingFactor.toStringAsFixed(1)}x'),
            Slider(
              value: _currentSettings.lineSpacingFactor,
              min: 0.5,
              max: 3.0,
              divisions: 25,
              label: '${_currentSettings.lineSpacingFactor.toStringAsFixed(1)}x',
              onChanged: (value) {
                _updateSettings(_currentSettings.copyWith(lineSpacingFactor: value));
              },
            ),
            
            const SizedBox(height: 16),
            
            // Max Address Lines
            Text('Max Address Lines: ${_currentSettings.maxLinesAddress}'),
            Slider(
              value: _currentSettings.maxLinesAddress.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _currentSettings.maxLinesAddress.toString(),
              onChanged: (value) {
                _updateSettings(_currentSettings.copyWith(maxLinesAddress: value.round()));
              },
            ),
            
            const SizedBox(height: 16),
            
            // Auto Sizing Toggle
            SwitchListTile(
              title: const Text('Enable Auto Sizing'),
              subtitle: const Text('Automatically adjust fonts to fit label'),
              value: _currentSettings.enableAutoSizing,
              onChanged: (value) {
                _updateSettings(_currentSettings.copyWith(enableAutoSizing: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Label Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show title only for larger labels
                  if (_currentSettings.labelTitleFontSize >= 3) ...[
                    Center(child: _buildPreviewText('labeltitle', 'SHIPPING LABEL')),
                    SizedBox(height: 4 * _currentSettings.lineSpacingFactor),
                    Center(child: _buildPreviewText('name', '====================')),
                    SizedBox(height: 8 * _currentSettings.lineSpacingFactor),
                  ],
                  
                  // TO section
                  _buildPreviewText('header', 'TO:'),
                  SizedBox(height: 4 * _currentSettings.lineSpacingFactor),
                  _buildPreviewText('name', 'John Doe'),
                  SizedBox(height: 2 * _currentSettings.lineSpacingFactor),
                  _buildPreviewText('address', '123 Main Street'),
                  SizedBox(height: 2 * _currentSettings.lineSpacingFactor),
                  _buildPreviewText('address', 'New York, NY 10001'),
                  SizedBox(height: 2 * _currentSettings.lineSpacingFactor),
                  _buildPreviewText('phone', 'TEL: +1-555-123-4567'),
                  SizedBox(height: 8 * _currentSettings.lineSpacingFactor),
                  
                  // FROM section
                  _buildPreviewText('header', 'FROM:'),
                  SizedBox(height: 4 * _currentSettings.lineSpacingFactor),
                  _buildPreviewText('name', 'ABC Company'),
                  SizedBox(height: 2 * _currentSettings.lineSpacingFactor),
                  _buildPreviewText('address', '456 Business Ave'),
                  SizedBox(height: 2 * _currentSettings.lineSpacingFactor),
                  _buildPreviewText('address', 'Los Angeles, CA 90210'),
                  SizedBox(height: 2 * _currentSettings.lineSpacingFactor),
                  _buildPreviewText('phone', 'TEL: +1-555-987-6543'),
                  SizedBox(height: 8 * _currentSettings.lineSpacingFactor),
                  
                  // Footer info
                  _buildPreviewText('name', 'LABEL ID: LBL-123456'),
                  SizedBox(height: 2 * _currentSettings.lineSpacingFactor),
                  _buildPreviewText('small', 'Date: 2025-09-08'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This preview shows how your label will appear when printed.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewText(String fontType, String text) {
    int fontSize;
    bool isBold;
    
    switch (fontType) {
      case 'header':
        fontSize = _currentSettings.headerFontSize;
        isBold = _currentSettings.headerBold;
        break;
      case 'name':
        fontSize = _currentSettings.nameFontSize;
        isBold = _currentSettings.nameBold;
        break;
      case 'address':
        fontSize = _currentSettings.addressFontSize;
        isBold = _currentSettings.addressBold;
        break;
      case 'phone':
        fontSize = _currentSettings.phoneFontSize;
        isBold = _currentSettings.phoneBold;
        break;
      case 'labeltitle':
        fontSize = _currentSettings.labelTitleFontSize;
        isBold = _currentSettings.labelTitleBold;
        break;
      // Backward compatibility
      case 'title':
        fontSize = _currentSettings.labelTitleFontSize;
        isBold = _currentSettings.labelTitleBold;
        break;
      case 'subtitle':
        fontSize = _currentSettings.headerFontSize;
        isBold = _currentSettings.headerBold;
        break;
      case 'content':
        fontSize = _currentSettings.nameFontSize;
        isBold = _currentSettings.nameBold;
        break;
      case 'small':
        fontSize = _currentSettings.phoneFontSize;
        isBold = _currentSettings.phoneBold;
        break;
      default:
        fontSize = 2;
        isBold = false;
    }
    
    // Approximate UI font size based on TSC font size
    double uiFontSize = 8.0 + (fontSize * 2.0);
    
    return Text(
      text,
      style: TextStyle(
        fontSize: uiFontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _resetToDefault,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset to Default'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade600,
            foregroundColor: Colors.white,
          ),
        ),
        if (_hasChanges)
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}
