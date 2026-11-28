import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _skipToGuest(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _openAuth(BuildContext context, bool isSignUp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(
          initialIsSignUp: isSignUp,
          onAuthSuccess: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('has_seen_welcome', true);
          },
        ),
      ),
    ).then((res) async {
      if (res == true && context.mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('has_seen_welcome', true);
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
            children: [
              const Spacer(),

              // App Logo with glowing accent
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primary.withValues(alpha: 0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.school, size: 52, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),

              // Title & Slogan
              const Text(
                'Vocap IELTS',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chinh phục 6.000 từ vựng IELTS cốt lõi một cách dễ dàng và hiệu quả',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 36),

              // Value Props Cards
              _buildFeatureRow(
                icon: Icons.psychology,
                title: 'Nhắc lại thông minh',
                subtitle: 'Tự động nhắc lại từ đúng lúc giúp bạn nhớ lâu không quên',
              ),
              const SizedBox(height: 14),
              _buildFeatureRow(
                icon: Icons.tune,
                title: 'Lọc trình độ cá nhân hóa',
                subtitle: 'Loại bỏ từ quá dễ, học đúng Band IELTS mục tiêu',
              ),
              const SizedBox(height: 14),
              _buildFeatureRow(
                icon: Icons.auto_stories,
                title: '20 Chủ đề học thuật chuẩn',
                subtitle: 'Kho từ Oxford 5000 kèm phát âm US/UK bản ngữ',
              ),

              const Spacer(),

              // Action Buttons
              ElevatedButton(
                onPressed: () => _openAuth(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: const Text(
                  'Bắt Đầu Ngay (Tạo Tài Khoản)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => _openAuth(context, false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Tôi Đã Có Tài Khoản', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _buildFeatureRow({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
