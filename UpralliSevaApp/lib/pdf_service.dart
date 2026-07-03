import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'models.dart';

/// PoojaData → A4 PDF → share / print.
///
/// ಕನ್ನಡ ಸರಿಯಾಗಿ ಮೂಡಲು HTML → ಸ್ಥಳೀಯ WebView ಮೂಲಕ PDF (Printing.convertHtml).
/// ವೆಬ್ ಆ್ಯಪ್‌ನ ಮುದ್ರಣ ಶೈಲಿಯನ್ನೇ ಪ್ರತಿಬಿಂಬಿಸುತ್ತದೆ:
///  - ಪ್ರತಿ ಮಾಗಣೆ ಸ್ವಂತ ಪುಟದಲ್ಲಿ, ನೀಲಿ ಗ್ರಿಡ್, 2-ಕಾಲಂ ಹರಿವು
///  - data: ✓/– ಗುರುತು ;  blank: ಖಾಲಿ + ಅಡ್ಡಗೆರೆ + ದೇವಸ್ಥಾನ ತಲೆಬರಹ
///  - phone: ಹೆಸರು + ದೂರವಾಣಿ ಕಾಲಂ (ಇರುವ ಸಂಖ್ಯೆ ತೋರಿಸಿ, ಇಲ್ಲದಿದ್ದರೆ ಖಾಲಿ)
class PdfService {
  static const String _temple =
      '<div class="th1">ಕರಸ್ಥಳ ಜಗದ್ಗುರು ಶ್ರೀ ನಾಗಲಿಂಗ ಸ್ವಾಮಿ ಹಾಗೂ ಶ್ರೀ ವಿಶ್ವಕರ್ಮೇಶ್ವರ ಸಾನಿಧ್ಯವಿರುವ</div>'
      '<div class="th2">ಶ್ರೀ ಕಾಳಿಕಾಂಬಾ ದೇವಸ್ಥಾನ, ಉಪ್ರಳ್ಳಿ</div>'
      '<div class="th3">ಉಳ್ಳೂರು – 11, ಪೋಸ್ಟ್ : ಮೂಡುಮಠ, ಕುಂದಾಪುರ ತಾಲೂಕು, ಉಡುಪಿ ಜಿಲ್ಲೆ – 576 219</div>';

  static String _esc(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  // ಖಾಲಿ ಅರ್ಜಿ/ದೂರವಾಣಿ ಹಾಳೆ — ಪುಟದ ಕೊನೆಯವರೆಗೆ ಖಾಲಿ ಸಾಲುಗಳು (ವೈಯಕ್ತಿಕ ಮಾಗಣೆಗೆ ಮಾತ್ರ)
  static const int _fillBlank = 90; // A4 ~ಪೂರ್ಣ ಪುಟ (2 ಕಾಲಂ)
  static const int _fillPhone = 18; // A4 ~ಪೂರ್ಣ ಪುಟ (1 ಕಾಲಂ)
  static const int _minFill = 8; // ಯಾವಾಗಲೂ ಕನಿಷ್ಠ ಇಷ್ಟು ಖಾಲಿ ಸಾಲು
  static int _pad(int n, int per) {
    final target = n <= per ? per : ((n + per - 1) ~/ per) * per;
    final p = target - n;
    return p < _minFill ? _minFill : p;
  }

  /// mode: 'data' | 'blank' | 'phone'
  /// fill: ವೈಯಕ್ತಿಕ ಮಾಗಣೆ — ಪುಟ ತುಂಬಲು ಖಾಲಿ ಸಾಲುಗಳು (ಎಲ್ಲ-ಮಾಗಣೆಗೆ ಇಲ್ಲ)
  static String _html(PoojaData data, String mode, {bool fill = false}) {
    final cols = data.columns;
    final blank = mode == 'blank';
    final phone = mode == 'phone';
    final sb = StringBuffer();
    sb.write('<!DOCTYPE html><html lang="kn"><head><meta charset="utf-8"><style>');
    sb.write(_css);
    sb.write('</style></head><body class="${blank ? 'blank' : phone ? 'phone' : 'data'}">');

    if (phone) {
      // ===== ದೂರವಾಣಿ ಸಂಗ್ರಹ ಹಾಳೆ — ಹೆಸರು + ದೂರವಾಣಿ ಕಾಲಂ =====
      for (final r in data.regions) {
        sb.write('<section class="ph-mag">');
        sb.write('<div class="ph-head"><span>${_esc('${r.no ?? ''}. ${r.name}')}</span>'
            '<span class="ph-mo">ಮೊ.: ${_esc(r.phone)}</span></div>');
        sb.write('<table class="ph-tbl"><thead><tr>'
            '<th class="ph-nm">ಹೆಸರು</th><th class="ph-num">ದೂರವಾಣಿ ಸಂಖ್ಯೆ</th>'
            '</tr></thead><tbody>');
        for (var i = 0; i < r.families.length; i++) {
          final f = r.families[i];
          sb.write('<tr><td class="ph-nm"><span class="row"><b>${i + 1}.</b>'
              '<span class="nm">${_esc(f.n)}</span></span></td>'
              '<td class="ph-num">${_esc(f.p)}</td></tr>');
        }
        // ಪುಟದ ಕೊನೆಯವರೆಗೆ ಖಾಲಿ ಸಾಲುಗಳು (ವೈಯಕ್ತಿಕ ಮಾಗಣೆಗೆ ಮಾತ್ರ)
        if (fill) {
          final np = _pad(r.families.length, _fillPhone);
          for (var j = 0; j < np; j++) {
            sb.write('<tr><td class="ph-nm">&nbsp;</td><td class="ph-num"></td></tr>');
          }
        }
        sb.write('</tbody></table></section>');
      }
      sb.write('</body></html>');
      return sb.toString();
    }

    // ===== ಡೇಟಾ / ಖಾಲಿ ಅರ್ಜಿ =====
    if (!blank) sb.write('<div class="pf-title">${_esc(data.title)}</div>');
    for (final r in data.regions) {
      sb.write('<section class="pf-mag">');
      if (blank) sb.write('<div class="pf-temple">$_temple</div>');
      sb.write('<div class="pf-head"><span>${_esc('${r.no ?? ''}. ${r.name}')}</span>'
          '<span class="pf-mo">ಮೊ.: ${_esc(r.phone)}</span></div>');
      sb.write('<table class="pf-tbl"><thead><tr><th class="pf-nm">ಹೆಸರು</th>');
      for (final c in cols) {
        sb.write('<th class="pf-c">${_esc(c)}</th>');
      }
      sb.write('</tr></thead><tfoot><tr>'
          '<td class="pf-foot" colspan="${cols.length + 1}"></td></tr></tfoot><tbody>');
      for (var i = 0; i < r.families.length; i++) {
        final f = r.families[i];
        sb.write('<tr><td class="pf-nm"><span class="row"><b>${i + 1}.</b>'
            '<span class="nm">${_esc(f.n)}</span></span></td>');
        for (var ci = 0; ci < cols.length; ci++) {
          final mark = blank ? '' : (f.isOn(ci) ? '✓' : '–');
          sb.write('<td class="pf-c"><i>$mark</i></td>');
        }
        sb.write('</tr>');
      }
      // ಖಾಲಿ ಅರ್ಜಿ — ಪುಟದ ಕೊನೆಯವರೆಗೆ ಖಾಲಿ ಸಾಲುಗಳು (ವೈಯಕ್ತಿಕ ಮಾಗಣೆಗೆ ಮಾತ್ರ)
      if (blank && fill) {
        final nb = _pad(r.families.length, _fillBlank);
        for (var j = 0; j < nb; j++) {
          sb.write('<tr class="pf-fill"><td class="pf-nm"><span class="row">'
              '<b></b><span class="nm">&nbsp;</span></span></td>');
          for (var ci = 0; ci < cols.length; ci++) {
            sb.write('<td class="pf-c"><i></i></td>');
          }
          sb.write('</tr>');
        }
      }
      sb.write('</tbody></table></section>');
    }
    sb.write('</body></html>');
    return sb.toString();
  }

  static const String _css = '''
    *{font-family:"Noto Sans Kannada","Noto Serif Kannada",sans-serif;}
    @page{margin:10mm 12mm;}
    html,body{margin:0;color:#111;-webkit-print-color-adjust:exact;print-color-adjust:exact;}
    .th1{font-size:12px;line-height:1.4;}
    .th2{font-size:16px;font-weight:800;line-height:1.4;}
    .th3{font-size:11px;line-height:1.4;}
    .pf-temple{text-align:center;margin:0 0 8px;}
    .pf-title{text-align:center;font-weight:800;font-size:15px;margin:0 0 10px;padding:0 0 6px;border-bottom:2px solid #23408e;color:#15224a;}
    /* ಪ್ರತಿ ಮಾಗಣೆ → ಸ್ವಂತ ಪುಟ; ಒಳಗೆ 2 ಕಾಲಂ ಹರಿವು */
    .pf-mag{column-count:2;column-gap:14px;column-fill:auto;page-break-before:always;}
    .pf-mag:first-of-type{page-break-before:avoid;}
    .pf-head{display:flex;justify-content:space-between;gap:8px;align-items:baseline;font-weight:800;font-size:13.5px;color:#15224a;border:1.6px solid #23408e;border-bottom:none;padding:4px 9px;background:#eaf0fb;break-after:avoid;}
    .pf-head .pf-mo{font-size:11px;font-weight:700;white-space:nowrap;}
    .pf-tbl{width:100%;border-collapse:separate;border-spacing:0;table-layout:fixed;}
    .pf-tbl th,.pf-tbl td{border:0;border-left:1.4px solid #23408e;padding:2px 7px;font-size:13px;font-weight:400;color:#111;vertical-align:top;overflow:hidden;box-sizing:border-box;line-height:1.3;}
    .pf-tbl tr>:last-child{border-right:1.6px solid #23408e;}
    .pf-tbl thead{display:table-header-group;}
    .pf-tbl thead th{border-top:1.6px solid #23408e;border-bottom:1.6px solid #23408e;font-weight:700;background:#eaf0fb;}
    .pf-tbl tfoot{display:table-footer-group;}
    .pf-tbl tfoot td{border:0;border-top:1.6px solid #23408e;padding:0;height:0;line-height:0;font-size:0;}
    .pf-tbl tr{page-break-inside:avoid;}
    .pf-tbl .pf-nm{text-align:left;word-break:break-word;border-left:1.6px solid #23408e;}
    .pf-tbl thead .pf-nm{text-align:center;}
    .pf-tbl td.pf-nm .row{display:flex;gap:5px;align-items:baseline;}
    .pf-tbl td.pf-nm .row b{flex:0 0 auto;font-weight:600;}
    .pf-tbl td.pf-nm .nm{flex:1 1 auto;min-width:0;word-break:break-word;}
    .pf-tbl .pf-c{width:32px;text-align:center;padding-left:1px;padding-right:1px;}
    .pf-tbl thead .pf-c{font-size:9px;line-height:1.15;padding:2px 1px;white-space:normal;word-break:break-word;}
    .pf-tbl .pf-c i{font-style:normal;font-weight:600;color:#23408e;}
    /* ಖಾಲಿ ಅರ್ಜಿ — ಪ್ರತಿ ಸಾಲಿಗೆ ಅಡ್ಡಗೆರೆ (ಕೈಯಲ್ಲಿ ಬರೆಯಲು) */
    body.blank .pf-tbl tbody td{border-bottom:1px solid #23408e;}
    /* ===== ದೂರವಾಣಿ ಸಂಗ್ರಹ ===== */
    .ph-mag{page-break-before:always;}
    .ph-mag:first-of-type{page-break-before:avoid;}
    .ph-head{display:flex;justify-content:space-between;gap:8px;align-items:baseline;font-weight:800;font-size:13.5px;color:#15224a;border:1.6px solid #23408e;border-bottom:none;padding:4px 9px;background:#eaf0fb;}
    .ph-head .ph-mo{font-size:11px;font-weight:700;white-space:nowrap;}
    .ph-tbl{width:100%;border-collapse:collapse;table-layout:fixed;}
    .ph-tbl th,.ph-tbl td{border:1px solid #23408e;padding:6px 8px;font-size:13px;color:#111;vertical-align:top;line-height:1.4;box-sizing:border-box;}
    .ph-tbl thead{display:table-header-group;}
    .ph-tbl thead th{background:#eaf0fb;font-weight:700;text-align:center;}
    .ph-tbl tr{page-break-inside:avoid;}
    .ph-tbl .ph-nm{width:62%;text-align:left;word-break:break-word;}
    .ph-tbl thead .ph-nm{text-align:center;}
    .ph-tbl td.ph-nm .row{display:flex;gap:5px;align-items:baseline;}
    .ph-tbl td.ph-nm .row b{flex:0 0 auto;font-weight:600;}
    .ph-tbl td.ph-nm .nm{flex:1 1 auto;min-width:0;word-break:break-word;}
    .ph-tbl .ph-num{width:38%;}
    .ph-tbl td.ph-num{height:30px;}
  ''';

  static Future<Uint8List> build(PoojaData data,
      {String mode = 'data', bool fill = false}) async {
    return Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: _html(data, mode, fill: fill),
    );
  }

  static String _mode({bool blank = false, bool phone = false}) =>
      phone ? 'phone' : (blank ? 'blank' : 'data');

  /// ಸಾಮಾನ್ಯ ಹಂಚಿಕೆ / ಉಳಿಸುವಿಕೆ (ಆ್ಯಂಡ್ರಾಯ್ಡ್ share sheet).
  /// fill=true → ವೈಯಕ್ತಿಕ ಮಾಗಣೆ (ಪುಟ ತುಂಬಲು ಖಾಲಿ ಸಾಲುಗಳು).
  static Future<void> share(PoojaData data,
      {bool blank = false, bool phone = false, bool fill = false}) async {
    final mode = _mode(blank: blank, phone: phone);
    final bytes = await build(data, mode: mode, fill: fill);
    await Printing.sharePdf(
        bytes: bytes, filename: 'upralli-seva-${data.year}-$mode.pdf');
  }

  static Future<void> printDoc(PoojaData data,
      {bool blank = false, bool phone = false, bool fill = false}) async {
    final mode = _mode(blank: blank, phone: phone);
    await Printing.layoutPdf(
        onLayout: (_) async => build(data, mode: mode, fill: fill));
  }
}
