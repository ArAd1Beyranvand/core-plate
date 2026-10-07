import 'package:plate_alphabet/plate_alphabet.dart';
import 'package:plate_core/plate_core.dart';

import 'package:flutter/widgets.dart';

import 'riyadh_colors.dart';
import 'riyadh_country.dart';

/// A row of cells: the centre of the first and the step to the next (negative
/// for the Arabic letters, which read right to left), and the row's top and
/// height. [glyph] is the printed size for an echo row, which is free of its
/// box; a slot's glyph is its box height.
class _Row {
  const _Row(this.cx, this.pitch, this.top, this.height, [double? glyph])
    : glyph = glyph ?? height;

  final double cx, pitch, top, height, glyph;
  double get left => cx - pitch.abs() / 2;
  double get width => pitch.abs();
}

/// The strip's wording and symbol, as boxes and glyph sizes.
class _Strip {
  const _Strip({
    required this.name,
    required this.nameGlyph,
    required this.ksaText,
    required this.ksa,
    required this.ksaGlyph,
    required this.ksaLineHeight,
    required this.symbol,
    required this.symbolGlyph,
    required this.emblem,
    required this.hologram,
  });

  final String ksaText;
  final PlateBox name, ksa, symbol, emblem, hologram;
  final double nameGlyph, ksaGlyph, ksaLineHeight, symbolGlyph;
}

class _Design {
  const _Design({
    required this.width,
    required this.height,
    required this.digitsAr,
    required this.digitsEn,
    required this.lettersAr,
    required this.lettersEn,
    required this.strip,
  });

  final double width, height;
  final _Row digitsAr, digitsEn, lettersAr, lettersEn;
  final _Strip strip;
}

/// Where the ink sits, in plate coordinates. Measured off the Wikipedia
/// artwork, flattened to 520×110 and rescaled to the documented size: x by
/// 335/520 and y by 155/110 for the US-size plate, x by 550/520 for the
/// EU-size one. The US artwork is drawn at 1.84 against the documented 2.16, so
/// its two axes stretch differently.
///
/// Two rows over three columns. The value is typed into the Latin row (the
/// slots) and the Arabic row above echoes it ([PlateMirror]s, editable, so
/// typing in either writes the other). The Arabic row is the echo because an
/// echo's glyph is free of its box: the Arabic ink is taller than any box that
/// fits between the plate's top edge and the row's centre.
///
/// Measured ink in the 520×110 flats (private plates), which the goldens are
/// checked against:
///
/// US size: digits ٧٦٥٣ x 31.5..236 y 10.8..41.5 (cx 53.8 + 52.9n); `7653`
/// y 67.2..98.5 (cx 47.9 + 55.4n); letters Arabic y 16..37.8 (cx 415.9 − 56.8n,
/// n = letter index), Latin y 65.8..97.2 (cx 298.4 + 57.1n). Rules at x 265.5
/// and 452.5 (2.6 thick), y 56.2 (1.5 thick). Strip: السعودية y 31.2..37.2,
/// `K S A` y 40.2..80.5 x 470.8..497.8, symbol y ~88..100.
///
/// EU size: Arabic digits y 9..47.5 (cx 47.8 + 44.1n), Latin y 65.2..97.8
/// (cx 46.8 + 47.2n); letters Arabic y 12..43.5 (cx 465.8 − 49n), Latin
/// y 65.2..97.8 (cx 366.5 + 51n). Rules at x 236 and 314.5, y 56.3. Strip:
/// السعودية y 32..44, `KSA` (one line, unlike the US size's stack) y 59..73.5 x 254.5..296.5, symbol y 82..97.
///
/// Glyph sizes are fitted by rendering and measuring the goldens against these
/// numbers. The Latin slots are capped by the plate's bottom edge, so their
/// ink is ~90% of the reference (US) and ~86% (EU). The emblem is the
/// Wikimedia `Emblem_of_Saudi_Arabia.svg` recoloured to one ink, drawn as the
/// country's flag in [PlatePanel] [_Strip.emblem]; the hologram is a grey
/// band, since the artwork censors it.
abstract final class _Layout {
  static const _Design us = _Design(
    width: 335,
    height: 155,
    digitsAr: _Row(34.65, 34.1, 0, 69.1, 82),
    digitsEn: _Row(30.9, 35.7, 81.8, 73),
    lettersAr: _Row(267.9, -36.55, 9.4, 56, 46),
    lettersEn: _Row(192.2, 36.8, 83, 64),
    strip: _Strip(
      emblem: PlateBox(300, 7, 24, 36.5),
      name: PlateBox(295, 41, 34, 12),
      nameGlyph: 9,
      ksaText: 'K\nS\nA',
      ksa: PlateBox(297, 52.5, 30, 62),
      ksaGlyph: 29,
      ksaLineHeight: 0.98,
      hologram: PlateBox(297, 116, 32, 8),
      symbol: PlateBox(297, 125, 30, 18),
      symbolGlyph: 24,
    ),
  );

  static const _Design eu = _Design(
    width: 550,
    height: 110,
    digitsAr: _Row(50.6, 46.7, 0, 46.7, 74),
    digitsEn: _Row(49.5, 49.9, 56, 54),
    lettersAr: _Row(492.7, -51.9, 0, 49, 48),
    lettersEn: _Row(387.6, 54, 56, 54),
    strip: _Strip(
      emblem: PlateBox(275, 12.5, 28, 30.5),
      name: PlateBox(271, 44, 40, 12),
      nameGlyph: 14,
      ksaText: 'KSA',
      ksa: PlateBox(262, 55.3, 58, 22),
      ksaGlyph: 27,
      ksaLineHeight: 1,
      hologram: PlateBox(262.8, 85, 27.8, 10),
      symbol: PlateBox(292.8, 78.9, 30, 21),
      symbolGlyph: 29,
    ),
  );

  /// Rules, in plate coordinates. `rowEnd` is the horizontal rule between the
  /// rows; the verticals are the column edges, thickness `colRule`.
  static const double rowEnd = 79.2, rowRule = 2.1;
  static const double euRowEnd = 56.3, euRowRule = 2.5;
  static const double colRule = 2.6;
  static const double usDigitsEnd = 171, usStripStart = 291.5;
  static const double euDigitsEnd = 249.6, euStripEnd = 332.7;
}

/// The mark under the strip that tells the category apart.
enum _Symbol {
  circle('●'),
  triangleUp('▲'),
  triangleDown('▼'),
  triangleLeft('◀'),
  none('');

  const _Symbol(this.glyph);
  final String glyph;
}

/// The Riyadh plates: three letters and up to four digits, in the
/// US size ([private] ...) or the EU size ([euPrivate] ...), one per category.
/// The category is the strip: its colour is the country's panel colour
/// (`RiyadhCountry.byCategory`) and its symbol is a label here, so pair
/// each spec with the matching country at the canvas. Groups `letters`,
/// `serial`; values are stored in Latin (`T N J 7 6 5 3`).
///
/// Not implemented: the pre-2006 and pre-2014 plates (the latter carries a
/// flag, not the strip), and the car-type symbol's exact artwork — it is the
/// Unicode glyph. The article names no Israel-specific value.
abstract final class RiyadhPlates {
  static final PlateSpec private = _build(
    'ye.riyadh.us.private',
    _Layout.us,
    _Symbol.circle,
  );
  static final PlateSpec publicTransport = _build(
    'ye.riyadh.us.public_transport',
    _Layout.us,
    _Symbol.triangleUp,
  );
  static final PlateSpec commercial = _build(
    'ye.riyadh.us.commercial',
    _Layout.us,
    _Symbol.triangleDown,
  );
  static final PlateSpec temporary = _build(
    'ye.riyadh.us.temporary',
    _Layout.us,
    _Symbol.triangleLeft,
  );
  static final PlateSpec diplomatic = _build(
    'ye.riyadh.us.diplomatic',
    _Layout.us,
    _Symbol.none,
  );

  static final PlateSpec euPrivate = _build(
    'ye.riyadh.eu.private',
    _Layout.eu,
    _Symbol.circle,
  );
  static final PlateSpec euPublicTransport = _build(
    'ye.riyadh.eu.public_transport',
    _Layout.eu,
    _Symbol.triangleUp,
  );
  static final PlateSpec euCommercial = _build(
    'ye.riyadh.eu.commercial',
    _Layout.eu,
    _Symbol.triangleDown,
  );
  static final PlateSpec euTemporary = _build(
    'ye.riyadh.eu.temporary',
    _Layout.eu,
    _Symbol.triangleLeft,
  );
  static final PlateSpec euDiplomatic = _build(
    'ye.riyadh.eu.diplomatic',
    _Layout.eu,
    _Symbol.none,
  );

  static List<PlateSpec> get all => <PlateSpec>[
    private, publicTransport, commercial, temporary, diplomatic, //
    euPrivate, euPublicTransport, euCommercial, euTemporary, euDiplomatic,
  ];

  /// Two stacked rows, split by the thin rule across the row's whole width.
  static PlateSection _rows(double end, double rule) =>
      PlateSection.rows(<PlatePart>[
        PlatePart(PlateSection.plain, end: end, divider: rule),
        const PlatePart(PlateSection.plain),
      ]);

  /// US: digits | letters | strip.
  static final PlateSection _usBackground = PlateSection.columns(<PlatePart>[
    PlatePart(
      _rows(_Layout.rowEnd, _Layout.rowRule),
      end: _Layout.usDigitsEnd,
      divider: _Layout.colRule,
    ),
    PlatePart(
      _rows(_Layout.rowEnd, _Layout.rowRule),
      end: _Layout.usStripStart,
      divider: _Layout.colRule,
    ),
    const PlatePart(PlateSection.fill(PlateFill.panel)),
  ]);

  /// EU: digits | strip | letters.
  static final PlateSection _euBackground = PlateSection.columns(<PlatePart>[
    PlatePart(
      _rows(_Layout.euRowEnd, _Layout.euRowRule),
      end: _Layout.euDigitsEnd,
      divider: _Layout.colRule,
    ),
    const PlatePart(
      PlateSection.fill(PlateFill.panel),
      end: _Layout.euStripEnd,
      divider: _Layout.colRule,
    ),
    PlatePart(_rows(_Layout.euRowEnd, _Layout.euRowRule)),
  ]);

  static PlateSpec _build(String id, _Design d, _Symbol symbol) {
    final bool us = identical(d, _Layout.us);
    final _Strip s = d.strip;
    List<PlateSlot> slots(PlateAlphabet a, _Row r, int n) => plateRegister(
      alphabet: a,
      count: n,
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      pitch: r.pitch,
    );
    List<PlateMirror> echo(PlateAlphabet a, _Row r, Iterable<int> sources) =>
        plateEcho(
          sources: sources,
          left: r.left,
          top: r.top,
          width: r.width,
          height: r.height,
          pitch: r.pitch,
          glyphHeight: r.glyph,
          alphabet: a,
          editable: true,
        );

    return PlateSpec(
      id: id,
      country: RiyadhCountry.private,
      canvasWidth: d.width,
      canvasHeight: d.height,
      panel: PlatePanel(box: s.emblem, padding: EdgeInsets.zero),
      background: us ? _usBackground : _euBackground,
      slots: <PlateSlot>[
        ...slots(RiyadhAlphabets.lettersLatin, d.lettersEn, 3),
        ...slots(RiyadhAlphabets.digits, d.digitsEn, 4),
      ],
      mirrors: <PlateMirror>[
        ...echo(RiyadhAlphabets.lettersArabic, d.lettersAr, <int>[0, 1, 2]),
        ...echo(RiyadhAlphabets.arabicDigits, d.digitsAr, <int>[3, 4, 5, 6]),
      ],
      bands: <PlateBand>[
        PlateBand(box: s.hologram, color: RiyadhColors.hologram),
      ],
      labels: <PlateLabel>[
        PlateLabel(text: 'السعودية', box: s.name, glyphHeight: s.nameGlyph),
        PlateLabel(
          text: s.ksaText,
          box: s.ksa,
          glyphHeight: s.ksaGlyph,
          lineHeight: s.ksaLineHeight,
        ),
        if (symbol != _Symbol.none)
          PlateLabel(
            text: symbol.glyph,
            box: s.symbol,
            glyphHeight: s.symbolGlyph,
          ),
      ],
      textGroups: const <PlateTextGroup>[
        PlateTextGroup(<int>[0, 1, 2], key: 'letters'),
        PlateTextGroup(<int>[3, 4, 5, 6], key: 'serial'),
      ],
    );
  }
}
