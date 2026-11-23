/// Supabase & CDN configuration constants for Vocap App
class SupabaseConstants {
  static const String supabaseUrl = 'https://boteorxtzjtalinujugc.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_WTALEZtp6ml-U7JkeiWW4Q_crYjRXJp';

  /// Cloudflare-backed Supabase CDN Base URL for Oxford 5000 US Audio MP3s
  static const String audioCdnBaseUrl =
      'https://boteorxtzjtalinujugc.supabase.co/storage/v1/object/public/vocab-audio';

  /// Helper to get full audio URL for a given US audio file name
  static String getAudioUrl(String? usFileName) {
    if (usFileName == null || usFileName.isEmpty) return '';
    return '$audioCdnBaseUrl/$usFileName';
  }
}
