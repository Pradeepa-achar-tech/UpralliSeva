import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

final authService = AuthService();
final firestoreService = FirestoreService();

// ಬ್ರ್ಯಾಂಡ್ ಬಣ್ಣಗಳು — ಕೇಸರಿ ಆ್ಯಕ್ಸೆಂಟ್ + ತಟಸ್ಥ ವೃತ್ತಿಪರ ಹಿನ್ನೆಲೆ
const kPrimary = Color(0xFFE9730C);
const kPrimaryDark = Color(0xFFC25E00);
const kAccent = kPrimary; // ಹಳೆಯ ಉಲ್ಲೇಖಗಳ ಹೊಂದಾಣಿಕೆಗೆ
const kBg = Color(0xFFF4F5F7);
const kInk = Color(0xFF1F2430);
const kCardLine = Color(0xFFECECF1);
// ಗಾಢ ಸ್ಲೇಟ್ ಕ್ರೋಮ್ (ವೆಬ್ ಸೈಡ್‌ಬಾರ್‌ಗೆ ಹೊಂದುವಂತೆ)
const kSide1 = Color(0xFF2A2E3A);
const kSide2 = Color(0xFF1B1E27);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Android: google-services.json ನಿಂದ ಸ್ವಯಂ
  runApp(const PoojaApp());
}

class PoojaApp extends StatelessWidget {
  const PoojaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      brightness: Brightness.light,
    );
    return MaterialApp(
      title: 'ಉಪ್ರಳ್ಳಿ ಸೇವೆ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        scaffoldBackgroundColor: kBg,
        useMaterial3: true,
        fontFamily: 'NotoSansKannada',
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: kCardLine),
          ),
          margin: EdgeInsets.zero,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          insetPadding: EdgeInsets.all(12),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// ಲಾಗಿನ್ ಇಲ್ಲದಿದ್ದರೆ ಲಾಗಿನ್ ಪರದೆ; ಲಾಗಿನ್ + whitelist ಆದರೆ ಮಾತ್ರ ಮುಖಪುಟ.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.userChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();

        return FutureBuilder<bool>(
          future: firestoreService.isEditor(user.email ?? ''),
          builder: (context, ed) {
            if (ed.connectionState == ConnectionState.waiting) {
              return const _Loading();
            }
            if (ed.data != true) {
              return LoginScreen(deniedEmail: user.email);
            }
            return const HomeScreen();
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
