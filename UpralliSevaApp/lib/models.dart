/// ದತ್ತಾಂಶ ಮಾದರಿಗಳು — ವೆಬ್ ಆ್ಯಪ್‌ನ Firestore ರಚನೆಯನ್ನೇ ಪ್ರತಿಬಿಂಬಿಸುತ್ತದೆ.
/// pooja/{year} = { title, columns:[], year, regions:[ {no,name,phone, families:[{n,c}]} ] }

class Family {
  String n; // ಹೆಸರು / ವಿಳಾಸ
  String c; // 5 ಅಕ್ಷರ; '1' = ✓
  String p; // ಮೊಬೈಲ್ (ಐಚ್ಛಿಕ)
  String k; // ಕಾಲುಕಾಣಿಕೆ ಮೊತ್ತ (ಐಚ್ಛಿಕ)
  Family({required this.n, required this.c, this.p = '', this.k = ''});

  factory Family.fromMap(Map m) => Family(
        n: (m['n'] ?? '').toString(),
        c: (m['c'] ?? '00000').toString(),
        p: (m['p'] ?? '').toString(),
        k: (m['k'] ?? '').toString(),
      );

  Map<String, dynamic> toMap() => {'n': n, 'c': c, 'p': p, 'k': k};

  bool isOn(int i) => i < c.length && c[i] == '1';

  void setOn(int i, bool v) {
    final list = c.padRight(5, '0').split('');
    if (i >= 0 && i < list.length) list[i] = v ? '1' : '0';
    c = list.join();
  }

  int get count => '1'.allMatches(c).length;
}

class Region {
  dynamic no;
  String name;
  String phone;
  List<Family> families;
  Region({this.no, required this.name, required this.phone, required this.families});

  factory Region.fromMap(Map m) => Region(
        no: m['no'],
        name: (m['name'] ?? '').toString(),
        phone: (m['phone'] ?? '').toString(),
        families: ((m['families'] as List?) ?? [])
            .map((f) => Family.fromMap(f as Map))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'no': no,
        'name': name,
        'phone': phone,
        'families': families.map((f) => f.toMap()).toList(),
      };
}

/// ಒಂದು ಪೂಜೆಯ ಈ ವರ್ಷದ ದರ.
class PoojaRate {
  String n; // ಪೂಜೆ ಹೆಸರು
  String r; // ದರ (ಪಠ್ಯ)
  PoojaRate({required this.n, required this.r});
  factory PoojaRate.fromMap(Map m) =>
      PoojaRate(n: (m['n'] ?? '').toString(), r: (m['r'] ?? '').toString());
  Map<String, dynamic> toMap() => {'n': n, 'r': r};
}

class PoojaData {
  String title;
  List<String> columns;
  int year;
  List<Region> regions;
  List<PoojaRate> rates;
  PoojaData({
    required this.title,
    required this.columns,
    required this.year,
    required this.regions,
    this.rates = const [],
  });

  factory PoojaData.fromDoc(Map m, int year) => PoojaData(
        title: (m['title'] ?? '').toString(),
        columns: ((m['columns'] as List?) ?? []).map((e) => e.toString()).toList(),
        year: (m['year'] is int) ? m['year'] as int : year,
        regions: ((m['regions'] as List?) ?? [])
            .map((r) => Region.fromMap(r as Map))
            .toList(),
        rates: ((m['rates'] as List?) ?? [])
            .map((x) => PoojaRate.fromMap(x as Map))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'columns': columns,
        'year': year,
        'regions': regions.map((r) => r.toMap()).toList(),
        'rates': rates.map((x) => x.toMap()).toList(),
      };

  /// ಕಾಲಂ → ದರ (ಸಂಖ್ಯೆ). ಖಾಲಿ/ಅಮಾನ್ಯ → 0.
  double rateFor(String col) {
    for (final x in rates) {
      if (x.n == col) return double.tryParse(x.r.trim()) ?? 0;
    }
    return 0;
  }

  /// ಒಬ್ಬ ವ್ಯಕ್ತಿಯ ಪೂಜಾ ಮೊತ್ತ (ಗುರುತಿಸಿದ ಪೂಜೆಗಳ ದರಗಳ ಮೊತ್ತ).
  double poojaAmount(Family f) {
    double s = 0;
    for (var ci = 0; ci < columns.length; ci++) {
      if (f.isOn(ci)) s += rateFor(columns[ci]);
    }
    return s;
  }

  /// ಹೊಸ ವರ್ಷಕ್ಕೆ — ಮಾಗಣೆ/ಹೆಸರು ಉಳಿಸಿ, ಎಲ್ಲ ಪೂಜಾ ಆಯ್ಕೆ + ದರ ಖಾಲಿ.
  PoojaData clearedForYear(int newYear) => PoojaData(
        title:
            '${newYear}ರಲ್ಲಿ ಹೂವಿನ ಪೂಜೆ, ವಿಶ್ವಕರ್ಮ ಪೂಜೆ, ನವರಾತ್ರಿ ಪೂಜೆ ಮಾಡಿಸಿದವರು',
        columns: List<String>.from(columns),
        year: newYear,
        rates: const [], // ದರಗಳು ಪ್ರತಿ ವರ್ಷ ಖಾಲಿಯಾಗಿ ಆರಂಭ
        regions: regions
            .map((r) => Region(
                  no: r.no,
                  name: r.name,
                  phone: r.phone,
                  families: r.families
                      .map((f) => Family(n: f.n, c: '00000', p: f.p))
                      .toList(),
                ))
            .toList(),
      );
}

/// ಸಂಖ್ಯೆಯನ್ನು ₹ ರೂಪದಲ್ಲಿ (ಭಾರತೀಯ ಗುಂಪು).
String money(num n) {
  final v = n.round();
  final s = v.abs().toString();
  if (s.length <= 3) return '₹$v';
  // ಭಾರತೀಯ ಸಮೂಹ: ಕೊನೆಯ 3, ನಂತರ 2-2
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final buf = StringBuffer();
  while (rest.length > 2) {
    buf.write(',${rest.substring(rest.length - 2)}');
    rest = rest.substring(0, rest.length - 2);
  }
  final grouped = rest + buf.toString();
  return '₹$grouped,$last3';
}
