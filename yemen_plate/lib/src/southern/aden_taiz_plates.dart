import 'package:plate_core/plate_core.dart';
import 'package:flutter/widgets.dart';

import '../common/yemen_alphabets.dart';
import '../common/yemen_country.dart';

/// Aden City's plates: black on white, عدن over ADEN, the Ras Marshag
/// lighthouse, and a four-digit number. Two sizes, both documented in mm.
///
/// Measured off `Yemen_License_Plate_-_Aden_-_520_x_110_mm.png` (plate
/// 978 × 209 px, ar 4.68 against the documented 4.73) and `…_335_x_170_mm.png`
/// (508 × 247 px, ar 2.06 against 1.97), each normalised to its mm:
///
///   520 × 110   عدن x 21 .. 136 y 26 .. 62   ADEN x 71 .. 143 y 64 .. 85
///               lighthouse x 172 .. 220 y 20 .. 98
///               digits centres 311 / 360 / 411 / 461, ink y 21 .. 92
///   335 × 170   lighthouse x 12 .. 43 y 12 .. 65
///               عدن x 219 .. 330 y 10 .. 45   ADEN x 260 .. 327 y 45 .. 64
///               digits centres 89 / 139 / 190 / 239, ink y 81 .. 154
///
/// The digits are FE-Schrift, 70 tall on the 110 plate. A slot's ink is ~0.525
/// of its box and the box may not leave the canvas, so the 110 plate's digits
/// are ~82% of reference and the 170 plate's ~79%. The article notes room for
/// five or six digits; only four are published, so only four are built.
///
/// The lighthouse is a decal cropped from the CC0 artwork — a drawing, not a
/// shape an algorithm can paint.
abstract final class YemenAdenPlates {
  static const AssetImage _lighthouse = AssetImage(
    'assets/southern/aden_lighthouse.png',
    package: 'yemen_plate',
  );

  static const PlatePanel _noPanel = PlatePanel(box: PlateBox(0, 0, 1, 1));

  static const List<PlateTextGroup> _groups = <PlateTextGroup>[
    PlateTextGroup(<int>[0, 1, 2, 3], key: 'serial'),
  ];

  /// The one-line plate, 520 × 110.
  static final PlateSpec oneLine = PlateSpec(
    id: 'ye.aden.520x110',
    country: YemenCountry.plain,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: _noPanel,
    noPanel: true,
    labels: const <PlateLabel>[
      PlateLabel(text: 'عدن', box: PlateBox(18, 14, 120, 60), glyphHeight: 64),
      PlateLabel(text: 'ADEN', box: PlateBox(67, 62, 80, 25), glyphHeight: 39),
    ],
    decals: const <PlateDecal>[
      PlateDecal(image: _lighthouse, box: PlateBox(171.7, 19.5, 47.9, 78.9)),
    ],
    // Centres 311 .. 461 sit 50 apart, but a bold sans digit at this height
    // is 55 wide; the cells keep the reference's centre (386) at 55.
    slots: plateRegister(
      alphabet: YemenAlphabets.digits,
      count: 4,
      left: 386 - 2 * 55,
      top: 0,
      width: 55,
      height: 110,
    ),
    textGroups: _groups,
  );

  /// The two-line plate, 335 × 170, for vehicles that cannot take the long one.
  static final PlateSpec twoLine = PlateSpec(
    id: 'ye.aden.335x170',
    country: YemenCountry.plain,
    canvasWidth: 335,
    canvasHeight: 170,
    panel: _noPanel,
    noPanel: true,
    borderWidthRatioOverride: 3.4 / 170,
    labels: const <PlateLabel>[
      PlateLabel(text: 'عدن', box: PlateBox(215, 2, 120, 50), glyphHeight: 58),
      PlateLabel(text: 'ADEN', box: PlateBox(252, 44, 80, 22), glyphHeight: 30),
    ],
    decals: const <PlateDecal>[
      PlateDecal(image: _lighthouse, box: PlateBox(11.9, 11.7, 31, 53.7)),
    ],
    // Ink centre y 117.7; the tallest centred box that stays on the plate is
    // 65 .. 170.
    slots: plateRegister(
      alphabet: YemenAlphabets.digits,
      count: 4,
      left: 164 - 2 * 50.2,
      top: 65.4,
      width: 50.2,
      height: 104.6,
    ),
    textGroups: _groups,
  );
}

/// Taiz's temporary plates, the de facto current issue: ج-ي (Republic,
/// Yemen) and مؤقت-تعز (temporary, Taiz) over a four-digit number, in black
/// on a blue (first class: private and for hire) or red (second class:
/// commercial) field. One spec; the class is the theme
/// (`YemenThemes.taizPrivate` / `taizCommercial`).
///
/// Measured off `Yemen_-_Taiz_-_License_Plate_-_Temporary_*.png`, 520 × 288
/// with the black frame inside the image:
///
///   divider    y 114 .. 119, full width
///   مؤقت-تعز   x  20 .. 289   y 27 .. 87
///   ج-ي        x 342 .. 488   y 32 .. 97
///   digits     x  96 .. 412   y 140 .. 259, centres 115 / 191 / 277 / 372
///
/// The digits (Mandatory) are 118 tall; the tallest centred box that stays on
/// the plate gives ~93 (79%).
abstract final class YemenTaizPlates {
  static final PlateSpec temporary = PlateSpec(
    id: 'ye.taiz.temporary',
    country: YemenCountry.plain,
    canvasWidth: 520,
    canvasHeight: 288,
    panel: const PlatePanel(box: PlateBox(0, 0, 1, 1)),
    noPanel: true,
    background: const PlateSection.rows(<PlatePart>[
      PlatePart(PlateSection.plain, end: 116.5, divider: 5),
      PlatePart(PlateSection.plain),
    ]),
    labels: const <PlateLabel>[
      PlateLabel(
        text: 'مؤقت-تعز',
        box: PlateBox(14.5, 17, 280, 80),
        glyphHeight: 66,
      ),
      PlateLabel(text: 'ج-ي', box: PlateBox(345, 25, 140, 80), glyphHeight: 66),
    ],
    slots: plateRegister(
      alphabet: YemenAlphabets.digits,
      count: 4,
      left: 254 - 2 * 86,
      top: 199.5 - 88.5,
      width: 86,
      height: 177,
    ),
    textGroups: const <PlateTextGroup>[
      PlateTextGroup(<int>[0, 1, 2, 3], key: 'serial'),
    ],
  );
}
