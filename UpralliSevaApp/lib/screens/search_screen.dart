import 'package:flutter/material.dart';
import '../main.dart';
import '../models.dart';
import 'region_screen.dart';

/// ಹುಡುಕಾಟ — ಎಲ್ಲ ಬಳಕೆದಾರರಿಗೆ (ಓದು + ಸಂಪಾದನೆ).
/// ಮಾಗಣೆ ಹೆಸರು · ವ್ಯಕ್ತಿಯ ಹೆಸರು · ದೂರವಾಣಿ ಸಂಖ್ಯೆ (ಮಾಗಣೆ ಅಥವಾ ವ್ಯಕ್ತಿಯದ್ದು).
class SearchScreen extends StatefulWidget {
  final PoojaData data;
  const SearchScreen({super.key, required this.data});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openRegion(int ri) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => RegionScreen(data: widget.data, regionIndex: ri)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final regions = widget.data.regions;

    final magHits = <int>[]; // ಮಾಗಣೆ (ಹೆಸರು/ದೂರವಾಣಿ)
    final personHits = <_Hit>[]; // ವ್ಯಕ್ತಿ (ಹೆಸರು/ದೂರವಾಣಿ)

    if (q.isNotEmpty) {
      for (var ri = 0; ri < regions.length; ri++) {
        final r = regions[ri];
        if (r.name.toLowerCase().contains(q) ||
            r.phone.toLowerCase().contains(q)) {
          magHits.add(ri);
        }
        for (var fi = 0; fi < r.families.length; fi++) {
          final f = r.families[fi];
          if (f.n.toLowerCase().contains(q) ||
              f.p.toLowerCase().contains(q)) {
            personHits.add(_Hit(ri, fi, f, r));
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSide2,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [kSide1, kSide2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'ಮಾಗಣೆ · ಹೆಸರು · ದೂರವಾಣಿ ಹುಡುಕಿ…',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
        actions: [
          if (_q.isNotEmpty)
            IconButton(
              tooltip: 'ತೆರವು',
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctrl.clear();
                setState(() => _q = '');
              },
            ),
        ],
      ),
      body: q.isEmpty
          ? _hint()
          : (magHits.isEmpty && personHits.isEmpty)
              ? _empty()
              : ListView(
                  children: [
                    if (magHits.isNotEmpty)
                      _sectionHeader('ಮಾಗಣೆ (${magHits.length})'),
                    ...magHits.map((ri) => _maganiTile(regions[ri], ri)),
                    if (personHits.isNotEmpty)
                      _sectionHeader('ವ್ಯಕ್ತಿಗಳು (${personHits.length})'),
                    ...personHits.map(_personTile),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }

  Widget _sectionHeader(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: kPrimaryDark,
                letterSpacing: .3)),
      );

  Widget _maganiTile(Region r, int ri) => ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: kPrimary.withOpacity(.12),
          child: Text('${r.no ?? ri + 1}',
              style:
                  const TextStyle(color: kPrimaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        title: Text(r.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${r.families.length} ಹೆಸರು${r.phone.trim().isEmpty ? '' : ' · 📞 ${r.phone}'}',
            style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: () => _openRegion(ri),
      );

  Widget _personTile(_Hit h) => ListTile(
        leading: const Icon(Icons.person_outline, color: kPrimary),
        title: Text(h.f.n.trim().isEmpty ? '—' : h.f.n,
            maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${h.r.name}${h.f.p.trim().isEmpty ? '' : ' · 📞 ${h.f.p}'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: () => _openRegion(h.ri),
      );

  Widget _hint() => const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 60, color: Colors.black26),
              SizedBox(height: 14),
              Text('ಮಾಗಣೆ ಹೆಸರು, ವ್ಯಕ್ತಿಯ ಹೆಸರು ಅಥವಾ\nದೂರವಾಣಿ ಸಂಖ್ಯೆಯಿಂದ ಹುಡುಕಿ',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 56, color: Colors.black26),
              const SizedBox(height: 12),
              Text('“$_q” — ಏನೂ ಸಿಗಲಿಲ್ಲ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );
}

class _Hit {
  final int ri;
  final int fi;
  final Family f;
  final Region r;
  _Hit(this.ri, this.fi, this.f, this.r);
}
