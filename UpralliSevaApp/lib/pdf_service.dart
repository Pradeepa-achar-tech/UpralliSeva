import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models.dart';

/// PoojaData → A4 PDF (Kannada font embedded) → share / print.
class PdfService {
  static Future<pw.Font> _loadFont() async {
    final d = await rootBundle.load('assets/fonts/NotoSansKannada-Regular.ttf');
    return pw.Font.ttf(d);
  }

  static Future<Uint8List> build(PoojaData data, {bool blank = false}) async {
    final font = await _loadFont();
    final doc = pw.Document(theme: pw.ThemeData.withFont(base: font, bold: font));

    final widgets = <pw.Widget>[
      pw.Center(
        child: pw.Text(data.title,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ),
      pw.SizedBox(height: 10),
    ];

    for (final r in data.regions) {
      widgets.add(pw.SizedBox(height: 8));
      widgets.add(pw.Text('${r.no ?? ''}  ${r.name}',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)));
      widgets.add(pw.SizedBox(height: 3));
      widgets.add(_table(r, data.columns, blank));
    }

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => widgets,
    ));
    return doc.save();
  }

  static pw.Widget _table(Region r, List<String> cols, bool blank) {
    final headers = <String>['ಕ್ರ.', 'ಹೆಸರು / ವಿಳಾಸ', ...cols];
    return pw.Table(
      border: pw.TableBorder.all(width: .5),
      columnWidths: {
        0: const pw.FixedColumnWidth(24),
        1: const pw.FlexColumnWidth(),
        for (var i = 0; i < cols.length; i++) (2 + i): const pw.FixedColumnWidth(34),
      },
      children: [
        pw.TableRow(
          repeat: true, // ಉಕ್ಕಿದ ಪುಟದಲ್ಲೂ ಶೀರ್ಷಿಕೆ ಸಾಲು ಪುನರಾವರ್ತನೆ
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers.map((h) => _cell(h, bold: true, center: true)).toList(),
        ),
        for (var i = 0; i < r.families.length; i++)
          pw.TableRow(
            children: [
              _cell('${i + 1}', center: true),
              _cell(r.families[i].n),
              for (var ci = 0; ci < cols.length; ci++)
                _cell((!blank && r.families[i].isOn(ci)) ? '✓' : '', center: true),
            ],
          ),
      ],
    );
  }

  static pw.Widget _cell(String t, {bool bold = false, bool center = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: pw.Text(
          t,
          textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
          style: pw.TextStyle(
              fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      );

  static const MethodChannel _channel = MethodChannel('app/share');

  /// ಸಾಮಾನ್ಯ ಹಂಚಿಕೆ (ಆ್ಯಂಡ್ರಾಯ್ಡ್ share sheet — WhatsApp ಸಹ ಇರುತ್ತದೆ).
  static Future<void> share(PoojaData data, {bool blank = false}) async {
    final bytes = await build(data, blank: blank);
    await Printing.sharePdf(bytes: bytes, filename: 'pooja-dakhale-${data.year}.pdf');
  }

  static Future<void> printDoc(PoojaData data, {bool blank = false}) async {
    await Printing.layoutPdf(onLayout: (_) async => build(data, blank: blank));
  }

  /// WhatsApp ಗೆ ನೇರ ಹಂಚಿಕೆ. WhatsApp ಇಲ್ಲದಿದ್ದರೆ ಸಾಮಾನ್ಯ share sheet ಗೆ ಮರಳುತ್ತದೆ.
  /// ಹಿಂತಿರುಗಿಸುತ್ತದೆ: true = WhatsApp ತೆರೆಯಿತು, false = fallback ಬಳಸಲಾಯಿತು.
  static Future<bool> shareWhatsApp(PoojaData data, {bool blank = false}) async {
    final bytes = await build(data, blank: blank);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pooja-dakhale-${data.year}.pdf');
    await file.writeAsBytes(bytes);

    for (final pkg in const ['com.whatsapp', 'com.whatsapp.w4b']) {
      try {
        final ok = await _channel
            .invokeMethod<bool>('whatsapp', {'path': file.path, 'package': pkg});
        if (ok == true) return true;
      } catch (_) {
        // ಈ ಪ್ಯಾಕೇಜ್ ಇಲ್ಲ — ಮುಂದಿನದನ್ನು ಪ್ರಯತ್ನಿಸು
      }
    }
    // Fallback: ಸಾಮಾನ್ಯ share sheet
    await Printing.sharePdf(bytes: bytes, filename: 'pooja-dakhale-${data.year}.pdf');
    return false;
  }
}
