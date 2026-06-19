import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../main.dart';
import '../models.dart';
import '../pdf_service.dart';
import 'region_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<int> _years = [];
  int _year = DateTime.now().year;
  bool _loadingYears = true;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    try {
      final years = await firestoreService.listYears();
      if (!mounted) return;
      setState(() {
        _years = years;
        if (years.isNotEmpty && !years.contains(_year)) _year = years.first;
        if (!_years.contains(_year)) _years = [_year, ..._years]..sort((a, b) => b - a);
        _loadingYears = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingYears = false);
    }
  }

  Future<void> _newYear() async {
    final controller = TextEditingController(text: '${_year + 1}');
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ಹೊಸ ವರ್ಷ'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'ವರ್ಷ (ಉದಾ. 2027)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ರದ್ದು')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim())),
            child: const Text('ಸರಿ'),
          ),
        ],
      ),
    );
    if (picked == null || picked < 2000 || picked > 2100) return;

    if (_years.contains(picked)) {
      setState(() => _year = picked);
      return;
    }
    final sourceYear = _years.isNotEmpty ? _years.first : null;
    if (sourceYear == null) {
      _snack('ಮೊದಲ ವರ್ಷವನ್ನು ವೆಬ್‌ನಲ್ಲಿ ರಚಿಸಿ (ಹೆಸರು ಪಟ್ಟಿ ಬೇಕಾಗುತ್ತದೆ).');
      return;
    }
    final src = await firestoreService.getYearOnce(sourceYear);
    if (src == null) return;
    await firestoreService.saveYear(src.clearedForYear(picked));
    await _loadYears();
    if (mounted) setState(() => _year = picked);
    _snack('ವರ್ಷ $picked ರಚಿಸಲಾಗಿದೆ');
  }

  Future<void> _sharePdf({bool whatsapp = false}) async {
    _snack('PDF ತಯಾರಿಸಲಾಗುತ್ತಿದೆ…');
    try {
      final data = await firestoreService.getYearOnce(_year);
      if (data == null) {
        _snack('$_year ವರ್ಷದ ದತ್ತಾಂಶ ಇಲ್ಲ');
        return;
      }
      if (whatsapp) {
        final direct = await PdfService.shareWhatsApp(data);
        if (!direct) _snack('WhatsApp ಸಿಗಲಿಲ್ಲ — ಸಾಮಾನ್ಯ ಹಂಚಿಕೆ ತೆರೆಯಲಾಗಿದೆ');
      } else {
        await PdfService.share(data);
      }
    } catch (e) {
      _snack('ಹಂಚಿಕೆ ವಿಫಲ: $e');
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: StreamBuilder<PoojaData?>(
                stream: firestoreService.watchYear(_year),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return _message(Icons.cloud_off, 'ಕ್ಲೌಡ್ ಸಂಪರ್ಕ ದೋಷ',
                        'ಇಂಟರ್ನೆಟ್ ಪರಿಶೀಲಿಸಿ, ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ.');
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data;
                  if (data == null) {
                    return _message(Icons.inbox_outlined, '$_year ವರ್ಷದ ದತ್ತಾಂಶ ಇಲ್ಲ',
                        'ಮೇಲಿನ ವರ್ಷ ಬದಲಿಸಿ ಅಥವಾ “ಹೊಸ ವರ್ಷ” ಸೇರಿಸಿ.');
                  }
                  return _content(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- ಮೇಲಿನ ಹೆಡರ್ (gradient + ವರ್ಷ + ಕ್ರಿಯೆಗಳು) ----------
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Image.asset('assets/icon/app_icon.png', width: 26, height: 26),
          ),
          const SizedBox(width: 8),
          const Text('ಉಪ್ರಳ್ಳಿ ಸೇವೆ',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          _yearChip(),
          const Spacer(),
          IconButton(
              tooltip: 'WhatsApp',
              onPressed: () => _sharePdf(whatsapp: true),
              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20)),
          IconButton(
              tooltip: 'PDF',
              onPressed: () => _sharePdf(),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) {
              if (v == 'new') _newYear();
              if (v == 'logout') authService.signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: ListTile(leading: Icon(Icons.calendar_month), title: Text('ಹೊಸ ವರ್ಷ'))),
              PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('ಲಾಗ್‌ಔಟ್'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _yearChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _years.contains(_year) ? _year : null,
          hint: Text('$_year', style: const TextStyle(color: Colors.white)),
          dropdownColor: Colors.white,
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          items: _years
              .map((y) => DropdownMenuItem(
                    value: y,
                    child: Text('$y', style: const TextStyle(color: Colors.black87)),
                  ))
              .toList(),
          onChanged: (y) {
            if (y != null) setState(() => _year = y);
          },
        ),
      ),
    );
  }

  // ---------- ವಿಷಯ: ಅಂಕಿಅಂಶ + ಮಾಗಣೆ ಪಟ್ಟಿ ----------
  Widget _content(PoojaData data) {
    final regions = data.regions;
    final totalNames = regions.fold<int>(0, (n, r) => n + r.families.length);
    final doneNames =
        regions.fold<int>(0, (n, r) => n + r.families.where((f) => f.count > 0).length);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 24),
      children: [
        Row(
          children: [
            _stat('${regions.length}', 'ಮಾಗಣೆ', Icons.location_city),
            const SizedBox(width: 10),
            _stat('$totalNames', 'ಹೆಸರು', Icons.groups),
            const SizedBox(width: 10),
            _stat('$doneNames', 'ಗುರುತಿಸಲಾಗಿದೆ', Icons.task_alt),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(regions.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _regionCard(data, i),
            )),
      ],
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: kPrimary, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _regionCard(PoojaData data, int i) {
    final r = data.regions[i];
    final total = r.families.length;
    final done = r.families.where((f) => f.count > 0).length;
    final pct = total == 0 ? 0.0 : done / total;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RegionScreen(data: data, regionIndex: i)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: kPrimary.withOpacity(.12),
                child: Text('${r.no ?? i + 1}',
                    style: const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.black12,
                        valueColor: const AlwaysStoppedAnimation(kPrimary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$done / $total ಗುರುತಿಸಲಾಗಿದೆ',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: Colors.black26),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _newYear,
              icon: const Icon(Icons.add),
              label: const Text('ಹೊಸ ವರ್ಷ'),
            ),
          ],
        ),
      ),
    );
  }
}
