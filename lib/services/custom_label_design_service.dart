import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_label_design.dart';
import '../models/label_config.dart';

/// Service for managing custom label designs
class CustomLabelDesignService {
  static const String _storageKey = 'custom_label_designs';
  static const String _activeDesignKey = 'active_label_design_id';
  
  static CustomLabelDesignService? _instance;
  static CustomLabelDesignService get instance {
    _instance ??= CustomLabelDesignService._internal();
    return _instance!;
  }
  
  CustomLabelDesignService._internal();

  /// Get all saved custom designs
  Future<List<CustomLabelDesign>> getAllDesigns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final designsJson = prefs.getStringList(_storageKey) ?? [];
      
      return designsJson.map((json) {
        final Map<String, dynamic> data = jsonDecode(json);
        return CustomLabelDesign.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error loading custom designs: $e');
      return [];
    }
  }

  /// Save a custom design
  Future<bool> saveDesign(CustomLabelDesign design) async {
    try {
      final designs = await getAllDesigns();
      
      // Remove existing design with same ID
      designs.removeWhere((d) => d.id == design.id);
      
      // Add updated design
      designs.add(design);
      
      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      final designsJson = designs.map((d) => jsonEncode(d.toJson())).toList();
      
      return await prefs.setStringList(_storageKey, designsJson);
    } catch (e) {
      print('Error saving custom design: $e');
      return false;
    }
  }

  /// Delete a custom design
  Future<bool> deleteDesign(String designId) async {
    try {
      final designs = await getAllDesigns();
      designs.removeWhere((d) => d.id == designId);
      
      final prefs = await SharedPreferences.getInstance();
      final designsJson = designs.map((d) => jsonEncode(d.toJson())).toList();
      
      return await prefs.setStringList(_storageKey, designsJson);
    } catch (e) {
      print('Error deleting custom design: $e');
      return false;
    }
  }

  /// Get design by ID
  Future<CustomLabelDesign?> getDesignById(String designId) async {
    final designs = await getAllDesigns();
    try {
      return designs.firstWhere((d) => d.id == designId);
    } catch (e) {
      return null;
    }
  }

  /// Get designs for a specific label config
  Future<List<CustomLabelDesign>> getDesignsForConfig(LabelConfig config) async {
    final allDesigns = await getAllDesigns();
    return allDesigns.where((design) => 
      design.labelConfig.widthMm == config.widthMm && 
      design.labelConfig.heightMm == config.heightMm
    ).toList();
  }

  /// Create and save default design for a label config
  Future<CustomLabelDesign> createDefaultDesign(LabelConfig config) async {
    final defaultDesign = CustomLabelDesign.createDefault(config);
    await saveDesign(defaultDesign);
    return defaultDesign;
  }

  /// Duplicate an existing design
  Future<CustomLabelDesign> duplicateDesign(CustomLabelDesign original, String newName) async {
    final now = DateTime.now();
    final duplicated = original.copyWith(
      id: 'custom_${now.millisecondsSinceEpoch}',
      name: newName,
      description: 'Copy of ${original.name}',
      createdAt: now,
      updatedAt: now,
      isDefault: false,
    );
    
    await saveDesign(duplicated);
    return duplicated;
  }

  /// Set active design for printing
  Future<bool> setActiveDesign(String designId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeDesignKey, designId);
      return true;
    } catch (e) {
      print('Error setting active design: $e');
      return false;
    }
  }

  /// Get the active design ID
  Future<String?> getActiveDesignId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeDesignKey);
    } catch (e) {
      print('Error getting active design ID: $e');
      return null;
    }
  }

  /// Get current active design
  Future<CustomLabelDesign?> getActiveDesign() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeId = prefs.getString(_activeDesignKey);
      
      if (activeId != null) {
        return await getDesignById(activeId);
      }
      return null;
    } catch (e) {
      print('Error getting active design: $e');
      return null;
    }
  }

  /// Create a new blank design
  Future<CustomLabelDesign> createBlankDesign(LabelConfig config, String name) async {
    final now = DateTime.now();
    final design = CustomLabelDesign(
      id: 'custom_${now.millisecondsSinceEpoch}',
      name: name,
      description: 'Custom design created ${now.toString().substring(0, 10)}',
      labelConfig: config,
      elements: [], // Start with no elements
      createdAt: now,
      updatedAt: now,
      isDefault: false,
    );
    
    await saveDesign(design);
    return design;
  }

  /// Import design from JSON
  Future<CustomLabelDesign?> importDesign(Map<String, dynamic> json) async {
    try {
      final design = CustomLabelDesign.fromJson(json);
      final now = DateTime.now();
      
      // Give it a new ID and timestamps
      final importedDesign = design.copyWith(
        id: 'imported_${now.millisecondsSinceEpoch}',
        name: '${design.name} (Imported)',
        createdAt: now,
        updatedAt: now,
        isDefault: false,
      );
      
      await saveDesign(importedDesign);
      return importedDesign;
    } catch (e) {
      print('Error importing design: $e');
      return null;
    }
  }

  /// Export design to JSON
  Map<String, dynamic> exportDesign(CustomLabelDesign design) {
    return design.toJson();
  }

  /// Clear all designs (for testing/reset)
  Future<void> clearAllDesigns() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove(_activeDesignKey);
  }
}
