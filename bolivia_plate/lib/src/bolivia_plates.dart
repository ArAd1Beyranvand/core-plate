import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'bolivia_alphabets.dart';
import 'bolivia_colors.dart';
import 'bolivia_country.dart';

/// Where the ink sits on a Bolivian plate, in millimetres.
///
/// Each reference's plate rectangle was found from its rim and mapped to the
/// article's 300×152 (PTA, diplomatic) or the Mercosur 400×130. The PTA photo
/// measures 2.06 against the documented 1.97 and the diplomatic one 1.84 (a
/// skewed photo), so x positions carry a few millimetres of perspective.
///
/// * PTA (`…2006_1852PHD_La_Paz.jpg`): `BOLIVIA` ink x 78.3..221.7,
///   y 18.1..39.6. Flag x 12.3..50.5, y 18.1..42.8, three equal stripes.
///   Department box x 248..289.7, y 14.4..45.3; its `L` ink x 256.8..278.7,
///   y 17.9..37.8. Serial ink y 54.5..134.1 (79.6 tall); centres 38.5, 77,
///   114.3, 150.7, 187.4, 224.8, 262 — pitch 37, the row centred on the
///   plate.
/// * Diplomatic (`KennzeichenBolivienCD.jpg`): `BOLIVIA` ink x 74.3..216.6,
///   y 19..38.9 — the PTA's, so it shares those constants. Serial ink
///   y 57.2..133.7; `57` centres 33.9, 76.9 and `07` 222.8, 266 (pitch 43);
///   `CD` ink x 110..185.7. Dots ~2.5 mm at x 101.2 and 197, y 97..100.
///   Flag x 248.3..282.5, y 16.2..39.6.
/// * Mercosur (artwork, 249×82 px): band y 0..34.5; `BOLIVIA` ink x
///   161.7..243.3, y 13.2..24.7; flag x 365..398.4, y 9.9..32.9, drawn at
///   361 so it clears the 2.5 mm frame. Serial ink
///   y 44.4..110.3; letter centres 44.2, 90.8 (pitch 46.6), digit centres
///   170.8..360 (pitch 47.3).
///
/// **Under-height ink, accepted.** The plates are stamped in a very condensed
/// face — a 32 mm wide digit 80 mm tall. A slot scales its glyph down to fit
/// its cell, and DejaVu Bold's digits are far wider than that, so the serial
/// is width-limited at about half the reference height. Labels are sized to
/// the measured ink *width* for the same reason. `core_plate` is unchanged.
///
/// **Not drawn.** The wiphala printed beside the diplomatic plate's
/// `BOLIVIA`, the
/// six-digit control number under the department letter, and the Mercosur
/// emblem.
abstract final class _Layout {
  static const double width = 300;
  static const double height = 152;
  static const double centre = width / 2;

  // Shared by the PTA and diplomatic plates.
  static const PlateBox caption = PlateBox(70, 14, 160, 30);
  static const double captionGlyph = 34;

  // PTA.
  /// The state flag, coat of arms and all, drawn by the country panel from
  /// `Flag_of_Bolivia_state.svg`. Measured x 12.3..50.5, y 18.1..42.8; the
  /// box keeps the SVG's 22:15 at the measured height, centred on the
  /// measured x, so the flag covers it and no panel colour shows.
  static const PlateBox flag = PlateBox(
    31.4 - 24.7 * 22 / 15 / 2,
    18.1,
    24.7 * 22 / 15,
    24.7,
  );
  static const PlateBox departmentBox = PlateBox(248, 14.4, 41.7, 30.9);

  /// Centred on the `L`'s ink (y 27.9); 19.9 mm of ink / 0.55.
  static const PlateBox department = PlateBox(248, 9.9, 41.7, 36);
  static const double pitch = 37;
  static const double serialTop = 39.3;
  static const double serialHeight = 110;

  // Diplomatic.
  static const double dipPitch = 43;
  static const double dipLeft = 33.9 - dipPitch / 2;
  static const double dipRight = 266 + dipPitch / 2;
  static const double dipSerialTop = 40.5;
  static const double dipSerialHeight = 110;

  /// The code's box, between the two digit pairs, centred on the `CD` ink
  /// (x 147.9, y 95.5).
  static const PlateBox dipCode = PlateBox(105, 65.5, 85.8, 60);
  static const double dipCodeGlyph = 70;
  static const double dotSize = 2.6;
  static const double dotY = 98.5 - dotSize / 2;
  static const List<double> dotX = <double>[101.2, 197];
  static const PlateBox dipFlag = PlateBox(248.3, 16.2, 34.2, 23.4);

  // Mercosur, 400×130.
  static const double mWidth = 400;
  static const double mHeight = 130;
  static const double mBand = 34.5;
  static const PlateBox mCaption = PlateBox(150, 6, 105, 26);
  static const double mCaptionGlyph = 24;
  static const PlateBox mFlag = PlateBox(361, 9.9, 33.3, 22.2);
  static const double mLetterPitch = 46.6;
  static const double mDigitPitch = 47.3;
  static const double mLettersLeft = 44.2 - mLetterPitch / 2;
  static const double mDigitsLeft = 170.8 - mDigitPitch / 2;
  static const double mSerialTop = 32.4;
  static const double mSerialHeight = 90;
}

/// The flag as three equal stripes floating in [box].
List<PlateBand> _flag(PlateBox box) {
  final double h = box.height / 3;
  return <PlateBand>[
    for (final (int i, Color c) in const <Color>[
      BoliviaColors.flagRed,
      BoliviaColors.flagYellow,
      BoliviaColors.flagGreen,
    ].indexed)
      PlateBand(
        box: PlateBox(box.left, box.top + i * h, box.width, h),
        color: c,
      ),
  ];
}

/// `BOLIVIA` letter-spaced as stamped: thin spaces between the capitals.
const String _bolivia = 'B\u2009O\u2009L\u2009I\u2009V\u2009I\u2009A';

/// The service a PTA plate's department box declares by its fill: white for
/// private, red for public service, yellow for government.
@immutable
class BoliviaService {
  const BoliviaService({required this.id, required this.fill, this.ink});

  final String id;
  final Color fill;

  /// The letter's ink, or null for the plate's blue.
  final Color? ink;

  /// Photographed: the box is the plate's own white.
  static const BoliviaService private = BoliviaService(
    id: 'priv',
    fill: BoliviaColors.white,
  );

  /// Not photographed: the flag's red, the letter in white to stay legible.
  static const BoliviaService public = BoliviaService(
    id: 'pub',
    fill: BoliviaColors.flagRed,
    ink: BoliviaColors.white,
  );

  /// Not photographed: the flag's yellow.
  static const BoliviaService government = BoliviaService(
    id: 'gov',
    fill: BoliviaColors.flagYellow,
  );

  static const List<BoliviaService> values = <BoliviaService>[
    private,
    public,
    government,
  ];
}

/// The status code between a special plate's two numbers. Every one is the
/// same design; the colours are the theme's (see `BoliviaThemes`).
@immutable
class BoliviaMission {
  const BoliviaMission({
    required this.id,
    required this.code,
    required this.english,
    required this.spanish,
  });

  final String id;
  final String code;
  final String english;
  final String spanish;

  static const BoliviaMission consular = BoliviaMission(
    id: 'cc',
    code: 'CC',
    english: 'Consular corps',
    spanish: 'Cuerpo consular',
  );
  static const BoliviaMission diplomatic = BoliviaMission(
    id: 'cd',
    code: 'CD',
    english: 'Diplomatic corps',
    spanish: 'Cuerpo diplomático',
  );
  static const BoliviaMission international = BoliviaMission(
    id: 'mi',
    code: 'MI',
    english: 'International mission',
    spanish: 'Misión internacional',
  );
  static const BoliviaMission organization = BoliviaMission(
    id: 'oi',
    code: 'OI',
    english: 'International organization',
    spanish: 'Organización internacional',
  );

  static const List<BoliviaMission> values = <BoliviaMission>[
    consular,
    diplomatic,
    international,
    organization,
  ];
}

abstract final class BoliviaPlates {
  /// The PTA plate, `1234ABC` under BOLIVIA, and the department letter. Older
  /// vehicles carry three digits; the row stays centred.
  ///
  /// Slots: the digits, the three letters, then the department.
  static PlateSpec standard({
    int digits = 4,
    BoliviaService service = BoliviaService.private,
  }) {
    assert(digits == 3 || digits == 4, 'A PTA number has 3 or 4 digits.');
    final int cells = digits + 3;
    final double left = _Layout.centre - cells * _Layout.pitch / 2;
    final double split = left + digits * _Layout.pitch;
    return PlateSpec(
      id: 'bo.pta$digits.${service.id}',
      country: BoliviaCountry.bolivia,
      canvasWidth: _Layout.width,
      canvasHeight: _Layout.height,
      panel: const PlatePanel(box: _Layout.flag, padding: EdgeInsets.zero),
      bands: <PlateBand>[
        PlateBand(box: _Layout.departmentBox, color: service.fill),
      ],
      labels: const <PlateLabel>[
        PlateLabel(
          text: _bolivia,
          box: _Layout.caption,
          glyphHeight: _Layout.captionGlyph,
        ),
      ],
      slots: <PlateSlot>[
        ...plateRegisterAcross(
          alphabet: BoliviaAlphabets.digits,
          count: digits,
          left: left,
          right: split,
          top: _Layout.serialTop,
          height: _Layout.serialHeight,
        ),
        ...plateRegisterAcross(
          alphabet: BoliviaAlphabets.letters,
          count: 3,
          left: split,
          right: split + 3 * _Layout.pitch,
          top: _Layout.serialTop,
          height: _Layout.serialHeight,
        ),
        PlateSlot(
          alphabet: BoliviaAlphabets.departments,
          box: _Layout.department,
          color: service.ink,
        ),
      ],
      textGroups: <PlateTextGroup>[
        PlateTextGroup(<int>[
          for (int i = 0; i < digits; i++) i,
        ], key: 'number'),
        PlateTextGroup(<int>[
          for (int i = digits; i < cells; i++) i,
        ], key: 'letters'),
        PlateTextGroup(<int>[cells], prefix: ' ', key: 'department'),
      ],
    );
  }

  /// The special plate, `12-CD-34`: the mission's country, its status code,
  /// and the vehicle's rank. Slots: the two pairs, left to right.
  static PlateSpec special([
    BoliviaMission mission = BoliviaMission.diplomatic,
  ]) => PlateSpec(
    id: 'bo.${mission.id}',
    country: BoliviaCountry.bolivia,
    canvasWidth: _Layout.width,
    canvasHeight: _Layout.height,
    noPanel: true,
    panel: const PlatePanel(box: _Layout.dipFlag),
    bands: _flag(_Layout.dipFlag),
    rules: <PlateRule>[
      for (final double x in _Layout.dotX)
        PlateRule(
          box: PlateBox(
            x - _Layout.dotSize / 2,
            _Layout.dotY,
            _Layout.dotSize,
            _Layout.dotSize,
          ),
        ),
    ],
    labels: <PlateLabel>[
      const PlateLabel(
        text: _bolivia,
        box: _Layout.caption,
        glyphHeight: _Layout.captionGlyph,
      ),
      PlateLabel(
        text: mission.code,
        box: _Layout.dipCode,
        glyphHeight: _Layout.dipCodeGlyph,
      ),
    ],
    slots: <PlateSlot>[
      ...plateRegisterAcross(
        alphabet: BoliviaAlphabets.digits,
        count: 2,
        left: _Layout.dipLeft,
        right: _Layout.dipLeft + 2 * _Layout.dipPitch,
        top: _Layout.dipSerialTop,
        height: _Layout.dipSerialHeight,
      ),
      ...plateRegisterAcross(
        alphabet: BoliviaAlphabets.digits,
        count: 2,
        left: _Layout.dipRight - 2 * _Layout.dipPitch,
        right: _Layout.dipRight,
        top: _Layout.dipSerialTop,
        height: _Layout.dipSerialHeight,
      ),
    ],
    textGroups: <PlateTextGroup>[
      const PlateTextGroup(<int>[0, 1], key: 'country'),
      PlateTextGroup(
        const <int>[2, 3],
        prefix: '-${mission.code}-',
        key: 'rank',
      ),
    ],
  );

  /// The Mercosur plate, `AB 12345`, 400×130 under the blue band.
  /// Slots: the two letters, then the five digits.
  static final PlateSpec mercosur = PlateSpec(
    id: 'bo.mercosur',
    country: BoliviaCountry.bolivia,
    canvasWidth: _Layout.mWidth,
    canvasHeight: _Layout.mHeight,
    noPanel: true,
    panel: const PlatePanel(box: _Layout.mFlag),
    background: const PlateSection.rows(<PlatePart>[
      PlatePart(
        PlateSection.fill(PlateFill.color(BoliviaColors.mercosurBlue)),
        end: _Layout.mBand,
      ),
      PlatePart(PlateSection.plain),
    ]),
    bands: _flag(_Layout.mFlag),
    labels: const <PlateLabel>[
      PlateLabel(
        text: 'BOLIVIA',
        box: _Layout.mCaption,
        glyphHeight: _Layout.mCaptionGlyph,
        color: BoliviaColors.mercosurWhite,
      ),
    ],
    slots: <PlateSlot>[
      ...plateRegister(
        alphabet: BoliviaAlphabets.letters,
        count: 2,
        left: _Layout.mLettersLeft,
        top: _Layout.mSerialTop,
        width: _Layout.mLetterPitch,
        height: _Layout.mSerialHeight,
      ),
      ...plateRegister(
        alphabet: BoliviaAlphabets.digits,
        count: 5,
        left: _Layout.mDigitsLeft,
        top: _Layout.mSerialTop,
        width: _Layout.mDigitPitch,
        height: _Layout.mSerialHeight,
      ),
    ],
    textGroups: const <PlateTextGroup>[
      PlateTextGroup(<int>[0, 1], key: 'letters'),
      PlateTextGroup(<int>[2, 3, 4, 5, 6], prefix: ' ', key: 'number'),
    ],
  );
}
