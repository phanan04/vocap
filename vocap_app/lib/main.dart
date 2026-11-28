import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/supabase_constants.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Backend connection
  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    publishableKey: SupabaseConstants.supabaseAnonKey,
  );

  final isLoggedIn = Supabase.instance.client.auth.currentUser != null;

  final initialScreen = isLoggedIn
      ? const HomeScreen()
      : const WelcomeScreen();

  runApp(VocapApp(initialScreen: initialScreen));
}

class VocapApp extends StatelessWidget {
  final Widget initialScreen;

  const VocapApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vocap - IELTS Vocabulary',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: initialScreen,
    );
  }
}
