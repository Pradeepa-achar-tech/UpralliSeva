import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

/// ವೆಬ್ ಆ್ಯಪ್‌ನ ಅದೇ Firestore ದತ್ತಾಂಶ — pooja/{year}, editors/{email}.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _pooja => _db.collection('pooja');

  /// whitelist ಪರಿಶೀಲನೆ — editors ಸಂಗ್ರಹದಲ್ಲಿ ಇಮೇಲ್ ದಾಖಲೆ ಇದೆಯೇ?
  Future<bool> isEditor(String email) async {
    try {
      final d = await _db.collection('editors').doc(email.toLowerCase()).get();
      return d.exists;
    } catch (_) {
      return false;
    }
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
}
