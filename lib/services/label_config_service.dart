import 'package:shared_preferences/shared_preferences.dart';
import '../models/label_config.dart';

/// Service to manage label configuration settings
/// Handles saving/loading of label size preferences
class LabelConfigService {
  static const String _labelConfigKey = 'selected_label_config';
  static const String _customConfigsKey = 'custom_label_configs';

  static LabelConfigService? _instance;
  static LabelConfigService get instance => _instance ??= LabelConfigService._();
  LabelConfigService._();

  SharedPreferences? _prefs;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get current selected label configuration
  Future<LabelConfig> getCurrentConfig() async {
    await initialize();
    
    final configName = _prefs!.getString(_labelConfigKey);
    if (configName != null) {
      final config = LabelConfigs.findByName(configName);
      if (config != null) {
        return config;
      }
    }
    
    // Return default if none saved or not found
    return LabelConfigs.defaultConfig;
  }

  /// Save selected label configuration
  Future<bool> saveCurrentConfig(LabelConfig config) async {
    await initialize();
    
    try {
      await _prefs!.setString(_labelConfigKey, config.name);
      print('Saved label config: ${config.name}');
      return true;
    } catch (e) {
      print('Error saving label config: $e');
      return false;
    }
  }

  /// Get all available configurations (presets + custom)
  Future<List<LabelConfig>> getAllConfigs() async {
    await initialize();
    
    List<LabelConfig> allConfigs = List.from(LabelConfigs.presets);
    
    // Add custom configurations if any
    final customConfigs = await getCustomConfigs();
    allConfigs.addAll(customConfigs);
    
    return allConfigs;
  }

  /// Get custom configurations saved by user
  Future<List<LabelConfig>> getCustomConfigs() async {
    await initialize();
    
    List<LabelConfig> customConfigs = [];
    
    try {
      final customConfigsJson = _prefs!.getStringList(_customConfigsKey) ?? [];
      for (String configString in customConfigsJson) {
        try {
          // Parse pipe-separated string: name|description|width|height|spacing
          final parts = configString.split('|');
          if (parts.length >= 4) {
            final config = LabelConfig(
              name: parts[0],
              description: parts[1],
              widthMm: double.parse(parts[2]),
              heightMm: double.parse(parts[3]),
              spacingMm: parts.length > 4 ? double.parse(parts[4]) : 2.0,
            );
            customConfigs.add(config);
          }
        } catch (e) {
          print('Error parsing custom config: $e');
        }
      }
    } catch (e) {
      print('Error getting custom configs: $e');
    }
    
    return customConfigs;
  }

  /// Save a custom label configuration
  Future<bool> saveCustomConfig(LabelConfig config) async {
    await initialize();
    
    try {
      final customConfigsJson = _prefs!.getStringList(_customConfigsKey) ?? [];
      
      // Remove existing config with same name
      customConfigsJson.removeWhere((c) => c.startsWith('${config.name}|'));
      
      // Add new config as pipe-separated string
      final configString = '${config.name}|${config.description}|${config.widthMm}|${config.heightMm}|${config.spacingMm}';
      customConfigsJson.add(configString);
      
      await _prefs!.setStringList(_customConfigsKey, customConfigsJson);
      
      print('Saved custom label config: ${config.name}');
      return true;
    } catch (e) {
      print('Error saving custom config: $e');
      return false;
    }
  }

  /// Check if a custom config name already exists
  Future<bool> customConfigExists(String name) async {
    final customConfigs = await getCustomConfigs();
    return customConfigs.any((config) => config.name == name);
  }

  /// Remove a custom configuration
  Future<bool> removeCustomConfig(String configName) async {
    await initialize();
    
    try {
      final customConfigsJson = _prefs!.getStringList(_customConfigsKey) ?? [];
      customConfigsJson.removeWhere((config) => config.startsWith('$configName|'));
      await _prefs!.setStringList(_customConfigsKey, customConfigsJson);
      
      print('Removed custom config: $configName');
      return true;
    } catch (e) {
      print('Error removing custom config: $e');
      return false;
    }
  }

  /// Reset to default configuration
  Future<bool> resetToDefault() async {
    await initialize();
    
    try {
      await _prefs!.remove(_labelConfigKey);
      print('Reset to default label configuration');
      return true;
    } catch (e) {
      print('Error resetting config: $e');
      return false;
    }
  }
}
