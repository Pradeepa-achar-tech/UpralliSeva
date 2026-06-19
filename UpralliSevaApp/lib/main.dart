import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'firestore_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

final authService = AuthService();
final firestoreService = FirestoreService();

const kAccent = Color(0xFF00BB66);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Android: google-services.json ನಿಂದ ಸ್ವಯಂ
  runApp(const PoojaApp());
}

class PoojaApp extends StatelessWidget {
  const PoojaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ಪೂಜಾ ದಾಖಲೆ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: kAccent,
        useMaterial3: true,
        fontFamily: 'NotoSansKannada',
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
