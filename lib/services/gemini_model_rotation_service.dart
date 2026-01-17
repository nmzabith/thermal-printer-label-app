import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/gemini_model_status.dart';

/// Service for managing Gemini API model rotation to handle rate limits
/// Automatically switches between models when rate limits are hit
/// Resets to top-performing model after daily quota refresh (midnight Pacific Time)
class GeminiModelRotationService {
  static final GeminiModelRotationService _instance =
      GeminiModelRotationService._internal();
  factory GeminiModelRotationService() => _instance;
  GeminiModelRotationService._internal();

  static const String _storageKey = 'gemini_model_statuses';
  static const String _lastResetCheckKey = 'gemini_last_reset_check';

  /// Available Gemini models ordered by performance (best first)
  late List<GeminiModelStatus> _models;

  DateTime? _lastResetCheck;
  bool _initialized = false;

  /// Initialize the service and load saved state
  Future<void> initialize() async {
    if (_initialized) return;

    // All available Gemini free tier models
    // Ordered by daily quota (RPD) for maximum usage, then by RPM
    _models = [
      // Highest daily quota models (1500 RPD)
      GeminiModelStatus(
        modelName: 'gemini-2.5-flash-lite',
        displayName: 'Gemini 2.5 Flash-Lite',
        rpmLimit: 30,
        rpdLimit: 1500,
        priority: 1, // Best: Highest throughput
      ),

      // Previous generation stable models (good fallbacks)
      GeminiModelStatus(
        modelName: 'gemini-2.0-flash',
        displayName: 'Gemini 2.0 Flash',
        rpmLimit: 15,
        rpdLimit: 1500,
        priority: 2,
      ),
      GeminiModelStatus(
        modelName: 'gemini-2.0-flash-lite',
        displayName: 'Gemini 2.0 Flash-Lite',
        rpmLimit: 15,
        rpdLimit: 1500,
        priority: 3,
      ),

      // Preview/Experimental models (moderate quotas)
      GeminiModelStatus(
        modelName: 'gemini-3-pro-preview',
        displayName: 'Gemini 3 Pro (Preview)',
        rpmLimit: 5,
        rpdLimit: 100,
        priority: 4, // Most capable but limited quota
      ),

      // Lower daily quota models (use when others exhausted)
      GeminiModelStatus(
        modelName: 'gemini-2.5-pro',
        displayName: 'Gemini 2.5 Pro',
        rpmLimit: 5,
        rpdLimit: 25,
        priority: 5, // Best reasoning, but very limited
      ),
      GeminiModelStatus(
        modelName: 'gemini-3-flash-preview',
        displayName: 'Gemini 3 Flash (Preview)',
        rpmLimit: 5,
        rpdLimit: 20,
        priority: 6,
      ),
      GeminiModelStatus(
        modelName: 'gemini-2.5-flash',
        displayName: 'Gemini 2.5 Flash',
        rpmLimit: 5,
        rpdLimit: 20,
        priority: 7,
      ),
    ];

    await _loadState();
    await _checkAndResetIfNeeded();
    _initialized = true;
  }

  /// Get the currently available model (best performing one that's not rate limited)
  Future<String> getCurrentModel() async {
    await initialize();
    await _checkAndResetIfNeeded();

    final now = DateTime.now();
    final nextReset = _calculateNextResetTime(now);

    // Find first available model (sorted by priority)
    for (var model in _models) {
      if (model.isAvailable(now, nextReset)) {
        print(
            'Selected model: ${model.modelName} (priority: ${model.priority})');
        return model.modelName;
      }
    }

    // If all models are rate limited, return the best one anyway
    // (user will get rate limit error but can try again after reset)
    print('WARNING: All models are rate limited. Using top priority model.');
    return _models.first.modelName;
  }

  /// Mark a model as rate limited (call this when you get HTTP 429 error)
  Future<void> markModelRateLimited(String modelName) async {
    await initialize();

    final model = _models.firstWhere(
      (m) => m.modelName == modelName,
      orElse: () => _models.first,
    );

    model.markRateLimited();
    await _saveState();

    print(
        'Model ${model.displayName} marked as rate limited at ${model.rateLimitHitTime}');
    print('Next reset: ${_calculateNextResetTime(DateTime.now())}');
  }

  /// Increment request count for a model
  Future<void> incrementRequestCount(String modelName) async {
    await initialize();

    final model = _models.firstWhere(
      (m) => m.modelName == modelName,
      orElse: () => _models.first,
    );

    model.requestCount++;

    // Save periodically (every 10 requests to avoid excessive writes)
    if (model.requestCount % 10 == 0) {
      await _saveState();
    }
  }

  /// Get status of all models for debugging/UI
  Future<List<GeminiModelStatus>> getAllModelStatuses() async {
    await initialize();
    await _checkAndResetIfNeeded();
    return List.unmodifiable(_models);
  }

  /// Calculate next midnight Pacific Time
  DateTime _calculateNextResetTime(DateTime now) {
    // Convert current time to Pacific Time (UTC-8 for PST, UTC-7 for PDT)
    // For simplicity, we'll use UTC-8 (PST) as the baseline
    // In production, you'd want to check if DST is active

    final pacificOffset = Duration(hours: -8);
    final nowInPacific = now.toUtc().add(pacificOffset);

    // Calculate next midnight Pacific Time
    var nextMidnight = DateTime(
      nowInPacific.year,
      nowInPacific.month,
      nowInPacific.day,
      0,
      0,
      0,
      0,
    ).add(Duration(days: 1));

    // Convert back to local time
    return nextMidnight.subtract(pacificOffset).toLocal();
  }

  /// Check if reset time has passed and reset all models if needed
  Future<void> _checkAndResetIfNeeded() async {
    final now = DateTime.now();

    // If we've never checked, just update the timestamp
    if (_lastResetCheck == null) {
      _lastResetCheck = now;
      await _saveState();
      return;
    }

    final nextReset = _calculateNextResetTime(_lastResetCheck!);

    // If current time is after the next reset time, reset all models
    if (now.isAfter(nextReset)) {
      print('Daily quota reset detected! Resetting all models.');
      for (var model in _models) {
        model.resetRateLimit();
      }
      _lastResetCheck = now;
      await _saveState();
    }
  }

  /// Load saved model statuses from persistent storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load model statuses
      final statusesJson = prefs.getString(_storageKey);
      if (statusesJson != null) {
        final List<dynamic> statusesList = jsonDecode(statusesJson);

        // Update existing models with saved data
        for (var savedStatus in statusesList) {
          final modelName = savedStatus['modelName'] as String;
          final existingModel = _models.firstWhere(
            (m) => m.modelName == modelName,
            orElse: () => _models.first,
          );

          // Restore rate limit info
          if (savedStatus['rateLimitHitTime'] != null) {
            existingModel.rateLimitHitTime =
                DateTime.parse(savedStatus['rateLimitHitTime']);
          }
          existingModel.requestCount = savedStatus['requestCount'] ?? 0;
        }
      }

      // Load last reset check time
      final lastResetStr = prefs.getString(_lastResetCheckKey);
      if (lastResetStr != null) {
        _lastResetCheck = DateTime.parse(lastResetStr);
      }

      print('Loaded model rotation state from storage');
    } catch (e) {
      print('Error loading model rotation state: $e');
      // Continue with default state
    }
  }

  /// Save current model statuses to persistent storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save model statuses
      final statusesList = _models.map((m) => m.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(statusesList));

      // Save last reset check time
      if (_lastResetCheck != null) {
        await prefs.setString(
            _lastResetCheckKey, _lastResetCheck!.toIso8601String());
      }
    } catch (e) {
      print('Error saving model rotation state: $e');
    }
  }

  /// Get time until next reset (for UI display)
  Future<Duration> getTimeUntilReset() async {
    await initialize();
    final now = DateTime.now();
    final nextReset = _calculateNextResetTime(now);
    return nextReset.difference(now);
  }

  /// Get formatted reset time in user's timezone
  Future<String> getNextResetTimeFormatted() async {
    await initialize();
    final now = DateTime.now();
    final nextReset = _calculateNextResetTime(now);

    return '${nextReset.day}/${nextReset.month}/${nextReset.year} '
        '${nextReset.hour.toString().padLeft(2, '0')}:'
        '${nextReset.minute.toString().padLeft(2, '0')} IST';
  }

  /// Reset all models manually (for testing)
  Future<void> resetAllModels() async {
    await initialize();
    for (var model in _models) {
      model.resetRateLimit();
    }
    _lastResetCheck = DateTime.now();
    await _saveState();
    print('Manually reset all models');
  }
}
