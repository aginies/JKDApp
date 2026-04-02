import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/series.dart';
import '../models/move.dart';
import 'localization_service.dart';

class PdfService {
  static Future<void> exportSeriesToPdf(JkdSeries series, String lang) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();

    // Load icons
    final jfgfIcon = await _loadIcon('assets/icon/jfgf.png');
    final jfkbIcon = await _loadIcon('assets/icon/jfkb.png');
    final kaliIcon = await _loadIcon('assets/icon/kali.png');
    final jkdIcon = await _loadIcon('assets/icon/JKD.png');

    pw.ImageProvider? categoryIcon;
    switch (series.category) {
      case 'Jun Fan Gung Fu':
        categoryIcon = jfgfIcon;
        break;
      case 'Jun Fan Kick Boxing':
        categoryIcon = jfkbIcon;
        break;
      case 'Kali':
        categoryIcon = kaliIcon;
        break;
      case 'JKD Moves':
        categoryIcon = jkdIcon;
        break;
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
            italic: italicFont,
          ),
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Jeet Kune Do',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Row(children: [
                    if (categoryIcon != null)
                      pw.Image(categoryIcon, width: 32, height: 32),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      series.category,
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              series.title,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red900,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${LocalizationService.translate('type', lang)}: ${series.type}',
              style: pw.TextStyle(fontSize: 12),
            ),
            if (series.attackMethod != null)
              pw.Text(
                '${LocalizationService.translate('method', lang)}: ${series.attackMethod}',
                style: pw.TextStyle(fontSize: 12),
              ),
            pw.SizedBox(height: 10),
            if (series.notes.isNotEmpty) ...[
              pw.Text(
                '${LocalizationService.translate('notes', lang)}:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                series.notes,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
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

  static Future<pw.MemoryImage> _loadIcon(String path) async {
    final data = await rootBundle.load(path);
    return pw.MemoryImage(data.buffer.asUint8List());
  }

  static pw.Widget _buildMoveWidget(Move move, int index, String lang) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Number circle
          pw.Container(
            width: 22,
            height: 22,
            decoration: const pw.BoxDecoration(
              color: PdfColors.redAccent,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                move.subLetter != null ? '$index${move.subLetter}' : '$index',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: move.subLetter != null ? 8 : 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildMoveContent(move, lang),
                if (move.counterName != null && !move.isCombo && !move.isChain)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: _buildCounterRow(move, lang),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMoveContent(Move move, String lang, {bool isSub = false}) {
    if (move.isCombo) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: move.subMoves.asMap().entries.map((e) {
          final subIdx = e.key;
          final sub = e.value;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (!isSub)
                  pw.Text('${subIdx + 1}. ', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSingleMoveLine(sub, lang),
                      if (sub.counterName != null)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2, left: 10),
                          child: _buildCounterRow(sub, lang),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    if (move.isChain) {
      return pw.Wrap(
        spacing: 10,
        runSpacing: 10,
        children: move.chain.asMap().entries.map((e) {
          final idx = e.key;
          final m = e.value;
          return pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSingleMoveLine(m, lang),
                  if (m.counterName != null)
                     pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 2, left: 10),
                        child: _buildCounterRow(m, lang),
                      ),
                ],
              ),
              if (idx < move.chain.length - 1)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                  child: pw.Text('->', style: pw.TextStyle(color: PdfColors.teal, fontWeight: pw.FontWeight.bold)),
                ),
            ],
          );
        }).toList(),
      );
    }

    return _buildSingleMoveLine(move, lang);
  }

  static pw.Widget _buildSingleMoveLine(Move move, String lang) {
    final side = move.side.isNotEmpty ? '(${move.side})' : '';
    final level = move.level.isNotEmpty
        ? LocalizationService.translate(move.level.toLowerCase(), lang)
        : '';
    final translation = move.translations[lang] ?? '';
    final reps = move.repetitions > 1 ? ' x${move.repetitions}' : '';

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          move.name,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
        ),
        if (translation.isNotEmpty)
          pw.Text(
            ' ($translation)',
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
          ),
        pw.SizedBox(width: 4),
        pw.Text(
          '$side $level$reps',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildCounterRow(Move move, String lang) {
    final counterSide = move.counterSide != null ? '(${move.counterSide})' : '';
    final counterLevel = move.counterLevel != null
        ? LocalizationService.translate(move.counterLevel!.toLowerCase(), lang)
        : '';
    final counterTranslation = move.counterTranslations[lang] ?? '';

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '-> ${LocalizationService.translate('answer', lang)}: ',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.orange900),
        ),
        pw.Text(
          move.counterName!,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.orange900),
        ),
        if (counterTranslation.isNotEmpty)
          pw.Text(
            ' ($counterTranslation)',
            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: PdfColors.orange700),
          ),
        pw.SizedBox(width: 4),
        pw.Text(
          '$counterSide $counterLevel',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.orange700),
        ),
      ],
    );
  }
}
