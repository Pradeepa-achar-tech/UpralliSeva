/// ದತ್ತಾಂಶ ಮಾದರಿಗಳು — ವೆಬ್ ಆ್ಯಪ್‌ನ Firestore ರಚನೆಯನ್ನೇ ಪ್ರತಿಬಿಂಬಿಸುತ್ತದೆ.
/// pooja/{year} = { title, columns:[], year, regions:[ {no,name,phone, families:[{n,c}]} ] }

class Family {
  String n; // ಹೆಸರು / ವಿಳಾಸ
  String c; // 5 ಅಕ್ಷರ; '1' = ✓
  Family({required this.n, required this.c});

  factory Family.fromMap(Map m) =>
      Family(n: (m['n'] ?? '').toString(), c: (m['c'] ?? '00000').toString());

  Map<String, dynamic> toMap() => {'n': n, 'c': c};

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

class PoojaData {
  String title;
  List<String> columns;
  int year;
  List<Region> regions;
  PoojaData({
    required this.title,
    required this.columns,
    required this.year,
    required this.regions,
  });

  factory PoojaData.fromDoc(Map m, int year) => PoojaData(
        title: (m['title'] ?? '').toString(),
        columns: ((m['columns'] as List?) ?? []).map((e) => e.toString()).toList(),
        year: (m['year'] is int) ? m['year'] as int : year,
        regions: ((m['regions'] as List?) ?? [])
            .map((r) => Region.fromMap(r as Map))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'columns': columns,
        'year': year,
        'regions': regions.map((r) => r.toMap()).toList(),
      };

  /// ಹೊಸ ವರ್ಷಕ್ಕೆ — ಮಾಗಣೆ/ಹೆಸರು ಉಳಿಸಿ, ಎಲ್ಲ ಪೂಜಾ ಆಯ್ಕೆ ಖಾಲಿ.
  PoojaData clearedForYear(int newYear) => PoojaData(
        title:
            '${newYear}ರಲ್ಲಿ ಹೂವಿನ ಪೂಜೆ, ವಿಶ್ವಕರ್ಮ ಪೂಜೆ, ನವರಾತ್ರಿ ಪೂಜೆ ಮಾಡಿಸಿದವರು',
        columns: List<String>.from(columns),
        year: newYear,
        regions: regions
            .map((r) => Region(
                  no: r.no,
                  name: r.name,
                  phone: r.phone,
                  families:
                      r.families.map((f) => Family(n: f.n, c: '00000')).toList(),
                ))
            .toList(),
      );
}
