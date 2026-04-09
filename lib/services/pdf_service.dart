import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/series.dart';
import '../models/move.dart';
import 'localization_service.dart';
import 'logging_service.dart';

/// Controls whether the PDF uses graphical cards or a compact list.
enum PdfLayout { graphical, list }

class PdfService {
  // ---------------------------------------------------------------------------
  // Font / icon caching — futures are reused across export calls.
  // ---------------------------------------------------------------------------

  static Future<(pw.Font, pw.Font, pw.Font)>? _fontsFuture;
  static Future<List<pw.MemoryImage>>? _iconsFuture;

  static Future<(pw.Font, pw.Font, pw.Font)> _getFonts() {
    return _fontsFuture ??= Future.wait([
      PdfGoogleFonts.robotoRegular(),
      PdfGoogleFonts.robotoBold(),
      PdfGoogleFonts.robotoItalic(),
    ]).then((r) => (r[0], r[1], r[2]));
  }

  static Future<List<pw.MemoryImage>> _getIcons() {
    return _iconsFuture ??= Future.wait([
      _loadIcon('assets/icon/jfgf.png'),
      _loadIcon('assets/icon/jfkb.png'),
      _loadIcon('assets/icon/kali.png'),
      _loadIcon('assets/icon/JKD.png'),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static Future<void> exportSeriesToPdf(
    JkdSeries series,
    String lang, {
    PdfLayout layout = PdfLayout.graphical,
    bool showTranslations = true,
  }) async {
    final (font, boldFont, italicFont) = await _getFonts();
    final icons = await _getIcons();

    final (categoryIcon, headerColor) = switch (series.category) {
      'Jun Fan Gung Fu' => (icons[0] as pw.ImageProvider?, PdfColors.blue900),
      'Jun Fan Kick Boxing' => (
        icons[1] as pw.ImageProvider?,
        PdfColors.purple900,
      ),
      'Kali' => (icons[2] as pw.ImageProvider?, PdfColors.brown900),
      'Moves' => (icons[3] as pw.ImageProvider?, PdfColors.grey900),
      _ => (null, PdfColors.blue900),
    };

    final pdf = pw.Document();

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
        header: (_) => _buildPageHeader(),
        footer: (ctx) => _buildPageFooter(ctx),
        build: (ctx) => [
          pw.SizedBox(height: 10),
          ..._buildCoverSection(series, categoryIcon, headerColor, lang),
          if (layout == PdfLayout.graphical)
            ...series.moves.asMap().entries.map(
              (e) => _buildGraphicalCard(
                e.value,
                e.key + 1,
                lang,
                showTranslations,
              ),
            )
          else
            ...series.moves.asMap().entries.map(
              (e) => _buildListRow(e.value, e.key + 1, lang, showTranslations),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${series.title.replaceAll(' ', '_')}.pdf',
    );
  }

  // ---------------------------------------------------------------------------
  // Page chrome
  // ---------------------------------------------------------------------------

  static pw.Widget _buildPageHeader() {
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
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
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
  }

  static List<pw.Widget> _buildCoverSection(
    JkdSeries series,
    pw.ImageProvider? categoryIcon,
    PdfColor headerColor,
    String lang,
  ) {
    return [
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
                  '${series.category} - ${series.type}'
                  '${series.attackMethod != null ? " (${series.attackMethod})" : ""}',
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
              pw.Text(series.notes, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    ];
  }

  // ---------------------------------------------------------------------------
  // Graphical layout
  // ---------------------------------------------------------------------------

  static pw.Widget _buildGraphicalCard(
    Move move,
    int index,
    String lang,
    bool showTranslations,
  ) {
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
              _buildMoveBody(move, lang, showTranslations),
              // Show counter for any move that has one (simple or structured).
              // Chain/combo containers handle sub-item counters inside _buildMoveBody.
              if (move.hasCounter && !move.isChain && !move.isCombo) ...[
                pw.SizedBox(height: 6),
                _buildPdfCounterBox(move, lang, showTranslations),
              ],
              if (move.hasStructuredCounter &&
                  (move.isChain || move.isCombo)) ...[
                pw.SizedBox(height: 6),
                _buildPdfCounterBox(move, lang, showTranslations),
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
                move.subLetter != null ? '$index${move.subLetter}' : '$index',
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
    final tag = switch (move.category) {
      'chain' => 'CHAIN',
      'simultaneous' => 'SIMULTANEOUS',
      'combo' => 'COMBO',
      _ => move.isChain ? 'CHAIN' : '',
    };

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

  static pw.Widget _buildMoveBody(
    Move move,
    String lang,
    bool showTranslations,
  ) {
    if (move.isChain) {
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
                  _buildMoveItemWithCounter(
                    m,
                    lang,
                    showTranslations,
                    mini: true,
                  ),
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
              child: _buildMoveItemWithCounter(
                sm,
                lang,
                showTranslations,
                mini: true,
              ),
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
                pw.Expanded(
                  child: _buildMoveItemWithCounter(sm, lang, showTranslations),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return _buildLeafItem(move, lang, showTranslations);
  }

  static pw.Widget _buildMoveItemWithCounter(
    Move move,
    String lang,
    bool showTranslations, {
    bool mini = false,
  }) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildLeafItem(move, lang, showTranslations, mini: mini),
        if (move.hasCounter)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: _buildPdfCounterBox(
              move,
              lang,
              showTranslations,
              mini: true,
            ),
          ),
      ],
    );
  }

  static pw.Widget _buildLeafItem(
    Move move,
    String lang,
    bool showTranslations, {
    bool mini = false,
  }) {
    final category = move.displayCategory;
    final colors = _getCategoryPdfColors(category);
    final translation = showTranslations ? (move.translations[lang] ?? '') : '';

    return pw.Container(
      padding: pw.EdgeInsets.all(mini ? 3 : 4),
      decoration: pw.BoxDecoration(
        color: colors.bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: colors.border, width: 0.5),
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
          if (translation.isNotEmpty)
            pw.Text(
              translation,
              style: pw.TextStyle(
                fontSize: mini ? 7 : 9,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
          if (move.side.isNotEmpty || move.level.isNotEmpty || move.isFeint)
            pw.Row(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                if (move.side.isNotEmpty)
                  _pdfTag(move.side, switch (move.side) {
                    'L' => PdfColors.blue700,
                    'R' => PdfColors.red700,
                    _ => PdfColors.green700,
                  }),
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
    String lang,
    bool showTranslations, {
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
              .map(
                (sm) => _buildLeafItem(sm, lang, showTranslations, mini: true),
              )
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
              _buildLeafItem(sm, lang, showTranslations, mini: true),
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
      final counterTranslation = showTranslations
          ? (move.counterTranslations[lang] ?? '')
          : '';
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
          if (counterTranslation.isNotEmpty)
            pw.Text(
              counterTranslation,
              style: pw.TextStyle(
                fontSize: mini ? 6 : 8,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
          if ((move.counterSide ?? '').isNotEmpty ||
              (move.counterLevel ?? '').isNotEmpty)
            pw.Row(
              children: [
                if ((move.counterSide ?? '').isNotEmpty)
                  _pdfTag(move.counterSide!, switch (move.counterSide!) {
                    'L' => PdfColors.blue700,
                    'R' => PdfColors.red700,
                    _ => PdfColors.green700,
                  }),
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

  // ---------------------------------------------------------------------------
  // List layout
  // ---------------------------------------------------------------------------

  static pw.Widget _buildListRow(
    Move move,
    int index,
    String lang,
    bool showTranslations,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
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
                _buildListMoveContent(move, lang, showTranslations),
                if (move.hasCounter && !move.isCombo && !move.isChain)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: _buildListCounterRow(move, lang, showTranslations),
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
    String lang,
    bool showTranslations, {
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
                      _buildListSingleMoveLine(sub, lang, showTranslations),
                      if (sub.hasCounter)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 2, left: 10),
                          child: _buildListCounterRow(
                            sub,
                            lang,
                            showTranslations,
                          ),
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
                  _buildListSingleMoveLine(m, lang, showTranslations),
                  if (m.hasCounter)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2, left: 10),
                      child: _buildListCounterRow(m, lang, showTranslations),
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

    return _buildListSingleMoveLine(move, lang, showTranslations);
  }

  static pw.Widget _buildListSingleMoveLine(
    Move move,
    String lang,
    bool showTranslations,
  ) {
    final side = move.side.isNotEmpty ? '(${move.side})' : '';
    final level = move.level.isNotEmpty
        ? LocalizationService.translate(move.level.toLowerCase(), lang)
        : '';
    final translation = showTranslations ? (move.translations[lang] ?? '') : '';
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

  static pw.Widget _buildListCounterRow(
    Move move,
    String lang,
    bool showTranslations,
  ) {
    // Resolve display name for any counter type (simple, simultaneous, chain).
    final String displayName;
    if (move.hasCounterCombo) {
      displayName = move.counterSubMoves.map((m) => m.name).join(' + ');
    } else if (move.hasCounterChain) {
      displayName = move.counterChain.map((m) => m.name).join(' -> ');
    } else {
      displayName = move.counterName!;
    }

    // Side/level/translation only meaningful for simple counters.
    final counterSide =
        (!move.hasStructuredCounter && (move.counterSide ?? '').isNotEmpty)
        ? '(${move.counterSide})'
        : '';
    final counterLevel =
        (!move.hasStructuredCounter && (move.counterLevel ?? '').isNotEmpty)
        ? LocalizationService.translate(move.counterLevel!.toLowerCase(), lang)
        : '';
    final counterTranslation = (!move.hasStructuredCounter && showTranslations)
        ? (move.counterTranslations[lang] ?? '')
        : '';

    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '-> ${LocalizationService.translate('answer', lang)}: ',
          style: pw.TextStyle(fontSize: 10, color: PdfColors.orange900),
        ),
        pw.Text(
          displayName,
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

  // ---------------------------------------------------------------------------
  // Common helpers
  // ---------------------------------------------------------------------------

  static Future<pw.MemoryImage> _loadIcon(String path) async {
    final data = await rootBundle.load(path);
    return pw.MemoryImage(data.buffer.asUint8List());
  }

  /// Returns border and background PDF colors for a move category.
  static ({PdfColor border, PdfColor bg}) _getCategoryPdfColors(
    String category,
  ) {
    return switch (category) {
      'punch' => (border: PdfColors.blue200, bg: PdfColors.blue50),
      'kick' => (border: PdfColors.red200, bg: PdfColors.red50),
      'packs' => (border: PdfColors.green200, bg: PdfColors.green50),
      'trapping' => (border: PdfColors.orange200, bg: PdfColors.orange50),
      'move' || 'text' => (border: PdfColors.teal200, bg: PdfColors.teal50),
      'kali' => (border: PdfColors.brown200, bg: PdfColors.brown50),
      _ => (border: PdfColors.grey200, bg: PdfColors.grey50),
    };
  }

  static pw.Widget _pdfLevelTag(String level, PdfColor color) {
    final symbol = switch (level.toLowerCase()) {
      'high' => '^',
      'mid' => '>',
      'low' => 'v',
      _ => level.substring(0, 1),
    };
    return _pdfTag(symbol, color);
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
