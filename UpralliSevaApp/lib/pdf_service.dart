import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'models.dart';

/// PoojaData → A4 PDF → share / print.
///
/// ಕನ್ನಡ ಸರಿಯಾಗಿ ಮೂಡಲು HTML → ಸ್ಥಳೀಯ WebView ಮೂಲಕ PDF (Printing.convertHtml).
/// (Dart `pdf` ಪ್ಯಾಕೇಜ್ ಸಂಯುಕ್ತಾಕ್ಷರಗಳನ್ನು ಸರಿಯಾಗಿ ಜೋಡಿಸುವುದಿಲ್ಲ — ಆದ್ದರಿಂದ
///  ಫಾಂಟ್/✓ ಹಾಳಾಗುತ್ತಿತ್ತು. WebView ಸ್ಥಳೀಯ ಕನ್ನಡ ಫಾಂಟ್‌ನಿಂದ ಸರಿಯಾಗಿ ಮೂಡಿಸುತ್ತದೆ.)
class PdfService {
  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  static String _html(PoojaData data, {bool blank = false}) {
    final cols = data.columns;
    final sb = StringBuffer();
    sb.write('<!DOCTYPE html><html lang="kn"><head><meta charset="utf-8">');
    sb.write('<style>'
        '*{font-family:"Noto Sans Kannada","Noto Serif Kannada",sans-serif;}'
        'body{margin:0;color:#000;}'
        'h1{font-size:15px;text-align:center;margin:0 0 4px;font-weight:700;}'
        '.legend{font-size:10px;text-align:center;color:#444;margin-bottom:8px;}'
        '.region{margin-top:10px;}'
        '.rh{font-size:12px;font-weight:700;margin:6px 0 3px;}'
        'table{width:100%;border-collapse:collapse;}'
        'th,td{border:1px solid #000;padding:3px 5px;font-size:10px;vertical-align:top;}'
        'thead th{background:#dcdcdc;text-align:center;font-weight:700;}'
        'td.c{text-align:center;width:30px;}'
        'td.no{text-align:center;width:24px;}'
        'tr{page-break-inside:avoid;}'
        'thead{display:table-header-group;}' // ಉಕ್ಕಿದ ಪುಟದಲ್ಲೂ ಶೀರ್ಷಿಕೆ
        '${blank ? '.region{page-break-before:always;}.region:first-of-type{page-break-before:avoid;}' : ''}'
        '</style></head><body>');
    sb.write('<h1>${_esc(data.title)}</h1>');
    sb.write('<div class="legend">ಕಾಲಂಗಳು: ${cols.map(_esc).join(" · ")}'
        '${blank ? '' : '  |  ✓ = ಪೂಜೆ ಮಾಡಿಸಿದ್ದಾರೆ'}</div>');
    for (final r in data.regions) {
      sb.write('<div class="region"><div class="rh">'
          '${r.no ?? ''}  ${_esc(r.name)}</div>');
      sb.write('<table><thead><tr><th>ಕ್ರ.</th><th>ಹೆಸರು / ವಿಳಾಸ</th>');
      for (final c in cols) {
        sb.write('<th>${_esc(c)}</th>');
      }
      sb.write('</tr></thead><tbody>');
      for (var i = 0; i < r.families.length; i++) {
        final f = r.families[i];
        sb.write('<tr><td class="no">${i + 1}</td><td>${_esc(f.n)}</td>');
        for (var ci = 0; ci < cols.length; ci++) {
          final on = !blank && f.isOn(ci);
          sb.write('<td class="c">${on ? '✓' : ''}</td>');
        }
        sb.write('</tr>');
      }
      sb.write('</tbody></table></div>');
    }
    sb.write('</body></html>');
    return sb.toString();
  }

  static Future<Uint8List> build(PoojaData data, {bool blank = false}) async {
    return Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: _html(data, blank: blank),
    );
  }

  /// ಸಾಮಾನ್ಯ ಹಂಚಿಕೆ / ಉಳಿಸುವಿಕೆ (ಆ್ಯಂಡ್ರಾಯ್ಡ್ share sheet).
  static Future<void> share(PoojaData data, {bool blank = false}) async {
    final bytes = await build(data, blank: blank);
    await Printing.sharePdf(bytes: bytes, filename: 'upralli-seva-${data.year}.pdf');
  }

  static Future<void> printDoc(PoojaData data, {bool blank = false}) async {
    await Printing.layoutPdf(onLayout: (_) async => build(data, blank: blank));
  }
}
