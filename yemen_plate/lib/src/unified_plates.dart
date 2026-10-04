import 'package:plate_core/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'yemen_alphabets.dart';
import 'yemen_country.dart';

/// System A — the unified plate. White for every usage; colour-coding lives in
/// [YemenThemes]. Usage varies the blue panel captions (country block), passed at render time.
/// Vehicle number is 4–6 digits; each length is a separate spec because [PlateSpec] has
/// a fixed slot list. Swapping specs on a live canvas preserves the value via group key.
///
/// Car canvas: 1024 x 292 (aspect 3.51), measured from an issued plate.
/// Four zones: country block (x 0.027 .. 0.276), vehicle number (x 0.285 .. 0.812),
/// stipple strip (x 0.818 .. 0.827), blue panel (x 0.827 .. 0.987 + overlap under frame).
/// Motorcycle: 289 x 288, not measured (no photo available); ratios carried from car.
/// Digits shorter than photo (0.46 vs 0.557) because Roboto is wider than FE-Schrift.
abstract final class YemenUnifiedPlates {
  // Shared geometry: car (measured), motorcycle (// CALIBRATE).
  // Coordinates given as units; comments show measured fractions.
  static const double _carWidth = 1024;
  static const double _carHeight = 292;
  static const double _motoWidth = 289; // CALIBRATE: no photo
  static const double _motoHeight = 288; // CALIBRATE: no photo
  static const double _borderRatio = 0.035; // CALIBRATE: matches theme ratio

  // --- Car: the four zones, left to right on a 1024-wide canvas. ------------
  //
  //   A  country block   x  28 ..  283   (0.027 .. 0.276)
  //   B  vehicle number  x 292 ..  832   (0.285 .. 0.812, widened — see above)
  //   C1 stipple strip   x 838 ..  847   (0.818 .. 0.827)
  //   C2 blue panel      x 847 .. 1024   (0.827 .. 0.987, run to the edge)

  // Zone C2: blue slab down right edge (x 0.827 .. 0.987 + overlap under frame to 1024).
  // Panel overlaps frame to avoid seams when scaled. Padding places caption at y 0.590 .. 0.775.
  static const PlatePanel _carPanel = PlatePanel(
    box: PlateBox(847, 0, 177, _carHeight),
    flagScale: 0, // No flag
    captionScale: 1.6,
    padding: EdgeInsets.fromLTRB(22, 172, 16, 66), // Top 172 = 0.590 * 292
  );

  // Zone C2 as the plate's last column, so the frame is drawn over its edge.
  static const PlateSection _carBackground = PlateSection.columns(<PlatePart>[
    PlatePart(PlateSection.plain, end: 847),
    PlatePart(PlateSection.fill(PlateFill.panel)),
  ]);

  // Zone A: اليمن (x 0.027 .. 0.276) and YEMEN, separate labels (not joined via newline).
  // Separate to keep bidi isolated. اليمن's height is larger (includes ascender/tail).
  static const List<PlateLabel> _carLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(28, 60, 255, 96), glyphHeight: 118),
    PlateLabel(
      text: 'YEMEN',
      box: PlateBox(28, 156, 255, 76),
      glyphHeight: 100,
    ),
  ];

  // Zone C1 — stippled strip left of blue panel (x 0.818 .. 0.827). Not a primitive
  // in core_plate; built as a column of short
  /// rules, one per dot. This one wins because it is *data*: the dots are where
  // Stipple strip x 0.818 .. 0.827 (838 wide 9), measured. Pitch 12 units is not measured;
  // 24 dots at that pitch reproduce the photograph's near-solid reading. Built with [plateStipple].
  static final List<PlateRule> _carStipple = plateStipple(
    count: 24,
    left: 838,
    top: 1,
    width: 9,
    height: 7,
    stepY: 12, // CALIBRATE: dot pitch
  );

  // Side code cells: measured x 0.876 .. 0.947, 40-unit pitch. Widened to 52 units
  // to fit Roboto digits (40 would clip). Kept measured centre (x 933).
  static const PlateSlot _carSideCodeHigh = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(881, 14, 52, 124),
  );
  static const PlateSlot _carSideCodeLow = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(933, 14, 52, 124),
  );

  // 4/5/6 number cells (x 292 .. 832) plus side-code cells. All lengths end flush at right edge;
  // only top/height differ per length. Tops centre cap on measured band (y 0.197 .. 0.754).
  static final List<PlateSlot> _car4Slots = <PlateSlot>[
    ...plateRegisterAcross(
      alphabet: YemenAlphabets.digits,
      count: 4,
      left: 292,
      right: 832,
      top: 14,
      height: 264,
    ),
    _carSideCodeHigh,
    _carSideCodeLow,
  ];

  static final List<PlateSlot> _car5Slots = <PlateSlot>[
    ...plateRegisterAcross(
      alphabet: YemenAlphabets.digits,
      count: 5,
      left: 292,
      right: 832,
      top: 15,
      height: 258,
    ),
    _carSideCodeHigh,
    _carSideCodeLow,
  ];

  static final List<PlateSlot> _car6Slots = <PlateSlot>[
    ...plateRegisterAcross(
      alphabet: YemenAlphabets.digits,
      count: 6,
      left: 292,
      right: 832,
      top: 31,
      height: 215,
    ),
    _carSideCodeHigh,
    _carSideCodeLow,
  ];

  // Motorcycle: same content reflowed into square canvas. Zone A becomes full-width
  // top band (اليمن + YEMEN side by side), Zone B the middle, Zone C2 a full-width
  // bottom band (side code left, usage labels right). Zone C1's stipple rotates vertical.

  static const PlatePanel _motoPanel = PlatePanel(
    box: PlateBox(0, 206, 289, 82),
    flagScale: 0,
    captionScale: 2.0, // CALIBRATE
    padding: EdgeInsets.fromLTRB(
      96,
      12,
      12,
      12,
    ), // CALIBRATE: big left inset aligns caption right
  );

  static const PlateSection _motoBackground = PlateSection.rows(<PlatePart>[
    PlatePart(PlateSection.plain, end: 206),
    PlatePart(PlateSection.fill(PlateFill.panel)),
  ]);

  static const List<PlateLabel> _motoLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(16, 14, 110, 42), glyphHeight: 42),
    PlateLabel(text: 'YEMEN', box: PlateBox(150, 20, 120, 30), glyphHeight: 30),
  ];

  // Horizontal stipple above bottom band: 22 dots on car's 12-unit pitch (inherited // CALIBRATE).
  static final List<PlateRule> _motoStipple = plateStipple(
    count: 22,
    left: 15,
    top: 197,
    width: 5,
    height: 5,
    stepX: 12, // CALIBRATE dot pitch
  );

  static const PlateSlot _motoSideCodeHigh = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(16, 214, 27, 60), // CALIBRATE
  );
  static const PlateSlot _motoSideCodeLow = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(48, 214, 27, 60), // CALIBRATE
  );

  // Motorcycle registers are gapped (cells narrower than stride); each states pitch.
  static final List<PlateSlot> _moto4Slots = <PlateSlot>[
    ...plateRegister(
      alphabet: YemenAlphabets.digits,
      count: 4,
      left: 21,
      top: 63,
      width: 57,
      height: 130,
      pitch: 63,
    ),
    _motoSideCodeHigh,
    _motoSideCodeLow,
  ];

  static final List<PlateSlot> _moto5Slots = <PlateSlot>[
    ...plateRegister(
      alphabet: YemenAlphabets.digits,
      count: 5,
      left: 16,
      top: 73,
      width: 48,
      height: 110,
      pitch: 52,
    ),
    _motoSideCodeHigh,
    _motoSideCodeLow,
  ];

  static final List<PlateSlot> _moto6Slots = <PlateSlot>[
    ...plateRegister(
      alphabet: YemenAlphabets.digits,
      count: 6,
      left: 17,
      top: 82,
      width: 40,
      height: 92,
      pitch: 43,
    ),
    _motoSideCodeHigh,
    _motoSideCodeLow,
  ];

  // Text groups: slots in reading order, side-code cells after number cells
  // (different zone). Keys restore the semantics; validator reads by key.
  static const List<PlateTextGroup> _groups4 = <PlateTextGroup>[
    PlateTextGroup(<int>[0, 1, 2, 3], key: 'number'),
    PlateTextGroup(<int>[4, 5], key: 'sideCode'),
  ];
  static const List<PlateTextGroup> _groups5 = <PlateTextGroup>[
    PlateTextGroup(<int>[0, 1, 2, 3, 4], key: 'number'),
    PlateTextGroup(<int>[5, 6], key: 'sideCode'),
  ];
  static const List<PlateTextGroup> _groups6 = <PlateTextGroup>[
    PlateTextGroup(<int>[0, 1, 2, 3, 4, 5], key: 'number'),
    PlateTextGroup(<int>[6, 7], key: 'sideCode'),
  ];

  // Six specs (one per geometry; used to be six geometries × five usages).
  // Usage is not a field — it selects the country block, passed at render time.
  // Usage example: PlateCanvas(spec: YemenUnifiedPlates.car(numberDigits: 5)!,
  //                            country: YemenCountry.unifiedFor(usage), ...)
  //
  // Each spec names `YemenCountry.unifiedPrivate` as its own `country`, so a
  // caller that passes no override gets the ordinary case rather than an
  // uncaptioned panel. If you are tempted to give a usage its own colour, read
  // `YemenThemes`.
  // ---------------------------------------------------------------------------

  /// A five-digit car plate: the length of the official mock-up sample
  /// `24378`, and the plate to reach for first.
  static final PlateSpec car5 = PlateSpec(
    id: 'ye.unified.car5',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _carWidth,
    canvasHeight: _carHeight,
    panel: _carPanel,
    background: _carBackground,
    slots: _car5Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit car plate.
  static final PlateSpec car4 = PlateSpec(
    id: 'ye.unified.car4',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _carWidth,
    canvasHeight: _carHeight,
    panel: _carPanel,
    background: _carBackground,
    slots: _car4Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit car plate.
  static final PlateSpec car6 = PlateSpec(
    id: 'ye.unified.car6',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _carWidth,
    canvasHeight: _carHeight,
    panel: _carPanel,
    background: _carBackground,
    slots: _car6Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A five-digit motorcycle plate.
  static final PlateSpec moto5 = PlateSpec(
    id: 'ye.unified.moto5',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _motoWidth,
    canvasHeight: _motoHeight,
    panel: _motoPanel,
    background: _motoBackground,
    slots: _moto5Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit motorcycle plate.
  static final PlateSpec moto4 = PlateSpec(
    id: 'ye.unified.moto4',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _motoWidth,
    canvasHeight: _motoHeight,
    panel: _motoPanel,
    background: _motoBackground,
    slots: _moto4Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit motorcycle plate.
  static final PlateSpec moto6 = PlateSpec(
    id: 'ye.unified.moto6',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _motoWidth,
    canvasHeight: _motoHeight,
    panel: _motoPanel,
    background: _motoBackground,
    slots: _moto6Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  // ---------------------------------------------------------------------------
  // Lookups. Keyed by number length alone — there is no usage axis left to key
  // on.
  // ---------------------------------------------------------------------------

  /// The car geometries this package builds, keyed by how many digits the
  /// vehicle number has.
  static final Map<int, PlateSpec> carGeometries = <int, PlateSpec>{
    4: car4,
    5: car5,
    6: car6,
  };

  /// The motorcycle geometries, keyed by how many digits the vehicle number
  /// has. Unverified — no photograph of a unified motorcycle plate was
  /// available.
  static final Map<int, PlateSpec> motoGeometries = <int, PlateSpec>{
    4: moto4,
    5: moto5,
    6: moto6,
  };

  /// The unified car plate whose vehicle number has [numberDigits] digits, or
  /// null when that is not a length this package builds.
  ///
  /// Usage is not a parameter. It selects the two caption lines in the blue
  /// side panel, which the host passes to the canvas:
  /// `country: YemenCountry.unifiedFor(usage)`.
  ///
  /// Handing a live `PlateCanvas` a spec with a different id carries the value
  /// across per `PlateCanvas.onSpecChange`; with `byGroupKey` a change of
  /// length keeps the digits that still fit. See the class doc.
  static PlateSpec? car({required int numberDigits}) =>
      carGeometries[numberDigits];

  /// The unified motorcycle plate whose vehicle number has [numberDigits]
  /// digits, or null.
  static PlateSpec? moto({required int numberDigits}) =>
      motoGeometries[numberDigits];

  /// The number lengths a unified plate can have, shortest first.
  static const List<int> numberLengths = <int>[4, 5, 6];
}
