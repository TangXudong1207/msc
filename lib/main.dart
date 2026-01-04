import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/admin_login_screen.dart';
import 'services/network_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(
        title: 'MSC',
        builder: (context, child) {
          return NetworkStatusWrapper(child: child!);
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9E5B4B), // Terracotta
            primary: const Color(0xFF9E5B4B),
            secondary: const Color(0xFF6B705C), // Olive
            surface: const Color(0xFFF7F4EF), // Card Surface
            background: const Color(0xFFF0EAE2), // App Background
            onSurface: const Color(0xFF2B2B2B),
          ),
          scaffoldBackgroundColor: const Color(0xFFF0EAE2),
          useMaterial3: true,
          fontFamily: 'Georgia', // Serif font fits the "Meaning" vibe better, or system serif
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Color(0xFF2B2B2B),
            ),
            bodyMedium: TextStyle(color: Color(0xFF4A4A4A)),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/admin': (context) => const AdminLoginScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        if (!auth.hasSeenOnboarding) {
          return const OnboardingScreen();
        }

        return const ChatScreen();
      },
    );
  }
}
