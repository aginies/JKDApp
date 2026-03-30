import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/series.dart';
import '../models/move.dart';
import 'localization_service.dart';

class PdfService {
  static Future<void> exportSeriesToPdf(JkdSeries series, String lang) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Jeet Kune Do', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(series.category, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(series.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
            pw.SizedBox(height: 10),
            pw.Text('${LocalizationService.translate('type', lang)}: ${series.type}', style: const pw.TextStyle(fontSize: 12)),
            if (series.attackMethod != null)
              pw.Text('${LocalizationService.translate('method', lang)}: ${series.attackMethod}', style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 10),
            if (series.notes.isNotEmpty) ...[
              pw.Text('${LocalizationService.translate('notes', lang)}:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(series.notes, style: const pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 20),
            ],
            pw.Divider(),
            pw.SizedBox(height: 10),
            ...series.moves.asMap().entries.map((entry) {
              final i = entry.key;
              final move = entry.value;
              return _buildMoveWidget(move, i + 1, lang);
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${series.title.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _buildMoveWidget(Move move, int index, String lang) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 20,
                height: 20,
                decoration: const pw.BoxDecoration(color: PdfColors.red, shape: pw.BoxShape.circle),
                child: pw.Center(child: pw.Text('$index', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10))),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (!move.isCombo)
                      _buildSingleMoveLine(move, lang)
                    else ...[
                      pw.Text(move.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ...move.subMoves.map((sub) => pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 15, top: 2),
                        child: _buildSingleMoveLine(sub, lang, isSub: true),
                      )),
                    ],
                    if (!move.isCombo && move.counterName != null)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 15, top: 2),
                        child: pw.Text(
                          '${LocalizationService.translate('answer', lang)}: ${move.counterName} (${move.counterSide ?? ''} ${move.counterLevel ?? ''})',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.orange900),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSingleMoveLine(Move move, String lang, {bool isSub = false}) {
    final side = move.side.isNotEmpty ? '(${move.side})' : '';
    final level = move.level.isNotEmpty ? LocalizationService.translate(move.level.toLowerCase(), lang) : '';
    final special = move.specialAction != null ? '[${move.specialAction}]' : '';
    
    return pw.Row(
      children: [
        if (isSub) pw.Text('> ', style: const pw.TextStyle(color: PdfColors.grey)),
        pw.Text(move.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: isSub ? 10 : 12)),
        pw.SizedBox(width: 5),
        pw.Text('$side $level $special', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        if (move.counterName != null && isSub) ...[
          pw.SizedBox(width: 10),
          pw.Text('-> ${move.counterName} (${move.counterSide ?? ''})', style: const pw.TextStyle(fontSize: 9, color: PdfColors.orange800)),
        ]
      ],
    );
  }
}
