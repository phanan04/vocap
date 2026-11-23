import 'package:flutter/material.dart';
import '../services/offline_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../core/theme/app_theme.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;

  const SettingsScreen({super.key, this.onSettingsChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final OfflineService _offlineService = OfflineService();
  final AuthService _authService = AuthService();
  final SupabaseService _supabaseService = SupabaseService();

  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  int _dailyTarget = 10;
  String _targetBand = '6.5';
  int _pendingSyncCount = 0;
  int _cachedWordsCount = 0;
  bool _isSyncing = false;

  final List<String> _targetBands = ['5.5', '6.0', '6.5', '7.0', '7.5', '8.0', '8.5'];
  final List<int> _dailyTargets = [5, 10, 15, 20, 25, 30];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final reminder = await _offlineService.getReminderSettings();
    final pending = await _offlineService.getPendingQueueCount();
    final cached = await _offlineService.getCachedWords();

    if (_authService.isLoggedIn) {
      final profile = await _authService.getUserProfile();
      if (profile != null) {
        if (profile['daily_target'] != null) {
          _dailyTarget = (profile['daily_target'] as num).toInt();
        }
        if (profile['target_band'] != null) {
          _targetBand = profile['target_band'] as String;
        }
      }
    }

    if (mounted) {
      setState(() {
        _reminderEnabled = reminder['enabled'] as bool;
        _reminderTime = TimeOfDay(hour: reminder['hour'] as int, minute: reminder['minute'] as int);
        _pendingSyncCount = pending;
        _cachedWordsCount = cached.length;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked != null) {
      setState(() => _reminderTime = picked);
      await _offlineService.saveReminderSettings(
        enabled: _reminderEnabled,
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  Future<void> _handleSyncNow() async {
    setState(() => _isSyncing = true);
    final count = await _offlineService.flushOfflineQueue(_supabaseService);
    final remaining = await _offlineService.getPendingQueueCount();

    if (mounted) {
      setState(() {
        _pendingSyncCount = remaining;
        _isSyncing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã đồng bộ thành công $count lượt ôn tập lên đám mây!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  Future<void> _handlePreloadWords() async {
    setState(() => _isSyncing = true);
    try {
      final words = await _supabaseService.getWordsByTopic('Education & Learning', limit: 100);
      await _offlineService.cacheWords(words);
      final cached = await _offlineService.getCachedWords();
      if (mounted) {
        setState(() {
          _cachedWordsCount = cached.length;
          _isSyncing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📥 Đã tải sẵn ${cached.length} từ vựng vào bộ nhớ máy để học ngoại tuyến!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài Đặt & Học Ngoại Tuyến'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            const Text('Tài khoản & Đồng bộ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _authService.isLoggedIn ? AppTheme.primary : Colors.grey,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  _authService.isLoggedIn
                      ? (_authService.currentUser?.email ?? 'Học viên')
                      : 'Khách (Chưa đăng nhập)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  _authService.isLoggedIn
                      ? 'Đang đồng bộ dữ liệu với Supabase Cloud'
                      : 'Đăng nhập để bảo toàn chuỗi Streak & điểm XP',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                trailing: _authService.isLoggedIn
                    ? IconButton(
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        tooltip: 'Đăng xuất',
                        onPressed: () async {
                          await _authService.signOut();
                          _loadSettings();
                          widget.onSettingsChanged?.call();
                        },
                      )
                    : ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AuthScreen(onAuthSuccess: () {
                                _loadSettings();
                                widget.onSettingsChanged?.call();
                              }),
                            ),
                          ).then((_) {
                            _loadSettings();
                            widget.onSettingsChanged?.call();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Đăng nhập'),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Study Goals Section
            const Text('Mục tiêu học tập', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Daily Target
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Số từ mục tiêu mỗi ngày:', style: TextStyle(fontSize: 15)),
                        DropdownButton<int>(
                          value: _dailyTarget,
                          dropdownColor: AppTheme.surfaceDark,
                          items: _dailyTargets.map((n) {
                            return DropdownMenuItem(value: n, child: Text('$n từ/ngày'));
                          }).toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(() => _dailyTarget = val);
                              if (_authService.isLoggedIn) {
                                await _authService.updateProfile(dailyTarget: val);
                              }
                              widget.onSettingsChanged?.call();
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Target Band
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Mục tiêu Band IELTS:', style: TextStyle(fontSize: 15)),
                        DropdownButton<String>(
                          value: _targetBand,
                          dropdownColor: AppTheme.surfaceDark,
                          items: _targetBands.map((b) {
                            return DropdownMenuItem(value: b, child: Text('Band $b'));
                          }).toList(),
                          onChanged: (val) async {
                            if (val != null) {
                              setState(() => _targetBand = val);
                              if (_authService.isLoggedIn) {
                                await _authService.updateProfile(targetBand: val);
                              }
                              widget.onSettingsChanged?.call();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Daily Reminder Section
            const Text('Nhắc nhở học tập hàng ngày', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Bật thông báo nhắc học', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Giữ chuỗi Streak 🔥 không bị đứt quãng'),
                    value: _reminderEnabled,
                    activeColor: AppTheme.primary,
                    onChanged: (val) async {
                      setState(() => _reminderEnabled = val);
                      await _offlineService.saveReminderSettings(
                        enabled: val,
                        hour: _reminderTime.hour,
                        minute: _reminderTime.minute,
                      );
                    },
                  ),
                  if (_reminderEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Giờ nhắc học'),
                      trailing: Text(
                        _reminderTime.format(context),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                      onTap: _pickReminderTime,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Offline & Cloud Sync Section
            const Text('Bộ nhớ ngoại tuyến & Đồng bộ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Từ vựng lưu trong máy:', style: TextStyle(fontSize: 14)),
                        Text('$_cachedWordsCount từ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lượt học chờ đồng bộ lên mây:', style: TextStyle(fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _pendingSyncCount > 0 ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$_pendingSyncCount lượt',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _pendingSyncCount > 0 ? Colors.orange : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSyncing ? null : _handlePreloadWords,
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text('Tải offline 100 từ'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSyncing || _pendingSyncCount == 0 ? null : _handleSyncNow,
                            icon: const Icon(Icons.cloud_upload, size: 18),
                            label: const Text('Đồng bộ ngay'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // App Version Info
            Center(
              child: Column(
                children: const [
                  Text(
                    'Vocap IELTS v1.0.0 (Oxford 5000 Edition)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Thuật toán SM-2 SRS • Cloudflare Audio CDN • Supabase Postgres',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
