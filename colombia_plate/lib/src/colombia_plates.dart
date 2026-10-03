import 'dart:math';

import 'package:core_plate/core_plate.dart';
import 'package:flutter/foundation.dart';

import 'colombia_alphabets.dart';
import 'colombia_colors.dart';
import 'colombia_country.dart';

/// Where the ink sits on a Colombian plate, in millimetres.
///
/// The article gives no size. The canvas is 330×165: a 330 mm width at the
/// 2:1 the private artwork measures (its plate is 336×168 px). Every
/// reference's plate rectangle was mapped onto it.
///
/// * Private (artwork, `NAZ 827 ARMENIA`): serial ink y 37.3..120.8 (83.5
///   tall); letter centres 33.9, 82.0, 128.2, digit centres 199.4, 248.0,
///   296.6. That is six cells at pitch 47.6 with a 23.6 gap after the
///   split, the row centred. The ministry roundel sits in the gap, ink
///   x 155.2..170.9, y 70.7..86.4. Caption ink y 134.6..155.2, x 111..219.
///   Screw holes 6.9 across, centres x 69.2 / 262.7, y 17.2 / 150.8.
/// * Administrative staff (`AT 0282` photo): centres 35.4, 83.5 | 152.2,
///   200.4, 248.5, 295.6, roundel centre 118.8. The same pitch and gap with
///   the split after two cells, which is what fixes the gap model.
/// * Antique (`AID 899` photo): the same serial; full-height cyan strips to
///   x 86 and from x 244; `ANTIGUO` ink x ~111..220, y ~12.6..25.7.
/// * Police (`60-0007` photo): ink y 37.1..119.6, centres 32.5, 82.1 |
///   162.7, 206.1, 250.2, 295.9, a pitch of 45.7 and a gap of 36. Dash ink
///   x 113.1..136.3, y 76.3..84.6. `COLOMBIA` ink y 14.4..28.9, x ~124..205 by
///   eye; `POLICIA NACIONAL` ink x 69.7..249.4, y 134.1..150.6.
/// * Diplomatic corps (`A FR 000` photo, normalised by its field inside a
///   5 mm rim): band to y 38; `COLOMBIA` ink ~x 96..246, y ~11.6..32.4,
///   estimated by eye where the band's gradient defeated the mask. Serial
///   ink y 41..123.5; centres 34.3 | 99.9, 147.2 | 208.5, 253.6, 298.3.
///   Dashed rule at y ~125.5, ~1.2 thick, estimated by eye: sixteen dashes
///   from x 16 to 314.
///
/// **Under-height ink, accepted.** The plates are stamped in a condensed
/// face, a 40 mm wide glyph 83 mm tall. A slot scales its glyph down to fit
/// its cell, and DejaVu Bold is far wider than that, so the serial is
/// width-limited below the reference height (~49 of 83 mm). Captions are
/// sized to the measured ink *width* for the same reason, so they come out
/// shorter than the reference too. A narrow glyph (`I`, `1`) is not width-
/// limited and stands taller than its neighbours. `core_plate` is unchanged.
///
/// **Not drawn.** The ministry roundel's artwork (a fisheye `◉` stands in
/// for it), the antique plate's car graphic, the diplomatic plate's crest,
/// QR code, hologram and printed control number.
abstract final class _Layout {
  static const double width = 330;
  static const double height = 165;
  static const double centre = width / 2;

  // The shared `ABC·123` design.
  static const double pitch = 47.6;
  static const double gap = 23.6;
  static const double serialTop = 24;
  static const double serialHeight = 110;
  static const double roundelY = 78.5;
  static const double roundelGlyph = 28;
  static const PlateBox caption = PlateBox(15, 125, 300, 40);
  static const double captionGlyph = 29;

  /// The most caption characters that clear the lower screw holes (x 72.7
  /// to 259.3) at [captionGlyph]; `BOGOTA D.C.` just does. Longer captions
  /// shrink in proportion.
  static const int captionFit = 11;
  static const double holeSize = 6.9;
  static const List<double> holeX = <double>[69.2, 262.7];
  static const List<double> holeY = <double>[17.2, 150.8];

  // Antique.
  static const double stripLeftEnd = 86;
  static const double stripRightStart = 244;
  static const PlateBox heading = PlateBox(60, 4, 210, 30);
  static const double headingGlyph = 24;

  // Police.
  static const double policePitch = 45.7;
  static const double policeGap = 36;
  static const PlateBox policeDash = PlateBox(113.1, 76.3, 23.2, 8.2);
  static const PlateBox policeTop = PlateBox(92, 6, 150, 30);
  static const double policeTopGlyph = 19;
  static const PlateBox policeBottom = PlateBox(30, 127, 260, 30);
  static const double policeBottomGlyph = 23.5;

  // Diplomatic corps.
  static const double band = 38;
  static const PlateBox dipCaption = PlateBox(85, 2, 170, 40);
  static const double dipCaptionGlyph = 35;
  static const double dipCell = 44.9;
  static const double dipSerialTop = 27;
  static const double dipSerialHeight = 110;
  static const double dipTypeCentre = 34.3;
  static const double dipCountryLeft = 99.9 - 47.3 / 2;
  static const double dipCountryPitch = 47.3;
  static const double dipNumberLeft = 208.5 - 44.9 / 2;
  static const double dipNumberPitch = 44.9;
  static const double dashY = 124.9;
  static const double dashThickness = 1.2;
  static const double dashLeft = 16;
  static const double dashRight = 314;
  static const int dashCount = 16;
  static const double dashLength = 12;
}

/// The four screw holes of the shared design.
final List<PlateBand> _holes = <PlateBand>[
  for (final double x in _Layout.holeX)
    for (final double y in _Layout.holeY)
      PlateBand(
        box: PlateBox(
          x - _Layout.holeSize / 2,
          y - _Layout.holeSize / 2,
          _Layout.holeSize,
          _Layout.holeSize,
        ),
        color: ColombiaColors.hole,
        topCornerRadius: _Layout.holeSize / 2,
        bottomCornerRadius: _Layout.holeSize / 2,
      ),
];

/// One kind of `ABC·123` plate: which characters it carries, in which
/// order, and what is printed above and below. Every one is the same design;
/// the colours are the theme's (see `ColombiaThemes`).
@immutable
class ColombiaSeries {
  const ColombiaSeries({
    required this.id,
    required this.english,
    required this.spanish,
    this.letters = 3,
    this.digits = 3,
    this.digitsFirst = false,
    this.fixed = '',
    this.caption,
    this.antique = false,
  });

  final String id;
  final String english;
  final String spanish;

  /// Letters in the series, [fixed] included.
  final int letters;
  final int digits;

  /// `123·ABC`, the mototaxi order.
  final bool digitsFirst;

  /// The letters every plate of the series starts with: `O`, `CC`, `R`.
  final String fixed;

  /// The caption under the serial, or null for the municipality of issue.
  final String? caption;

  /// Cyan side strips and `ANTIGUO` across the top.
  final bool antique;

  static const ColombiaSeries private = ColombiaSeries(
    id: 'private',
    english: 'Private',
    spanish: 'Particular',
  );
  static const ColombiaSeries commercial = ColombiaSeries(
    id: 'commercial',
    english: 'Public service',
    spanish: 'Servicio público',
  );
  static const ColombiaSeries official = ColombiaSeries(
    id: 'official',
    english: 'Official',
    spanish: 'Oficial',
    fixed: 'O',
  );
  static const ColombiaSeries antiqueCar = ColombiaSeries(
    id: 'antique',
    english: 'Antique car',
    spanish: 'Auto antiguo',
    antique: true,
  );
  static const ColombiaSeries mototaxi = ColombiaSeries(
    id: 'mototaxi',
    english: 'Auto rickshaw',
    spanish: 'Mototaxi',
    digitsFirst: true,
  );
  static const ColombiaSeries trailer = ColombiaSeries(
    id: 'trailer',
    english: 'Trailer',
    spanish: 'Remolque',
    letters: 1,
    digits: 5,
    fixed: 'R',
  );
  static const ColombiaSeries tankTruck = ColombiaSeries(
    id: 'tank',
    english: 'Tank truck',
    spanish: 'Carrotanque',
    letters: 1,
    digits: 4,
    fixed: 'T',
  );
  static const ColombiaSeries consular = ColombiaSeries(
    id: 'cc',
    english: 'Consular corps',
    spanish: 'Cuerpo consular',
    letters: 2,
    digits: 4,
    fixed: 'CC',
    caption: 'COLOMBIA',
  );
  static const ColombiaSeries organization = ColombiaSeries(
    id: 'oi',
    english: 'International organization',
    spanish: 'Organización internacional',
    letters: 2,
    digits: 4,
    fixed: 'OI',
    caption: 'COLOMBIA',
  );
  static const ColombiaSeries staff = ColombiaSeries(
    id: 'at',
    english: 'Non-diplomatic staff',
    spanish: 'Servicio administrativo y técnico',
    letters: 2,
    digits: 4,
    fixed: 'AT',
    caption: 'COLOMBIA',
  );

  static const List<ColombiaSeries> values = <ColombiaSeries>[
    private,
    commercial,
    official,
    antiqueCar,
    mototaxi,
    trailer,
    tankTruck,
    consular,
    organization,
    staff,
  ];
}

/// No Colombian plate has a flag panel; every spec sets `noPanel`.
const PlatePanel _noPanel = PlatePanel(box: PlateBox(0, 0, 0, _Layout.height));

abstract final class ColombiaPlates {
  /// The `ABC·123` plate: the serial split by the ministry roundel, the
  /// municipality (or `COLOMBIA`) under it.
  ///
  /// Slots: the first group then the second, left to right; the letter
  /// group's leading cells hold the series' fixed letters.
  static PlateSpec standard({
    ColombiaSeries series = ColombiaSeries.private,
    String city = 'BOGOTA D.C.',
  }) {
    final String caption = series.caption ?? city;
    final int cells = series.letters + series.digits;
    final int split = series.digitsFirst ? series.digits : series.letters;
    final double left =
        _Layout.centre - (cells * _Layout.pitch + _Layout.gap) / 2;
    final double splitX = left + split * _Layout.pitch;
    final double secondLeft = splitX + _Layout.gap;
    final double secondRight = secondLeft + (cells - split) * _Layout.pitch;

    final List<PlateBox> boxes = <PlateBox>[
      for (final PlateSlot s in plateRegisterAcross(
        alphabet: ColombiaAlphabets.letters,
        count: split,
        left: left,
        right: splitX,
        top: _Layout.serialTop,
        height: _Layout.serialHeight,
      ))
        s.box,
      for (final PlateSlot s in plateRegisterAcross(
        alphabet: ColombiaAlphabets.letters,
        count: cells - split,
        left: secondLeft,
        right: secondRight,
        top: _Layout.serialTop,
        height: _Layout.serialHeight,
      ))
        s.box,
    ];
    final int firstLetter = series.digitsFirst ? series.digits : 0;
    PlateAlphabet alphabetAt(int i) {
      final int letter = i - firstLetter;
      if (letter < 0 || letter >= series.letters) {
        return ColombiaAlphabets.digits;
      }
      return letter < series.fixed.length
          ? ColombiaAlphabets.fixed(series.fixed[letter])
          : ColombiaAlphabets.letters;
    }

    final List<int> firstIdx = <int>[for (int i = 0; i < split; i++) i];
    final List<int> secondIdx = <int>[for (int i = split; i < cells; i++) i];

    return PlateSpec(
      id: 'co.${series.id}',
      country: ColombiaCountry.colombia,
      canvasWidth: _Layout.width,
      canvasHeight: _Layout.height,
      noPanel: true,
      panel: _noPanel,
      background: series.antique
          ? const PlateSection.columns(<PlatePart>[
              PlatePart(
                PlateSection.fill(PlateFill.divider),
                end: _Layout.stripLeftEnd,
              ),
              PlatePart(PlateSection.plain, end: _Layout.stripRightStart),
              PlatePart(PlateSection.fill(PlateFill.divider)),
            ])
          : PlateSection.plain,
      bands: _holes,
      labels: <PlateLabel>[
        PlateLabel(
          text: '◉',
          box: PlateBox(
            splitX,
            _Layout.roundelY - _Layout.gap / 2,
            _Layout.gap,
            _Layout.gap,
          ),
          glyphHeight: _Layout.roundelGlyph,
        ),
        PlateLabel(
          text: caption,
          box: _Layout.caption,
          glyphHeight:
              _Layout.captionGlyph *
              min(1, _Layout.captionFit / caption.length),
        ),
        if (series.antique)
          const PlateLabel(
            text: 'ANTIGUO',
            box: _Layout.heading,
            glyphHeight: _Layout.headingGlyph,
            color: ColombiaColors.antiqueBlue,
          ),
      ],
      slots: <PlateSlot>[
        for (final (int i, PlateBox box) in boxes.indexed)
          PlateSlot(alphabet: alphabetAt(i), box: box),
      ],
      textGroups: <PlateTextGroup>[
        PlateTextGroup(
          firstIdx,
          key: series.digitsFirst ? 'number' : 'letters',
        ),
        PlateTextGroup(
          secondIdx,
          prefix: ' ',
          key: series.digitsFirst ? 'letters' : 'number',
        ),
      ],
    );
  }

  /// The National Police plate, `60-0007`, between `COLOMBIA` and
  /// `POLICIA NACIONAL`. Slots: the two digits, then the four.
  static final PlateSpec police = () {
    final double left =
        _Layout.centre - (6 * _Layout.policePitch + _Layout.policeGap) / 2;
    final double split = left + 2 * _Layout.policePitch;
    return PlateSpec(
      id: 'co.police',
      country: ColombiaCountry.colombia,
      canvasWidth: _Layout.width,
      canvasHeight: _Layout.height,
      noPanel: true,
      panel: _noPanel,
      rules: const <PlateRule>[PlateRule(box: _Layout.policeDash)],
      labels: const <PlateLabel>[
        PlateLabel(
          text: 'COLOMBIA',
          box: _Layout.policeTop,
          glyphHeight: _Layout.policeTopGlyph,
        ),
        PlateLabel(
          text: 'POLICIA NACIONAL',
          box: _Layout.policeBottom,
          glyphHeight: _Layout.policeBottomGlyph,
        ),
      ],
      slots: <PlateSlot>[
        ...plateRegisterAcross(
          alphabet: ColombiaAlphabets.digits,
          count: 2,
          left: left,
          right: split,
          top: _Layout.serialTop,
          height: _Layout.serialHeight,
        ),
        ...plateRegisterAcross(
          alphabet: ColombiaAlphabets.digits,
          count: 4,
          left: split + _Layout.policeGap,
          right: split + _Layout.policeGap + 4 * _Layout.policePitch,
          top: _Layout.serialTop,
          height: _Layout.serialHeight,
        ),
      ],
      textGroups: const <PlateTextGroup>[
        PlateTextGroup(<int>[0, 1], key: 'unit'),
        PlateTextGroup(<int>[2, 3, 4, 5], prefix: '-', key: 'number'),
      ],
    );
  }();

  /// The diplomatic-corps plate, `A FR 000`, under the blue `COLOMBIA`
  /// band: the mission type, the country's initials and the number.
  /// Slots: the type, the two initials, the three digits.
  static final PlateSpec diplomatic = PlateSpec(
    id: 'co.cd',
    country: ColombiaCountry.colombia,
    canvasWidth: _Layout.width,
    canvasHeight: _Layout.height,
    noPanel: true,
    panel: _noPanel,
    background: const PlateSection.rows(<PlatePart>[
      PlatePart(
        PlateSection.fill(PlateFill.color(ColombiaColors.diplomaticBand)),
        end: _Layout.band,
      ),
      PlatePart(PlateSection.plain),
    ]),
    rules: <PlateRule>[
      for (int i = 0; i < _Layout.dashCount; i++)
        PlateRule(
          box: PlateBox(
            _Layout.dashLeft +
                i *
                    (_Layout.dashRight -
                        _Layout.dashLeft -
                        _Layout.dashLength) /
                    (_Layout.dashCount - 1),
            _Layout.dashY,
            _Layout.dashLength,
            _Layout.dashThickness,
          ),
        ),
    ],
    labels: const <PlateLabel>[
      PlateLabel(
        text: 'COLOMBIA',
        box: _Layout.dipCaption,
        glyphHeight: _Layout.dipCaptionGlyph,
        color: ColombiaColors.diplomaticNavy,
      ),
    ],
    slots: <PlateSlot>[
      ...plateRegister(
        alphabet: ColombiaAlphabets.letters,
        count: 1,
        left: _Layout.dipTypeCentre - _Layout.dipCell / 2,
        top: _Layout.dipSerialTop,
        width: _Layout.dipCell,
        height: _Layout.dipSerialHeight,
      ),
      ...plateRegister(
        alphabet: ColombiaAlphabets.letters,
        count: 2,
        left: _Layout.dipCountryLeft,
        top: _Layout.dipSerialTop,
        width: _Layout.dipCountryPitch,
        height: _Layout.dipSerialHeight,
      ),
      ...plateRegister(
        alphabet: ColombiaAlphabets.digits,
        count: 3,
        left: _Layout.dipNumberLeft,
        top: _Layout.dipSerialTop,
        width: _Layout.dipNumberPitch,
        height: _Layout.dipSerialHeight,
      ),
    ],
    textGroups: const <PlateTextGroup>[
      PlateTextGroup(<int>[0], key: 'type'),
      PlateTextGroup(<int>[1, 2], prefix: ' ', key: 'country'),
      PlateTextGroup(<int>[3, 4, 5], prefix: ' ', key: 'number'),
    ],
  );
}
