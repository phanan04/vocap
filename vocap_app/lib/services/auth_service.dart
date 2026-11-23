import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'progress_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign Up with Email and Password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
    String targetBand = '6.5',
    int dailyTarget = 10,
  }) async {
    // Clear previous guest/device progress so new user starts completely clean
    await ProgressService().clearLocalProgress();

    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': displayName.trim(),
        'target_band': targetBand,
        'daily_target': dailyTarget,
      },
    );

    return response;
  }

  /// Sign In with Email and Password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    return response;
  }

  /// Sign Out
  Future<void> signOut() async {
    await _client.auth.signOut();
    await ProgressService().clearLocalProgress();
  }

  /// Fetch user profile from Supabase profiles table
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return data;
    } catch (_) {
      return null;
    }
  }

  /// Update user profile (Target Band, Current Band, Daily Target, Display Name)
  Future<void> updateProfile({
    String? displayName,
    String? targetBand,
    String? currentBand,
    int? dailyTarget,
  }) async {
    final user = currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (displayName != null) updates['display_name'] = displayName;
    if (targetBand != null) updates['target_band'] = targetBand;
    if (currentBand != null) updates['current_band'] = currentBand;
    if (dailyTarget != null) updates['daily_target'] = dailyTarget;

    await _client.from('profiles').update(updates).eq('id', user.id);
  }

  /// Sync local Guest progress to Cloud database upon login
  Future<void> syncLocalProgressToCloud() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final localLearned = prefs.getStringList('total_learned_ids') ?? [];

      for (final idStr in localLearned) {
        final wordId = int.tryParse(idStr);
        if (wordId != null) {
          await _client.rpc('submit_srs_review', params: {
            'p_user_id': user.id,
            'p_word_id': wordId,
            'p_quality': 4,
            'p_response_time_ms': 1000,
            'p_review_type': 'sync',
          });
        }
      }
    } catch (_) {
      // Ignore background sync errors
    }
  }
}
