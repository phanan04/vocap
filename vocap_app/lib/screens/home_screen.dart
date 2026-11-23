import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
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
      if (_authService.isLoggedIn) {
        profile = await _authService.getUserProfile();
        cloudLearnedToday = await _supabaseService.getTodayLearnedCount();
        if (cloudLearnedToday != null && cloudLearnedToday > 0) {
          await _progressService.syncCloudLearnedCount(cloudLearnedToday);
        }
      }

      int learnedToday = progress['learnedToday'] as int;
      if (cloudLearnedToday != null && cloudLearnedToday > learnedToday) {
        learnedToday = cloudLearnedToday;
      }

      final targetBand = profile != null && profile['target_band'] != null
          ? profile['target_band'] as String
          : '6.5';
      final currentBand = profile != null && profile['current_band'] != null
          ? profile['current_band'] as String
          : (localAssessedBand ?? '5.5');
      final dailyTarget = profile != null && profile['daily_target'] != null
          ? (profile['daily_target'] as num).toInt()
          : (progress['dailyTarget'] as int);

      // Call Thematic Adaptive SRS session
      final sessionWords = await _supabaseService.getSmartStudySession(
        targetBand: targetBand,
        currentBand: currentBand,
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
          _totalLearned = progress['totalLearned'] as int;
          _totalMastered = progress['totalMastered'] as int;
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
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildHomeTab(),
          const TopicExplorerScreen(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (idx) {
          setState(() => _selectedTab = idx);
          if (idx == 0 || idx == 2) {
            _loadDashboardData();
          }
        },
        backgroundColor: AppTheme.surfaceDark,
        indicatorColor: AppTheme.primary.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primary),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: AppTheme.primary),
            label: 'Khám phá',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primary),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final progressPercent = _dailyTarget > 0 ? (_learnedToday / _dailyTarget).clamp(0.0, 1.0) : 0.0;
    final userName = _userProfile?['display_name'] ?? (_authService.isLoggedIn ? 'Học viên' : 'Khách');

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
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
                            Text('Xin chào $userName! 👋', style: const TextStyle(fontSize: 14, color: AppTheme.textMuted)),
                            if (!_authService.isLoggedIn) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: _openAuthScreen,
                                child: const Text(
                                  '(Đăng nhập)',
                                  style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text('Luyện từ vựng hôm nay', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF97316), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$_streak Ngày',
                          style: const TextStyle(color: Color(0xFFF97316), fontWeight: FontWeight.bold),
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
                        radius: 42,
                        lineWidth: 8,
                        percent: progressPercent,
                        center: Text(
                          '$_learnedToday/$_dailyTarget',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        progressColor: AppTheme.primary,
                        backgroundColor: const Color(0xFF334155),
                        circularStrokeCap: CircularStrokeCap.round,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mục tiêu hàng ngày', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              _learnedToday >= _dailyTarget
                                  ? '🎉 Xuất sắc! Bạn đã đạt mục tiêu $_dailyTarget từ hôm nay!'
                                  : 'Đã ôn $_learnedToday/$_dailyTarget từ. Còn ${_dailyTarget - _learnedToday} từ nữa để hoàn thành mục tiêu!',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // SRS Spaced Repetition Due Card
              Card(
                color: const Color(0xFF1E293B),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.15),
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
                              Text('Phiên học hôm nay (Adaptive SRS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF97316).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF97316), width: 1),
                              ),
                              child: Text(
                                '🔥 ${_dueWords.where((w) => w.sessionType == "review").length} từ ôn SM-2',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF97316)),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (_dueWords.any((w) => w.sessionType == 'new')) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981), width: 1),
                              ),
                              child: Text(
                                '✨ ${_dueWords.where((w) => w.sessionType == "new").length} từ mới theo chủ đề',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Thuật toán Thematic Adaptive SRS tự động ưu tiên ôn từ sắp quên, cấp từ mới đúng trình độ Band $_currentBand ➔ Mục tiêu Band $_targetBand theo từng chủ đề.',
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
                                    builder: (_) => FlashcardScreen(words: _dueWords, title: 'Adaptive Daily Session'),
                                  ),
                                ).then((_) => _loadDashboardData());
                              },
                        icon: const Icon(Icons.play_arrow),
                        label: Text(_isLoading ? 'Đang chuẩn bị phiên học...' : 'Bắt đầu phiên học ngay (${_dueWords.length} từ)'),
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
                    title: 'Trắc nghiệm',
                    subtitle: 'Chọn nghĩa đúng',
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
                    icon: Icons.headphones,
                    color: const Color(0xFF38BDF8),
                    title: 'Luyện nghe',
                    subtitle: 'Âm thanh US',
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
                  const SizedBox(width: 12),
                  _buildQuickAction(
                    icon: Icons.edit_note,
                    color: const Color(0xFFF59E0B),
                    title: 'Điền từ',
                    subtitle: 'Ví dụ IELTS',
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
                ],
              ),
            ],
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
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    final isLoggedIn = _authService.isLoggedIn;
    final displayName = _userProfile?['display_name'] ?? (isLoggedIn ? 'Học viên IELTS' : 'Khách (Chưa đăng nhập)');
    final targetBand = _userProfile?['target_band'] ?? '6.5';
    final email = _authService.currentUser?.email ?? 'Chế độ trải nghiệm khách';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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

            // Target Band Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.flag, color: AppTheme.accent),
                        SizedBox(width: 10),
                        Text('Mục tiêu IELTS (Target Band):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getBandColor(targetBand).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.getBandColor(targetBand)),
                      ),
                      child: Text(
                        'Band $targetBand',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.getBandColor(targetBand)),
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
