import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/custom_label_design.dart';
import '../models/label_element.dart';
import '../models/label_config.dart';
import '../services/custom_label_design_service.dart';
import '../services/label_config_service.dart';
import '../widgets/material3_components.dart';

class VisualLabelDesignerScreen extends StatefulWidget {
  final CustomLabelDesign? initialDesign;
  final LabelConfig? labelConfig;

  const VisualLabelDesignerScreen({
    super.key,
    this.initialDesign,
    this.labelConfig,
  });

  @override
  State<VisualLabelDesignerScreen> createState() =>
      _VisualLabelDesignerScreenState();
}

class _VisualLabelDesignerScreenState extends State<VisualLabelDesignerScreen> {
  late CustomLabelDesign _currentDesign;
  late LabelConfig _labelConfig;
  LabelElement? _selectedElement;
  bool _isModified = false;

  final CustomLabelDesignService _designService =
      CustomLabelDesignService.instance;
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
    _canvasWidth = _labelConfig.widthMm *
        8 *
        _canvasScale; // Convert mm to dots then scale
    _canvasHeight = _labelConfig.heightMm * 8 * _canvasScale;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 700;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isWideScreen
                  ? 'Label Designer - ${_currentDesign.name}'
                  : _currentDesign.name,
              style: textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: colorScheme.surface,
            scrolledUnderElevation: 3,
            leading: isWideScreen
                ? null
                : IconButton(
                    icon: const Icon(Icons.widgets_outlined),
                    onPressed: () => _showElementsBottomSheet(context),
                    tooltip: 'Elements',
                  ),
            actions: [
              IconButton(
                icon: _isModified
                    ? Icon(Icons.save, color: colorScheme.primary)
                    : Icon(Icons.save_outlined,
                        color: colorScheme.onSurface.withAlpha(97)),
                onPressed: _isModified ? _saveDesign : null,
                tooltip: 'Save Design',
              ),
              if (!isWideScreen)
                IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () => _showPropertiesBottomSheet(context),
                  tooltip: 'Properties',
                ),
              IconButton(
                icon: const Icon(Icons.preview_outlined),
                onPressed: _previewLabel,
                tooltip: 'Preview Label',
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download_outlined,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('Export Design', style: textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(Icons.file_upload_outlined,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('Import Design', style: textTheme.bodyLarge),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_outlined,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text('Duplicate', style: textTheme.bodyLarge),
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
          body: isWideScreen
              ? Row(
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
                )
              : _buildDesignCanvas(), // Mobile: just the canvas
          floatingActionButton: FloatingActionButton(
            onPressed: _addCustomText,
            tooltip: 'Add Text',
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            elevation: 4,
            child: const Icon(Icons.text_fields),
          ),
        );
      },
    );
  }

  void _showElementsBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child:
                  _buildElementPaletteContent(scrollController, isMobile: true),
            ),
          ],
        ),
      ),
    );
  }

  void _showPropertiesBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: _selectedElement != null
                  ? _buildElementPropertiesContent(
                      _selectedElement!, scrollController)
                  : _buildDesignPropertiesContent(scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElementPaletteContent(ScrollController? scrollController,
      {bool isMobile = false}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.widgets_outlined, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Tap to Add Element',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        _buildMobilePaletteSection(
            'Headers',
            [
              LabelElementType.toHeader,
              LabelElementType.fromHeader,
              LabelElementType.labelTitle,
            ],
            isMobile),
        _buildMobilePaletteSection(
            'Contact Info',
            [
              LabelElementType.toName,
              LabelElementType.fromName,
              LabelElementType.toAddress,
              LabelElementType.fromAddress,
              LabelElementType.toPhone,
              LabelElementType.fromPhone,
            ],
            isMobile),
        _buildMobilePaletteSection(
            'Other',
            [
              LabelElementType.text,
              LabelElementType.separator,
              LabelElementType.icon,
            ],
            isMobile),
      ],
    );
  }

  Widget _buildMobilePaletteSection(
      String title, List<LabelElementType> types, bool isMobile) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...types.map((type) => _buildMobilePaletteItem(type, isMobile)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMobilePaletteItem(LabelElementType type, bool isMobile) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material3Components.enhancedCard(
        elevation: 0,
        onTap: () {
          // Add element to canvas
          _addElementToCanvas(type, null);
          // Close the bottom sheet if on mobile
          if (isMobile) {
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(type.icon, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.displayName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Tap to add',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline,
                  size: 20, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElementPropertiesContent(
      LabelElement element, ScrollController? scrollController) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                element.type.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Element',
                    style: textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    element.type.displayName,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 32),

        // Content
        if (element.type != LabelElementType.icon) ...[
          Material3Components.enhancedTextField(
            label: 'Content',
            initialValue: element.content,
            onChanged: (value) {
              _updateElement(element.copyWith(content: value));
              _isModified = true;
            },
            maxLines: element.type == LabelElementType.text ? 3 : 1,
          ),
          const SizedBox(height: 24),
        ],

        // Font Size
        Text(
          'Font Size',
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: element.fontSize.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                label: element.fontSize.toString(),
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceVariant,
                onChanged: (value) {
                  _updateElement(element.copyWith(fontSize: value.round()));
                  _isModified = true;
                },
              ),
            ),
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                element.fontSize.toString(),
                style:
                    textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        // Bold
        SwitchListTile(
          title: const Text('Bold'),
          value: element.isBold,
          onChanged: (value) {
            _updateElement(element.copyWith(isBold: value));
            _isModified = true;
          },
          tileColor: colorScheme.surface,
          contentPadding: EdgeInsets.zero,
        ),

        // Visible
        SwitchListTile(
          title: const Text('Visible'),
          value: element.isVisible,
          onChanged: (value) {
            _updateElement(element.copyWith(isVisible: value));
            _isModified = true;
          },
          tileColor: colorScheme.surface,
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(height: 32),

        // Position
        Text(
          'Position',
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('X: ${element.x.toInt()}', style: textTheme.bodySmall),
                  Slider(
                    value: element.x,
                    min: 0,
                    max: _labelConfig.widthMm * 8,
                    activeColor: colorScheme.secondary,
                    onChanged: (value) {
                      _updateElement(element.copyWith(x: value));
                      _isModified = true;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Y: ${element.y.toInt()}', style: textTheme.bodySmall),
                  Slider(
                    value: element.y,
                    min: 0,
                    max: _labelConfig.heightMm * 8,
                    activeColor: colorScheme.secondary,
                    onChanged: (value) {
                      _updateElement(element.copyWith(y: value));
                      _isModified = true;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Delete button
        Center(
          child: Material3Components.enhancedButton(
            label: 'Delete Element',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _deleteElement(element);
              Navigator.pop(context); // Close the bottom sheet
            },
            isPrimary: false,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesignPropertiesContent(ScrollController? scrollController) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.design_services, color: colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Design Settings',
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Global properties',
                    style: textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        Material3Components.enhancedTextField(
          label: 'Design Name',
          initialValue: _currentDesign.name,
          prefixIcon: const Icon(Icons.label_outline),
          onChanged: (value) {
            _currentDesign = _currentDesign.copyWith(name: value);
            _isModified = true;
          },
        ),
        const SizedBox(height: 16),
        Material3Components.enhancedTextField(
          label: 'Description',
          initialValue: _currentDesign.description,
          prefixIcon: const Icon(Icons.description_outlined),
          onChanged: (value) {
            _currentDesign = _currentDesign.copyWith(description: value);
            _isModified = true;
          },
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Material3Components.enhancedCard(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildInfoRow(Icons.print, 'Label Type', _labelConfig.name,
                    colorScheme, textTheme),
                const SizedBox(height: 8),
                _buildInfoRow(
                    Icons.aspect_ratio,
                    'Size',
                    '${_labelConfig.widthMm} × ${_labelConfig.heightMm} mm',
                    colorScheme,
                    textTheme),
                const SizedBox(height: 8),
                _buildInfoRow(
                    Icons.layers,
                    'Elements',
                    '${_currentDesign.elements.length} items',
                    colorScheme,
                    textTheme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildElementPalette() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme
                .surfaceVariant, // Fixed: surfaceContainer -> surfaceVariant
            child: Row(
              children: [
                Icon(Icons.widgets_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Elements',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            title,
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...types.map((type) => _buildPaletteItem(type)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPaletteItem(LabelElementType type) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Draggable<LabelElementType>(
      data: type,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(type.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Text(
                type.displayName,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material3Components.enhancedCard(
          elevation: 0,
          onTap: null, // Just for styling
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text(type.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type.displayName,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.drag_indicator,
                    size: 16, color: colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesignCanvas() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: colorScheme.surface, // Canvas background
      child: Column(
        children: [
          // Canvas toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              border:
                  Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(Icons.aspect_ratio,
                    size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  '${_labelConfig.name} (${_labelConfig.widthMm}×${_labelConfig.heightMm}mm)',
                  style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () {
                    // TODO: Implement zoom
                  },
                  tooltip: 'Zoom In',
                  color: colorScheme.onSurfaceVariant,
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out),
                  onPressed: () {
                    // TODO: Implement zoom
                  },
                  tooltip: 'Zoom Out',
                  color: colorScheme.onSurfaceVariant,
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
                      color: Colors.white, // The label itself should be white
                      border: Border.all(color: colorScheme.outline, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
    final colorScheme = Theme.of(context).colorScheme;
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
            final newX = (element.x + details.delta.dx / _canvasScale)
                .clamp(0.0, _labelConfig.widthMm * 8 - 50);
            final newY = (element.y + details.delta.dy / _canvasScale)
                .clamp(0.0, _labelConfig.heightMm * 8 - 20);

            _updateElement(element.copyWith(x: newX, y: newY));
            _isModified = true;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            border: isSelected
                ? Border.all(color: colorScheme.primary, width: 1.5)
                : Border.all(color: Colors.transparent, width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildElementWidget(element),
        ),
      ),
    );
  }

  Widget _buildElementWidget(LabelElement element) {
    if (element.type == LabelElementType.icon && element.iconPath != null) {
      return const Icon(
        Icons.image_outlined,
        size: 24,
        color: Colors.black54,
      );
    }

    return Text(
      element.content,
      style: TextStyle(
        fontSize: (8 + element.fontSize * 2) * _canvasScale,
        fontWeight: element.isBold ? FontWeight.bold : FontWeight.normal,
        color: element.isVisible ? Colors.black : Colors.grey.shade300,
        fontFamily: 'Roboto',
      ),
    );
  }

  Widget _buildPropertiesPanel() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceVariant,
            child: Row(
              children: [
                Icon(Icons.tune, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Properties',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                element.type.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Element',
                    style: textTheme.labelSmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    element.type.displayName,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 32),

        // Content
        if (element.type != LabelElementType.icon) ...[
          Material3Components.enhancedTextField(
            label: 'Content',
            initialValue: element.content,
            onChanged: (value) {
              _updateElement(element.copyWith(content: value));
              _isModified = true;
            },
            maxLines: element.type == LabelElementType.text ? 3 : 1,
          ),
          const SizedBox(height: 24),
        ],

        // Font Size
        Text(
          'Font Size',
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: element.fontSize.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                label: element.fontSize.toString(),
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.surfaceVariant,
                onChanged: (value) {
                  _updateElement(element.copyWith(fontSize: value.round()));
                  _isModified = true;
                },
              ),
            ),
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                element.fontSize.toString(),
                style:
                    textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),

        // Bold
        SwitchListTile(
          title: const Text('Bold'),
          value: element.isBold,
          onChanged: (value) {
            _updateElement(element.copyWith(isBold: value));
            _isModified = true;
          },
          tileColor: colorScheme.surface,
          contentPadding: EdgeInsets.zero,
        ),

        // Visible
        SwitchListTile(
          title: const Text('Visible'),
          value: element.isVisible,
          onChanged: (value) {
            _updateElement(element.copyWith(isVisible: value));
            _isModified = true;
          },
          tileColor: colorScheme.surface,
          contentPadding: EdgeInsets.zero,
        ),

        const Divider(height: 32),

        // Position
        Text(
          'Position',
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('X: ${element.x.toInt()}', style: textTheme.bodySmall),
                  Slider(
                    value: element.x,
                    min: 0,
                    max: _labelConfig.widthMm * 8,
                    activeColor: colorScheme.secondary,
                    onChanged: (value) {
                      _updateElement(element.copyWith(x: value));
                      _isModified = true;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Y: ${element.y.toInt()}', style: textTheme.bodySmall),
                  Slider(
                    value: element.y,
                    min: 0,
                    max: _labelConfig.heightMm * 8,
                    activeColor: colorScheme.secondary,
                    onChanged: (value) {
                      _updateElement(element.copyWith(y: value));
                      _isModified = true;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Delete button
        Center(
          child: Material3Components.enhancedButton(
            label: 'Delete Element',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _deleteElement(element);
            },
            isPrimary: false,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesignProperties() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.design_services, color: colorScheme.secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Design Settings',
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Global properties',
                      style: textTheme.labelSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Material3Components.enhancedTextField(
            label: 'Design Name',
            initialValue: _currentDesign.name,
            prefixIcon: const Icon(Icons.label_outline),
            onChanged: (value) {
              _currentDesign = _currentDesign.copyWith(name: value);
              _isModified = true;
            },
          ),
          const SizedBox(height: 16),
          Material3Components.enhancedTextField(
            label: 'Description',
            initialValue: _currentDesign.description,
            prefixIcon: const Icon(Icons.description_outlined),
            onChanged: (value) {
              _currentDesign = _currentDesign.copyWith(description: value);
              _isModified = true;
            },
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          Material3Components.enhancedCard(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _buildInfoRow(Icons.print, 'Label Type', _labelConfig.name,
                      colorScheme, textTheme),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      Icons.aspect_ratio,
                      'Size',
                      '${_labelConfig.widthMm} × ${_labelConfig.heightMm} mm',
                      colorScheme,
                      textTheme),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                      Icons.layers,
                      'Elements',
                      '${_currentDesign.elements.length} items',
                      colorScheme,
                      textTheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _addElementToCanvas(LabelElementType type, Offset? position) {
    final now = DateTime.now();
    final elementId =
        '${type.toString().split('.').last}_${now.millisecondsSinceEpoch}';

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
      final elements =
          _currentDesign.elements.where((e) => e.id != element.id).toList();
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
    final name = await _showNameDialog(
        'Duplicate Design', _currentDesign.name + ' Copy');
    if (name != null) {
      final duplicated =
          await _designService.duplicateDesign(_currentDesign, name);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                VisualLabelDesignerScreen(initialDesign: duplicated),
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
