import 'package:flutter/material.dart';
import '../models/print_session.dart';
import '../services/session_service.dart';
import 'session_detail_screen.dart';
import 'thermal_printer_settings_screen.dart';
import 'from_contacts_manager_screen.dart';
import 'font_settings_screen.dart';

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
        _sessions = sessions..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
        content: Text('Are you sure you want to delete the session: ${session.getDisplayName()}?'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Sessions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'printer_settings':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ThermalPrinterSettingsScreen(),
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
                      const Icon(
                        Icons.print_disabled,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No sessions found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your first print session to get started',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _createNewSession,
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Session'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSessions,
                  child: ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: session.allLabelsReady
                                ? Colors.green
                                : session.hasReadyLabels
                                    ? Colors.orange  
                                    : Colors.red,
                            child: Icon(
                              session.allLabelsReady
                                  ? Icons.check
                                  : session.hasReadyLabels
                                      ? Icons.warning
                                      : Icons.error,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(session.getDisplayName()),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Created: ${_formatDate(session.createdAt)}'),
                              Text('Updated: ${_formatDate(session.updatedAt)}'),
                              Text(session.getStatusText()),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
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
                          onTap: () => _editSession(session),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewSession,
        tooltip: 'Create New Session',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
