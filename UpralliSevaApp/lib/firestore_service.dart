import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

/// ಪ್ರವೇಶ ಮಟ್ಟ — ವೆಬ್‌ನ checkAccess ಗೆ ಹೊಂದುತ್ತದೆ.
class Access {
  final bool allowed; // ಲಾಗಿನ್ ಅನುಮತಿ
  final bool canEdit; // ಸಂಪಾದನೆ ಪ್ರವೇಶ
  final bool admin; // ಬಳಕೆದಾರ ನಿರ್ವಹಣೆ (super admin ಮಾತ್ರ)
  final bool disabled; // ಖಾತೆ ನಿಷ್ಕ್ರಿಯ
  const Access(
      {this.allowed = false,
      this.canEdit = false,
      this.admin = false,
      this.disabled = false});
}

class AppUser {
  final String email;
  final String role; // 'edit' | 'read'
  final bool disabled;
  final bool boot; // ಕೋಡ್‌ನಲ್ಲಿ (ಟಾಗಲ್ ಇಲ್ಲ)
  final bool legacy; // ಹಳೆಯ "editors" ಸಂಗ್ರಹದವರು
  AppUser(this.email, this.role, this.disabled,
      {this.boot = false, this.legacy = false});
}

/// ವೆಬ್ ಆ್ಯಪ್‌ನ ಅದೇ Firestore ದತ್ತಾಂಶ — pooja/{year}, users/{email}.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pooja => _db.collection('pooja');

  /// super admin (ಬಳಕೆದಾರ ನಿರ್ವಹಣೆ) — ವೆಬ್‌ನ ALLOWED_EDITORS ಗೆ ಹೊಂದುವಂತೆ
  static const List<String> superAdmins = ['thanthrajnaani@gmail.com'];
  static const List<String> readonlyBoot = ['prabhakaracharya13799@gmail.com'];

  /// ಪ್ರವೇಶ ಪರಿಶೀಲನೆ: superAdmins → readonlyBoot → users/{email} → editors → ನಿರಾಕರಣೆ
  Future<Access> getAccess(String email) async {
    final e = email.toLowerCase();
    if (superAdmins.contains(e)) {
      return const Access(allowed: true, canEdit: true, admin: true);
    }
    if (readonlyBoot.contains(e)) {
      return const Access(allowed: true, canEdit: false, admin: false);
    }
    for (var i = 0; i < 4; i++) {
      try {
        final d = await _db.collection('users').doc(e).get();
        if (d.exists) {
          final x = d.data() ?? {};
          if (x['disabled'] == true) {
            return const Access(allowed: false, disabled: true);
          }
          final edit = x['role'] == 'edit';
          return Access(allowed: true, canEdit: edit, admin: false);
        }
        final le = await _db.collection('editors').doc(e).get(); // ಹಳೆಯ whitelist
        if (le.exists) return const Access(allowed: true, canEdit: true, admin: false);
        return const Access(allowed: false);
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return const Access(allowed: false);
  }

  // ---------- ಬಳಕೆದಾರ ನಿರ್ವಹಣೆ (users ಸಂಗ್ರಹ) ----------
  Future<List<AppUser>> listUsers() async {
    final snap = await _db.collection('users').get();
    final rows = snap.docs
        .map((d) => AppUser(d.id.toLowerCase(),
            (d.data()['role'] ?? 'read').toString(), d.data()['disabled'] == true))
        .toList();
    final have = rows.map((r) => r.email).toSet();
    // ಹಳೆಯ "editors" ಸಂಗ್ರಹ (users ನಲ್ಲಿ ಇಲ್ಲದಿದ್ದರೆ) — ಸಂಪಾದಕರಾಗಿ
    try {
      final esnap = await _db.collection('editors').get();
      for (final d in esnap.docs) {
        final em = d.id.toLowerCase();
        if (em.isNotEmpty && !have.contains(em)) {
          rows.add(AppUser(em, 'edit', false, legacy: true));
          have.add(em);
        }
      }
    } catch (_) {}
    final boot = <AppUser>[
      for (final a in superAdmins)
        if (!have.contains(a)) AppUser(a, 'edit', false, boot: true),
      for (final r in readonlyBoot)
        if (!have.contains(r)) AppUser(r, 'read', false, boot: true),
    ];
    final all = [...boot, ...rows]..sort((a, b) => a.email.compareTo(b.email));
    return all;
  }

  Future<void> setUser(String email, String role) async {
    await _db.collection('users').doc(email.toLowerCase()).set({
      'email': email.toLowerCase(),
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setUserDisabled(String email, bool disabled) async {
    await _db.collection('users').doc(email.toLowerCase()).set({
      'disabled': disabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUser(String email) async {
    final e = email.toLowerCase();
    try { await _db.collection('users').doc(e).delete(); } catch (_) {}
    try { await _db.collection('editors').doc(e).delete(); } catch (_) {}
  }

  /// ಕ್ಲೌಡ್‌ನಲ್ಲಿರುವ ಎಲ್ಲ ವರ್ಷಗಳು (ಇಳಿಕೆ ಕ್ರಮ).
  Future<List<int>> listYears() async {
    final snap = await _pooja.get();
    final years =
        snap.docs.map((d) => int.tryParse(d.id)).whereType<int>().toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  /// ಒಂದು ವರ್ಷದ ನೇರ-ಪ್ರಸಾರ (live).
  Stream<PoojaData?> watchYear(int year) {
    return _pooja.doc('$year').snapshots().map(
        (d) => d.exists ? PoojaData.fromDoc(d.data()!, year) : null);
  }

  Future<PoojaData?> getYearOnce(int year) async {
    final d = await _pooja.doc('$year').get();
    return d.exists ? PoojaData.fromDoc(d.data()!, year) : null;
  }

  Future<void> saveYear(PoojaData data) async {
    await _pooja.doc('${data.year}').set({
      ...data.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// regions/title/columns ಉಳಿಸು — `rates` ಕ್ಷೇತ್ರ ಮುಟ್ಟದೆ (merge).
  /// ಹೆಸರು/ಪೂಜೆ/ಕಾಲುಕಾಣಿಕೆ ಬದಲಾವಣೆ ದರಗಳನ್ನು ಅಳಿಸುವುದಿಲ್ಲ.
  Future<void> saveYearFields(PoojaData data) async {
    final m = data.toMap()..remove('rates');
    await _pooja.doc('${data.year}').set({
      ...m,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ದರಗಳನ್ನು ಮಾತ್ರ ಉಳಿಸು (merge) — regions ಮುಟ್ಟದೆ.
  Future<void> saveRates(int year, List<PoojaRate> rates) async {
    await _pooja.doc('$year').set({
      'rates': rates.map((x) => x.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteYear(int year) async {
    await _pooja.doc('$year').delete();
  }
}
