import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../services/placement_test_service.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import '../core/theme/app_theme.dart';

class PlacementTestScreen extends StatefulWidget {
  final bool isInitialOnboarding;
  final String initialTargetBand;
  final int initialDailyTarget;
  final VoidCallback? onTestCompleted;

  const PlacementTestScreen({
    super.key,
    this.isInitialOnboarding = false,
    this.initialTargetBand = '6.5',
    this.initialDailyTarget = 10,
    this.onTestCompleted,
  });

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen> {
  final PlacementTestService _testService = PlacementTestService();
  final SupabaseService _supabaseService = SupabaseService();
  final AuthService _authService = AuthService();

  late bool _showingIntro;
  late String _targetBand;
  late int _dailyTarget;
  String _manualSelectedBand = '6.5';

  int _currentIndex = 0;
  int _score = 0;
  int? _selectedIndex;
  bool _answered = false;
  bool _isCompleted = false;
  bool _isApplying = false;

  final List<PlacementQuestion> _questions = PlacementTestService.questions;
  final List<String> _targetBands = ['5.5', '6.0', '6.5', '7.0', '7.5', '8.0', '8.5'];
  final List<int> _dailyTargets = [5, 10, 15, 20, 25, 30];

  @override
  void initState() {
    super.initState();
    _showingIntro = widget.isInitialOnboarding;
    _targetBand = widget.initialTargetBand;
    _dailyTarget = widget.initialDailyTarget;
  }

  void _handleOptionSelect(int index) {
    if (_answered) return;

    final isCorrect = (index == _questions[_currentIndex].correctIndex);
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (isCorrect) _score++;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _answered = false;
      });
    } else {
      setState(() {
        _isCompleted = true;
      });
    }
  }

  Future<void> _applyResult(String assessedBand, {int score = 10}) async {
    setState(() => _isApplying = true);

    try {
      // 1. Save locally
      await _testService.saveResult(band: assessedBand, score: score);

      // 2. If logged in, update profile and call bulk skip RPC
      if (_authService.isLoggedIn) {
        await _authService.updateProfile(
          currentBand: assessedBand,
          targetBand: _targetBand,
          dailyTarget: _dailyTarget,
        );
        final res = await _supabaseService.skipWordsBelowBand(assessedBand);
        final skippedCount = res['skipped_count'] ?? 0;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎯 Đã lưu trình độ Band $assessedBand và tự động lọc bỏ $skippedCount từ vựng dễ!'),
              backgroundColor: Colors.green.shade800,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎯 Đã lưu trình độ Band $assessedBand!'),
              backgroundColor: Colors.green.shade800,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      widget.onTestCompleted?.call();

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApplying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showingIntro) {
      return _buildIntroSetupView();
    }

    if (_isCompleted) {
      return _buildResultsView();
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh Giá Trình Độ Đầu Vào'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearPercentIndicator(
            lineHeight: 4,
            percent: progress,
            progressColor: AppTheme.primary,
            backgroundColor: Colors.white12,
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress & Level Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu ${_currentIndex + 1} / ${_questions.length}',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                    ),
                    child: Text(
                      question.level,
                      style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Question Target Word Card
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            question.word,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${question.type})',
                            style: const TextStyle(fontSize: 14, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                          ),
                          const Spacer(),
                          Text(
                            question.phonetic,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Ngữ cảnh trong câu:',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        question.prompt,
                        style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Chọn nghĩa chính xác nhất của từ:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),

              // Multiple Choice Options
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final isSelected = (_selectedIndex == index);
                    final isCorrect = (index == question.correctIndex);

                    Color bgColor = const Color(0xFF1E293B);
                    Color borderColor = Colors.white12;
                    IconData? statusIcon;
                    Color iconColor = Colors.white;

                    if (_answered) {
                      if (isCorrect) {
                        bgColor = Colors.green.shade900.withOpacity(0.35);
                        borderColor = Colors.greenAccent;
                        statusIcon = Icons.check_circle;
                        iconColor = Colors.greenAccent;
                      } else if (isSelected) {
                        bgColor = Colors.red.shade900.withOpacity(0.35);
                        borderColor = Colors.redAccent;
                        statusIcon = Icons.cancel;
                        iconColor = Colors.redAccent;
                      }
                    }

                    return InkWell(
                      onTap: _answered ? null : () => _handleOptionSelect(index),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppTheme.primary : Colors.white10,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (statusIcon != null) ...[
                              Icon(statusIcon, color: iconColor, size: 22),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Explanation & Next Button
              if (_answered) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question.explanation,
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _currentIndex < _questions.length - 1 ? 'Câu Tiếp Theo ➔' : 'Xem Kết Quả Đánh Giá 🎉',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Initial Onboarding Intro Setup Screen (shown immediately when signing up)
  Widget _buildIntroSetupView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết Lập Mục Tiêu & Trình Độ'),
        automaticallyImplyLeading: !widget.isInitialOnboarding,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.track_changes, size: 48, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lộ Trình Học Cá Nhân Hóa 🎯',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Để Vocap không cho các từ vựng quá dễ, hãy thiết lập mục tiêu và xác định trình độ của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 24),

              // Target Goals Card
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Target Band
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mục tiêu IELTS của bạn:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          DropdownButton<String>(
                            value: _targetBand,
                            dropdownColor: AppTheme.surfaceDark,
                            items: _targetBands.map((b) => DropdownMenuItem(value: b, child: Text('Band $b'))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _targetBand = val);
                            },
                          ),
                        ],
                      ),
                      const Divider(height: 18),

                      // Daily Target
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mục tiêu mỗi ngày:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          DropdownButton<int>(
                            value: _dailyTarget,
                            dropdownColor: AppTheme.surfaceDark,
                            items: _dailyTargets.map((n) => DropdownMenuItem(value: n, child: Text('$n từ/ngày'))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _dailyTarget = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Option 1: Take Placement Test (Recommended)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withOpacity(0.2), const Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.primary, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('KHUYÊN DÙNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        const Text('Kiểm tra trình độ (15 câu / 2 phút)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Làm bài kiểm tra ngắn để Vocap tự động xác định trình độ và loại bỏ ~3.000 từ vựng cơ bản (A1, A2, B1) cho bạn.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.3),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _showingIntro = false);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Bắt Đầu Kiểm Tra Trình Độ', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Option 2: Manual Selection (Skip test)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hoặc tự chọn trình độ hiện tại của bạn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _manualSelectedBand,
                      dropdownColor: AppTheme.surfaceDark,
                      items: const [
                        DropdownMenuItem(value: '4.5', child: Text('Band 4.5 (Cơ bản / A2 - Bỏ qua A1)')),
                        DropdownMenuItem(value: '5.5', child: Text('Band 5.5 (Tiền trung cấp / B1 - Bỏ qua A1, A2)')),
                        DropdownMenuItem(value: '6.5', child: Text('Band 6.5 (Trung cấp / B2 - Bỏ qua A1, A2, B1)')),
                        DropdownMenuItem(value: '7.5', child: Text('Band 7.5+ (Nâng cao / C1 - Bỏ qua từ dưới C1)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _manualSelectedBand = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _isApplying ? null : () => _applyResult(_manualSelectedBand, score: 10),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: Text(
                        _isApplying ? 'Đang thiết lập...' : 'Bỏ qua bài test & Vào học ngay',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final result = PlacementTestService.evaluateScore(_score);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả Đánh Giá Trình Độ'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.15),
                  border: Border.all(color: AppTheme.primary, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_score / ${_questions.length}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                      const Text(
                        'Đúng',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title and Assessed Band Badge
              Text(
                result.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'IELTS Band ${result.band} (CEFR ${result.cefr})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),

              // Description Card
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.insights, color: AppTheme.primary, size: 22),
                          SizedBox(width: 8),
                          Text('Đánh giá năng lực từ vựng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result.description,
                        style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white70),
                      ),
                      const Divider(height: 24),
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
                          SizedBox(width: 8),
                          Text('Lộ trình cá nhân hóa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result.recommendation,
                        style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.white70),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        children: result.skippedLevels.map((lvl) {
                          return Chip(
                            backgroundColor: Colors.red.withOpacity(0.15),
                            side: BorderSide(color: Colors.red.withOpacity(0.5)),
                            label: Text(
                              'Đã lọc bỏ $lvl',
                              style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Big Action Button: Apply & Finish Setup
              ElevatedButton.icon(
                onPressed: _isApplying ? null : () => _applyResult(result.band, score: _score),
                icon: _isApplying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.rocket_launch),
                label: Text(
                  _isApplying ? 'Đang hoàn tất thiết lập...' : 'Hoàn Tất & Vào Học Ngay 🚀',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
