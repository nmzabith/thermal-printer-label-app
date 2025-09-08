import 'package:flutter/material.dart';
import '../models/label_config.dart';
import '../services/label_config_service.dart';

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
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save label configuration'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error saving configuration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
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
            const SnackBar(
              content: Text('Reset to default label size'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Label Settings'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfigurations,
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _showResetDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, size: 20),
                    SizedBox(width: 8),
                    Text('Reset to Default'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Configuration Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.label,
                                color: Colors.green[700],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current Label Configuration',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_currentConfig != null) ...[
                            _buildConfigDetails(_currentConfig!),
                          ] else ...[
                            const Text('No configuration loaded'),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Available Configurations
                  Text(
                    'Available Label Sizes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableConfigs.length,
                      itemBuilder: (context, index) {
                        final config = _availableConfigs[index];
                        final isSelected = _currentConfig?.name == config.name;
                        
                        return Card(
                          elevation: isSelected ? 6 : 2,
                          color: isSelected ? Colors.green[50] : null,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              Icons.label_outline,
                              color: isSelected ? Colors.green[700] : Colors.grey[600],
                              size: 28,
                            ),
                            title: Text(
                              config.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.green[800] : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(config.description),
                                const SizedBox(height: 4),
                                Text(
                                  'Size: ${config.widthMm}mm × ${config.heightMm}mm | Gap: ${config.spacingMm}mm',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: Colors.green[700])
                                : const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              if (!isSelected) {
                                _showConfirmDialog(config);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Help Text
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Label Configuration Help',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Select label size that matches your physical thermal labels\n'
                          '• Smaller labels (50mm height) use compact layout\n'
                          '• Larger labels (80mm+ height) include full header and details\n'
                          '• Gap setting controls spacing between printed labels\n'
                          '• Changes apply to all new prints immediately',
                          style: TextStyle(fontSize: 13),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                config.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(config.description),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDetailChip('Width', '${config.widthMm}mm'),
              const SizedBox(width: 8),
              _buildDetailChip('Height', '${config.heightMm}mm'),
              const SizedBox(width: 8),
              _buildDetailChip('Gap', '${config.spacingMm}mm'),
            ],
          ),
        ],
      ),
    );
  }

  /// Build detail chip widget
  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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
            Text('Switch to ${config.name}?'),
            const SizedBox(height: 8),
            Text(
              config.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Dimensions: ${config.widthMm}mm × ${config.heightMm}mm',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Label spacing: ${config.spacingMm}mm',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveConfiguration(config);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply'),
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetToDefault();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
