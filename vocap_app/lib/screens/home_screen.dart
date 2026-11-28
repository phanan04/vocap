import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';
import '../services/progress_service.dart';
import '../services/auth_service.dart';
import '../services/placement_test_service.dart';
import '../models/word_model.dart';
import '../core/theme/app_theme.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';
import 'topic_explorer_screen.dart';
import 'auth_screen.dart';
import 'settings_screen.dart';
import 'placement_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final ProgressService _progressService = ProgressService();
  final AuthService _authService = AuthService();
  final PlacementTestService _testService = PlacementTestService();
  int _selectedTab = 0;

  List<WordModel> _dueWords = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Real progress state
  int _dailyTarget = 10;
  int _learnedToday = 0;
  int _streak = 0;
  int _totalLearned = 0;
  int _totalMastered = 0;
  int _xp = 0;

  // Level & Assessment State
  String _currentBand = '5.5';
  String _targetBand = '6.5';

  // User Profile
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final progress = await _progressService.getProgress();
      final localAssessedBand = await _testService.getAssessedBand();

      Map<String, dynamic>? profile;
      int? cloudLearnedToday;
      Map<String, int>? cloudStats;
      if (_authService.isLoggedIn) {
        profile = await _authService.getUserProfile();
        cloudLearnedToday = await _supabaseService.getTodayLearnedCount();
        cloudStats = await _supabaseService.getUserCloudStats();
        if (cloudLearnedToday != null && cloudLearnedToday > 0) {
          await _progressService.syncCloudLearnedCount(cloudLearnedToday);
        }
      }

      int learnedToday = progress['learnedToday'] as int;
      if (cloudLearnedToday != null && cloudLearnedToday > learnedToday) {
        learnedToday = cloudLearnedToday;
      }

      final totalLearned = cloudStats != null
          ? cloudStats['totalLearned']!
          : (progress['totalLearned'] as int);
      final totalMastered = cloudStats != null
          ? cloudStats['totalMastered']!
          : (progress['totalMastered'] as int);

      final prefs = await SharedPreferences.getInstance();
      final targetBand = profile != null && profile['target_band'] != null
          ? profile['target_band'] as String
          : (prefs.getString('target_band') ?? '6.5');
      final currentBand = profile != null && profile['current_band'] != null
          ? profile['current_band'] as String
          : (localAssessedBand ?? prefs.getString('placement_assessed_band') ?? '5.5');
      final dailyTarget = profile != null && profile['daily_target'] != null
          ? (profile['daily_target'] as num).toInt()
          : (prefs.getInt('daily_target') ?? (progress['dailyTarget'] as int));

      final autoSkip = prefs.getBool('auto_skip_below_band') ?? true;
      final effectiveStudyBand = autoSkip ? currentBand : '4.0';

      // Call Thematic Adaptive SRS session
      final sessionWords = await _supabaseService.getSmartStudySession(
        targetBand: targetBand,
        currentBand: effectiveStudyBand,
        limit: dailyTarget,
      );

      if (mounted) {
        setState(() {
          _dailyTarget = dailyTarget;
          _learnedToday = learnedToday;
          _currentBand = currentBand;
          _targetBand = targetBand;
          _streak = profile != null && profile['streak_count'] != null && (profile['streak_count'] as int) > 0
              ? (profile['streak_count'] as int)
              : (progress['streak'] as int);
          _totalLearned = totalLearned;
          _totalMastered = totalMastered;
          _xp = profile != null && profile['xp_points'] != null && (profile['xp_points'] as int) > 0
              ? (profile['xp_points'] as int)
              : (progress['xp'] as int);
          _dueWords = sessionWords;
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openAuthScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(onAuthSuccess: _loadDashboardData),
      ),
    ).then((_) => _loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildHomeTab(),
          const TopicExplorerScreen(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _buildFloatingDock(),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final displayLearned = _dailyTarget > 0 ? _learnedToday.clamp(0, _dailyTarget) : _learnedToday;
    final progressPercent = _dailyTarget > 0 ? (displayLearned / _dailyTarget).clamp(0.0, 1.0) : 0.0;
    final userName = _userProfile?['display_name'] ?? (_authService.isLoggedIn ? 'Học viên' : 'Khách');

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Top Header: Greeting & Streak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'XIN CHÀO, ${userName.toUpperCase()} 👋',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 0.5),
                            ),
                            if (!_authService.isLoggedIn) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _openAuthScreen,
                                child: const Text(
                                  'Đăng nhập',
                                  style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hôm nay',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.6),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.orange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: AppTheme.orange, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$_streak ngày',
                          style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                    ],
                  ),
                ),

              // Daily Goal Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircularPercentIndicator(
                        radius: 38,
                        lineWidth: 6,
                        percent: progressPercent,
                        center: Text(
                          '$displayLearned/$_dailyTarget',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: -0.2),
                        ),
                        progressColor: AppTheme.primary,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mục tiêu hàng ngày', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                            const SizedBox(height: 4),
                            Text(
                              displayLearned >= _dailyTarget
                                  ? '🎉 Xuất sắc! Bạn đã đạt mục tiêu $_dailyTarget từ hôm nay!'
                                  : 'Đã ôn $displayLearned/$_dailyTarget từ. Còn ${_dailyTarget - displayLearned} từ nữa.',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Daily Study Hero Card
              Card(
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.psychology, color: AppTheme.primary, size: 22),
                              SizedBox(width: 8),
                              Text('Bài học hôm nay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_dueWords.length} từ',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (_dueWords.any((w) => w.sessionType == 'review')) ...[
                            _buildGlassBadge(
                              icon: Icons.local_fire_department_rounded,
                              count: _dueWords.where((w) => w.sessionType == "review").length,
                              label: 'cần nhắc lại',
                              color: AppTheme.orange,
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_dueWords.any((w) => w.sessionType == 'new')) ...[
                            _buildGlassBadge(
                              icon: Icons.auto_awesome_rounded,
                              count: _dueWords.where((w) => w.sessionType == "new").length,
                              label: 'từ mới hôm nay',
                              color: AppTheme.mint,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tự động nhắc lại từ sắp quên và học thêm từ mới phù hợp mục tiêu Band $_targetBand của bạn.',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading || _dueWords.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FlashcardScreen(words: _dueWords, title: 'Bài học hôm nay'),
                                  ),
                                ).then((_) => _loadDashboardData());
                              },
                        icon: const Icon(Icons.play_arrow),
                        label: Text(_isLoading ? 'Đang chuẩn bị phiên học...' : 'Bắt đầu học ngay (${_dueWords.length} từ)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Practice Modes Grid
              const Text('Chế độ luyện tập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.style,
                    color: const Color(0xFF10B981),
                    title: 'Flashcards',
                    subtitle: 'Lật thẻ ghi nhớ',
                    onTap: () {
                      if (_dueWords.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FlashcardScreen(words: _dueWords),
                          ),
                        ).then((_) => _loadDashboardData());
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.quiz,
                    color: const Color(0xFF6366F1),
                    title: 'Nghĩa ➔ Từ',
                    subtitle: 'Trắc nghiệm chọn từ',
                    onTap: () {
                      if (_dueWords.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              words: _dueWords.take(15).toList(),
                              distractorPool: _dueWords,
                              mode: QuizMode.meaningToWord,
                            ),
                          ),
                        ).then((_) => _loadDashboardData());
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.translate,
                    color: const Color(0xFF8B5CF6),
                    title: 'Từ ➔ Nghĩa',
                    subtitle: 'Hiểu ngữ nghĩa nhanh',
                    onTap: () {
                      if (_dueWords.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              words: _dueWords.take(15).toList(),
                              distractorPool: _dueWords,
                              mode: QuizMode.wordToMeaning,
                            ),
                          ),
                        ).then((_) => _loadDashboardData());
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.headphones,
                    color: const Color(0xFF38BDF8),
                    title: 'Luyện nghe',
                    subtitle: 'Âm thanh US chuẩn',
                    onTap: () {
                      if (_dueWords.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              words: _dueWords.take(15).toList(),
                              distractorPool: _dueWords,
                              mode: QuizMode.listening,
                            ),
                          ),
                        ).then((_) => _loadDashboardData());
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.edit_note,
                    color: const Color(0xFFF59E0B),
                    title: 'Điền từ',
                    subtitle: 'Ngữ cảnh câu IELTS',
                    onTap: () {
                      if (_dueWords.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              words: _dueWords.take(15).toList(),
                              distractorPool: _dueWords,
                              mode: QuizMode.fillBlank,
                            ),
                          ),
                        ).then((_) => _loadDashboardData());
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.explore,
                    color: const Color(0xFFEC4899),
                    title: 'Khám phá 5.000 từ',
                    subtitle: '20 Chủ đề & Bộ lọc',
                    onTap: () {
                      setState(() => _selectedTab = 1);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildQuickAction({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(height: 14),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBadge({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.38), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$count ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.2,
                  ),
                ),
                TextSpan(
                  text: label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.04, end: 0);
  }

  Widget _buildFloatingDock() {
    return Center(
      heightFactor: 1.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xE61C1C1E),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDockItem(index: 0, icon: Icons.home_rounded, label: 'Trang chủ'),
                  _buildDockItem(index: 1, icon: Icons.explore_rounded, label: 'Khám phá'),
                  _buildDockItem(index: 2, icon: Icons.person_rounded, label: 'Cá nhân'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem({required int index, required IconData icon, required String label}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        if (index == 0 || index == 2) _loadDashboardData();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 18 : 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: isSelected
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.35), width: 0.8)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final isLoggedIn = _authService.isLoggedIn;
    final displayName = _userProfile?['display_name'] ?? (isLoggedIn ? 'Học viên IELTS' : 'Khách (Chưa đăng nhập)');
    final email = _authService.currentUser?.email ?? 'Chế độ trải nghiệm khách';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Hồ sơ học tập', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AppTheme.textMuted),
                  tooltip: 'Cài đặt & Ngoại tuyến',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(onSettingsChanged: _loadDashboardData),
                      ),
                    ).then((_) => _loadDashboardData());
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // User Info Card
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLoggedIn ? AppTheme.primary : Colors.grey,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(email),
                trailing: isLoggedIn
                    ? IconButton(
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        tooltip: 'Đăng xuất',
                        onPressed: () async {
                          await _authService.signOut();
                          _loadDashboardData();
                        },
                      )
                    : TextButton(
                        onPressed: _openAuthScreen,
                        child: const Text('Đăng nhập', style: TextStyle(color: AppTheme.primary)),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Cloud Sync Notice for Guests
            if (!isLoggedIn)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_sync, color: AppTheme.primary, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Đồng bộ tiến độ học', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Đăng nhập tài khoản Vocap để lưu chuỗi Streak và lịch sử ôn tập trên đám mây.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _openAuthScreen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Đăng ký'),
                    ),
                  ],
                ),
              ),

            // Study Goals & Level Card
            Card(
              color: const Color(0xFF1E293B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.track_changes, color: AppTheme.primary, size: 22),
                            SizedBox(width: 8),
                            Text('Lộ trình & Trình độ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(onSettingsChanged: _loadDashboardData),
                              ),
                            ).then((_) => _loadDashboardData());
                          },
                          child: const Text('Cài đặt ➔', style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Trình độ', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                const SizedBox(height: 4),
                                Text('Band $_currentBand', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF10B981))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mục tiêu', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                const SizedBox(height: 4),
                                Text('Band $_targetBand', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF38BDF8))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mỗi ngày', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                const SizedBox(height: 4),
                                Text('$_dailyTarget từ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFF59E0B))),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlacementTestScreen(onTestCompleted: _loadDashboardData),
                          ),
                        ).then((_) => _loadDashboardData());
                      },
                      icon: const Icon(Icons.quiz, size: 18, color: AppTheme.primary),
                      label: const Text('Làm bài test đánh giá lại trình độ', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 42),
                        side: BorderSide(color: AppTheme.primary.withOpacity(0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stats Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow('Từ vựng đã học', '$_totalLearned từ'),
                    const Divider(height: 20),
                    _buildStatRow('Từ đã ghi nhớ sâu (Mastered)', '$_totalMastered từ'),
                    const Divider(height: 20),
                    _buildStatRow('Chuỗi ngày học liên tiếp (Streak)', '$_streak ngày 🔥'),
                    const Divider(height: 20),
                    _buildStatRow('Tổng điểm kinh nghiệm', '$_xp XP 🏆'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
