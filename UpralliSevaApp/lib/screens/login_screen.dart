import 'package:flutter/material.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  final String? deniedEmail;
  const LoginScreen({super.key, this.deniedEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    if (widget.deniedEmail != null) {
      _err = '“${widget.deniedEmail}” ಗೆ ಅನುಮತಿ ಇಲ್ಲ. ನಿರ್ವಾಹಕರನ್ನು ಸಂಪರ್ಕಿಸಿ.';
      // ಅನುಮತಿ ಇಲ್ಲದ ಖಾತೆಯನ್ನು ಹೊರಹಾಕು
      WidgetsBinding.instance.addPostFrameCallback((_) => authService.signOut());
    }
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await authService.signInWithGoogle();
      // AuthGate ಮುಂದಿನದನ್ನು ನಿರ್ವಹಿಸುತ್ತದೆ
    } catch (e) {
      setState(() => _err = 'ಲಾಗಿನ್ ವಿಫಲ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF0F2),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(.10),
                    blurRadius: 28,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/icon/app_icon.png', width: 110, height: 110),
                const SizedBox(height: 8),
                const Text('ಉಪ್ರಳ್ಳಿ ಸೇವೆ',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                  'ಮುಂದುವರಿಯಲು ನಿಮ್ಮ ಅನುಮತಿ ಪಡೆದ Google ಖಾತೆಯಿಂದ ಲಾಗಿನ್ ಆಗಿ.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13.5),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _login,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.login),
                    label: Text(_busy ? 'ಲಾಗಿನ್ ಆಗುತ್ತಿದೆ…' : 'Google ಮೂಲಕ ಲಾಗಿನ್'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                if (_err != null) ...[
                  const SizedBox(height: 14),
                  Text(_err!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFA40000), fontSize: 12.5)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
