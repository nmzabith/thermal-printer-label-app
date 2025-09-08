import 'package:flutter/material.dart';
import '../models/custom_label_design.dart';
import '../models/label_config.dart';
import '../services/custom_label_design_service.dart';
import '../services/label_config_service.dart';
import 'visual_label_designer_screen.dart';

class LabelDesignerListScreen extends StatefulWidget {
  const LabelDesignerListScreen({super.key});

  @override
  State<LabelDesignerListScreen> createState() => _LabelDesignerListScreenState();
}

class _LabelDesignerListScreenState extends State<LabelDesignerListScreen> {
  final CustomLabelDesignService _designService = CustomLabelDesignService.instance;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Label Designer'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
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
                  color: Colors.purple.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Custom Label Designs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            Text(
                              _currentConfig != null
                                  ? 'Current Label: ${_currentConfig!.name} (${_currentConfig!.widthMm}×${_currentConfig!.heightMm}mm)'
                                  : 'No label configuration loaded',
                              style: const TextStyle(color: Colors.purple),
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
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Design'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.design_services,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Custom Designs Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first custom label design\nwith drag-and-drop functionality',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewDesign,
            icon: const Icon(Icons.add),
            label: const Text('Create Design'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _designs.length,
      itemBuilder: (context, index) {
        final design = _designs[index];
        return _buildDesignCard(design);
      },
    );
  }

  Widget _buildDesignCard(CustomLabelDesign design) {
    return FutureBuilder<String?>(
      future: _designService.getActiveDesignId(),
      builder: (context, snapshot) {
        final isActive = snapshot.data == design.id;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isActive ? 4 : 2,
          child: Container(
            decoration: isActive
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.purple, width: 2),
                  )
                : null,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive ? Colors.purple : Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isActive ? Icons.check_circle : Icons.design_services,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      design.name,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple,
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (design.description.isNotEmpty)
                    Text(design.description),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.label, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${design.labelConfig.name}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.widgets, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${design.elements.length} elements',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Modified: ${_formatDate(design.lastModified)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
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
                        Icon(Icons.check_circle),
                        SizedBox(width: 8),
                        Text('Set Active'),
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
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download),
                        SizedBox(width: 8),
                        Text('Export'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) => _handleMenuAction(value, design),
              ),
              onTap: () => _editDesign(design),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VisualLabelDesignerScreen(
          initialDesign: design,
        ),
      ),
    ).then((_) => _loadData());
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
    final name = await _showNameDialog('Duplicate Design', '${design.name} Copy');
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VisualLabelDesignerScreen(
            labelConfig: _currentConfig,
            initialDesign: CustomLabelDesign.createDefault(_currentConfig!)
                .copyWith(name: name),
          ),
        ),
      ).then((_) => _loadData());
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
            labelText: 'Design Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(name.trim().isEmpty ? null : name.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
