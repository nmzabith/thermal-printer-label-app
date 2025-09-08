import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/print_session.dart';

class SessionService {
  static const String _sessionsKey = 'print_sessions';
  static const String _currentSessionKey = 'current_session';

  // Save all sessions to storage
  Future<void> saveSessions(List<PrintSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = sessions.map((session) => session.toMap()).toList();
      await prefs.setString(_sessionsKey, jsonEncode(sessionsJson));
    } catch (e) {
      print('Error saving sessions: $e');
    }
  }

  // Load all sessions from storage
  Future<List<PrintSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsString = prefs.getString(_sessionsKey);
      
      if (sessionsString == null) return [];
      
      final sessionsList = jsonDecode(sessionsString) as List;
      return sessionsList
          .map((sessionMap) => PrintSession.fromMap(sessionMap))
          .toList();
    } catch (e) {
      print('Error loading sessions: $e');
      return [];
    }
  }

  // Save current session
  Future<void> saveCurrentSession(PrintSession? session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (session == null) {
        await prefs.remove(_currentSessionKey);
      } else {
        await prefs.setString(_currentSessionKey, jsonEncode(session.toMap()));
      }
    } catch (e) {
      print('Error saving current session: $e');
    }
  }

  // Load current session
  Future<PrintSession?> loadCurrentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionString = prefs.getString(_currentSessionKey);
      
      if (sessionString == null) return null;
      
      final sessionMap = jsonDecode(sessionString) as Map<String, dynamic>;
      return PrintSession.fromMap(sessionMap);
    } catch (e) {
      print('Error loading current session: $e');
      return null;
    }
  }

  // Add a new session
  Future<void> addSession(PrintSession session) async {
    final sessions = await loadSessions();
    sessions.add(session);
    await saveSessions(sessions);
  }

  // Update existing session
  Future<void> updateSession(PrintSession session) async {
    final sessions = await loadSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      session.updateTimestamp();
      sessions[index] = session;
      await saveSessions(sessions);
    }
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    final sessions = await loadSessions();
    sessions.removeWhere((session) => session.id == sessionId);
    await saveSessions(sessions);
  }

  // Get session by ID
  Future<PrintSession?> getSessionById(String sessionId) async {
    final sessions = await loadSessions();
    try {
      return sessions.firstWhere((session) => session.id == sessionId);
    } catch (e) {
      return null;
    }
  }
}
