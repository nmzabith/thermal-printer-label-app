import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/custom_label_design.dart';
import '../models/label_element.dart';
import '../models/label_config.dart';
import '../services/custom_label_design_service.dart';
import '../services/label_config_service.dart';

class VisualLabelDesignerScreen extends StatefulWidget {
  final CustomLabelDesign? initialDesign;
  final LabelConfig? labelConfig;

  const VisualLabelDesignerScreen({
    super.key,
    this.initialDesign,
    this.labelConfig,
  });

  @override
  State<VisualLabelDesignerScreen> createState() => _VisualLabelDesignerScreenState();
}

class _VisualLabelDesignerScreenState extends State<VisualLabelDesignerScreen> {
  late CustomLabelDesign _currentDesign;
  late LabelConfig _labelConfig;
  LabelElement? _selectedElement;
  bool _isModified = false;
  
  final CustomLabelDesignService _designService = CustomLabelDesignService.instance;
  final LabelConfigService _configService = LabelConfigService.instance;
  
  // Design canvas properties
  final double _canvasScale = 0.5; // Scale factor for display
  late double _canvasWidth;
  late double _canvasHeight;

  @override
  void initState() {
    super.initState();
    _initializeDesign();
  }

  void _initializeDesign() async {
    if (widget.initialDesign != null) {
      _currentDesign = widget.initialDesign!;
      _labelConfig = _currentDesign.labelConfig;
    } else if (widget.labelConfig != null) {
      _labelConfig = widget.labelConfig!;
      _currentDesign = CustomLabelDesign.createDefault(_labelConfig);
    } else {
      // Use current label config
      _labelConfig = await _configService.getCurrentConfig();
      _currentDesign = CustomLabelDesign.createDefault(_labelConfig);
    }
    
    // Calculate canvas dimensions (scaled for display)
    _canvasWidth = _labelConfig.widthMm * 8 * _canvasScale; // Convert mm to dots then scale
    _canvasHeight = _labelConfig.heightMm * 8 * _canvasScale;
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Label Designer - ${_currentDesign.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isModified ? _saveDesign : null,
            tooltip: 'Save Design',
          ),
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: _previewLabel,
            tooltip: 'Preview Label',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export Design'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.file_upload),
                    SizedBox(width: 8),
                    Text('Import Design'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _exportDesign();
                  break;
                case 'import':
                  _importDesign();
                  break;
                case 'duplicate':
                  _duplicateDesign();
                  break;
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Element Palette (Left Side)
          _buildElementPalette(),
          
          // Design Canvas (Center)
          Expanded(
            flex: 3,
            child: _buildDesignCanvas(),
          ),
          
          // Properties Panel (Right Side)
          _buildPropertiesPanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCustomText,
        tooltip: 'Add Text',
        child: const Icon(Icons.text_fields),
      ),
    );
  }

  Widget _buildElementPalette() {
    return Container(
      width: 250,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.widgets, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Elements',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildPaletteSection('Headers', [
                  LabelElementType.toHeader,
                  LabelElementType.fromHeader,
                  LabelElementType.labelTitle,
                ]),
                _buildPaletteSection('Contact Info', [
                  LabelElementType.toName,
                  LabelElementType.fromName,
                  LabelElementType.toAddress,
                  LabelElementType.fromAddress,
                  LabelElementType.toPhone,
                  LabelElementType.fromPhone,
                ]),
                _buildPaletteSection('Other', [
                  LabelElementType.text,
                  LabelElementType.separator,
                  LabelElementType.icon,
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteSection(String title, List<LabelElementType> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        ...types.map((type) => _buildPaletteItem(type)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPaletteItem(LabelElementType type) {
    return Draggable<LabelElementType>(
      data: type,
      feedback: Material(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(type.icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(type.displayName),
            ],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(type.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(type.displayName)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignCanvas() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Canvas toolbar
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Text('${_labelConfig.name} (${_labelConfig.widthMm}×${_labelConfig.heightMm}mm)'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () {
                    // TODO: Implement zoom
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  onPressed: () {
                    // TODO: Implement zoom
                  },
                ),
              ],
            ),
          ),
          
          // Main canvas
          Expanded(
            child: Center(
              child: DragTarget<LabelElementType>(
                onAccept: (elementType) {
                  _addElementToCanvas(elementType, null);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    width: _canvasWidth,
                    height: _canvasHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: _currentDesign.elements.map((element) {
                        return _buildCanvasElement(element);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasElement(LabelElement element) {
    final isSelected = _selectedElement?.id == element.id;
    
    return Positioned(
      left: element.x * _canvasScale,
      top: element.y * _canvasScale,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedElement = element;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final newX = (element.x + details.delta.dx / _canvasScale).clamp(0.0, _labelConfig.widthMm * 8 - 50);
            final newY = (element.y + details.delta.dy / _canvasScale).clamp(0.0, _labelConfig.heightMm * 8 - 20);
            
            _updateElement(element.copyWith(x: newX, y: newY));
            _isModified = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade100 : Colors.transparent,
            border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
            borderRadius: BorderRadius.circular(2),
          ),
          child: _buildElementWidget(element),
        ),
      ),
    );
  }

  Widget _buildElementWidget(LabelElement element) {
    if (element.type == LabelElementType.icon && element.iconPath != null) {
      return Icon(
        Icons.image,
        size: 20,
        color: Colors.grey,
      );
    }
    
    return Text(
      element.content,
      style: TextStyle(
        fontSize: (8 + element.fontSize * 2) * _canvasScale,
        fontWeight: element.isBold ? FontWeight.bold : FontWeight.normal,
        color: element.isVisible ? Colors.black : Colors.grey,
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    return Container(
      width: 250,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: const Row(
              children: [
                Icon(Icons.settings, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Properties',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedElement != null
                ? _buildElementProperties(_selectedElement!)
                : _buildDesignProperties(),
          ),
        ],
      ),
    );
  }

  Widget _buildElementProperties(LabelElement element) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          element.type.displayName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Content
        if (element.type != LabelElementType.icon) ...[
          const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
          TextFormField(
            initialValue: element.content,
            onChanged: (value) {
              _updateElement(element.copyWith(content: value));
              _isModified = true;
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Font Size
        const Text('Font Size:', style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: element.fontSize.toDouble(),
          min: 1,
          max: 8,
          divisions: 7,
          label: element.fontSize.toString(),
          onChanged: (value) {
            _updateElement(element.copyWith(fontSize: value.round()));
            _isModified = true;
          },
        ),
        
        // Bold
        CheckboxListTile(
          title: const Text('Bold'),
          value: element.isBold,
          onChanged: (value) {
            _updateElement(element.copyWith(isBold: value ?? false));
            _isModified = true;
          },
        ),
        
        // Visible
        CheckboxListTile(
          title: const Text('Visible'),
          value: element.isVisible,
          onChanged: (value) {
            _updateElement(element.copyWith(isVisible: value ?? true));
            _isModified = true;
          },
        ),
        
        // Position
        const Text('Position:', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            const Text('X:'),
            Expanded(
              child: Slider(
                value: element.x,
                min: 0,
                max: _labelConfig.widthMm * 8,
                onChanged: (value) {
                  _updateElement(element.copyWith(x: value));
                  _isModified = true;
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text('Y:'),
            Expanded(
              child: Slider(
                value: element.y,
                min: 0,
                max: _labelConfig.heightMm * 8,
                onChanged: (value) {
                  _updateElement(element.copyWith(y: value));
                  _isModified = true;
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Delete button
        ElevatedButton.icon(
          onPressed: () {
            _deleteElement(element);
          },
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDesignProperties() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Design Settings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Design name
          const Text('Name:', style: TextStyle(fontWeight: FontWeight.bold)),
          TextFormField(
            initialValue: _currentDesign.name,
            onChanged: (value) {
              _currentDesign = _currentDesign.copyWith(name: value);
              _isModified = true;
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
          TextFormField(
            initialValue: _currentDesign.description,
            onChanged: (value) {
              _currentDesign = _currentDesign.copyWith(description: value);
              _isModified = true;
            },
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          // Label info
          Text('Label: ${_labelConfig.name}'),
          Text('Size: ${_labelConfig.widthMm}×${_labelConfig.heightMm}mm'),
          Text('Elements: ${_currentDesign.elements.length}'),
        ],
      ),
    );
  }

  void _addElementToCanvas(LabelElementType type, Offset? position) {
    final now = DateTime.now();
    final elementId = '${type.toString().split('.').last}_${now.millisecondsSinceEpoch}';
    
    // Default position (center if no position specified)
    final x = position?.dx ?? (_labelConfig.widthMm * 8) / 2;
    final y = position?.dy ?? (_labelConfig.heightMm * 8) / 2;
    
    String content = _getDefaultContent(type);
    
    final element = LabelElement(
      id: elementId,
      type: type,
      content: content,
      x: x,
      y: y,
      fontSize: _getDefaultFontSize(type),
      isBold: _getDefaultBold(type),
    );
    
    setState(() {
      _currentDesign = _currentDesign.copyWith(
        elements: [..._currentDesign.elements, element],
      );
      _selectedElement = element;
      _isModified = true;
    });
  }

  String _getDefaultContent(LabelElementType type) {
    switch (type) {
      case LabelElementType.toHeader:
        return 'TO:';
      case LabelElementType.fromHeader:
        return 'FROM:';
      case LabelElementType.toName:
        return '[TO NAME]';
      case LabelElementType.fromName:
        return '[FROM NAME]';
      case LabelElementType.toAddress:
        return '[TO ADDRESS]';
      case LabelElementType.fromAddress:
        return '[FROM ADDRESS]';
      case LabelElementType.toPhone:
        return '[TO PHONE]';
      case LabelElementType.fromPhone:
        return '[FROM PHONE]';
      case LabelElementType.text:
        return 'Custom Text';
      case LabelElementType.separator:
        return '═══════════════';
      case LabelElementType.labelTitle:
        return 'SHIPPING LABEL';
      case LabelElementType.icon:
        return '🖼️';
    }
  }

  int _getDefaultFontSize(LabelElementType type) {
    switch (type) {
      case LabelElementType.labelTitle:
        return 5;
      case LabelElementType.toHeader:
      case LabelElementType.fromHeader:
        return 4;
      case LabelElementType.toName:
      case LabelElementType.fromName:
        return 3;
      case LabelElementType.toAddress:
      case LabelElementType.fromAddress:
      case LabelElementType.toPhone:
      case LabelElementType.fromPhone:
        return 2;
      default:
        return 2;
    }
  }

  bool _getDefaultBold(LabelElementType type) {
    switch (type) {
      case LabelElementType.labelTitle:
      case LabelElementType.toHeader:
      case LabelElementType.fromHeader:
        return true;
      default:
        return false;
    }
  }

  void _updateElement(LabelElement updatedElement) {
    setState(() {
      final elements = _currentDesign.elements.toList();
      final index = elements.indexWhere((e) => e.id == updatedElement.id);
      if (index != -1) {
        elements[index] = updatedElement;
        _currentDesign = _currentDesign.copyWith(elements: elements);
        _selectedElement = updatedElement;
      }
    });
  }

  void _deleteElement(LabelElement element) {
    setState(() {
      final elements = _currentDesign.elements.where((e) => e.id != element.id).toList();
      _currentDesign = _currentDesign.copyWith(elements: elements);
      _selectedElement = null;
      _isModified = true;
    });
  }

  void _addCustomText() {
    _addElementToCanvas(LabelElementType.text, null);
  }

  Future<void> _saveDesign() async {
    final success = await _designService.saveDesign(_currentDesign);
    if (success) {
      setState(() {
        _isModified = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design saved successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save design')),
        );
      }
    }
  }

  void _previewLabel() {
    // TODO: Implement preview functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preview feature coming soon!')),
    );
  }

  void _exportDesign() {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }

  void _importDesign() {
    // TODO: Implement import functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import feature coming soon!')),
    );
  }

  void _duplicateDesign() async {
    final name = await _showNameDialog('Duplicate Design', _currentDesign.name + ' Copy');
    if (name != null) {
      final duplicated = await _designService.duplicateDesign(_currentDesign, name);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => VisualLabelDesignerScreen(initialDesign: duplicated),
          ),
        );
      }
    }
  }

  Future<String?> _showNameDialog(String title, String initialValue) async {
    String name = initialValue;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextFormField(
          initialValue: initialValue,
          onChanged: (value) => name = value,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(name),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
