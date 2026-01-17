/// Model status data class for tracking Gemini API model availability and rate limits
class GeminiModelStatus {
  final String modelName;
  final String displayName;
  final int rpmLimit;
  final int rpdLimit;
  final int priority; // Lower number = higher priority
  DateTime? rateLimitHitTime;
  int requestCount;

  GeminiModelStatus({
    required this.modelName,
    required this.displayName,
    required this.rpmLimit,
    required this.rpdLimit,
    required this.priority,
    this.rateLimitHitTime,
    this.requestCount = 0,
  });

  /// Check if this model is currently available (not rate limited)
  bool isAvailable(DateTime now, DateTime nextResetTime) {
    // If never hit rate limit, it's available
    if (rateLimitHitTime == null) return true;

    // If reset time has passed, it's available again
    if (now.isAfter(nextResetTime)) return true;

    // Otherwise, still rate limited
    return false;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'modelName': modelName,
      'displayName': displayName,
      'rpmLimit': rpmLimit,
      'rpdLimit': rpdLimit,
      'priority': priority,
      'rateLimitHitTime': rateLimitHitTime?.toIso8601String(),
      'requestCount': requestCount,
    };
  }

  /// Create from JSON
  factory GeminiModelStatus.fromJson(Map<String, dynamic> json) {
    return GeminiModelStatus(
      modelName: json['modelName'] as String,
      displayName: json['displayName'] as String,
      rpmLimit: json['rpmLimit'] as int,
      rpdLimit: json['rpdLimit'] as int,
      priority: json['priority'] as int,
      rateLimitHitTime: json['rateLimitHitTime'] != null
          ? DateTime.parse(json['rateLimitHitTime'] as String)
          : null,
      requestCount: json['requestCount'] as int? ?? 0,
    );
  }

  /// Mark this model as rate limited
  void markRateLimited() {
    rateLimitHitTime = DateTime.now();
  }

  /// Reset rate limit status
  void resetRateLimit() {
    rateLimitHitTime = null;
    requestCount = 0;
  }

  @override
  String toString() {
    return 'GeminiModelStatus(model: $modelName, priority: $priority, '
        'rateLimitHit: ${rateLimitHitTime?.toIso8601String() ?? "never"}, '
        'requests: $requestCount)';
  }
}
