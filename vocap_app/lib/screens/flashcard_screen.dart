import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/supabase_service.dart';
import '../services/progress_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/audio_play_button.dart';
import '../widgets/ielts_band_badge.dart';
import 'quiz_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final List<WordModel> words;
  final String title;

  const FlashcardScreen({
    super.key,
    required this.words,
    this.title = 'Thẻ ghi nhớ Flashcards',
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final ProgressService _progressService = ProgressService();

  late List<WordModel> _words;
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isBookmarked = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _words = List<WordModel>.from(widget.words);
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _checkBookmark();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _checkBookmark() async {
    if (_words.isEmpty || _currentIndex >= _words.length) return;
    final currentWord = _words[_currentIndex];
    final bookmarked = await _supabaseService.isWordBookmarked(currentWord.id);
    if (mounted) {
      setState(() => _isBookmarked = bookmarked);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_words.isEmpty || _currentIndex >= _words.length) return;
    final currentWord = _words[_currentIndex];
    final newState = await _supabaseService.toggleBookmark(currentWord.id, _isBookmarked);
    if (mounted) {
      setState(() => _isBookmarked = newState);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newState ? '⭐ Đã lưu vào sổ tay yêu thích!' : 'Đã bỏ lưu từ.'),
          duration: const Duration(seconds: 1),
          backgroundColor: newState ? AppTheme.primary : Colors.grey.shade800,
        ),
      );
    }
  }

  void _flipCard() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  Future<void> _handleSrsQuality(int quality) async {
    final currentWord = _words[_currentIndex];

    // Record progress locally
    await _progressService.recordReview(currentWord.id, quality);

    // Submit to Supabase SM-2 SRS engine in background
    _supabaseService.submitSrsReview(
      wordId: currentWord.id,
      quality: quality,
      reviewType: 'flashcard',
    );

    // If rated Again (1: Quên), re-queue word at the end of the session to reinforce recall
    if (quality == 1) {
      setState(() {
        _words.add(currentWord);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔁 Đã thêm "${currentWord.word}" vào cuối phiên để ôn lại!'),
            duration: const Duration(milliseconds: 1400),
            backgroundColor: AppTheme.qualityAgain,
          ),
        );
      }
    }

    if (_currentIndex < _words.length - 1) {
      if (_isFlipped) {
        await _flipController.reverse();
        _isFlipped = false;
      }
      setState(() => _currentIndex++);
      _checkBookmark();
    } else {
      _showCompletionDialog();
    }
  }

  Future<void> _handleMarkAsKnown() async {
    final currentWord = _words[_currentIndex];

    // Record progress locally
    await _progressService.recordReview(currentWord.id, 4);

    // Call Supabase RPC
    _supabaseService.markWordAsKnown(currentWord.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã đánh dấu "${currentWord.word}" là đã thuộc (sẽ không xuất hiện lại).'),
          duration: const Duration(milliseconds: 1500),
          backgroundColor: Colors.green.shade800,
        ),
      );
    }

    if (_currentIndex < _words.length - 1) {
      if (_isFlipped) {
        await _flipController.reverse();
        _isFlipped = false;
      }
      setState(() => _currentIndex++);
      _checkBookmark();
    } else {
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Chúc mừng!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            Text(
              'Bạn đã nạp xong ${widget.words.length} từ vựng!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Làm ngay bài trắc nghiệm nhanh để kiểm tra phản xạ và khắc sâu trí nhớ nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.3),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      words: widget.words,
                      title: 'Củng Cố ${widget.words.length} Từ Vừa Học',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.quiz, size: 18),
              label: const Text('Củng Cố Bằng Bài Quiz ➔', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Về Trang Chủ', style: TextStyle(color: AppTheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Không có từ vựng nào cần ôn tập hôm nay!')),
      );
    }

    final word = _words[_currentIndex];
    final progress = (_currentIndex + 1) / _words.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_words.length}'),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? Colors.amber : AppTheme.textMuted,
            ),
            tooltip: _isBookmarked ? 'Bỏ lưu từ' : 'Lưu từ vào sổ tay',
            onPressed: _toggleBookmark,
          ),
          Tooltip(
            message: 'Đánh dấu từ này là đã thuộc (không học lại nữa)',
            child: TextButton.icon(
              onPressed: _handleMarkAsKnown,
              icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 18),
              label: const Text(
                'Đã biết',
                style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Topic Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (word.sessionType != null) ...[
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: word.sessionType == 'review'
                                      ? const Color(0xFFF97316).withValues(alpha: 0.2)
                                      : const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: word.sessionType == 'review'
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFF10B981),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  word.sessionType == 'review' ? '🔥 ÔN LẠI' : '✨ TỪ MỚI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: word.sessionType == 'review'
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                word.topic,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IeltsBandBadge(band: word.ieltsBand, cefr: word.cefr),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Flip Flashcard
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: _flipCard,
                      child: AnimatedBuilder(
                        animation: _flipAnimation,
                        builder: (context, child) {
                          final angle = _flipAnimation.value * pi;
                          final isFront = angle < (pi / 2);
                          return Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(angle),
                            alignment: Alignment.center,
                            child: isFront
                                ? _buildFrontCard(word)
                                : Transform(
                                    transform: Matrix4.identity()..rotateY(pi),
                                    alignment: Alignment.center,
                                    child: _buildBackCard(word),
                                  ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // SM-2 Review Buttons (Visible after card is flipped)
                if (_isFlipped) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        _buildSrsButton('Quên', 'Again', AppTheme.qualityAgain, () => _handleSrsQuality(1)),
                        const SizedBox(width: 8),
                        _buildSrsButton('Khó', 'Hard', AppTheme.qualityHard, () => _handleSrsQuality(2)),
                        const SizedBox(width: 8),
                        _buildSrsButton('Nhớ', 'Good', AppTheme.qualityGood, () => _handleSrsQuality(3)),
                        const SizedBox(width: 8),
                        _buildSrsButton('Dễ', 'Easy', AppTheme.qualityEasy, () => _handleSrsQuality(4)),
                      ],
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: _handleMarkAsKnown,
                      icon: const Icon(Icons.done_all, size: 16, color: Colors.greenAccent),
                      label: const Text(
                        'Từ này tôi đã thuộc hoàn toàn (Bỏ qua, không học lại)',
                        style: TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      onPressed: _flipCard,
                      icon: const Icon(Icons.touch_app, size: 20),
                      label: const Text('Chạm thẻ để xem nghĩa & chi tiết IELTS'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        foregroundColor: AppTheme.textMuted,
                        side: const BorderSide(color: Color(0xFF334155)),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(WordModel word) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                word.word,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  word.type,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (word.phonNAm != null && word.phonNAm!.isNotEmpty)
                Text(
                  word.phonNAm!,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  if (word.us != null && word.us!.isNotEmpty)
                    AudioPlayButton(
                      usAudioFile: word.us,
                      label: 'Phát âm US',
                      size: 46,
                      color: AppTheme.primary,
                    ),
                  if (word.uk != null && word.uk!.isNotEmpty)
                    AudioPlayButton(
                      audioFile: word.uk,
                      label: 'Phát âm UK',
                      size: 46,
                      color: AppTheme.accent,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(WordModel word) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Headword & Audio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.word,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${word.type} • ${word.phonNAm ?? ""}',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (word.us != null && word.us!.isNotEmpty)
                      AudioPlayButton(usAudioFile: word.us, size: 38, color: const Color(0xFF38BDF8)),
                    if (word.uk != null && word.uk!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      AudioPlayButton(audioFile: word.uk, size: 38, color: const Color(0xFFA78BFA)),
                    ],
                  ],
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFF334155)),

            // Vietnamese Meaning
            const Text('Nghĩa tiếng Việt:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            Text(
              word.meaningVi,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF34D399), // Emerald highlight
              ),
            ),
            const SizedBox(height: 16),

            // English Definition
            const Text('Định nghĩa Oxford:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            Text(
              word.definition,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),

            // Bilingual Example
            const Text('Ví dụ mẫu:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: const Border(left: BorderSide(color: AppTheme.primary, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.example,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    word.exampleVi,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Word Family (if available)
            if (word.wordFamily.isNotEmpty) ...[
              const Text('Gia đình từ (Word Family):', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: word.wordFamily.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFFBBF24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Collocations
            if (word.collocations.isNotEmpty) ...[
              const Text('Cụm từ Collocations ăn điểm:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: word.collocations.map((col) => Chip(
                  label: Text(col, style: const TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Synonyms
            if (word.synonyms.isNotEmpty) ...[
              const Text('Từ đồng nghĩa (Synonyms):', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: word.synonyms.take(4).map((syn) => Chip(
                  label: Text(syn, style: const TextStyle(fontSize: 12, color: Color(0xFF93C5FD))),
                  backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSrsButton(String viLabel, String enLabel, Color color, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.14),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.35), width: 0.8),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
            const SizedBox(height: 1),
            Text(enLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
