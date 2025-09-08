import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/font_settings.dart';

/// Service for managing font settings persistence
class FontSettingsService {
  static const String _fontSettingsKey = 'font_settings';
  static const String _presetSettingsKey = 'font_settings_preset';
  
  static FontSettingsService? _instance;
  static FontSettingsService get instance {
    _instance ??= FontSettingsService._internal();
    return _instance!;
  }

  FontSettingsService._internal();

  /// Get current font settings
  Future<FontSettings> getCurrentSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_fontSettingsKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        return FontSettings.fromJson(json);
      }
      
      return FontSettings.defaultSettings;
    } catch (e) {
      print('Error loading font settings: $e');
      return FontSettings.defaultSettings;
    }
  }

  /// Save font settings
  Future<bool> saveSettings(FontSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString(_fontSettingsKey, jsonString);
      
      // Clear preset selection since this is custom
      await prefs.remove(_presetSettingsKey);
      
      print('Font settings saved: $settings');
      return true;
    } catch (e) {
      print('Error saving font settings: $e');
      return false;
    }
  }

  /// Get current preset name if any
  Future<String?> getCurrentPreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_presetSettingsKey);
    } catch (e) {
      print('Error loading font preset: $e');
      return null;
    }
  }

  /// Apply and save preset settings
  Future<bool> applyPreset(String presetName) async {
    try {
      FontSettings settings;
      
      // Normalize preset name (remove spaces, lowercase)
      String normalizedName = presetName.toLowerCase().replaceAll(' ', '');
      
      switch (normalizedName) {
        case 'default':
          settings = FontSettings.defaultSettings;
          break;
        case 'smalllabel':
        case 'small':
          settings = FontSettings.smallLabel;
          break;
        case 'largelabel':
        case 'large':
          settings = FontSettings.largeLabel;
          break;
        default:
          print('Unknown preset: $presetName (normalized: $normalizedName)');
          return false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(settings.toJson());
      await prefs.setString(_fontSettingsKey, jsonString);
      await prefs.setString(_presetSettingsKey, presetName);
      
      print('Applied font preset: $presetName - $settings');
      return true;
    } catch (e) {
      print('Error applying font preset: $e');
      return false;
    }
  }

  /// Reset to default settings
  Future<bool> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_fontSettingsKey);
      await prefs.remove(_presetSettingsKey);
      
      print('Font settings reset to default');
      return true;
    } catch (e) {
      print('Error resetting font settings: $e');
      return false;
    }
  }

  /// Get available presets
  Map<String, FontSettings> getAvailablePresets() {
    return {
      'Default': FontSettings.defaultSettings,
      'Small Label': FontSettings.smallLabel,
      'Large Label': FontSettings.largeLabel,
    };
  }

  /// Check if current settings match a preset
  Future<String?> detectCurrentPreset() async {
    try {
      final current = await getCurrentSettings();
      final presets = getAvailablePresets();
      
      for (final entry in presets.entries) {
        if (entry.value == current) {
          return entry.key;
        }
      }
      
      return null; // Custom settings
    } catch (e) {
      print('Error detecting current preset: $e');
      return null;
    }
  }

  /// Validate font settings
  bool validateSettings(FontSettings settings) {
    // Check font size ranges (1-8 for TSC printers)
    if (settings.labelTitleFontSize < 1 || settings.labelTitleFontSize > 8) return false;
    if (settings.headerFontSize < 1 || settings.headerFontSize > 8) return false;
    if (settings.nameFontSize < 1 || settings.nameFontSize > 8) return false;
    if (settings.addressFontSize < 1 || settings.addressFontSize > 8) return false;
    if (settings.phoneFontSize < 1 || settings.phoneFontSize > 8) return false;
    
    // Check line spacing factor
    if (settings.lineSpacingFactor < 0.5 || settings.lineSpacingFactor > 3.0) return false;
    
    // Check max lines
    if (settings.maxLinesAddress < 1 || settings.maxLinesAddress > 10) return false;
    
    return true;
  }

  /// Get font preview text for different types
  Map<String, String> getPreviewText() {
    return {
      'title': 'SHIPPING LABEL',
      'subtitle': 'Order #12345',
      'content': 'John Doe\n123 Main Street',
      'small': 'Printed: 2025-09-08',
    };
  }
}
