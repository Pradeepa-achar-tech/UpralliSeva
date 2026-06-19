// ಮಾದರಿ ಪರೀಕ್ಷೆ — Family ಆಯ್ಕೆ ತರ್ಕ (Firebase ಬೇಕಿಲ್ಲ).
import 'package:flutter_test/flutter_test.dart';
import 'package:upralliseva_app/models.dart';

void main() {
  test('Family.setOn / isOn / count', () {
    final f = Family(n: 'ಪರೀಕ್ಷೆ', c: '00000');
    expect(f.isOn(0), false);
    f.setOn(0, true);
    f.setOn(2, true);
    expect(f.c, '10100');
    expect(f.isOn(2), true);
    expect(f.count, 2);
    f.setOn(0, false);
    expect(f.c, '00100');
    expect(f.count, 1);
  });

  test('PoojaData.clearedForYear keeps names, clears selections', () {
    final src = PoojaData(
      title: 't',
      columns: ['a', 'b', 'c', 'd', 'e'],
      year: 2025,
      regions: [
        Region(no: 1, name: 'R1', phone: '', families: [Family(n: 'X', c: '11000')]),
      ],
    );
    final fresh = src.clearedForYear(2026);
    expect(fresh.year, 2026);
    expect(fresh.regions.first.families.first.n, 'X');
    expect(fresh.regions.first.families.first.c, '00000');
  });
}
