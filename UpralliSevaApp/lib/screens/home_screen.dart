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

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  Future<void> _loadYears() async {
    final years = await firestoreService.listYears();
    setState(() {
      _years = years;
      if (years.isNotEmpty && !years.contains(_year)) _year = years.first;
      if (!_years.contains(_year)) _years = [_year, ..._years];
    });
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

    // ಈಗಾಗಲೇ ಇದ್ದರೆ ಅದನ್ನೇ ತೆರೆ
    if (_years.contains(picked)) {
      setState(() => _year = picked);
      return;
    }
    // ಇತ್ತೀಚಿನ ವರ್ಷದ ಹೆಸರು ಪಟ್ಟಿಯಿಂದ ಹೊಸ (ಖಾಲಿ ಆಯ್ಕೆ) ವರ್ಷ ರಚಿಸು
    final sourceYear = _years.isNotEmpty ? _years.first : null;
    if (sourceYear == null) {
      _snack('ಮೊದಲ ವರ್ಷವನ್ನು ವೆಬ್‌ನಲ್ಲಿ ರಚಿಸಿ (ಹೆಸರು ಪಟ್ಟಿ ಬೇಕಾಗುತ್ತದೆ).');
      return;
    }
    final src = await firestoreService.getYearOnce(sourceYear);
    if (src == null) return;
    final fresh = src.clearedForYear(picked);
    await firestoreService.saveYear(fresh);
    await _loadYears();
    setState(() => _year = picked);
    _snack('ವರ್ಷ $picked ರಚಿಸಲಾಗಿದೆ');
  }

  Future<void> _sharePdf() async {
    _snack('PDF ತಯಾರಿಸಲಾಗುತ್ತಿದೆ…');
    try {
      final data = await firestoreService.getYearOnce(_year);
      if (data == null) {
        _snack('$_year ವರ್ಷದ ದತ್ತಾಂಶ ಇಲ್ಲ');
        return;
      }
      await PdfService.share(data);
    } catch (e) {
      _snack('PDF ವಿಫಲ: $e');
    }
  }

  Future<void> _shareWhatsApp() async {
    _snack('PDF ತಯಾರಿಸಲಾಗುತ್ತಿದೆ…');
    try {
      final data = await firestoreService.getYearOnce(_year);
      if (data == null) {
        _snack('$_year ವರ್ಷದ ದತ್ತಾಂಶ ಇಲ್ಲ');
        return;
      }
      final direct = await PdfService.shareWhatsApp(data);
      if (!direct) _snack('WhatsApp ಸಿಗಲಿಲ್ಲ — ಸಾಮಾನ್ಯ ಹಂಚಿಕೆ ತೆರೆಯಲಾಗಿದೆ');
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
      appBar: AppBar(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text('ಪೂಜಾ ದಾಖಲೆ'),
            const SizedBox(width: 12),
            _yearDropdown(),
          ],
        ),
        actions: [
          IconButton(
              tooltip: 'WhatsApp ಗೆ ಕಳುಹಿಸಿ',
              onPressed: _shareWhatsApp,
              icon: const FaIcon(FontAwesomeIcons.whatsapp)),
          IconButton(
              tooltip: 'PDF ಹಂಚಿಕೊಳ್ಳಿ / ಮುದ್ರಿಸಿ',
              onPressed: _sharePdf,
              icon: const Icon(Icons.picture_as_pdf)),
          IconButton(
              tooltip: 'ಹೊಸ ವರ್ಷ', onPressed: _newYear, icon: const Icon(Icons.calendar_month)),
          IconButton(
              tooltip: 'ಲಾಗ್‌ಔಟ್',
              onPressed: () => authService.signOut(),
              icon: const Icon(Icons.logout)),
        ],
      ),
      body: StreamBuilder<PoojaData?>(
        stream: firestoreService.watchYear(_year),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          if (data == null) {
            return _empty();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.regions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = data.regions[i];
              final done = r.families.where((f) => f.count > 0).length;
              return Card(
                elevation: 1,
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: kAccent.withOpacity(.15),
                      child: Text('${r.no ?? i + 1}',
                          style: const TextStyle(
                              color: kAccent, fontWeight: FontWeight.bold))),
                  title: Text(r.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${r.families.length} ಹೆಸರು · $done ಗುರುತಿಸಲಾಗಿದೆ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RegionScreen(data: data, regionIndex: i),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _yearDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          color: Colors.white24, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _years.contains(_year) ? _year : null,
          dropdownColor: Colors.white,
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 15),
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

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 56, color: Colors.black26),
            const SizedBox(height: 12),
            Text('$_year ವರ್ಷದ ದತ್ತಾಂಶ ಇಲ್ಲ',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text('“ಹೊಸ ವರ್ಷ” ಒತ್ತಿ ರಚಿಸಿ, ಅಥವಾ ಮೇಲಿನ ಪಟ್ಟಿಯಿಂದ ಬೇರೆ ವರ್ಷ ಆಯ್ಕೆಮಾಡಿ.',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
