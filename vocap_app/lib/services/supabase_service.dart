import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word_model.dart';
import 'offline_service.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  final OfflineService _offlineService = OfflineService();

  SupabaseClient get client => _client;
  OfflineService get offlineService => _offlineService;

  /// Get list of words by topic with pagination and optional band filter
  Future<List<WordModel>> getWordsByTopic(
    String topic, {
    String? band,
    int limit = 1000,
    int offset = 0,
  }) async {
    var query = _client.from('words').select().eq('topic', topic);
    if (band != null && band != 'All' && band.isNotEmpty) {
      query = query.eq('ielts_band', band);
    }

    final response = await query
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>)
        .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get list of words by IELTS Band
  Future<List<WordModel>> getWordsByIeltsBand(String band, {int limit = 50, int offset = 0}) async {
    final response = await _client
        .from('words')
        .select()
        .eq('ielts_band', band)
        .order('id', ascending: true)
        .range(offset, offset + limit - 1);

    return (response as List<dynamic>)
        .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Comprehensive Search and Multi-criteria Filter with Total Count
  Future<Map<String, dynamic>> filterWordsWithCount({
    String? query,
    String? topic,
    String? band,
    String? cefr,
    String? type,
    bool? hasCollocations,
    String sortBy = 'id_asc',
    int limit = 50,
    int offset = 0,
  }) async {
    var queryBuilder = _client.from('words').select();

    // 1. Text Search (English headword or Vietnamese meaning)
    if (query != null && query.trim().isNotEmpty) {
      final sanitized = query.trim().replaceAll("'", "''");
      queryBuilder = queryBuilder.or('word.ilike.%$sanitized%,meaning_vi.ilike.%$sanitized%');
    }

    // 2. Topic Filter
    if (topic != null && topic != 'All' && topic.isNotEmpty) {
      queryBuilder = queryBuilder.eq('topic', topic);
    }

    // 3. Band Filter
    if (band != null && band != 'All' && band.isNotEmpty) {
      queryBuilder = queryBuilder.eq('ielts_band', band);
    }

    // 4. CEFR Filter
    if (cefr != null && cefr != 'All' && cefr.isNotEmpty) {
      queryBuilder = queryBuilder.ilike('cefr', cefr.toLowerCase());
    }

    // 5. Part of speech Filter (type)
    if (type != null && type != 'All' && type.isNotEmpty) {
      queryBuilder = queryBuilder.ilike('type', '%$type%');
    }

    // 6. Collocations Filter
    if (hasCollocations == true) {
      queryBuilder = queryBuilder.not('collocations', 'is', null).neq('collocations', '{}');
    }

    // 7. Sort Order & Range (Transform) with exact count
    PostgrestTransformBuilder transformBuilder;
    if (sortBy == 'word_asc') {
      transformBuilder = queryBuilder.order('word', ascending: true);
    } else if (sortBy == 'word_desc') {
      transformBuilder = queryBuilder.order('word', ascending: false);
    } else if (sortBy == 'cefr_asc') {
      transformBuilder = queryBuilder.order('cefr', ascending: true);
    } else if (sortBy == 'cefr_desc') {
      transformBuilder = queryBuilder.order('cefr', ascending: false);
    } else {
      transformBuilder = queryBuilder.order('id', ascending: true);
    }

    final response = await transformBuilder
        .range(offset, offset + limit - 1)
        .count(CountOption.exact);

    final words = (response.data as List<dynamic>)
        .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return {
      'words': words,
      'total': response.count,
    };
  }

  /// Comprehensive Search and Multi-criteria Filter
  Future<List<WordModel>> filterWords({
    String? query,
    String? topic,
    String? band,
    String? cefr,
    String? type,
    bool? hasCollocations,
    String sortBy = 'id_asc',
    int limit = 50,
    int offset = 0,
  }) async {
    var queryBuilder = _client.from('words').select();

    // 1. Text Search (English headword or Vietnamese meaning)
    if (query != null && query.trim().isNotEmpty) {
      final sanitized = query.trim().replaceAll("'", "''");
      queryBuilder = queryBuilder.or('word.ilike.%$sanitized%,meaning_vi.ilike.%$sanitized%');
    }

    // 2. Topic Filter
    if (topic != null && topic != 'All' && topic.isNotEmpty) {
      queryBuilder = queryBuilder.eq('topic', topic);
    }

    // 3. Band Filter
    if (band != null && band != 'All' && band.isNotEmpty) {
      queryBuilder = queryBuilder.eq('ielts_band', band);
    }

    // 4. CEFR Filter
    if (cefr != null && cefr != 'All' && cefr.isNotEmpty) {
      queryBuilder = queryBuilder.ilike('cefr', cefr.toLowerCase());
    }

    // 5. Part of speech Filter (type)
    if (type != null && type != 'All' && type.isNotEmpty) {
      queryBuilder = queryBuilder.ilike('type', '%$type%');
    }

    // 6. Collocations Filter
    if (hasCollocations == true) {
      queryBuilder = queryBuilder.not('collocations', 'is', null).neq('collocations', '{}');
    }

    // 7. Sort Order & Range (Transform)
    PostgrestTransformBuilder transformBuilder;
    if (sortBy == 'word_asc') {
      transformBuilder = queryBuilder.order('word', ascending: true);
    } else if (sortBy == 'word_desc') {
      transformBuilder = queryBuilder.order('word', ascending: false);
    } else if (sortBy == 'cefr_asc') {
      transformBuilder = queryBuilder.order('cefr', ascending: true);
    } else if (sortBy == 'cefr_desc') {
      transformBuilder = queryBuilder.order('cefr', ascending: false);
    } else {
      transformBuilder = queryBuilder.order('id', ascending: true);
    }

    final response = await transformBuilder.range(offset, offset + limit - 1);
    return (response as List<dynamic>)
        .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Instant search words by keyword (English word or Vietnamese meaning)
  Future<List<WordModel>> searchWords(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];

    final response = await _client
        .from('words')
        .select()
        .or('word.ilike.%$query%,meaning_vi.ilike.%$query%')
        .order('id', ascending: true)
        .limit(limit);

    return (response as List<dynamic>)
        .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all distinct topics with word counts via RPC (optionally filtered by band)
  Future<List<Map<String, dynamic>>> getTopicsWithCounts({String? band}) async {
    try {
      final effectiveBand = (band != null && band.isNotEmpty) ? band : 'All';
      final response = await _client.rpc('get_topic_stats', params: {'p_band': effectiveBand});
      return (response as List<dynamic>)
          .map((e) => {
                'topic': e['topic'] as String,
                'count': (e['word_count'] as num).toInt(),
              })
          .where((item) => (item['count'] as int) > 0)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get unified smart study session: SM-2 Reviews First + Thematic Adaptive New Words
  Future<List<WordModel>> getSmartStudySession({
    String targetBand = '6.5',
    String currentBand = '5.5',
    int limit = 20,
  }) async {
    final user = _client.auth.currentUser;
    try {
      final response = await _client.rpc('get_smart_study_session', params: {
        'p_user_id': user?.id,
        'p_target_band': targetBand,
        'p_limit': limit,
        'p_current_band': currentBand,
      });

      final words = (response as List<dynamic>)
          .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return words;
    } catch (_) {
      // Offline fallback
      final cached = await _offlineService.getCachedWords();
      if (cached.isNotEmpty) {
        return cached.take(limit).toList();
      }
      return [];
    }
  }

  /// Fetch words at or above a minimum IELTS band
  Future<List<WordModel>> getWordsAtOrAboveBand(double minBand, {int limit = 20}) async {
    final List<String> allowedBands = [];
    if (minBand <= 2.5) allowedBands.add('1.0 - 2.5');
    if (minBand <= 3.5) allowedBands.add('3.0 - 3.5');
    if (minBand <= 5.0) allowedBands.add('4.0 - 5.0');
    if (minBand <= 6.5) allowedBands.add('5.5 - 6.5');
    if (minBand <= 8.0) allowedBands.add('7.0 - 8.0');
    allowedBands.add('8.5 - 9.0');

    try {
      final response = await _client
          .from('words')
          .select()
          .inFilter('ielts_band', allowedBands)
          .order('id', ascending: true)
          .limit(limit);

      return (response as List<dynamic>)
          .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fetch ALL words in batches for full offline mode
  Future<List<WordModel>> fetchAllWordsForOffline({void Function(int loaded)? onProgress}) async {
    final List<WordModel> allWords = [];
    int offset = 0;
    const int pageSize = 1000;

    while (true) {
      final response = await _client
          .from('words')
          .select()
          .order('id', ascending: true)
          .range(offset, offset + pageSize - 1);

      final batch = (response as List<dynamic>)
          .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (batch.isEmpty) break;
      allWords.addAll(batch);
      onProgress?.call(allWords.length);

      if (batch.length < pageSize) break;
      offset += pageSize;
    }

    return allWords;
  }

  /// Bulk skip all words below current assessed band
  Future<Map<String, dynamic>> skipWordsBelowBand(String currentBand) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return {'status': 'guest_mode', 'success': true};
    }

    try {
      final response = await _client.rpc('skip_words_below_band', params: {
        'p_current_band': currentBand,
      });
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      return {'status': 'error', 'error': e.toString()};
    }
  }

  /// Fetch due words for SM-2 Spaced Repetition review (with offline cache fallback)
  Future<List<WordModel>> getDueWords({int limit = 20}) async {
    final user = _client.auth.currentUser;
    try {
      List<WordModel> words = [];
      if (user == null) {
        // Demo / Guest mode: return first 20 words
        final response = await _client
            .from('words')
            .select()
            .order('id', ascending: true)
            .limit(limit);
        words = (response as List<dynamic>)
            .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        final response = await _client.rpc('get_due_words', params: {
          'p_limit': limit,
        });

        words = (response as List<dynamic>)
            .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // Cache words locally for offline review
      if (words.isNotEmpty) {
        await _offlineService.cacheWords(words);
      }
      return words;
    } catch (_) {
      // Fallback to offline cached words
      final cached = await _offlineService.getCachedWords();
      if (cached.isNotEmpty) {
        return cached.take(limit).toList();
      }
      return [];
    }
  }

  /// Submit an SM-2 SRS review score (0: Again, 3: Hard, 4: Good, 5: Easy)
  Future<Map<String, dynamic>> submitSrsReview({
    required int wordId,
    required int quality,
    int responseTimeMs = 0,
    String reviewType = 'flashcard',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return {'status': 'guest_mode', 'success': true};
    }

    try {
      final response = await _client.rpc('submit_srs_review', params: {
        'p_word_id': wordId,
        'p_rating': quality,
      });

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      // Offline fallback: Queue review action locally
      await _offlineService.queueOfflineReview(
        wordId: wordId,
        quality: quality,
        responseTimeMs: responseTimeMs,
        reviewType: reviewType,
      );
      return {'status': 'offline_queued', 'success': true};
    }
  }

  /// Mark a word as already known / mastered so it won't appear in study sessions
  Future<Map<String, dynamic>> markWordAsKnown(int wordId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      // Guest mode: record locally
      return {'status': 'guest_mode', 'success': true};
    }

    try {
      final response = await _client.rpc('mark_word_as_known', params: {
        'p_word_id': wordId,
      });
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      // Fallback: submit rating 4 with reviewType 'mastered'
      return submitSrsReview(wordId: wordId, quality: 4, reviewType: 'mastered');
    }
  }

  /// Get count of words learned or reviewed today from Supabase Cloud
  Future<int?> getTodayLearnedCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // 1. Check study_logs for today
      final res = await _client
          .from('study_logs')
          .select('words_reviewed')
          .eq('user_id', user.id)
          .eq('study_date', todayStr)
          .maybeSingle();

      if (res != null && res['words_reviewed'] != null) {
        return (res['words_reviewed'] as num).toInt();
      }

      // 2. Fallback: check count of user_words reviewed today
      final countRes = await _client
          .from('user_words')
          .select()
          .eq('user_id', user.id)
          .gte('last_reviewed_at', '${todayStr}T00:00:00')
          .count(CountOption.exact);

      return countRes.count;
    } catch (_) {
      return null;
    }
  }

  /// Get real user stats from Supabase (actual words learned & mastered) with exact count
  Future<Map<String, int>?> getUserCloudStats() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final learnedRes = await _client
          .from('user_words')
          .select()
          .eq('user_id', user.id)
          .neq('status', 'mastered')
          .count(CountOption.exact);

      final masteredRes = await _client
          .from('user_words')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'mastered')
          .count(CountOption.exact);

      return {
        'totalLearned': learnedRes.count,
        'totalMastered': masteredRes.count,
      };
    } catch (_) {
      return null;
    }
  }

  /// Toggle word bookmark
  Future<bool> toggleBookmark(int wordId, bool isBookmarked) async {
    final user = _client.auth.currentUser;
    final newBookmarkState = !isBookmarked;

    if (user != null) {
      try {
        await _client.from('user_words').upsert({
          'user_id': user.id,
          'word_id': wordId,
          'is_bookmarked': newBookmarkState,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id,word_id');
      } catch (_) {}
    }

    // Also persist in local SharedPreferences for offline & Guest
    await _offlineService.toggleLocalBookmark(wordId, newBookmarkState);
    return newBookmarkState;
  }

  /// Check if a word is bookmarked
  Future<bool> isWordBookmarked(int wordId) async {
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        final res = await _client
            .from('user_words')
            .select('is_bookmarked')
            .eq('user_id', user.id)
            .eq('word_id', wordId)
            .maybeSingle();
        if (res != null && res['is_bookmarked'] != null) {
          return res['is_bookmarked'] as bool;
        }
      } catch (_) {}
    }
    return _offlineService.isLocalBookmarked(wordId);
  }
}
