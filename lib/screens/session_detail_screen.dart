import 'package:flutter/material.dart';
import '../models/print_session.dart';
import '../models/shipping_label.dart';
import '../services/session_service.dart';
import '../services/thermal_printer_service.dart';
import 'label_editor_screen.dart';
import 'thermal_printer_settings_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final PrintSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late PrintSession _session;
  final SessionService _sessionService = SessionService();
  final ThermalPrinterService _printerService = ThermalPrinterService();
  bool _isLoading = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedLabelIds = {};

  @override
  void initState() {
    super.initState();
    _session = widget.session;
  }

  Future<void> _saveSession() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.updateSession(_session);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving session: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedLabelIds.clear();
      }
    });
  }

  void _toggleLabelSelection(String labelId) {
    setState(() {
      if (_selectedLabelIds.contains(labelId)) {
        _selectedLabelIds.remove(labelId);
      } else {
        _selectedLabelIds.add(labelId);
      }
    });
  }

  void _selectAllLabels() {
    setState(() {
      _selectedLabelIds.addAll(_session.labels.map((label) => label.id));
    });
  }

  void _deselectAllLabels() {
    setState(() {
      _selectedLabelIds.clear();
    });
  }

  void _selectReadyLabels() {
    setState(() {
      _selectedLabelIds.addAll(
        _session.labels
            .where((label) => label.isReadyToPrint())
            .map((label) => label.id)
      );
    });
  }

  bool get _isAllSelected => 
      _session.labels.isNotEmpty && 
      _selectedLabelIds.length == _session.labels.length;

  bool get _hasSelectedLabels => _selectedLabelIds.isNotEmpty;

  int get _selectedReadyCount => _session.labels
      .where((label) => _selectedLabelIds.contains(label.id) && label.isReadyToPrint())
      .length;

  Future<void> _printSelectedLabels() async {
    final selectedLabels = _session.labels
        .where((label) => _selectedLabelIds.contains(label.id) && label.isReadyToPrint())
        .toList();
    
    if (selectedLabels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No ready-to-print labels selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check printer connection
    bool isConnected = await _printerService.isConnected;
    if (!isConnected) {
      _showPrinterConnectionDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the selected labels
      final selectedLabels = _session.labels.where((label) => 
          _selectedLabelIds.contains(label.id)).toList();
      
      // Print selected labels using ESC/POS service
      final success = await _printerService.printSelectedLabels(selectedLabels);
      
      if (success) {
        setState(() {
          _isSelectionMode = false;
          _selectedLabelIds.clear();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${selectedLabels.length} labels printed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to print labels'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _printAllReadyLabels() async {
    final readyLabels = _session.labels.where((label) => label.isReadyToPrint()).toList();
    
    if (readyLabels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No labels are ready to print'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check printer connection
    bool isConnected = await _printerService.isConnected;
    if (!isConnected) {
      _showPrinterConnectionDialog();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Print all ready labels using ESC/POS service
      final success = await _printerService.printSelectedLabels(readyLabels);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${readyLabels.length} labels printed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to print session'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPrinterConnectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printer Not Connected'),
        content: const Text('Please connect to your XPrinter XP-365B before printing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ThermalPrinterSettingsScreen(),
                ),
              );
            },
            child: const Text('Printer Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewLabel() async {
    final newLabel = ShippingLabel.empty();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LabelEditorScreen(label: newLabel, isNew: true),
      ),
    );

    if (result == true) {
      setState(() {
        _session.addLabel(newLabel);
      });
      await _saveSession();
    }
  }

  Future<void> _editLabel(ShippingLabel label) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LabelEditorScreen(label: label, isNew: false),
      ),
    );

    if (result == true) {
      setState(() {
        _session.updateLabel(label);
      });
      await _saveSession();
    }
  }

  Future<void> _deleteLabel(ShippingLabel label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Label'),
        content: Text('Are you sure you want to delete the label: ${label.getDisplayName()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _session.removeLabel(label.id);
      });
      await _saveSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Label deleted successfully')),
        );
      }
    }
  }

  Future<void> _editSessionName() async {
    final controller = TextEditingController(text: _session.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Session Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Session Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _session.name) {
      setState(() {
        _session.name = newName;
        _session.updateTimestamp();
      });
      await _saveSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode 
            ? Text('${_selectedLabelIds.length} selected')
            : GestureDetector(
                onTap: _editSessionName,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _session.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.edit, size: 18),
                  ],
                ),
              ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: _isSelectionMode
            ? IconButton(
                onPressed: _toggleSelectionMode,
                icon: const Icon(Icons.close),
                tooltip: 'Exit selection mode',
              )
            : null,
        actions: _isSelectionMode
            ? [
                if (_session.labels.isNotEmpty) ...[
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'select_all':
                          _selectAllLabels();
                          break;
                        case 'deselect_all':
                          _deselectAllLabels();
                          break;
                        case 'select_ready':
                          _selectReadyLabels();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'select_all',
                        enabled: !_isAllSelected,
                        child: const Row(
                          children: [
                            Icon(Icons.select_all),
                            SizedBox(width: 8),
                            Text('Select All'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deselect_all',
                        enabled: _hasSelectedLabels,
                        child: const Row(
                          children: [
                            Icon(Icons.deselect),
                            SizedBox(width: 8),
                            Text('Deselect All'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'select_ready',
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle),
                            SizedBox(width: 8),
                            Text('Select Ready'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_selectedReadyCount > 0)
                    IconButton(
                      onPressed: _isLoading ? null : _printSelectedLabels,
                      icon: const Icon(Icons.print),
                      tooltip: 'Print Selected ($_selectedReadyCount ready)',
                    ),
                ],
              ]
            : [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ThermalPrinterSettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  tooltip: 'Printer Settings',
                ),
                if (_session.labels.isNotEmpty)
                  IconButton(
                    onPressed: _toggleSelectionMode,
                    icon: const Icon(Icons.checklist),
                    tooltip: 'Select labels',
                  ),
                if (_session.hasReadyLabels)
                  IconButton(
                    onPressed: _isLoading ? null : _printAllReadyLabels,
                    icon: const Icon(Icons.print),
                    tooltip: 'Print Ready Labels',
                  ),
              ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Session Info Card
              Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Session Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Total Labels: ${_session.totalLabels}'),
                            Text('Ready to Print: ${_session.readyToPrintCount}'),
                            Text('Created: ${_formatDate(_session.createdAt)}'),
                            Text('Updated: ${_formatDate(_session.updatedAt)}'),
                          ],
                        ),
                      ),
                      Icon(
                        _session.allLabelsReady
                            ? Icons.check_circle
                            : _session.hasReadyLabels
                                ? Icons.warning
                                : Icons.error,
                        color: _session.allLabelsReady
                            ? Colors.green
                            : _session.hasReadyLabels
                                ? Colors.orange
                                : Colors.red,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Labels List
              Expanded(
                child: _session.labels.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.label_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No labels in this session',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add your first shipping label',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _addNewLabel,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Label'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _session.labels.length,
                        itemBuilder: (context, index) {
                          final label = _session.labels[index];
                          final isSelected = _selectedLabelIds.contains(label.id);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: _isSelectionMode && isSelected 
                                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                                : null,
                            child: ListTile(
                              leading: _isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        _toggleLabelSelection(label.id);
                                      },
                                    )
                                  : CircleAvatar(
                                      backgroundColor: label.isReadyToPrint()
                                          ? Colors.green
                                          : Colors.orange,
                                      child: Icon(
                                        label.isReadyToPrint()
                                            ? Icons.check
                                            : Icons.warning,
                                        color: Colors.white,
                                      ),
                                    ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(label.getDisplayName())),
                                  if (!_isSelectionMode && !label.isReadyToPrint())
                                    const Icon(
                                      Icons.warning,
                                      color: Colors.orange,
                                      size: 18,
                                    )
                                  else if (!_isSelectionMode && label.isReadyToPrint())
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Created: ${_formatDate(label.createdAt)}'),
                                  if (_isSelectionMode)
                                    Text(
                                      label.isReadyToPrint() ? 'Ready to print' : 'Incomplete data',
                                      style: TextStyle(
                                        color: label.isReadyToPrint() ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  else if (!label.isReadyToPrint())
                                    const Text(
                                      'Incomplete data',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                ],
                              ),
                              trailing: _isSelectionMode 
                                  ? null
                                  : PopupMenuButton<String>(
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _editLabel(label);
                                            break;
                                          case 'delete':
                                            _deleteLabel(label);
                                            break;
                                        }
                                      },
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
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                              onTap: _isSelectionMode 
                                  ? () => _toggleLabelSelection(label.id)
                                  : () => _editLabel(label),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomSheet: _isSelectionMode && _hasSelectedLabels
          ? Container(
              height: 80,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_selectedLabelIds.length} labels selected',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (_selectedReadyCount > 0)
                          Text(
                            '$_selectedReadyCount ready to print',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_selectedReadyCount > 0) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _printSelectedLabels,
                      icon: const Icon(Icons.print),
                      label: const Text('Print'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            )
          : null,
      floatingActionButton: _isSelectionMode 
          ? null
          : FloatingActionButton(
              onPressed: _addNewLabel,
              tooltip: 'Add New Label',
              child: const Icon(Icons.add),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
