import 'package:flutter/material.dart';
import '../main.dart';
import '../models.dart';

/// ಸೇವಾ ದರಗಳು (ಪ್ರತಿ ವರ್ಷ) — 5 ಡೀಫಾಲ್ಟ್ ಪೂಜೆಗಳಿಗೆ ದರ + ಹೆಚ್ಚುವರಿ ಪೂಜೆ ಸೇರಿಸಬಹುದು.
class RatesScreen extends StatefulWidget {
  final int year;
  const RatesScreen({super.key, required this.year});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  PoojaData? _data;
  bool _loading = true;
  String? _error;
  int _nCore = 0;

  // ಡ್ರಾಫ್ಟ್ ಸಾಲುಗಳು
  final List<TextEditingController> _name = [];
  final List<TextEditingController> _rate = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _name) c.dispose();
    for (final c in _rate) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await firestoreService.getYearOnce(widget.year);
      if (d == null) {
        setState(() {
          _loading = false;
          _error = '${widget.year} ವರ್ಷದ ದತ್ತಾಂಶ ಇಲ್ಲ';
        });
        return;
      }
      _data = d;
      _nCore = d.columns.length;
      // ಕೋರ್ (ಕಾಲಂ) ಸಾಲುಗಳು — ಇರುವ ದರ ಉಳಿಸಿ
      for (final col in d.columns) {
        final existing = d.rates.where((x) => x.n == col).toList();
        _name.add(TextEditingController(text: col));
        _rate.add(TextEditingController(text: existing.isNotEmpty ? existing.first.r : ''));
      }
      // ಹೆಚ್ಚುವರಿ ಪೂಜೆಗಳು
      for (final x in d.rates.where((x) => !d.columns.contains(x.n))) {
        _name.add(TextEditingController(text: x.n));
        _rate.add(TextEditingController(text: x.r));
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'ಲೋಡ್ ವಿಫಲ: $e';
      });
    }
  }

  void _addRow() {
    setState(() {
      _name.add(TextEditingController());
      _rate.add(TextEditingController());
    });
  }

  void _delRow(int i) {
    setState(() {
      _name.removeAt(i).dispose();
      _rate.removeAt(i).dispose();
    });
  }

  Future<void> _save() async {
    final d = _data;
    if (d == null) return;
    final List<PoojaRate> rates = [];
    for (var i = 0; i < _name.length; i++) {
      final n = _name[i].text.trim();
      final r = _rate[i].text.trim();
      if (i < _nCore) {
        rates.add(PoojaRate(n: d.columns[i], r: r)); // ಕೋರ್ ಹೆಸರು ಬದಲಾಗದು
      } else if (n.isNotEmpty) {
        rates.add(PoojaRate(n: n, r: r));
      }
    }
    d.rates = rates;
    try {
      await firestoreService.saveYear(d);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('✓ ದರಗಳು ಉಳಿಸಲಾಗಿದೆ (${widget.year})')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('ಉಳಿಯಲಿಲ್ಲ: $e')));
    }
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
                end: Alignment.bottomRight),
          ),
        ),
        title: Text('ಸೇವಾ ದರಗಳು — ${widget.year}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
                  children: [
                    const Text('ಪ್ರತಿ ಪೂಜೆಗೆ ಈ ವರ್ಷದ ದರ ನಮೂದಿಸಿ',
                        style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _name.length; i++) _row(i),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add),
                      label: const Text('ಹೊಸ ಪೂಜೆ ಸೇರಿಸಿ'),
                    ),
                  ],
                ),
      floatingActionButton: (_loading || _error != null)
          ? null
          : FloatingActionButton.extended(
              onPressed: _save,
              backgroundColor: kPrimary,
              icon: const Icon(Icons.save),
              label: const Text('ಉಳಿಸಿ'),
            ),
    );
  }

  Widget _row(int i) {
    final core = i < _nCore;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: core
                ? Text(_name[i].text,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))
                : TextField(
                    controller: _name[i],
                    decoration: const InputDecoration(
                        labelText: 'ಪೂಜೆ ಹೆಸರು', border: OutlineInputBorder(), isDense: true),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: TextField(
              controller: _rate[i],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'ದರ', prefixText: '₹ ', border: OutlineInputBorder(), isDense: true),
            ),
          ),
          if (!core)
            IconButton(
              tooltip: 'ತೆಗೆ',
              onPressed: () => _delRow(i),
              icon: const Icon(Icons.close, color: Colors.red),
            ),
        ],
      ),
    );
  }
}
