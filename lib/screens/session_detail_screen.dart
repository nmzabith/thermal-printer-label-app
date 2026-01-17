import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/print_session.dart';
import '../models/shipping_label.dart';
import '../services/session_service.dart';
import '../services/thermal_printer_service.dart';
import '../services/gemini_ai_service.dart';
import '../widgets/material3_components.dart';
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
  final GeminiAiService _geminiService = GeminiAiService();
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
      _selectedLabelIds.addAll(_session.labels
          .where((label) => label.isReadyToPrint())
          .map((label) => label.id));
    });
  }

  bool get _isAllSelected =>
      _session.labels.isNotEmpty &&
      _selectedLabelIds.length == _session.labels.length;

  bool get _hasSelectedLabels => _selectedLabelIds.isNotEmpty;

  int get _selectedReadyCount => _session.labels
      .where((label) =>
          _selectedLabelIds.contains(label.id) && label.isReadyToPrint())
      .length;

  Future<void> _printSelectedLabels() async {
    final selectedLabels = _session.labels
        .where((label) =>
            _selectedLabelIds.contains(label.id) && label.isReadyToPrint())
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
      final selectedLabels = _session.labels
          .where((label) => _selectedLabelIds.contains(label.id))
          .toList();

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
              content:
                  Text('${selectedLabels.length} labels printed successfully!'),
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
    final readyLabels =
        _session.labels.where((label) => label.isReadyToPrint()).toList();

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
              content:
                  Text('${readyLabels.length} labels printed successfully!'),
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
        content: const Text(
            'Please connect to your XPrinter XP-365B before printing.'),
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
    // Show dialog to choose between Manual and Auto entry
    final selectedOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Label'),
        content: const Text('Choose how you want to add the label:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('manual'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit),
                SizedBox(width: 8),
                Text('Manual Entry'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('auto'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome),
                SizedBox(width: 8),
                Text('Auto Process'),
              ],
            ),
          ),
        ],
      ),
    );

    if (selectedOption == 'manual') {
      await _addManualLabel();
    } else if (selectedOption == 'auto') {
      await _showAutoProcessDialog();
    }
  }

  Future<void> _addManualLabel() async {
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

  Future<void> _showAutoProcessDialog() async {
    final TextEditingController textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto Process Label'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste or enter label information:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Example: Names, addresses, phone numbers from emails, messages, or documents.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    // Textarea
                    TextField(
                      controller: textController,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText:
                            'Paste shipping information here...\n\nExample:\nTO: John Doe\n123 Main St, City, State 12345\n(555) 123-4567\n\nFROM: Jane Smith\n456 Oak Ave, Town, State 67890\n(555) 987-6543',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    // Paste icon row
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () async {
                              try {
                                final clipboardData = await Clipboard.getData(
                                    Clipboard.kTextPlain);
                                if (clipboardData?.text != null) {
                                  textController.text = clipboardData!.text!;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Content pasted from clipboard'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('No text found in clipboard'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to paste: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.content_paste),
                            tooltip: 'Paste from clipboard',
                          ),
                          const Spacer(),
                          const Text(
                            'Paste content here',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processAutoText(textController.text);
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  Future<void> _processAutoText(String text) async {
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text to process'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Show processing message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Processing with AI...'),
          backgroundColor: Colors.blue,
        ),
      );

      // Process text with Gemini AI
      final extractedLabel = await _geminiService.extractShippingInfo(text);

      if (extractedLabel != null) {
        // Navigate to label editor with pre-filled data
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                LabelEditorScreen(label: extractedLabel, isNew: true),
          ),
        );

        if (result == true) {
          setState(() {
            _session.addLabel(extractedLabel);
          });
          await _saveSession();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Label extracted and added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Could not extract shipping information from the text. Please try manual entry.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing text: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        content: Text(
            'Are you sure you want to delete the label: ${label.getDisplayName()}?'),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                    const SizedBox(width: 8),
                    Icon(Icons.edit, size: 18, color: colorScheme.onSurface),
                  ],
                ),
              ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 3,
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
                        child: Row(
                          children: [
                            Icon(Icons.select_all,
                                color: colorScheme.onSurface),
                            const SizedBox(width: 8),
                            const Text('Select All'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'deselect_all',
                        enabled: _hasSelectedLabels,
                        child: Row(
                          children: [
                            Icon(Icons.deselect, color: colorScheme.onSurface),
                            const SizedBox(width: 8),
                            const Text('Deselect All'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'select_ready',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: colorScheme.onSurface),
                            const SizedBox(width: 8),
                            const Text('Select Ready'),
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
                        builder: (context) =>
                            const ThermalPrinterSettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_outlined),
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Material3Components.enhancedCard(
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
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                  Icons.label_outline,
                                  'Total Labels: ${_session.totalLabels}',
                                  colorScheme,
                                  textTheme),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                  Icons.print_outlined,
                                  'Ready to Print: ${_session.readyToPrintCount}',
                                  colorScheme,
                                  textTheme),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                  Icons.calendar_today_outlined,
                                  'Created: ${_formatDate(_session.createdAt)}',
                                  colorScheme,
                                  textTheme),
                              const SizedBox(height: 4),
                              _buildInfoRow(
                                  Icons.update,
                                  'Updated: ${_formatDate(_session.updatedAt)}',
                                  colorScheme,
                                  textTheme),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _session.allLabelsReady
                                ? colorScheme.primaryContainer
                                : _session.hasReadyLabels
                                    ? colorScheme.tertiaryContainer
                                    : colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _session.allLabelsReady
                                ? Icons.check_circle
                                : _session.hasReadyLabels
                                    ? Icons.warning_amber_rounded
                                    : Icons.error_outline,
                            color: _session.allLabelsReady
                                ? colorScheme.onPrimaryContainer
                                : _session.hasReadyLabels
                                    ? colorScheme.onTertiaryContainer
                                    : colorScheme.onErrorContainer,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
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
                            Icon(
                              Icons.label_off_outlined,
                              size: 80,
                              color: colorScheme.surfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No labels in this session',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first shipping label',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Material3Components.enhancedButton(
                              onPressed: _addNewLabel,
                              icon: const Icon(Icons.add),
                              label: 'Add Label',
                              isPrimary: true,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _session.labels.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final label = _session.labels[index];
                          final isSelected =
                              _selectedLabelIds.contains(label.id);
                          final isReady = label.isReadyToPrint();

                          return Material3Components.enhancedCard(
                            onTap: _isSelectionMode
                                ? () => _toggleLabelSelection(label.id)
                                : () => _editLabel(label),
                            isSelected: isSelected,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  if (_isSelectionMode)
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (value) {
                                        _toggleLabelSelection(label.id);
                                      },
                                    )
                                  else
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isReady
                                            ? colorScheme.primaryContainer
                                            : colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isReady
                                            ? Icons.check
                                            : Icons.priority_high,
                                        color: isReady
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onErrorContainer,
                                        size: 20,
                                      ),
                                    ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          label.getDisplayName(),
                                          style:
                                              textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Created: ${_formatDate(label.createdAt)}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (!isReady)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              'Incomplete data',
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: colorScheme.error,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (!_isSelectionMode)
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_vert,
                                          color: colorScheme.onSurfaceVariant),
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
                                              Icon(Icons.edit_outlined),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline,
                                                  color: colorScheme.error),
                                              const SizedBox(width: 8),
                                              Text('Delete',
                                                  style: TextStyle(
                                                      color:
                                                          colorScheme.error)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
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
          ? Material3Components.showEnhancedBottomSheet(
              context: context,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_selectedLabelIds.length} labels selected',
                            style: textTheme.titleMedium,
                          ),
                          if (_selectedReadyCount > 0)
                            Text(
                              '$_selectedReadyCount ready to print',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          if (_selectedReadyCount == 0)
                            Text(
                              'No printable labels selected',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_selectedReadyCount > 0) ...[
                      const SizedBox(width: 16),
                      Material3Components.enhancedButton(
                        onPressed: _isLoading ? null : _printSelectedLabels,
                        icon: const Icon(Icons.print),
                        label: 'Print',
                        isPrimary: true,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ) as Widget? // Cast is hacky but we need to match the signature or just inline the container
          : null,
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _addNewLabel,
              tooltip: 'Add New Label',
              icon: const Icon(Icons.add),
              label: const Text('Add Label'),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, ColorScheme colorScheme,
      TextTheme textTheme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          text,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
