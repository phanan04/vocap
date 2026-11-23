import 'package:audioplayers/audioplayers.dart';
import '../core/constants/supabase_constants.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  String? _currentlyPlayingUrl;

  AudioPlayer get player => _player;
  String? get currentlyPlayingUrl => _currentlyPlayingUrl;

  /// Play Oxford 5000 US audio file by filename (e.g. 'abandon_us.mp3')
  Future<void> playAudio(String? usFileName) async {
    if (usFileName == null || usFileName.isEmpty) return;

    final url = SupabaseConstants.getAudioUrl(usFileName);
    try {
      if (_player.state == PlayerState.playing) {
        await _player.stop();
      }
      _currentlyPlayingUrl = url;
      await _player.play(UrlSource(url));
    } catch (e) {
      // Audio playback error handling
      _currentlyPlayingUrl = null;
    }
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    _currentlyPlayingUrl = null;
  }

  void dispose() {
    _player.dispose();
  }
}
