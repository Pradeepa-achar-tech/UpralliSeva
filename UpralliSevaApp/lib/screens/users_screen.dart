import 'package:flutter/material.dart';
import '../main.dart';
import '../firestore_service.dart';

/// ಬಳಕೆದಾರ ನಿರ್ವಹಣೆ — super admin (thanthrajnaani@gmail.com) ಗೆ ಮಾತ್ರ.
/// ಇಮೇಲ್ ಸೇರಿಸಿ · ಓದು/ಸಂಪಾದನೆ · ಸಕ್ರಿಯ/ನಿಷ್ಕ್ರಿಯ. ಸ್ವಂತ ಖಾತೆ ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗದು.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _emailCtrl = TextEditingController();
  String _newRole = 'read';
  List<AppUser> _users = [];
  bool _loading = true;
  String? _error;

  static final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final u = await firestoreService.listUsers();
      if (!mounted) return;
      setState(() {
        _users = u;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'ಪಟ್ಟಿ ಲೋಡ್ ಆಗಲಿಲ್ಲ: $e\n(Firestore ನಿಯಮಗಳಲ್ಲಿ "users" ಓದು/ಬರಹ ಅನುಮತಿ ಬೇಕು)';
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final em = _emailCtrl.text.trim().toLowerCase();
    if (!_emailRe.hasMatch(em)) {
      _snack('ಸರಿಯಾದ ಇಮೇಲ್ ನಮೂದಿಸಿ');
      return;
    }
    try {
      await firestoreService.setUser(em, _newRole);
      _emailCtrl.clear();
      _snack('✓ ಬಳಕೆದಾರ ಸೇರಿಸಲಾಗಿದೆ');
      await _load();
    } catch (e) {
      _snack('ಸೇರಿಸಲಾಗಲಿಲ್ಲ: $e');
    }
  }

  Future<void> _setRole(AppUser u, String role) async {
    try {
      await firestoreService.setUser(u.email, role);
      _snack('✓ ಪ್ರವೇಶ ಬದಲಾಗಿದೆ');
      await _load();
    } catch (e) {
      _snack('ಬದಲಾಯಿಸಲಾಗಲಿಲ್ಲ: $e');
    }
  }

  Future<void> _toggleDisabled(AppUser u) async {
    if (u.email == gEmail) {
      _snack('ಸ್ವಂತ ಖಾತೆ ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗದು');
      return;
    }
    try {
      await firestoreService.setUserDisabled(u.email, !u.disabled);
      _snack(!u.disabled ? 'ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ' : 'ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ');
      await _load();
    } catch (e) {
      _snack('ಬದಲಾಯಿಸಲಾಗಲಿಲ್ಲ: $e');
    }
  }

  Future<void> _delete(AppUser u) async {
    if (u.email == gEmail) {
      _snack('ಸ್ವಂತ ಖಾತೆ ತೆಗೆಯಲಾಗದು');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ಬಳಕೆದಾರ ತೆಗೆ'),
        content: Text('“${u.email}” ಬಳಕೆದಾರರನ್ನು ತೆಗೆದುಹಾಕಬೇಕೆ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ರದ್ದು')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ತೆಗೆ')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.deleteUser(u.email);
      _snack('ತೆಗೆಯಲಾಗಿದೆ');
      await _load();
    } catch (e) {
      _snack('ತೆಗೆಯಲಾಗಲಿಲ್ಲ: $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(milliseconds: 1600)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSide2,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [kSide1, kSide2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
        ),
        title: const Text('ಬಳಕೆದಾರ ನಿರ್ವಹಣೆ'),
      ),
      body: Column(
        children: [
          // ಸೇರಿಸು
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kCardLine),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'ಇಮೇಲ್ ವಿಳಾಸ',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _newRole,
                  items: const [
                    DropdownMenuItem(value: 'read', child: Text('ಓದು')),
                    DropdownMenuItem(value: 'edit', child: Text('ಸಂಪಾದನೆ')),
                  ],
                  onChanged: (v) => setState(() => _newRole = v ?? 'read'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _add, child: const Text('ಸೇರಿಸಿ')),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('ಸ್ವಂತ ಖಾತೆ ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಲಾಗದು',
                  style: TextStyle(fontSize: 11.5, color: Colors.black54)),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!,
                            style: const TextStyle(color: Color(0xFFC0392B))))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => _userTile(_users[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _userTile(AppUser u) {
    final self = u.email == gEmail;
    return Opacity(
      opacity: u.disabled ? .55 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.email,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    Row(children: [
                      if (u.boot)
                        _tag('ಕೋಡ್'),
                      if (self) _tag('ನೀವು'),
                      if (u.disabled) _tag('ನಿಷ್ಕ್ರಿಯ'),
                    ]),
                  ],
                ),
              ),
              if (u.boot)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(u.role == 'edit' ? 'ಸಂಪಾದನೆ' : 'ಓದು',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                )
              else ...[
                DropdownButton<String>(
                  value: u.role == 'edit' ? 'edit' : 'read',
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'read', child: Text('ಓದು')),
                    DropdownMenuItem(value: 'edit', child: Text('ಸಂಪಾದನೆ')),
                  ],
                  onChanged: (v) => _setRole(u, v ?? 'read'),
                ),
                IconButton(
                  tooltip: u.disabled ? 'ಸಕ್ರಿಯಗೊಳಿಸಿ' : 'ನಿಷ್ಕ್ರಿಯಗೊಳಿಸಿ',
                  onPressed: self ? null : () => _toggleDisabled(u),
                  icon: Icon(u.disabled ? Icons.check_circle_outline : Icons.block,
                      color: u.disabled ? const Color(0xFF0B8A4F) : const Color(0xFFC0392B)),
                ),
                IconButton(
                  tooltip: 'ತೆಗೆ',
                  onPressed: self ? null : () => _delete(u),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String t) => Container(
        margin: const EdgeInsets.only(top: 3, right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        decoration: BoxDecoration(
            color: const Color(0xFFEEF0F4), borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF56607A))),
      );
}
