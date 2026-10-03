import 'package:flutter/widgets.dart';
import 'package:core_plate/core_plate.dart';

import 'palestine_alphabets.dart';
import 'palestine_country.dart';

/// Gaza plate designs: one grammar (3·DDDD·DD). Group 3 drives glyph colour.
/// Flag (no identity block). Field always white; no inversion. All dimensions
/// provisional (CALIBRATE); copied from West Bank for visual consistency only.
abstract final class PSGazaPlates {
  static const List<PlateTextGroup> _groups = [
    PlateTextGroup([0], key: 'prefix'),
    PlateTextGroup([1, 2, 3, 4], key: 'serial'),
    PlateTextGroup([5, 6], key: 'usage'),
  ];

  // -------------------------------------------------------------------------
  // car2012 — vertical flag, full height, ~55 units wide.
  // -------------------------------------------------------------------------

  // Seven-cell layout reused from PSWestBankPlates.legacyCar (duplicated for module privacy).
  static final List<PlateSlot> _sevenCellSlots = [
    const PlateSlot(
      alphabet: PSAlphabets.gazaPrefix,
      box: PlateBox(20, 9, 47, 92),
    ),
    ...plateRegister(
      alphabet: PSAlphabets.digits,
      count: 4,
      left: 95,
      top: 9,
      width: 47,
      height: 92,
      pitch: 51,
    ),
    const PlateSlot(
      alphabet: PSAlphabets.digits,
      box: PlateBox(323, 9, 47, 92),
    ),
    const PlateSlot(
      alphabet: PSAlphabets.digits,
      box: PlateBox(374, 9, 47, 92),
    ),
  ];

  static const List<PlateLabel> _sevenCellLabels = [
    PlateLabel(
      text: '-',
      box: PlateBox(64.9, 36.6, 32.2, 36.8),
      glyphHeight: 50.6,
    ),
    PlateLabel(
      text: '-',
      box: PlateBox(292.9, 36.6, 32.2, 36.8),
      glyphHeight: 50.6,
    ),
  ];

  static const List<PlateRule> _car2012Rules = [];

  /// 2012–2021: flag rotated vertical (aspect 1:2), fills right strip.
  static final PlateSpec car2012 = PlateSpec(
    id: 'ps.gz.2012.car',
    country: PSCountries.gaza2012,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: PlatePanel(
      box: PlateBox(455, 0, 55, 110),
      flagScale: 1,
      padding: EdgeInsets.zero,
    ),
    borderWidthRatioOverride: 0.027,
    slots: _sevenCellSlots,
    rules: _car2012Rules,
    labels: _sevenCellLabels,
    textGroups: _groups,
  );

  /// Watermark: raster (not SVG) due to PlateDecal constraints. Pre-faded to ~12% grey.
  /// Draws under digits (spec.decals painted before spec.slots in Stack).
  static const PlateDecal _watermark = PlateDecal(
    image: AssetImage(
      'assets/marks/palestine_watermark.png',
      package: 'palestine_plate',
    ),
    box: PlateBox(10, 9, 380, 92),
  );

  // Motorcycle: one-line, horizontal flag + watermark (only Gaza one-line with horizontal flag).
  // CALIBRATE — proportions from car layout; no reference photograph.
  static final List<PlateSlot> _motoSlots = [
    const PlateSlot(
      alphabet: PSAlphabets.gazaPrefix,
      box: PlateBox(14, 9, 48, 92),
    ),
    ...plateRegister(
      alphabet: PSAlphabets.digits,
      count: 4,
      left: 74,
      top: 9,
      width: 48,
      height: 92,
      pitch: 52,
    ),
    const PlateSlot(
      alphabet: PSAlphabets.digits,
      box: PlateBox(290, 9, 48, 92),
    ),
    const PlateSlot(
      alphabet: PSAlphabets.digits,
      box: PlateBox(342, 9, 48, 92),
    ),
  ];

  static const List<PlateLabel> _motoLabels = [
    PlateLabel(text: '-', box: PlateBox(56, 36.6, 18, 36.8), glyphHeight: 50.6),
    PlateLabel(
      text: '-',
      box: PlateBox(272, 36.6, 18, 36.8),
      glyphHeight: 50.6,
    ),
  ];

  static const List<PlateRule> _motoRules = [];

  /// One-line motorcycle: horizontal flag (aspect 2/1) + watermark.
  static final PlateSpec moto = PlateSpec(
    id: 'ps.gz.moto',
    country: PSCountries.gaza2021,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: PlatePanel(
      box: PlateBox(400, 27.5, 110, 55),
      flagScale: 1,
      padding: EdgeInsets.zero,
    ),
    borderWidthRatioOverride: 0.027,
    slots: _motoSlots,
    rules: _motoRules,
    labels: _motoLabels,
    decals: [_watermark],
    textGroups: _groups,
  );

  // Two-line: flag becomes horizontal band across top (vertical strip won't fit landscape).
  static const PlatePanel _twoLinePanel = PlatePanel(
    box: PlateBox(4, 4, 292, 40),
    flagScale: 1,
    padding: EdgeInsets.zero,
  );

  static const List<PlateRule> _twoLineRules = [];

  // Line positions duplicated from PSWestBankPlates.legacyCarTwoLine.
  static final List<PlateSlot> _twoLineSlots = [
    const PlateSlot(
      alphabet: PSAlphabets.gazaPrefix,
      box: PlateBox(16.5, 53, 34, 42),
    ),
    ...plateRegister(
      alphabet: PSAlphabets.digits,
      count: 4,
      left: 70.5,
      top: 53,
      width: 34,
      height: 42,
      pitch: 37,
    ),
    const PlateSlot(
      alphabet: PSAlphabets.digits,
      box: PlateBox(80.5, 101, 34, 42),
    ), // Line 2
    const PlateSlot(
      alphabet: PSAlphabets.digits,
      box: PlateBox(117.5, 101, 34, 42),
    ),
  ];

  static const List<PlateLabel> _twoLineLabels = [
    PlateLabel(
      text: '-',
      box: PlateBox(49.5, 65.6, 21, 16.8),
      glyphHeight: 23.1,
    ),
  ];

  /// Car 2012–2021 wrapped onto two lines. Flag becomes horizontal (see class doc).
  static final PlateSpec car2012TwoLine = PlateSpec(
    id: 'ps.gz.2012.car2l',
    country: PSCountries.gaza2021,
    canvasWidth: 300,
    canvasHeight: 150,
    panel: _twoLinePanel,
    borderWidthRatioOverride: 0.027,
    slots: _twoLineSlots,
    rules: _twoLineRules,
    labels: _twoLineLabels,
    textGroups: _groups,
  );

  /// Car 2021 wrapped onto two lines (same layout as car2012TwoLine) + watermark.
  static final PlateSpec car2021TwoLine = PlateSpec(
    id: 'ps.gz.2021.car2l',
    country: PSCountries.gaza2021,
    canvasWidth: 300,
    canvasHeight: 150,
    panel: _twoLinePanel,
    borderWidthRatioOverride: 0.027,
    slots: _twoLineSlots,
    rules: _twoLineRules,
    labels: _twoLineLabels,
    decals: [
      PlateDecal(
        image: AssetImage(
          'assets/marks/palestine_watermark.png',
          package: 'palestine_plate',
        ),
        box: PlateBox(10, 50, 282, 96),
      ),
    ],
    textGroups: _groups,
  );

  static final List<PlateSpec> all = [
    car2012,
    car2012TwoLine,
    car2021TwoLine,
    moto,
  ];
}
