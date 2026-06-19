import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models.dart';
import '../pdf_service.dart';

/// ಒಂದು ಮಾಗಣೆಯ ಹೆಸರುಗಳು — ಪ್ರತಿ ವ್ಯಕ್ತಿಗೆ ಪೂಜಾ ಕಾಲಂಗಳ ಚಿಪ್‌ಗಳು.
class RegionScreen extends StatefulWidget {
  final PoojaData data;
  final int regionIndex;
  const RegionScreen({super.key, required this.data, required this.regionIndex});

  @override
  State<RegionScreen> createState() => _RegionScreenState();
}

class _RegionScreenState extends State<RegionScreen> {
  Timer? _debounce;
  bool _dirty = false;

  Region get region => widget.data.regions[widget.regionIndex];
  List<String> get cols => widget.data.columns;

  void _scheduleSave() {
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  Future<void> _save() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      await firestoreService.saveYear(widget.data);
    } catch (e) {
      if (mounted) _snack('⚠ ಉಳಿಯಲಿಲ್ಲ — ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ', false);
    }
  }

  /// ಸಂಪಾದನೆ ಪಾಪ್‌ಅಪ್ — ಹೆಸರು + ಪೂಜೆಗಳು ಬದಲಾಯಿಸಿ → ನವೀಕರಿಸಿ / ರದ್ದು
  Future<bool> _editFamily(int i) async {
    final f = region.families[i];
    final nameCtrl = TextEditingController(text: f.n);
    nameCtrl.selection = const TextSelection.collapsed(offset: 0); // ಕರ್ಸರ್ ಆರಂಭದಲ್ಲಿ
    final sel = List<bool>.generate(cols.length, (ci) => f.isOn(ci));
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('ತಿದ್ದುಪಡಿ — ಕ್ರ. ${i + 1}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'ಹೆಸರು / ವಿಳಾಸ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ಪೂಜೆಗಳು', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: List.generate(cols.length, (ci) => FilterChip(
                        label: Text(cols[ci]),
                        selected: sel[ci],
                        showCheckmark: true,
                        selectedColor: kPrimary.withOpacity(.2),
                        onSelected: (v) => setLocal(() => sel[ci] = v),
                      )),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ರದ್ದು')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ನವೀಕರಿಸಿ')),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() {
        f.n = nameCtrl.text.trim();
        for (var ci = 0; ci < cols.length; ci++) f.setOn(ci, sel[ci]);
      });
      _dirty = true;
      await _save();
      if (mounted) _snack('✓ ನವೀಕರಿಸಲಾಗಿದೆ', true);
      return true;
    }
    return false;
  }

  Future<void> _addRow() async {
    setState(() => region.families.add(Family(n: '', c: '00000')));
    final idx = region.families.length - 1;
    await _editFamily(idx);
    // ಖಾಲಿ ಸಾಲು (ರದ್ದು ಮಾಡಿದರೆ) ತೆಗೆದುಹಾಕು
    if (idx < region.families.length) {
      final f = region.families[idx];
      if (f.n.trim().isEmpty && f.count == 0) {
        setState(() => region.families.removeAt(idx));
      }
    }
  }

  /// ಓದಲು-ಮಾತ್ರ ಪೂಜಾ ಟ್ಯಾಗ್ (ಸ್ಪರ್ಶಿಸಲಾಗದು)
  Widget _poojaTag(String label, bool on) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: on ? kPrimary.withOpacity(.14) : Colors.white,
        border: Border.all(color: on ? kPrimary.withOpacity(.5) : kCardLine),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(on ? Icons.check_circle : Icons.circle_outlined,
              size: 14, color: on ? kPrimaryDark : Colors.black26),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  color: on ? kPrimaryDark : Colors.black54,
                  fontWeight: on ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }

  void _snack(String m, bool ok) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(m, style: const TextStyle(fontSize: 15)),
        backgroundColor: ok ? const Color(0xFF0B8A4F) : const Color(0xFFC0392B),
        duration: const Duration(milliseconds: 1400),
      ));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _save(); // ಹೊರಡುವ ಮುನ್ನ ಉಳಿಸು
    super.dispose();
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
        title: Text(region.name, overflow: TextOverflow.ellipsis),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              final single = PoojaData(
                title: widget.data.title,
                columns: widget.data.columns,
                year: widget.data.year,
                regions: [region],
              );
              try {
                if (v == 'pdf') await PdfService.share(single);
                if (v == 'blank') await PdfService.share(single, blank: true);
              } catch (e) {
                _snack('ಹಂಚಿಕೆ ವಿಫಲ: $e', false);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'pdf',
                  child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('PDF ಡೌನ್‌ಲೋಡ್'))),
              PopupMenuItem(
                  value: 'blank',
                  child: ListTile(leading: Icon(Icons.description_outlined), title: Text('ಖಾಲಿ ಅರ್ಜಿ PDF'))),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRow,
        backgroundColor: kPrimary,
        icon: const Icon(Icons.person_add),
        label: const Text('ಹೆಸರು'),
      ),
      body: region.families.isEmpty
          ? const Center(child: Text('ಇನ್ನೂ ಹೆಸರು ಸೇರಿಸಿಲ್ಲ'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
              itemCount: region.families.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final f = region.families[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: kPrimary.withOpacity(.12),
                              child: Text('${i + 1}',
                                  style: const TextStyle(fontSize: 12, color: kPrimaryDark, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f.n.trim().isEmpty ? '— ಹೆಸರು ಸೇರಿಸಿ —' : f.n,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: f.n.trim().isEmpty ? Colors.black38 : kInk),
                              ),
                            ),
                            // ✎ ತಿದ್ದು — ಪಾಪ್‌ಅಪ್‌ನಲ್ಲಿ ಮಾತ್ರ ಬದಲಾವಣೆ (ಆಕಸ್ಮಿಕ ತಿದ್ದುಪಡಿ ಇಲ್ಲ)
                            Material(
                              color: kPrimary.withOpacity(.10),
                              borderRadius: BorderRadius.circular(9),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(9),
                                onTap: () => _editFamily(i),
                                child: const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(Icons.edit, size: 18, color: kPrimaryDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: List.generate(
                              cols.length, (ci) => _poojaTag(cols[ci], f.isOn(ci))),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
