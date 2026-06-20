import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

/// ವೆಬ್ ಆ್ಯಪ್‌ನ ಅದೇ Firestore ದತ್ತಾಂಶ — pooja/{year}, editors/{email}.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pooja => _db.collection('pooja');

  /// ಬೂಟ್‌ಸ್ಟ್ರ್ಯಾಪ್ ಸಂಪಾದಕರು (ವೆಬ್‌ನ ALLOWED_EDITORS ಗೆ ಹೊಂದುವಂತೆ)
  static const List<String> _bootstrapEditors = ['thanthrajnaani@gmail.com'];

  /// whitelist ಪರಿಶೀಲನೆ — editors ಸಂಗ್ರಹದಲ್ಲಿ ಇಮೇಲ್ ದಾಖಲೆ ಇದೆಯೇ?
  /// ತಣ್ಣನೆ ಆರಂಭದಲ್ಲಿ ಟೋಕನ್ ಸಿದ್ಧವಾಗುವ ಮುನ್ನ ಓದಿದರೆ ದೋಷ ಬರಬಹುದು — ಮರುಪ್ರಯತ್ನ.
  Future<bool> isEditor(String email) async {
    final e = email.toLowerCase();
    if (_bootstrapEditors.contains(e)) return true;
    for (var i = 0; i < 4; i++) {
      try {
        final d = await _db.collection('editors').doc(e).get();
        return d.exists;
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    return false;
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
