import 'package:flutter/material.dart';
import '../models/print_session.dart';
import '../services/session_service.dart';
import '../widgets/material3_components.dart';
import 'session_detail_screen.dart';
import 'thermal_printer_settings_screen.dart';
import 'from_contacts_manager_screen.dart';
import 'font_settings_screen.dart';
import 'label_designer_list_screen.dart';
import 'material3_showcase_screen.dart';
import 'logo_manager_screen.dart';

class SessionsListScreen extends StatefulWidget {
  const SessionsListScreen({super.key});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  final SessionService _sessionService = SessionService();
  List<PrintSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _sessionService.loadSessions();
      setState(() {
        _sessions = sessions
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sessions: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSession(PrintSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
            'Are you sure you want to delete the session: ${session.getDisplayName()}?'),
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
      try {
        await _sessionService.deleteSession(session.id);
        await _loadSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting session: $e')),
          );
        }
      }
    }
  }

  Future<void> _editSession(PrintSession session) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionDetailScreen(session: session),
      ),
    );

    if (result != null) {
      await _loadSessions();
    }
  }

  Future<void> _createNewSession() async {
    // Show dialog to get session name
    final controller = TextEditingController();
    final sessionName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Session'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Session Name',
            hintText: 'Enter session name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (sessionName != null && sessionName.isNotEmpty) {
      final newSession = PrintSession.empty(sessionName: sessionName);
      await _sessionService.addSession(newSession);
      await _loadSessions();

      if (mounted) {
        // Navigate to the new session
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SessionDetailScreen(session: newSession),
          ),
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
        title: const Text('Print Sessions'),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 3,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurfaceVariant),
            onSelected: (value) {
              switch (value) {
                case 'printer_settings':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const ThermalPrinterSettingsScreen(),
                    ),
                  );
                  break;
                case 'font_settings':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FontSettingsScreen(),
                    ),
                  );
                  break;
                case 'from_contacts':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FromContactsManagerScreen(),
                    ),
                  );
                  break;
                case 'logo_manager':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LogoManagerScreen(),
                    ),
                  );
                  break;
                case 'label_designer':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LabelDesignerListScreen(),
                    ),
                  );
                  break;
                case 'material3_showcase':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Material3ShowcaseScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'from_contacts',
                child: Row(
                  children: [
                    Icon(Icons.contact_phone),
                    SizedBox(width: 8),
                    Text('FROM Contacts'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logo_manager',
                child: Row(
                  children: [
                    Icon(Icons.image),
                    SizedBox(width: 8),
                    Text('Logo Manager'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'label_designer',
                child: Row(
                  children: [
                    Icon(Icons.design_services),
                    SizedBox(width: 8),
                    Text('Label Designer'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'material3_showcase',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome),
                    SizedBox(width: 8),
                    Text('Material 3 Demo'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'printer_settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Printer Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'font_settings',
                child: Row(
                  children: [
                    Icon(Icons.text_fields),
                    SizedBox(width: 8),
                    Text('Font Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.print_disabled,
                        size: 80,
                        color: colorScheme.surfaceVariant,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No sessions found',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your first print session to get started',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Material3Components.enhancedButton(
                        onPressed: _createNewSession,
                        icon: const Icon(Icons.add),
                        label: 'Create New Session',
                        isPrimary: true,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: _sessions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material3Components.enhancedCard(
                          onTap: () => _editSession(session),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: session.allLabelsReady
                                          ? Colors.green.withOpacity(0.1)
                                          : session.hasReadyLabels
                                              ? Colors.orange.withOpacity(0.1)
                                              : colorScheme.errorContainer,
                                      child: Icon(
                                        session.allLabelsReady
                                            ? Icons.check_circle
                                            : session.hasReadyLabels
                                                ? Icons.warning_amber
                                                : Icons.error_outline,
                                        color: session.allLabelsReady
                                            ? Colors.green
                                            : session.hasReadyLabels
                                                ? Colors.orange
                                                : colorScheme.error,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.getDisplayName(),
                                            style:
                                                textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            'Updated: ${_formatDate(session.updatedAt)}',
                                            style:
                                                textTheme.bodySmall?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(Icons.more_horiz,
                                          color: colorScheme.onSurfaceVariant),
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            _editSession(session);
                                            break;
                                          case 'delete':
                                            _deleteSession(session);
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
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      session.getStatusText(),
                                      style: textTheme.labelLarge?.copyWith(
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: colorScheme.outline,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewSession,
        tooltip: 'Create New Session',
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
