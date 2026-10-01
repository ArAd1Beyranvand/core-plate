import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'lebanon_alphabets.dart';
import 'lebanon_colors.dart';
import 'lebanon_country.dart';

/// Lebanon's two geometries: [oneLine] (1040×220, band left) and [twoLine]
/// (520×288, band top). Both use up to six digits. Shorter numbers are
/// available via [oneLineOf] / [twoLineOf] (one to six digits), keyed and
/// cached in [oneLineGeometries] / [twoLineGeometries].
///
/// Everything is from photographs, marked `// CALIBRATE`. The one-line band
/// text runs vertically on the real plate; here it prints horizontally
/// (core limitation).
abstract final class LebanonPlates {
  static const double _borderRatio = 0.022; // CALIBRATE
  static const int standardDigits = 6;
  static const List<int> digitLengths = <int>[1, 2, 3, 4, 5, 6];

  static const double _oneLineWidth = 1040;
  static const double _oneLineHeight = 220;

  /// Band down the left edge, with لبنان label and cedar.
  static const PlatePanel _oneLinePanel = PlatePanel(
    box: PlateBox(0, 0, 126, _oneLineHeight),
    flagScale: 0.62,
    captionScale: 1.1, // CALIBRATE
    padding: EdgeInsets.fromLTRB(10, 86, 8, 10), // CALIBRATE
  );

  /// The band as the plate's first column, run out under the frame.
  static const PlateSection _oneLineBackground = PlateSection.columns(<PlatePart>[
    PlatePart(PlateSection.fill(PlateFill.panel), end: 126),
    PlatePart(PlateSection.plain),
  ]);

  static const List<PlateLabel> _oneLineLabels = <PlateLabel>[
    PlateLabel(text: 'لبنان', box: PlateBox(10, 14, 106, 56), glyphHeight: 50, color: LebanonColors.bandInk),
  ];

  /// Letter cell, wider to accommodate `MP` (two glyphs).
  static const PlateSlot _oneLineLetter = PlateSlot(
    alphabet: LebanonAlphabets.letters,
    box: PlateBox(160, 34, 110, 152),
  );

  static const double _twoLineWidth = 520;
  static const double _twoLineHeight = 288;

  /// Band across the top, horizontal layout.
  static const PlatePanel _twoLinePanel = PlatePanel(
    box: PlateBox(0, 0, _twoLineWidth, 88),
    flagScale: 0.85,
    captionScale: 1.9, // CALIBRATE
    padding: EdgeInsets.fromLTRB(236, 16, 16, 16), // CALIBRATE
    direction: Axis.horizontal,
  );

  /// The band as the plate's top row.
  static const PlateSection _twoLineBackground = PlateSection.rows(<PlatePart>[
    PlatePart(PlateSection.fill(PlateFill.panel), end: 88),
    PlatePart(PlateSection.plain),
  ]);

  static const List<PlateLabel> _twoLineLabels = <PlateLabel>[
    PlateLabel(text: 'لبنان', box: PlateBox(16, 18, 130, 52), glyphHeight: 46, color: LebanonColors.bandInk),
  ];

  static const PlateSlot _twoLineLetter = PlateSlot(
    alphabet: LebanonAlphabets.letters,
    box: PlateBox(26, 116, 84, 140),
  );

  static List<PlateSlot> _oneLineSlots(int digits) => <PlateSlot>[
    _oneLineLetter,
    ...plateRegister(
      alphabet: LebanonAlphabets.digits,
      count: digits,
      left: 320,
      top: 34,
      width: 113,
      height: 152,
      pitch: 113,
    ),
  ];

  static List<PlateSlot> _twoLineSlots(int digits) => <PlateSlot>[
    _twoLineLetter,
    ...plateRegister(
      alphabet: LebanonAlphabets.digits,
      count: digits,
      left: 120,
      top: 116,
      width: 62,
      height: 140,
      pitch: 62,
    ),
  ];

  /// Slot 0 is letter; remaining are serial digits.
  static List<PlateTextGroup> _groups(int digits) => <PlateTextGroup>[
    const PlateTextGroup(<int>[0], key: 'letter'),
    PlateTextGroup(<int>[for (int i = 1; i <= digits; i++) i], key: 'serial'),
  ];

  static final PlateSpec oneLine = _oneLineSpec(standardDigits);
  static final PlateSpec twoLine = _twoLineSpec(standardDigits);

  static PlateSpec _oneLineSpec(int digits) => PlateSpec(
    id: 'lb.oneLine$digits',
    country: LebanonCountry.private,
    canvasWidth: _oneLineWidth,
    canvasHeight: _oneLineHeight,
    panel: _oneLinePanel,
    background: _oneLineBackground,
    slots: _oneLineSlots(digits),
    labels: _oneLineLabels,
    textGroups: _groups(digits),
    borderWidthRatioOverride: _borderRatio,
  );

  static PlateSpec _twoLineSpec(int digits) => PlateSpec(
    id: 'lb.twoLine$digits',
    country: LebanonCountry.private,
    canvasWidth: _twoLineWidth,
    canvasHeight: _twoLineHeight,
    panel: _twoLinePanel,
    background: _twoLineBackground,
    slots: _twoLineSlots(digits),
    labels: _twoLineLabels,
    textGroups: _groups(digits),
    borderWidthRatioOverride: _borderRatio,
  );

  /// One-line and two-line geometries by digit count, built once.
  static final Map<int, PlateSpec> oneLineGeometries = <int, PlateSpec>{
    for (final int d in digitLengths) d: d == standardDigits ? oneLine : _oneLineSpec(d),
  };

  static final Map<int, PlateSpec> twoLineGeometries = <int, PlateSpec>{
    for (final int d in digitLengths) d: d == standardDigits ? twoLine : _twoLineSpec(d),
  };

  static PlateSpec? oneLineOf({required int digits}) => oneLineGeometries[digits];
  static PlateSpec? twoLineOf({required int digits}) => twoLineGeometries[digits];

  static List<PlateSpec> get all => <PlateSpec>[oneLine, twoLine];
}
