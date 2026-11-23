import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  static const String _keyDailyTarget = 'daily_target';
  static const String _keyLearnedToday = 'learned_today';
  static const String _keyTodayWordIds = 'today_word_ids';
  static const String _keyLastDate = 'last_study_date';
  static const String _keyStreak = 'streak_count';
  static const String _keyTotalLearned = 'total_learned_ids';
  static const String _keyMastered = 'mastered_ids';
  static const String _keyXp = 'total_xp';

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final lastDate = prefs.getString(_keyLastDate) ?? '';

    // Reset daily counter only if it is genuinely a new day
    if (lastDate.isNotEmpty && lastDate != today) {
      final lastDateTime = DateTime.tryParse(lastDate);
      if (lastDateTime != null) {
        final diff = DateTime.now().difference(lastDateTime).inDays;
        if (diff > 1) {
          await prefs.setInt(_keyStreak, 0); // Streak broken
        }
      }
      await prefs.setStringList(_keyTodayWordIds, []);
      await prefs.setInt(_keyLearnedToday, 0);
    }

    // Always ensure lastDate is saved as today
    await prefs.setString(_keyLastDate, today);

    final todayWordsSet = (prefs.getStringList(_keyTodayWordIds) ?? []).toSet();
    int learnedToday = todayWordsSet.length;
    final savedLearnedToday = prefs.getInt(_keyLearnedToday) ?? 0;
    if (savedLearnedToday > learnedToday) {
      learnedToday = savedLearnedToday;
    }

    final streak = prefs.getInt(_keyStreak) ?? 0;
    final dailyTarget = prefs.getInt(_keyDailyTarget) ?? 10;
    final totalLearned = prefs.getStringList(_keyTotalLearned)?.length ?? 0;
    final totalMastered = prefs.getStringList(_keyMastered)?.length ?? 0;
    final xp = prefs.getInt(_keyXp) ?? 0;

    return {
      'dailyTarget': dailyTarget,
      'learnedToday': learnedToday,
      'streak': streak,
      'totalLearned': totalLearned,
      'totalMastered': totalMastered,
      'xp': xp,
    };
  }

  Future<void> recordReview(int wordId, int quality, {bool countTowardsDaily = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    final lastDate = prefs.getString(_keyLastDate) ?? '';

    int streak = prefs.getInt(_keyStreak) ?? 0;
    if (lastDate != today) {
      final lastDateTime = DateTime.tryParse(lastDate);
      if (lastDateTime != null && DateTime.now().difference(lastDateTime).inDays == 1) {
        streak++;
      } else if (lastDate.isEmpty || DateTime.now().difference(lastDateTime ?? DateTime.now()).inDays > 1) {
        streak = 1;
      }
      await prefs.setString(_keyLastDate, today);
      await prefs.setInt(_keyStreak, streak);
      await prefs.setStringList(_keyTodayWordIds, []);
    }

    // Track unique words learned today only if part of the daily study session
    if (countTowardsDaily) {
      final todayWordsSet = (prefs.getStringList(_keyTodayWordIds) ?? []).toSet();
      todayWordsSet.add(wordId.toString());
      await prefs.setStringList(_keyTodayWordIds, todayWordsSet.toList());
      await prefs.setInt(_keyLearnedToday, todayWordsSet.length);
    }

    // Track total unique learned words
    final learnedSet = (prefs.getStringList(_keyTotalLearned) ?? []).toSet();
    learnedSet.add(wordId.toString());
    await prefs.setStringList(_keyTotalLearned, learnedSet.toList());

    // Track mastered if quality is 4 (Easy) or marked as known
    if (quality >= 4) {
      final masteredSet = (prefs.getStringList(_keyMastered) ?? []).toSet();
      masteredSet.add(wordId.toString());
      await prefs.setStringList(_keyMastered, masteredSet.toList());
    }

    // Add XP
    final xpGain = quality >= 3 ? 10 : 5;
    int currentXp = (prefs.getInt(_keyXp) ?? 0) + xpGain;
    await prefs.setInt(_keyXp, currentXp);
  }

  /// Sync cloud learned count into local storage to avoid discrepancies
  Future<void> syncCloudLearnedCount(int cloudCount) async {
    if (cloudCount <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();
    await prefs.setString(_keyLastDate, today);
    final currentLearned = prefs.getInt(_keyLearnedToday) ?? 0;
    if (cloudCount > currentLearned) {
      await prefs.setInt(_keyLearnedToday, cloudCount);
    }
  }
}
