import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_model.dart';
import '../services/supabase_service.dart';
import '../services/audio_service.dart';
import '../services/progress_service.dart';
import '../core/theme/app_theme.dart';
import '../widgets/audio_play_button.dart';

enum QuizMode {
  meaningToWord, // Nghĩa tiếng Việt -> Chọn từ vựng
  wordToMeaning, // Từ tiếng Anh -> Chọn nghĩa
  listening,     // Nghe phát âm -> Chọn từ
  fillBlank,     // Điền từ vào chỗ trống trong câu ví dụ
}

class QuizScreen extends StatefulWidget {
  final List<WordModel> words;
  final List<WordModel>? distractorPool;
  final QuizMode mode;
  final String? title;

  const QuizScreen({
    super.key,
    required this.words,
    this.distractorPool,
    this.mode = QuizMode.meaningToWord,
    this.title,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final AudioService _audioService = AudioService();
  final ProgressService _progressService = ProgressService();
  final Random _random = Random();

  int _currentIndex = 0;
  int _score = 0;
  List<String> _options = [];
  String _correctAnswer = '';
  String? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  void _loadQuestion() {
    if (_currentIndex >= widget.words.length) return;

    final targetWord = widget.words[_currentIndex];
    _answered = false;
    _selectedAnswer = null;

    final effectivePool = (widget.distractorPool != null && widget.distractorPool!.isNotEmpty)
        ? widget.distractorPool!
        : widget.words;

    final Set<String> optionsSet = {};
    if (widget.mode == QuizMode.meaningToWord || widget.mode == QuizMode.listening || widget.mode == QuizMode.fillBlank) {
      _correctAnswer = targetWord.word;
      optionsSet.add(_correctAnswer);

      // Pick 3 distractors
      final shuffledPool = List<WordModel>.from(effectivePool)..shuffle(_random);
      for (final w in shuffledPool) {
        if (w.word != targetWord.word && !optionsSet.contains(w.word)) {
          optionsSet.add(w.word);
          if (optionsSet.length == 4) break;
        }
      }
    } else {
      // wordToMeaning
      _correctAnswer = targetWord.meaningVi;
      optionsSet.add(_correctAnswer);

      final shuffledPool = List<WordModel>.from(effectivePool)..shuffle(_random);
      for (final w in shuffledPool) {
        if (w.meaningVi != targetWord.meaningVi && !optionsSet.contains(w.meaningVi)) {
          optionsSet.add(w.meaningVi);
          if (optionsSet.length == 4) break;
        }
      }
    }

    _options = optionsSet.toList()..shuffle(_random);

    // Auto-play audio if in listening mode
    if (widget.mode == QuizMode.listening && targetWord.us != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _audioService.playAudio(targetWord.us);
        }
      });
    }

    setState(() {});
  }

  Future<void> _handleOptionSelect(String option) async {
    if (_answered) return;

    final isCorrect = (option == _correctAnswer);
    setState(() {
      _selectedAnswer = option;
      _answered = true;
      if (isCorrect) _score++;
    });

    // Record SRS review (XP and SM-2 update, without inflating daily new-word counter or prematurely marking mastered)
    final currentWord = widget.words[_currentIndex];
    final rating = isCorrect ? 3 : 1;
    await _progressService.recordReview(
      currentWord.id,
      rating,
      countTowardsDaily: false,
      canMarkMastered: false,
    );
    _supabaseService.submitSrsReview(
      wordId: currentWord.id,
      quality: rating,
      reviewType: 'quiz',
    );
  }

  void _nextQuestion() {
    if (_currentIndex < widget.words.length - 1) {
      setState(() => _currentIndex++);
      _loadQuestion();
    } else {
      _showQuizResults();
    }
  }

  void _showQuizResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kết Quả Bài Luyện Tập', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 70),
            const SizedBox(height: 12),
            Text(
              'Đúng $_score / ${widget.words.length} câu!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '+${_score * 10} XP tích lũy',
              style: const TextStyle(fontSize: 15, color: AppTheme.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Hoàn tất', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Luyện tập Quiz')),
        body: const Center(child: Text('Không đủ dữ liệu từ vựng để tạo bài Quiz.')),
      );
    }

    final word = widget.words[_currentIndex];
    final progress = (_currentIndex + 1) / widget.words.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title != null
            ? '${widget.title} (${_currentIndex + 1}/${widget.words.length})'
            : 'Câu ${_currentIndex + 1}/${widget.words.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // Prompt Card
              Expanded(
                flex: 4,
                child: Card(
                  elevation: 4,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildPromptContent(word),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4 Multiple Choice Options
              ..._options.map((opt) => _buildOptionButton(opt)),

              const SizedBox(height: 12),

              // Next Question Button
              if (_answered)
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _currentIndex < widget.words.length - 1 ? 'Câu tiếp theo ➔' : 'Xem kết quả',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildPromptContent(WordModel word) {
    switch (widget.mode) {
      case QuizMode.meaningToWord:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Từ nào có nghĩa dưới đây?', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            Text(
              word.meaningVi,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text('(${word.type})', style: const TextStyle(color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
          ],
        );

      case QuizMode.wordToMeaning:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nghĩa tiếng Việt của từ:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 12),
            Text(
              word.word,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (word.phonNAm != null) ...[
              const SizedBox(height: 4),
              Text(word.phonNAm!, style: const TextStyle(color: Color(0xFF38BDF8))),
            ],
            const SizedBox(height: 12),
            AudioPlayButton(usAudioFile: word.us, size: 44),
          ],
        );

      case QuizMode.listening:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nghe và chọn từ vựng chính xác:', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 20),
            AudioPlayButton(usAudioFile: word.us, size: 70),
            const SizedBox(height: 16),
            const Text('Chạm loa để nghe lại', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          ],
        );

      case QuizMode.fillBlank:
        final sentenceWithBlank = word.example.replaceAll(
          RegExp('\\b${RegExp.escape(word.word)}\\b', caseSensitive: false),
          '__________',
        );
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Điền từ thích hợp vào chỗ trống:', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 16),
            Text(
              sentenceWithBlank,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, height: 1.4, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              word.exampleVi,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        );
    }
  }

  Widget _buildOptionButton(String option) {
    Color? backgroundColor = AppTheme.surfaceDark;
    Color borderColor = const Color(0xFF334155);
    Color textColor = Colors.white;

    if (_answered) {
      if (option == _correctAnswer) {
        backgroundColor = const Color(0xFF10B981).withOpacity(0.2);
        borderColor = const Color(0xFF10B981);
        textColor = const Color(0xFF34D399);
      } else if (option == _selectedAnswer) {
        backgroundColor = const Color(0xFFEF4444).withOpacity(0.2);
        borderColor = const Color(0xFFEF4444);
        textColor = const Color(0xFFF87171);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton(
        onPressed: _answered ? null : () => _handleOptionSelect(option),
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          option,
          style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
