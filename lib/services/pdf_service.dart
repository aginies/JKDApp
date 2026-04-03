import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/series.dart';
import '../models/move.dart';
import 'localization_service.dart';
import 'logging_service.dart';

class PdfService {
  static Future<void> exportSeriesToPdf(
    JkdSeries series,
    String lang, {
    bool isGraphical = true,
  }) async {
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
    PdfColor headerColor = PdfColors.blue900;

    switch (series.category) {
      case 'Jun Fan Gung Fu':
        categoryIcon = jfgfIcon;
        headerColor = PdfColors.blue900;
        break;
      case 'Jun Fan Kick Boxing':
        categoryIcon = jfkbIcon;
        headerColor = PdfColors.purple900;
        break;
      case 'Kali':
        categoryIcon = kaliIcon;
        headerColor = PdfColors.brown900;
        break;
      case 'JKD Moves':
        categoryIcon = jkdIcon;
        headerColor = PdfColors.grey900;
        break;
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
            italic: italicFont,
          ),
        ),
        header: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'JKD Training Library',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateTime.now().toString().substring(0, 10),
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'JKDApp ${LoggingService.appVersion} ginies.org',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                if (categoryIcon != null)
                  pw.Image(categoryIcon, width: 40, height: 40),
                pw.SizedBox(width: 15),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        series.title,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: headerColor,
                        ),
                      ),
                      pw.Text(
                        '${series.category} - ${series.type}${series.attackMethod != null ? " ($series.attackMethod)" : ""}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey700,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            if (series.notes.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      LocalizationService.translate('notes', lang),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      series.notes,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
            ],

            if (isGraphical)
              ...series.moves.asMap().entries.map((entry) {
                final i = entry.key;
                final move = entry.value;
                return _buildGraphicalCard(move, i + 1, lang);
              })
            else
              ...series.moves.asMap().entries.map((entry) {
                final i = entry.key;
                final move = entry.value;
                return _buildListRow(move, i + 1, lang);
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

  // --- Graphical Layout Widgets ---

  static pw.Widget _buildGraphicalCard(Move move, int index, String lang) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Stack(
        children: [
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildCardHeader(move, lang),
              pw.SizedBox(height: 4),
              _buildMoveBody(move, lang),
              // Top-level counter (if any and not already handled by body)
              if (move.counterName != null &&
                  !move.isChain &&
                  !move.isCombo &&
                  !move.hasStructuredCounter) ...[
                pw.SizedBox(height: 6),
                _buildPdfCounterBox(move, lang),
              ],
              // Handle top-level structured counters
              if (move.hasStructuredCounter) ...[
                pw.SizedBox(height: 6),
                _buildPdfCounterBox(move, lang),
              ],
            ],
          ),
          pw.Positioned(
            top: -2,
            right: -2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: const pw.BoxDecoration(
                color: PdfColors.redAccent,
                shape: pw.BoxShape.circle,
              ),
              child: pw.Text(
                '${move.subLetter != null ? "$index${move.subLetter}" : index}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCardHeader(Move move, String lang) {
    String tag = '';
    if (move.category == 'chain' || move.isChain) tag = 'CHAIN';
    if (move.category == 'simultaneous') tag = 'SIMULTANEOUS';
    if (move.category == 'combo') tag = 'COMBO';

    if (tag.isEmpty) return pw.SizedBox.shrink();

    return pw.Text(
      tag,
      style: pw.TextStyle(
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey500,
      ),
    );
  }

  static pw.Widget _buildMoveBody(Move move, String lang) {
    if (move.category == 'chain' || move.isChain) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
        ),
        child: pw.Wrap(
          spacing: 4,
          runSpacing: 8,
          children: move.chain.asMap().entries.map((e) {
            final m = e.value;
            return pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
              ),
              padding: const pw.EdgeInsets.only(bottom: 2, right: 4),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  _buildMoveItemWithCounter(m, lang, mini: true),
                  if (e.key < move.chain.length - 1)
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                      child: pw.Text(
                        ' > ',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.teal,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    if (move.category == 'simultaneous') {
      return pw.Container(
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        child: pw.Wrap(
          spacing: 4,
          runSpacing: 8,
          children: move.subMoves.map((sm) {
            return pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                ),
              ),
              padding: const pw.EdgeInsets.only(bottom: 2, right: 4),
              child: _buildMoveItemWithCounter(sm, lang, mini: true),
            );
          }).toList(),
        ),
      );
    }

    if (move.category == 'combo') {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: move.subMoves.asMap().entries.map((e) {
          final idx = e.key;
          final sm = e.value;
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    '${idx + 1}.',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(child: _buildMoveItemWithCounter(sm, lang)),
              ],
            ),
          );
        }).toList(),
      );
    }

    return _buildLeafItem(move, lang);
  }

  static pw.Widget _buildMoveItemWithCounter(
    Move move,
    String lang, {
    bool mini = false,
  }) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildLeafItem(move, lang, mini: mini),
        if (move.counterName != null || move.hasStructuredCounter)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: _buildPdfCounterBox(move, lang, mini: true),
          ),
      ],
    );
  }

  static pw.Widget _buildLeafItem(Move move, String lang, {bool mini = false}) {
    final category = move.displayCategory;
    final color = _getCategoryPdfColor(category);
    final bgColor = _getCategoryPdfBgColor(category);

    return pw.Container(
      padding: pw.EdgeInsets.all(mini ? 3 : 4),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: color, width: 0.5),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            move.name,
            style: pw.TextStyle(
              fontSize: mini ? 9 : 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (move.side.isNotEmpty || move.level.isNotEmpty || move.isFeint)
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                if (move.side.isNotEmpty)
                  _pdfTag(
                    move.side,
                    move.side == 'L'
                        ? PdfColors.blue700
                        : (move.side == 'R'
                              ? PdfColors.red700
                              : PdfColors.green700),
                  ),
                if (move.level.isNotEmpty)
                  _pdfLevelTag(move.level, PdfColors.grey700),
                if (move.isFeint) _pdfTag('D', PdfColors.orange700),
              ],
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfCounterBox(
    Move move,
    String lang, {
    bool mini = false,
  }) {
    pw.Widget counterContent;

    if (move.hasCounterCombo) {
      counterContent = pw.Container(
        padding: const pw.EdgeInsets.all(2),
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Wrap(
          spacing: 2,
          runSpacing: 2,
          children: move.counterSubMoves
              .map((sm) => _buildLeafItem(sm, lang, mini: true))
              .toList(),
        ),
      );
    } else if (move.hasCounterChain) {
      counterContent = pw.Wrap(
        spacing: 2,
        runSpacing: 2,
        children: move.counterChain.asMap().entries.map((e) {
          final sm = e.value;
          return pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              _buildLeafItem(sm, lang, mini: true),
              if (e.key < move.counterChain.length - 1)
                pw.Text(
                  ' > ',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.teal),
                ),
            ],
          );
        }).toList(),
      );
    } else {
      counterContent = pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            move.counterName!,
            style: pw.TextStyle(
              fontSize: mini ? 8 : 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if ((move.counterSide ?? '').isNotEmpty ||
              (move.counterLevel ?? '').isNotEmpty)
            pw.Row(
              children: [
                if ((move.counterSide ?? '').isNotEmpty)
                  _pdfTag(
                    move.counterSide!,
                    move.counterSide == 'L'
                        ? PdfColors.blue700
                        : (move.counterSide == 'R'
                              ? PdfColors.red700
                              : PdfColors.green700),
                  ),
                if ((move.counterLevel ?? '').isNotEmpty)
                  _pdfLevelTag(move.counterLevel!, PdfColors.grey700),
              ],
            ),
        ],
      );
    }

    return pw.Container(
      padding: pw.EdgeInsets.all(mini ? 3 : 6),
      decoration: const pw.BoxDecoration(
        color: PdfColors.red50,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.fromBorderSide(
          pw.BorderSide(color: PdfColors.red100),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            LocalizationService.translate('answer', lang).toUpperCase(),
            style: pw.TextStyle(
              fontSize: mini ? 6 : 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red700,
            ),
          ),
          pw.SizedBox(height: mini ? 1 : 2),
          counterContent,
        ],
      ),
    );
  }

  // --- List Layout Widgets ---

  static pw.Widget _buildListRow(Move move, int index, String lang) {
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
                _buildListMoveContent(move, lang),
                if (move.counterName != null && !move.isCombo && !move.isChain)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: _buildListCounterRow(move, lang),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildListMoveContent(
    Move move,
    String lang, {
    bool isSub = false,
  }) {
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
                  pw.Text(
                    '${subIdx + 1}. ',
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildListSingleMoveLine(sub, lang),
                      if (sub.counterName != null)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2, left: 10),
                          child: _buildListCounterRow(sub, lang),
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
                  _buildListSingleMoveLine(m, lang),
                  if (m.counterName != null)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2, left: 10),
                      child: _buildListCounterRow(m, lang),
                    ),
                ],
              ),
              if (idx < move.chain.length - 1)
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                  child: pw.Text(
                    '->',
                    style: pw.TextStyle(
                      color: PdfColors.teal,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        }).toList(),
      );
    }

    return _buildListSingleMoveLine(move, lang);
  }

  static pw.Widget _buildListSingleMoveLine(Move move, String lang) {
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
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey700,
            ),
          ),
        pw.SizedBox(width: 4),
        pw.Text(
          '$side $level$reps',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    );
  }

  static pw.Widget _buildListCounterRow(Move move, String lang) {
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
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
            color: PdfColors.orange900,
          ),
        ),
        if (counterTranslation.isNotEmpty)
          pw.Text(
            ' ($counterTranslation)',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.orange700,
            ),
          ),
        pw.SizedBox(width: 4),
        pw.Text(
          '$counterSide $counterLevel',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.orange700),
        ),
      ],
    );
  }

  // --- Common Helpers ---

  static PdfColor _getCategoryPdfColor(String category) {
    switch (category) {
      case 'punch':
        return PdfColors.blue200;
      case 'kick':
        return PdfColors.red200;
      case 'packs':
        return PdfColors.green200;
      case 'trapping':
        return PdfColors.orange200;
      case 'move':
        return PdfColors.teal200;
      case 'jkd_moves':
        return PdfColors.blue200;
      case 'kali':
        return PdfColors.brown200;
      case 'text':
        return PdfColors.teal200;
      default:
        return PdfColors.grey200;
    }
  }

  static PdfColor _getCategoryPdfBgColor(String category) {
    switch (category) {
      case 'punch':
        return PdfColors.blue50;
      case 'kick':
        return PdfColors.red50;
      case 'packs':
        return PdfColors.green50;
      case 'trapping':
        return PdfColors.orange50;
      case 'move':
        return PdfColors.teal50;
      case 'jkd_moves':
        return PdfColors.blue50;
      case 'kali':
        return PdfColors.brown50;
      case 'text':
        return PdfColors.teal50;
      default:
        return PdfColors.grey50;
    }
  }

  static pw.Widget _pdfLevelTag(String level, PdfColor color) {
    String symbol = level.substring(0, 1);
    final lowLevel = level.toLowerCase();
    if (lowLevel == 'high') symbol = '^';
    if (lowLevel == 'mid') symbol = '>';
    if (lowLevel == 'low') symbol = 'v';

    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 2, top: 2),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        symbol,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _pdfTag(String text, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 2, top: 2),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }
}
