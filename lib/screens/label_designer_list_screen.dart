import 'package:flutter/material.dart';
import '../models/custom_label_design.dart';
import '../models/label_config.dart';
import '../services/custom_label_design_service.dart';
import '../services/label_config_service.dart';
import '../widgets/material3_components.dart';
import 'visual_label_designer_screen.dart';

class LabelDesignerListScreen extends StatefulWidget {
  const LabelDesignerListScreen({super.key});

  @override
  State<LabelDesignerListScreen> createState() =>
      _LabelDesignerListScreenState();
}

class _LabelDesignerListScreenState extends State<LabelDesignerListScreen> {
  final CustomLabelDesignService _designService =
      CustomLabelDesignService.instance;
  final LabelConfigService _configService = LabelConfigService.instance;

  List<CustomLabelDesign> _designs = [];
  LabelConfig? _currentConfig;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final designs = await _designService.getAllDesigns();
      final config = await _configService.getCurrentConfig();

      setState(() {
        _designs = designs;
        _currentConfig = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading designs: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Label Designer'),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 3,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Label Designs',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currentConfig != null
                                  ? 'Current Label: ${_currentConfig!.name} (${_currentConfig!.widthMm}×${_currentConfig!.heightMm}mm)'
                                  : 'No label configuration loaded',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Designs list
                Expanded(
                  child: _designs.isEmpty
                      ? _buildEmptyState()
                      : _buildDesignsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewDesign,
        icon: const Icon(Icons.add),
        label: const Text('New Design'),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.design_services,
            size: 80,
            color: colorScheme.surfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            'No Custom Designs Yet',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first custom label design\nwith drag-and-drop functionality',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Material3Components.enhancedButton(
            onPressed: _createNewDesign,
            icon: const Icon(Icons.add),
            label: 'Create Design',
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDesignsList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: _designs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final design = _designs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildDesignCard(design),
        );
      },
    );
  }

  Widget _buildDesignCard(CustomLabelDesign design) {
    return FutureBuilder<String?>(
      future: _designService.getActiveDesignId(),
      builder: (context, snapshot) {
        final isActive = snapshot.data == design.id;
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Material3Components.enhancedCard(
          isSelected: isActive,
          onTap: () => _editDesign(design),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isActive ? Icons.check_circle : Icons.design_services,
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  design.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(height: 4),
                          if (design.description.isNotEmpty)
                            Text(
                              design.description,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.label_outline,
                                  size: 16, color: colorScheme.outline),
                              const SizedBox(width: 4),
                              Text(
                                design.labelConfig.name,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.widgets_outlined,
                                  size: 16, color: colorScheme.outline),
                              const SizedBox(width: 4),
                              Text(
                                '${design.elements.length} elements',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Modified: ${_formatDate(design.lastModified)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert,
                          color: colorScheme.onSurfaceVariant),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'activate',
                          enabled: !isActive,
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline),
                              SizedBox(width: 8),
                              Text('Set Active'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy_rounded),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.file_download_outlined),
                              SizedBox(width: 8),
                              Text('Export'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: colorScheme.error),
                              const SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: colorScheme.error)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) => _handleMenuAction(value, design),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _handleMenuAction(String action, CustomLabelDesign design) {
    switch (action) {
      case 'edit':
        _editDesign(design);
        break;
      case 'activate':
        _setActiveDesign(design);
        break;
      case 'duplicate':
        _duplicateDesign(design);
        break;
      case 'export':
        _exportDesign(design);
        break;
      case 'delete':
        _deleteDesign(design);
        break;
    }
  }

  void _editDesign(CustomLabelDesign design) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => VisualLabelDesignerScreen(
              initialDesign: design,
            ),
          ),
        )
        .then((_) => _loadData());
  }

  Future<void> _setActiveDesign(CustomLabelDesign design) async {
    final success = await _designService.setActiveDesign(design.id);
    if (success) {
      setState(() {
        // Trigger rebuild to show new active state
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${design.name} is now the active design')),
        );
      }
    }
  }

  Future<void> _duplicateDesign(CustomLabelDesign design) async {
    final name =
        await _showNameDialog('Duplicate Design', '${design.name} Copy');
    if (name != null) {
      await _designService.duplicateDesign(design, name);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Design duplicated as "$name"')),
        );
      }
    }
  }

  void _exportDesign(CustomLabelDesign design) {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }

  Future<void> _deleteDesign(CustomLabelDesign design) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Design'),
        content: Text('Are you sure you want to delete "${design.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _designService.deleteDesign(design.id);
      if (success) {
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${design.name}"')),
          );
        }
      }
    }
  }

  void _createNewDesign() async {
    if (_currentConfig == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure a label first'),
        ),
      );
      return;
    }

    final name = await _showNameDialog('New Design', 'My Custom Design');
    if (name != null) {
      if (!mounted) return;
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => VisualLabelDesignerScreen(
                labelConfig: _currentConfig,
                initialDesign: CustomLabelDesign.createDefault(_currentConfig!)
                    .copyWith(name: name),
              ),
            ),
          )
          .then((_) => _loadData());
    }
  }

  Future<String?> _showNameDialog(String title, String initialValue) async {
    String name = initialValue;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Material3Components.enhancedTextField(
          label: 'Design Name',
          initialValue: initialValue,
          onChanged: (value) => name = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(name.trim().isEmpty ? null : name.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
