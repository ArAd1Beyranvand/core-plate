import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'algeria_alphabets.dart';
import 'algeria_country.dart';

/// Where the ink sits on an Algerian plate, in millimetres.
///
/// The article gives 520×110 (455–520 × 100–110 allowed). The single-line
/// figures are off the front/rear artwork, its black rim's outer edge
/// (978×209 px, aspect 4.68 against the documented 4.73) mapped to 520×110:
///
/// * Ink rows y 19.2..86.3 (front) and 20.4..88.0 (rear): 67 mm tall,
///   centred at ~53.5.
/// * Glyph centres 31.7 78.2 126.0 171.2 217.5 | 280.5 319.9 366.6 |
///   434.7 482.8. A least-squares fit of left, pitch and group gap (the
///   proportional `1` left out) gives pitch 45.6 and an extra 18.0 between
///   groups, residuals ≤ 5. The run is centred: 14 + 10·45.6 + 2·18 + 14.
/// * The army photo (silver rim 52..530 × 38..2406 px mapped to 520×110):
///   nine digits, centres 129.6 … 471.8, pitch 42.8, ink 13..97; the round
///   flag at x 47.4..104.0, y ~31..91.
///
/// **Under-height ink, accepted.** The regulation asks for 75 mm digits and
/// the artwork draws 67; 67 would need a ~128 mm slot on a 110 mm plate
/// (`glyphStyle` sets 0.72 of the slot, a bold digit is ~0.73 of that). The
/// slots are as tall as the plate allows, and the glyph is then
/// width-limited by its 45.6 mm cell, since DejaVu Bold's digits are far
/// wider than the plate's condensed face. `core_plate` is unchanged.
///
/// **Fixed cells.** The regulation makes `1` 20 mm wide and every other digit
/// 30, with an even 10 mm between them; a `PlateSlot` is a fixed cell, so a
/// `1` here sits centred in a full cell.
abstract final class _Layout {
  static const double width = 520;
  static const double height = 110;
  static const double slotTop = 2;
  static const double slotHeight = 104;
  static const double left = 14;
  static const double pitch = 45.6;
  static const double groupGap = 18;

  // Two-line, 275×200, from the article's regulation text alone — no image.
  // Digits 30 wide with 10 between them: pitch 40. Two 75 mm rows with equal
  // air around them centre at 54.2 and 145.8. The group gap is the
  // single-line one scaled to the pitch.
  static const double twoWidth = 275;
  static const double twoHeight = 200;
  static const double twoPitch = 40;
  static const double twoGap = 16;
  static const double twoSlotHeight = 92;
  static const double twoRow1Top = 54.2 - twoSlotHeight / 2;
  static const double twoRow2Top = 145.8 - twoSlotHeight / 2;

  // Diplomatic NNN-NN-NN: no image exists on the page, so this is the
  // single-line digit cell with two hyphen cells, centred. Unmeasured.
  static const double hyphenWidth = 30;

  /// A label is not shrunk to its box: this prints a ~15 mm dash.
  static const double hyphenGlyph = 58;

  // Army.
  static const double armyLeft = 108.2;
  static const double armyPitch = 42.8;
  static const double armySlotTop = 3;
  static const double roundelLeft = 46.7;
  static const double roundelTop = 31;
  static const double roundelSize = 58;
}

/// Algeria's plate geometries.
///
/// * [singleLine] — the 520×110 plate, `NNNNN NNN NN`. White on black at the
///   front, black on yellow at the rear: the theme, not the spec.
/// * [twoLine] — the 275×200 plate: serial over class+year and wilaya.
/// * [diplomatic] — `NNN-NN-NN`, black on teal.
/// * [army] — nine silver digits on black, the flag in a roundel at the left.
///
/// The civil specs have the text groups `serial` (5), `type` (3: vehicle
/// class then year of manufacture) and `wilaya` (2); diplomatic has
/// `serial`, `status` and `mission`; army has `serial`.
///
/// Not implemented: the 140×120 motorcycle plate. The article gives 26 mm
/// digits with "the rest the same", i.e. 10 mm between them, which cannot
/// put five digits on a 140 mm row.
abstract final class AlgeriaPlates {
  static const List<PlateTextGroup> _civilGroups = <PlateTextGroup>[
    PlateTextGroup(<int>[0, 1, 2, 3, 4], key: 'serial'),
    PlateTextGroup(<int>[5, 6, 7], key: 'type'),
    PlateTextGroup(<int>[8, 9], key: 'wilaya'),
  ];

  static List<PlateSlot> _digits(
    int count, {
    required double left,
    required double top,
    required double pitch,
    required double height,
  }) => plateRegister(
    alphabet: AlgeriaAlphabets.digits,
    count: count,
    left: left,
    top: top,
    width: pitch,
    height: height,
  );

  static final PlateSpec singleLine = () {
    const double p = _Layout.pitch;
    const double typeLeft = _Layout.left + 5 * p + _Layout.groupGap;
    const double wilayaLeft = typeLeft + 3 * p + _Layout.groupGap;
    List<PlateSlot> group(int n, double left) => _digits(
      n,
      left: left,
      top: _Layout.slotTop,
      pitch: p,
      height: _Layout.slotHeight,
    );
    return PlateSpec(
      id: 'dz.singleLine',
      country: AlgeriaCountry.algeria,
      canvasWidth: _Layout.width,
      canvasHeight: _Layout.height,
      noPanel: true,
      panel: const PlatePanel(box: PlateBox(0, 0, 0, _Layout.height)),
      slots: <PlateSlot>[
        ...group(5, _Layout.left),
        ...group(3, typeLeft),
        ...group(2, wilayaLeft),
      ],
      textGroups: _civilGroups,
    );
  }();

  static final PlateSpec twoLine = () {
    const double p = _Layout.twoPitch;
    const double w = _Layout.twoWidth;
    const double lowerLeft = (w - (5 * p + _Layout.twoGap)) / 2;
    List<PlateSlot> group(int n, double left, double top) => _digits(
      n,
      left: left,
      top: top,
      pitch: p,
      height: _Layout.twoSlotHeight,
    );
    return PlateSpec(
      id: 'dz.twoLine',
      country: AlgeriaCountry.algeria,
      canvasWidth: w,
      canvasHeight: _Layout.twoHeight,
      // The theme's rim ratio is of a 110 mm height; keep the rim 4.3 mm.
      borderWidthRatioOverride: 4.3 / _Layout.twoHeight,
      noPanel: true,
      panel: const PlatePanel(box: PlateBox(0, 0, 0, _Layout.twoHeight)),
      slots: <PlateSlot>[
        ...group(5, (w - 5 * p) / 2, _Layout.twoRow1Top),
        ...group(3, lowerLeft, _Layout.twoRow2Top),
        ...group(2, lowerLeft + 3 * p + _Layout.twoGap, _Layout.twoRow2Top),
      ],
      textGroups: _civilGroups,
    );
  }();

  /// `NNN-NN-NN`: the vehicle's number, whether it serves a diplomat or the
  /// embassy's staff, and the embassy (27 Italy, 37 Norway).
  static final PlateSpec diplomatic = () {
    const double p = _Layout.pitch;
    const double h = _Layout.hyphenWidth;
    const double left = (_Layout.width - (7 * p + 2 * h)) / 2;
    const double statusLeft = left + 3 * p + h;
    const double missionLeft = statusLeft + 2 * p + h;
    List<PlateSlot> group(int n, double left) => _digits(
      n,
      left: left,
      top: _Layout.slotTop,
      pitch: p,
      height: _Layout.slotHeight,
    );
    return PlateSpec(
      id: 'dz.diplomatic',
      country: AlgeriaCountry.algeria,
      canvasWidth: _Layout.width,
      canvasHeight: _Layout.height,
      noPanel: true,
      panel: const PlatePanel(box: PlateBox(0, 0, 0, _Layout.height)),
      slots: <PlateSlot>[
        ...group(3, left),
        ...group(2, statusLeft),
        ...group(2, missionLeft),
      ],
      labels: <PlateLabel>[_hyphen(left + 3 * p), _hyphen(statusLeft + 2 * p)],
      textGroups: const <PlateTextGroup>[
        PlateTextGroup(<int>[0, 1, 2], key: 'serial'),
        PlateTextGroup(<int>[3, 4], key: 'status'),
        PlateTextGroup(<int>[5, 6], key: 'mission'),
      ],
    );
  }();

  static PlateLabel _hyphen(double left) => PlateLabel(
    text: '-',
    box: PlateBox(
      left,
      _Layout.slotTop,
      _Layout.hyphenWidth,
      _Layout.slotHeight,
    ),
    glyphHeight: _Layout.hyphenGlyph,
  );

  /// Nine digits at an even pitch. The article documents no army format, so
  /// this is the one plate on the page. Its outline — the bottom corners are
  /// cut away under the flag — is drawn as the plain rectangle.
  static final PlateSpec army = PlateSpec(
    id: 'dz.army',
    country: AlgeriaCountry.algeria,
    canvasWidth: _Layout.width,
    canvasHeight: _Layout.height,
    noPanel: true,
    panel: const PlatePanel(box: PlateBox(0, 0, 0, _Layout.height)),
    slots: _digits(
      9,
      left: _Layout.armyLeft,
      top: _Layout.armySlotTop,
      pitch: _Layout.armyPitch,
      height: _Layout.slotHeight,
    ),
    decals: const <PlateDecal>[
      PlateDecal(
        image: AssetImage('assets/dz_roundel.png', package: 'algeria_plate'),
        box: PlateBox(
          _Layout.roundelLeft,
          _Layout.roundelTop,
          _Layout.roundelSize,
          _Layout.roundelSize,
        ),
      ),
    ],
    textGroups: const <PlateTextGroup>[
      PlateTextGroup(<int>[0, 1, 2, 3, 4, 5, 6, 7, 8], key: 'serial'),
    ],
  );
}
