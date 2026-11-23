import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';
import 'supabase_service.dart';

/// Manages offline vocabulary caching and offline SRS review queue
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  static const String _keyCachedWords = 'cached_words_json';
  static const String _keyOfflineReviewQueue = 'offline_review_queue';
  static const String _keyDailyReminderHour = 'reminder_hour';
  static const String _keyDailyReminderMinute = 'reminder_minute';
  static const String _keyReminderEnabled = 'reminder_enabled';

  /// Save words list to local disk cache
  Future<void> cacheWords(List<WordModel> words) async {
    if (words.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final wordsJsonList = words.map((w) => jsonEncode(w.toJson())).toList();
      await prefs.setStringList(_keyCachedWords, wordsJsonList);
    } catch (_) {
      // Ignore cache write errors
    }
  }

  /// Load cached words when offline
  Future<List<WordModel>> getCachedWords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wordsJsonList = prefs.getStringList(_keyCachedWords) ?? [];
      if (wordsJsonList.isEmpty) return [];

      return wordsJsonList
          .map((item) => WordModel.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Queue an SRS review action when device is offline
  Future<void> queueOfflineReview({
    required int wordId,
    required int quality,
    required int responseTimeMs,
    required String reviewType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_keyOfflineReviewQueue) ?? [];

      final item = jsonEncode({
        'word_id': wordId,
        'quality': quality,
        'response_time_ms': responseTimeMs,
        'review_type': reviewType,
        'timestamp': DateTime.now().toIso8601String(),
      });

      queue.add(item);
      await prefs.setStringList(_keyOfflineReviewQueue, queue);
    } catch (_) {}
  }

  /// Sync all queued offline reviews to Supabase when back online
  Future<int> flushOfflineQueue(SupabaseService supabaseService) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_keyOfflineReviewQueue) ?? [];
      if (queue.isEmpty) return 0;

      int syncedCount = 0;
      final remaining = <String>[];

      for (final itemStr in queue) {
        try {
          final item = jsonDecode(itemStr) as Map<String, dynamic>;
          await supabaseService.submitSrsReview(
            wordId: item['word_id'] as int,
            quality: item['quality'] as int,
            responseTimeMs: item['response_time_ms'] as int? ?? 1000,
            reviewType: item['review_type'] as String? ?? 'flashcard',
          );
          syncedCount++;
        } catch (_) {
          remaining.add(itemStr);
        }
      }

      await prefs.setStringList(_keyOfflineReviewQueue, remaining);
      return syncedCount;
    } catch (_) {
      return 0;
    }
  }

  /// Get pending offline reviews count
  Future<int> getPendingQueueCount() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_keyOfflineReviewQueue) ?? [];
    return queue.length;
  }

  /// Reminder Settings
  Future<Map<String, dynamic>> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enabled': prefs.getBool(_keyReminderEnabled) ?? true,
      'hour': prefs.getInt(_keyDailyReminderHour) ?? 20, // 20:00 (8:00 PM)
      'minute': prefs.getInt(_keyDailyReminderMinute) ?? 0,
    };
  }

  Future<void> saveReminderSettings({required bool enabled, required int hour, required int minute}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderEnabled, enabled);
    await prefs.setInt(_keyDailyReminderHour, hour);
    await prefs.setInt(_keyDailyReminderMinute, minute);
  }
}
