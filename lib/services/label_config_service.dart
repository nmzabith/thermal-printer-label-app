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
    
    final customConfigsJson = _prefs!.getStringList(_customConfigsKey) ?? [];
    
    List<LabelConfig> customConfigs = [];
    for (String configJson in customConfigsJson) {
      try {
        // In a real implementation, you'd use JSON decode
        // For now, we'll keep it simple with preset configurations
      } catch (e) {
        print('Error parsing custom config: $e');
      }
    }
    
    return customConfigs;
  }

  /// Save a custom label configuration
  Future<bool> saveCustomConfig(LabelConfig config) async {
    await initialize();
    
    try {
      final customConfigs = await getCustomConfigs();
      customConfigs.add(config);
      
      // Convert to string list for storage
      final configStrings = customConfigs.map((c) => c.name).toList();
      await _prefs!.setStringList(_customConfigsKey, configStrings);
      
      print('Saved custom label config: ${config.name}');
      return true;
    } catch (e) {
      print('Error saving custom config: $e');
      return false;
    }
  }

  /// Remove a custom configuration
  Future<bool> removeCustomConfig(String configName) async {
    await initialize();
    
    try {
      final customConfigsJson = _prefs!.getStringList(_customConfigsKey) ?? [];
      customConfigsJson.removeWhere((config) => config.contains(configName));
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
