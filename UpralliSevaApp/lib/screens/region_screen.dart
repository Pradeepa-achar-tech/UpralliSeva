import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../models.dart';

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

  void _toggle(Family f, int ci) {
    final now = !f.isOn(ci);
    setState(() => f.setOn(ci, now));
    final col = ci < cols.length ? cols[ci] : '';
    final person = f.n.split(',').first.trim();
    _snack(
      now ? '✓ $col ಸೇರಿಸಲಾಗಿದೆ${person.isNotEmpty ? ' — $person' : ''}'
          : '✗ $col ತೆಗೆಯಲಾಗಿದೆ${person.isNotEmpty ? ' — $person' : ''}',
      now,
    );
    _scheduleSave();
  }

  void _scheduleSave() {
    _dirty = true;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _save);
  }

  bool _pendingNameSnack = false;

  Future<void> _save() async {
    if (!_dirty) return;
    _dirty = false;
    try {
      await firestoreService.saveYear(widget.data);
      if (_pendingNameSnack && mounted) {
        _pendingNameSnack = false;
        _snack('✓ ಹೆಸರು ಉಳಿಸಲಾಗಿದೆ', true);
      }
    } catch (e) {
      if (mounted) _snack('⚠ ಉಳಿಯಲಿಲ್ಲ — ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ', false);
    }
  }

  void _addRow() {
    setState(() => region.families.add(Family(n: '', c: '00000')));
    _scheduleSave();
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
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        title: Text(region.name, overflow: TextOverflow.ellipsis),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRow,
        backgroundColor: kAccent,
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
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: Colors.black12,
                              child: Text('${i + 1}',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                initialValue: f.n,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: UnderlineInputBorder(),
                                  hintText: 'ಹೆಸರು / ವಿಳಾಸ ಸಂಪಾದಿಸಿ',
                                  suffixIcon: Icon(Icons.edit, size: 16, color: Colors.black38),
                                ),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                                onChanged: (v) {
                                  f.n = v;
                                  _pendingNameSnack = true;
                                  _scheduleSave();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: List.generate(cols.length, (ci) {
                            final on = f.isOn(ci);
                            return FilterChip(
                              label: Text(cols[ci]),
                              selected: on,
                              showCheckmark: true,
                              selectedColor: kAccent.withOpacity(.20),
                              onSelected: (_) => _toggle(f, ci),
                            );
                          }),
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
