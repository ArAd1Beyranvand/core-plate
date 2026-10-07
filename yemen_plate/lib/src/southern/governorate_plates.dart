import 'package:plate_core/plate_core.dart';
import 'package:flutter/widgets.dart';

import '../common/yemen_alphabets.dart';
import '../common/yemen_country.dart';

/// Where the ink sits on the Hadhramaut / Al Mahrah / Shabwah / Marib plates,
/// in the artwork's own pixels with the frame's outer edge at 0. The article
/// gives no size in mm, so the artwork is the coordinate space: car 508 × 276,
/// motorcycle 271 × 276.
///
/// Measured off the Wikipedia artwork (`Yemen_-_<Gov>_-_License_Plate_-_*.png`,
/// 520 × 288 and 289 × 288 with the frame at x 3 or 9, y 5):
///
///   strip divider      x 124 .. 129, full height          (temporary: 379 .. 384)
///   row divider        y 109 .. 114, from strip to frame  (motorcycle: full width)
///   strip letter H     x  32 ..  95   y  62 .. 202        (M 19 .. 97, W 14 .. 111)
///   name حضرموت        x 199 .. 423   y  35 ..  85        (others y 24 .. 89)
///   serial, 4 digits   x 192 .. 408   y 140 .. 242
///   serial, 5 digits   x 167 .. 462   y 140 .. 242
///   police HP / 123    x 151 .. 290 / 319 .. 472   y 139 .. 240
///   police stacked name x 41 .. 91    y  25 .. 249
///   temporary مؤقت      x 412 .. 466   y  35 .. 240
///
/// What the engine cannot reproduce, and why:
/// - The digits are a condensed serif, 102 tall and ~46 wide. A slot's ink is
///   about 0.525 of its box, and the box may not leave the canvas, so the
///   tallest centred box is 170 (ink ~89, 87%). Five digits and the
///   motorcycle's four are narrower than a bold sans digit at that size, so
///   the slots shrink them to fit their pitch.
/// - The strip letter is 140 tall in a face half as wide as a bold sans. A
///   label does not shrink to its box, so the letter is sized to fit the
///   118-wide strip instead: ~65% of the reference height for H.
/// - Police "HP 123" is five characters across 321 units; at the reference
///   height a bold sans needs 470, so the row is ~66% of reference height.
abstract final class _Layout {
  static const double carWidth = 508;
  static const double motoWidth = 271;
  static const double height = 276;

  static const double divider = 5;
  static const double stripEnd = 126.5;
  static const double tempStripEnd = 381.5;
  static const double rowEnd = 111.5;

  /// Strip letter: ink centre (63, 132).
  static const double letterCx = 63;
  static const double letterCy = 132;

  /// Name: ink centre y 58 on every governorate; x 306 on the car, 138 on the
  /// motorcycle, 195 left of the temporary strip.
  static const double nameCy = 58;
  static const double nameGlyph = 78;

  /// Serial: ink centre y 191. The box is the tallest centred one that stays
  /// on the canvas.
  static const double serialCy = 191;
  static const double serialHeight = 170;
  static const double serialTop = serialCy - serialHeight / 2;

  /// Usable serial run right of the strip, between divider and frame.
  static const double serialLeft = 136;
  static const double serialRight = 496;

  /// A bold sans digit's advance at [serialHeight]: 0.696 em × 0.72 × 170.
  static const double digitPitch = 85;
}

/// A southern governorate's lettering. Not an enum: a consumer can add a
/// governorate that starts issuing this format.
@immutable
class YemenSouthernGovernorate {
  const YemenSouthernGovernorate({
    required this.id,
    required this.name,
    required this.letter,
    required this.letterGlyph,
    this.banded = false,
    this.policePrefix,
  });

  /// Spec id fragment, e.g. `hadhramaut`.
  final String id;

  /// The Arabic name across the top row, e.g. حضرموت.
  final String name;

  /// The Latin letter on the strip: H, M or W.
  final String letter;

  /// Glyph height that fits [letter] in the strip — W is wider than H.
  final double letterGlyph;

  /// Marib prints its name on a band in the strip colour, not on white.
  final bool banded;

  /// The letters before a police serial, e.g. HP. Null where no police plate
  /// is published.
  final String? policePrefix;

  static const YemenSouthernGovernorate hadhramaut = YemenSouthernGovernorate(
    id: 'hadhramaut',
    name: 'حضرموت',
    letter: 'H',
    letterGlyph: 165,
    policePrefix: 'HP',
  );

  static const YemenSouthernGovernorate alMahrah = YemenSouthernGovernorate(
    id: 'mahrah',
    name: 'المهرة',
    letter: 'M',
    letterGlyph: 140,
  );

  static const YemenSouthernGovernorate shabwah = YemenSouthernGovernorate(
    id: 'shabwah',
    name: 'شبوة',
    letter: 'W',
    letterGlyph: 120,
    policePrefix: 'WP',
  );

  /// Marib also prints M — the same letter as Al Mahrah.
  static const YemenSouthernGovernorate marib = YemenSouthernGovernorate(
    id: 'marib',
    name: 'مأرب',
    letter: 'M',
    letterGlyph: 140,
    banded: true,
  );
}

/// The plates Hadhramaut (2019), Al Mahrah, Shabwah (2020) and Marib (2019)
/// issue in place of the 1993 format: black on white, a coloured strip down
/// the left with the governorate's letter, the Arabic name over a 3–5 digit
/// serial.
///
/// The strip colour is the usage and rides on the country block
/// (`YemenCountry.southernFor`); the theme is always `YemenThemes.southern`.
/// So one spec per governorate and digit count serves private, hire,
/// commercial and government alike.
abstract final class YemenGovernoratePlates {
  // ---------------------------------------------------------------------------
  // Backgrounds. Every strip and divider runs to the frame.
  // ---------------------------------------------------------------------------

  static PlateSection _top(bool banded) =>
      banded ? const PlateSection.fill(PlateFill.panel) : PlateSection.plain;

  /// Strip | (name / serial). Marib's name row is in the strip colour.
  static PlateSection _carBackground(bool banded) =>
      PlateSection.columns(<PlatePart>[
        const PlatePart(
          PlateSection.fill(PlateFill.panel),
          end: _Layout.stripEnd,
          divider: _Layout.divider,
        ),
        PlatePart(
          PlateSection.rows(<PlatePart>[
            PlatePart(
              _top(banded),
              end: _Layout.rowEnd,
              divider: _Layout.divider,
            ),
            const PlatePart(PlateSection.plain),
          ]),
        ),
      ]);

  /// (name / serial) | blue مؤقت strip.
  static const PlateSection _temporaryBackground = PlateSection.columns(
    <PlatePart>[
      PlatePart(
        PlateSection.rows(<PlatePart>[
          PlatePart(
            PlateSection.plain,
            end: _Layout.rowEnd,
            divider: _Layout.divider,
          ),
          PlatePart(PlateSection.plain),
        ]),
        end: _Layout.tempStripEnd,
        divider: _Layout.divider,
      ),
      PlatePart(PlateSection.fill(PlateFill.panel)),
    ],
  );

  /// White name column | (blue الشرطة band / serial).
  static const PlateSection _policeBackground = PlateSection.columns(
    <PlatePart>[
      PlatePart(
        PlateSection.plain,
        end: _Layout.stripEnd,
        divider: _Layout.divider,
      ),
      PlatePart(
        PlateSection.rows(<PlatePart>[
          PlatePart(
            PlateSection.fill(PlateFill.panel),
            end: _Layout.rowEnd,
            divider: _Layout.divider,
          ),
          PlatePart(PlateSection.plain),
        ]),
      ),
    ],
  );

  /// name / serial, divider full width. Marib's name row is in the band colour.
  static PlateSection _motoBackground(bool banded) =>
      PlateSection.rows(<PlatePart>[
        PlatePart(_top(banded), end: _Layout.rowEnd, divider: _Layout.divider),
        const PlatePart(PlateSection.plain),
      ]);

  // ---------------------------------------------------------------------------
  // Pieces.
  // ---------------------------------------------------------------------------

  /// A label whose ink is centred on ([cx], [cy]). The box is generous; a
  /// label is positioned by its box's centre and is free to overflow it.
  static PlateLabel _centred(
    String text,
    double cx,
    double cy,
    double glyph, {
    double width = 240,
    double height = 90,
    double? lineHeight,
  }) => PlateLabel(
    text: text,
    box: PlateBox(cx - width / 2, cy - height / 2, width, height),
    glyphHeight: glyph,
    lineHeight: lineHeight,
  );

  /// [count] digit cells of [pitch], centred on [cx].
  static List<PlateSlot> _serial(int count, double cx, double pitch) =>
      plateRegister(
        alphabet: YemenAlphabets.digits,
        count: count,
        left: cx - count * pitch / 2,
        top: _Layout.serialTop,
        width: pitch,
        height: _Layout.serialHeight,
      );

  /// The pitch for [count] digits across [span]: a full bold digit when it
  /// fits, otherwise an even share and the slot shrinks the glyph.
  static double _pitch(int count, double span) =>
      span / count < _Layout.digitPitch ? span / count : _Layout.digitPitch;

  static List<PlateTextGroup> _groups(int count) => <PlateTextGroup>[
    PlateTextGroup(List<int>.generate(count, (i) => i), key: 'serial'),
  ];

  /// Upright letters, one per line, for a word stacked down a strip.
  static String _stacked(String word) => word.split('').join('\n');

  static const PlatePanel _noPanel = PlatePanel(box: PlateBox(0, 0, 1, 1));

  // ---------------------------------------------------------------------------
  // Builders.
  // ---------------------------------------------------------------------------

  /// The car plate: strip, name, [count]-digit serial. [count] is 4 on every
  /// published plate but Hadhramaut's private, which shows 5.
  static PlateSpec car(YemenSouthernGovernorate g, {int count = 4}) {
    const span = _Layout.serialRight - _Layout.serialLeft;
    const cx = (_Layout.serialLeft + _Layout.serialRight) / 2;
    return PlateSpec(
      id: 'ye.${g.id}.car.s$count',
      country: YemenCountry.southernPrivate,
      canvasWidth: _Layout.carWidth,
      canvasHeight: _Layout.height,
      panel: _noPanel,
      noPanel: true,
      background: _carBackground(g.banded),
      labels: <PlateLabel>[
        _centred(
          g.letter,
          _Layout.letterCx,
          _Layout.letterCy,
          g.letterGlyph,
          width: 110,
          height: 140,
        ),
        _centred(g.name, 306, _Layout.nameCy, _Layout.nameGlyph),
      ],
      slots: _serial(count, cx, _pitch(count, span)),
      textGroups: _groups(count),
    );
  }

  /// The temporary plate: no letter strip; a blue strip on the right reading
  /// مؤقت top to bottom. Hadhramaut and Shabwah publish one.
  static PlateSpec temporary(YemenSouthernGovernorate g, {int count = 4}) {
    const left = 12.0, right = _Layout.tempStripEnd - 8;
    const cx = (left + right) / 2;
    return PlateSpec(
      id: 'ye.${g.id}.temporary.s$count',
      country: YemenCountry.southernTemporary,
      canvasWidth: _Layout.carWidth,
      canvasHeight: _Layout.height,
      panel: _noPanel,
      noPanel: true,
      background: _temporaryBackground,
      labels: <PlateLabel>[
        _centred(g.name, 195, _Layout.nameCy, _Layout.nameGlyph),
        // Ink x 412 .. 466, y 35 .. 240: four letters, ~51 a line.
        _centred(
          _stacked('مؤقت'),
          441,
          137.5,
          62,
          width: 110,
          height: 220,
          lineHeight: 1.1,
        ),
      ],
      slots: _serial(count, cx, _pitch(count, right - left)),
      textGroups: _groups(count),
    );
  }

  /// The police plate: the name stacked down a white left column, الشرطة on a
  /// blue band, and [YemenSouthernGovernorate.policePrefix] before a three-digit serial.
  /// Hadhramaut (HP) and Shabwah (WP) publish one.
  static PlateSpec police(YemenSouthernGovernorate g, {int count = 3}) {
    assert(g.policePrefix != null, '${g.id} publishes no police plate');
    // Prefix ink x 151 .. 290, digits 319 .. 472, y 139 .. 240. Scaled to
    // 66%: a bold sans "HP" at this height is ~144 wide, a digit ~64.
    const height = 128.0, pitch = 64.0;
    return PlateSpec(
      id: 'ye.${g.id}.police.s$count',
      country: YemenCountry.southernPolice,
      canvasWidth: _Layout.carWidth,
      canvasHeight: _Layout.height,
      panel: _noPanel,
      noPanel: true,
      background: _policeBackground,
      labels: <PlateLabel>[
        // Ink x 41 .. 91, y 25 .. 249 for six letters; four for شبوة.
        _centred(
          _stacked(g.name),
          66,
          137,
          g.name.length > 4 ? 44 : 58,
          width: 110,
          height: 240,
          lineHeight: 0.95,
        ),
        _centred('الشرطة', 330.5, 60, _Layout.nameGlyph),
        _centred(
          g.policePrefix ?? '',
          212,
          _Layout.serialCy,
          height,
          width: 160,
          height: height,
        ),
      ],
      slots: plateRegister(
        alphabet: YemenAlphabets.digits,
        count: count,
        left: 300,
        top: _Layout.serialCy - height / 2,
        width: pitch,
        height: height,
      ),
      textGroups: _groups(count),
    );
  }

  /// The motorcycle plate: name over serial, no strip. Marib's name band is
  /// yellow; the others are white.
  static PlateSpec motorcycle(YemenSouthernGovernorate g, {int count = 4}) {
    const left = 14.0, right = _Layout.motoWidth - 14;
    const cx = _Layout.motoWidth / 2;
    return PlateSpec(
      id: 'ye.${g.id}.moto.s$count',
      country: g.banded
          ? YemenCountry.southernForHire
          : YemenCountry.southernPrivate,
      canvasWidth: _Layout.motoWidth,
      canvasHeight: _Layout.height,
      panel: _noPanel,
      noPanel: true,
      background: _motoBackground(g.banded),
      labels: <PlateLabel>[_centred(g.name, cx, _Layout.nameCy, 78)],
      slots: _serial(count, cx, _pitch(count, right - left)),
      textGroups: _groups(count),
    );
  }

  // ---------------------------------------------------------------------------
  // The published plates, one per article row that differs in layout.
  // Usage rows that differ only in strip colour share a spec.
  // ---------------------------------------------------------------------------

  static final PlateSpec hadhramaut = car(YemenSouthernGovernorate.hadhramaut);
  static final PlateSpec hadhramautFiveDigit = car(
    YemenSouthernGovernorate.hadhramaut,
    count: 5,
  );
  static final PlateSpec hadhramautTemporary = temporary(
    YemenSouthernGovernorate.hadhramaut,
  );
  static final PlateSpec hadhramautPolice = police(
    YemenSouthernGovernorate.hadhramaut,
  );
  static final PlateSpec hadhramautMotorcycle = motorcycle(
    YemenSouthernGovernorate.hadhramaut,
  );

  static final PlateSpec alMahrah = car(YemenSouthernGovernorate.alMahrah);
  static final PlateSpec alMahrahMotorcycle = motorcycle(
    YemenSouthernGovernorate.alMahrah,
  );

  static final PlateSpec shabwah = car(YemenSouthernGovernorate.shabwah);
  static final PlateSpec shabwahTemporary = temporary(
    YemenSouthernGovernorate.shabwah,
  );
  static final PlateSpec shabwahPolice = police(
    YemenSouthernGovernorate.shabwah,
  );

  /// Shabwah's motorcycle artwork shows three digits.
  static final PlateSpec shabwahMotorcycle = motorcycle(
    YemenSouthernGovernorate.shabwah,
    count: 3,
  );

  static final PlateSpec marib = car(YemenSouthernGovernorate.marib);
  static final PlateSpec maribMotorcycle = motorcycle(
    YemenSouthernGovernorate.marib,
  );
}
