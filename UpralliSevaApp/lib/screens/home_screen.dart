import 'package:flutter/material.dart';
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
    try {
      final years = await firestoreService.listYears();
      if (!mounted) return;
      setState(() {
        // dropdown = ಕ್ಲೌಡ್‌ನಲ್ಲಿ ಇರುವ ವರ್ಷಗಳು ಮಾತ್ರ (ಅಳಿಸಿದ ವರ್ಷ ಮರಳಿ ಬರದಂತೆ)
        _years = [...years]..sort((a, b) => b - a);
        if (_years.isEmpty) {
          _years = [_year];                                   // ಏನೂ ಇಲ್ಲ — ಪ್ರಸ್ತುತ ತೋರಿಸು
        } else if (!_years.contains(_year)) {
          _year = _years.first;                               // ಅಳಿಸಿದ/ಅಮಾನ್ಯ → ಇರುವ ವರ್ಷಕ್ಕೆ
        }
      });
    } catch (_) {/* ignore */}
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

  Future<void> _deleteYear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ವರ್ಷ $_year ಅಳಿಸಿ'),
        content: Text('$_year ವರ್ಷದ ಎಲ್ಲ ದತ್ತಾಂಶವನ್ನು ಶಾಶ್ವತವಾಗಿ ಅಳಿಸಬೇಕೆ? ಇದನ್ನು ಹಿಂಪಡೆಯಲಾಗದು.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ರದ್ದು')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ಅಳಿಸಿ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await firestoreService.deleteYear(_year);
      _snack('ವರ್ಷ $_year ಅಳಿಸಲಾಗಿದೆ');
      final remaining = (await firestoreService.listYears())..remove(_year);
      await _loadYears();
      if (mounted && remaining.isNotEmpty) setState(() => _year = remaining.first);
    } catch (e) {
      _snack('ಅಳಿಸಲಾಗಲಿಲ್ಲ: $e');
    }
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
        backgroundColor: kSide2,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kSide1, kSide2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        titleSpacing: 12,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Image.asset('assets/icon/app_icon.png', width: 26, height: 26),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text('ಉಪ್ರಳ್ಳಿ ಸೇವೆ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(
              tooltip: 'PDF', onPressed: () => _sharePdf(), icon: const Icon(Icons.picture_as_pdf)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'new') _newYear();
              if (v == 'delete') _deleteYear();
              if (v == 'logout') authService.signOut();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'new', child: ListTile(leading: Icon(Icons.calendar_month), title: Text('ಹೊಸ ವರ್ಷ'))),
              PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('ಈ ವರ್ಷ ಅಳಿಸಿ'))),
              PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('ಲಾಗ್‌ಔಟ್'))),
            ],
          ),
        ],
      ),
      body: StreamBuilder<PoojaData?>(
        stream: firestoreService.watchYear(_year),
        builder: (context, snap) {
          if (snap.hasError) {
            return _message(Icons.cloud_off, 'ಕ್ಲೌಡ್ ಸಂಪರ್ಕ ದೋಷ', 'ಇಂಟರ್ನೆಟ್ ಪರಿಶೀಲಿಸಿ.');
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _yearBar()),
              if (data == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _message(Icons.inbox_outlined, '$_year ವರ್ಷದ ದತ್ತಾಂಶ ಇಲ್ಲ',
                      'ಮೇಲಿನ ವರ್ಷ ಬದಲಿಸಿ ಅಥವಾ “ಹೊಸ ವರ್ಷ” ಸೇರಿಸಿ.'),
                )
              else ...[
                SliverToBoxAdapter(child: _stats(data)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  sliver: SliverList.separated(
                    itemCount: data.regions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _regionCard(data, i),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ---------- ವರ್ಷ ಆಯ್ಕೆ ಪಟ್ಟಿ ----------
  Widget _yearBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: kPrimary, size: 20),
            const SizedBox(width: 8),
            const Text('ವರ್ಷ', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _years.contains(_year) ? _year : null,
                  hint: Text('$_year'),
                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                  onChanged: (y) {
                    if (y != null) setState(() => _year = y);
                  },
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _newYear,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('ಹೊಸ'),
              style: TextButton.styleFrom(foregroundColor: kPrimaryDark),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- ಅಂಕಿಅಂಶ ----------
  Widget _stats(PoojaData data) {
    final regions = data.regions;
    final totalNames = regions.fold<int>(0, (n, r) => n + r.families.length);
    final doneNames = regions.fold<int>(0, (n, r) => n + r.families.where((f) => f.count > 0).length);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Row(
        children: [
          _stat('${regions.length}', 'ಮಾಗಣೆ', Icons.location_city),
          const SizedBox(width: 10),
          _stat('$totalNames', 'ಹೆಸರು', Icons.groups),
          const SizedBox(width: 10),
          _stat('$doneNames', 'ಪೂಜೆ ಸಲ್ಲಿಸಿದ್ದಾರೆ', Icons.task_alt),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kCardLine),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 6, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Container(width: 3, height: 38, decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kInk)),
                  ),
                  const SizedBox(height: 2),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: Colors.black54, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
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
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.black12,
                        valueColor: const AlwaysStoppedAnimation(kPrimary),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text('$done / $total ಪೂಜೆ ಸಲ್ಲಿಸಿದ್ದಾರೆ',
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
            FilledButton.icon(onPressed: _newYear, icon: const Icon(Icons.add), label: const Text('ಹೊಸ ವರ್ಷ')),
          ],
        ),
      ),
    );
  }
}
