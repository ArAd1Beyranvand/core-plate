import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'yemen_alphabets.dart';
import 'yemen_country.dart';
import 'yemen_usage.dart';

/// **System A** — the unified plate approved on 9 May 2026 by the Ministry of
/// Interior of the internationally recognised government, and valid only in the
/// governorates that government controls.
///
/// A plate carries the name of Yemen, the vehicle number, a two-character side
/// code, and the type of use. It is white for every usage: System A does not
/// colour-code by use, and `YemenThemes.unified` is the only theme this
/// namespace needs. What varies with usage is the two caption lines in the blue
/// side panel, which is why each geometry appears once per usage below.
///
/// This is **not** the "current" system and `YemenNorthernPlates` the legacy
/// one. Both are current, in different geographies, on different vehicles. The
/// two namespaces are siblings and there is deliberately no flag, enum or
/// parameter anywhere in this package that selects between them at runtime.
///
/// ### Variable length, and why it is six geometries and not one
///
/// The vehicle number is four to six digits. [PlateSpec] has a fixed slot list,
/// so that cannot be one spec — a slot either exists or it does not. Hence
/// [byNumberLength], and hence the caveat that goes with it:
///
/// > **Swapping `spec:` on a live `PlateCanvas` resets the bloc.** Core
/// > dispatches `SpecIsChanged` when the spec id changes, which empties every
/// > value, because the old plate's values are the wrong length for the new
/// > one. So a host picks the number length *before* entry begins, not during
/// > it.
///
/// The opposite conclusion is the right one where a plate's variants have the
/// same slot *count* — there one spec covers them all, and splitting them would
/// wipe good input for nothing. Here the count itself differs, so one spec
/// cannot cover them, and the reset is unavoidable rather than a cost to be
/// designed around.
///
/// ### Geometry
///
/// The canvas is 520 x 288 for a car and 289 x 288 for a motorcycle — the
/// dimensions Wikimedia Commons holds governorate plate files at — with the
/// unit taken as one millimetre. Everything is `// CALIBRATE`: System A is
/// weeks old and its only public image is a ministry mock-up.
abstract final class YemenUnifiedPlates {
  // ---------------------------------------------------------------------------
  // Shared geometry. Declared once and referenced by every spec below, so a
  // recalibration is one edit rather than thirty, and so each spec const is
  // short enough to read as what it is: a geometry crossed with a usage.
  // ---------------------------------------------------------------------------

  static const double _carWidth = 520; // CALIBRATE
  static const double _motoWidth = 289; // CALIBRATE
  static const double _height = 288; // CALIBRATE

  /// Matches `YemenThemes._borderWidthRatio`, and is repeated on every spec via
  /// [PlateSpec.borderWidthRatioOverride] so the geometry survives a host that
  /// supplies its own theme.
  static const double _borderRatio = 0.035; // CALIBRATE

  // --- Car: the four zones, left to right on a 520-wide canvas. -------------
  //
  //   A  country block   x  12 ..  100   (~17%)
  //   B  vehicle number  x 104 ..  400   (~57%)
  //   C1 stipple strip   x 404 ..  414   (~2%)
  //   C2 blue panel      x 416 ..  520   (~20%)

  /// Zone C2. The blue slab down the right edge, overlapping the frame on the
  /// three edges it touches rather than sitting flush at the border thickness:
  /// core clips panel paint back to the rounded face, so extending it under the
  /// frame kills the hairline seam a flush edge leaves once the whole canvas is
  /// scaled.
  ///
  /// The padding is what puts the usage caption in the *lower* two thirds of
  /// the panel, clear of the side-code cells above it: `CountryPanel` lays a
  /// flag out at the top and the caption at the bottom, and with `flagScale: 0`
  /// the caption is handed the whole inner box, so the inner box is where the
  /// caption goes.
  static const PlatePanel _carPanel = PlatePanel(
    box: PlateBox(416, 0, 104, 288),
    // No flag on a Yemeni plate; do not reserve a strip for a null image.
    flagScale: 0,
    captionScale: 1.3, // CALIBRATE
    padding: EdgeInsets.fromLTRB(10, 140, 8, 20), // CALIBRATE
  );

  /// Zone A. Two labels, not one.
  ///
  /// `اليمن` and `YEMEN` are kept as separate [PlateLabel]s rather than joined
  /// into one string with a newline, and the reason is bidi: [PlateLabel] has
  /// no `TextDirection` and core lays a label out exactly as given, so an
  /// Arabic label on its own is an isolated run and renders correctly, while
  /// concatenating it with a Latin one would hand the bidi algorithm a mixed
  /// paragraph and let it reorder the two.
  static const List<PlateLabel> _carLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(12, 109, 88, 44), glyphHeight: 44),
    PlateLabel(text: 'YEMEN', box: PlateBox(12, 157, 88, 32), glyphHeight: 32),
  ];

  /// Zone C1 — the narrow stippled strip immediately left of the blue panel.
  ///
  /// **This is the honest option of the two available, and it is verbose.**
  /// `core_plate` has [PlateRule], which paints one solid box, and no stippled
  /// or dashed primitive; the alternatives were a single solid rule with a
  /// `TODO` saying the stipple is unimplemented, or this — a column of sixteen
  /// short rules, one per dot. This one wins because it is *data*: the dots are
  /// where they are said to be, a recalibration of the pitch is an edit to this
  /// list, and nothing was added to `core_plate` to make it work.
  ///
  /// Dot pitch and dot size are both `// CALIBRATE`: 6 units tall on a 16-unit
  /// pitch is a reading of a low-resolution mock-up, not a measurement.
  static const List<PlateRule> _carStipple = <PlateRule>[
    PlateRule(box: PlateBox(404, 20, 10, 6)), // CALIBRATE dot pitch
    PlateRule(box: PlateBox(404, 36, 10, 6)),
    PlateRule(box: PlateBox(404, 52, 10, 6)),
    PlateRule(box: PlateBox(404, 68, 10, 6)),
    PlateRule(box: PlateBox(404, 84, 10, 6)),
    PlateRule(box: PlateBox(404, 100, 10, 6)),
    PlateRule(box: PlateBox(404, 116, 10, 6)),
    PlateRule(box: PlateBox(404, 132, 10, 6)),
    PlateRule(box: PlateBox(404, 148, 10, 6)),
    PlateRule(box: PlateBox(404, 164, 10, 6)),
    PlateRule(box: PlateBox(404, 180, 10, 6)),
    PlateRule(box: PlateBox(404, 196, 10, 6)),
    PlateRule(box: PlateBox(404, 212, 10, 6)),
    PlateRule(box: PlateBox(404, 228, 10, 6)),
    PlateRule(box: PlateBox(404, 244, 10, 6)),
    PlateRule(box: PlateBox(404, 260, 10, 6)),
  ];

  // The two side-code cells, centred in the blue panel's upper third. 40 x 90
  // keeps the width/height ratio near 0.44 — see the note on _car4Slots.
  static const PlateSlot _carSideCodeHigh = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(425, 26, 40, 90), // CALIBRATE
  );
  static const PlateSlot _carSideCodeLow = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(471, 26, 40, 90), // CALIBRATE
  );

  /// Four number cells plus the two side-code cells.
  ///
  /// **On cell size.** The published specification puts the number's cap height
  /// at about 62% of the plate height — roughly 178 units on this canvas. That
  /// is unreachable here and the number below is the fitted one, not the
  /// published one. The arithmetic: core sets a glyph at `0.72 * cellHeight`,
  /// and a weight-700 digit in an ordinary grotesque runs about 0.57 em wide,
  /// so a cell is about `0.41 * cellHeight` of advance width. Six digits at a
  /// 178-unit cap would need well over 800 units of Zone B, which is 296 units
  /// wide. A genuinely condensed face — FE-Schrift, which is what these plates
  /// are set in — closes some of that gap but not all of it, and this package
  /// cannot supply a font (see the README's `## Fonts`).
  ///
  /// So the cells are sized to fit the zone at a 0.44 width/height ratio, and
  /// the glyphs sit smaller relative to the plate than a photograph does. The
  /// shorter the number, the taller its digits: four digits get 160 units of
  /// cell where six get 106.
  // CALIBRATE: cap height, against a photograph rather than a mock-up.
  static const List<PlateSlot> _car4Slots = <PlateSlot>[
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(104, 64, 70, 160)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(179, 64, 70, 160)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(254, 64, 70, 160)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(329, 64, 70, 160)),
    _carSideCodeHigh,
    _carSideCodeLow,
  ];

  /// Five number cells plus the two side-code cells — the length of the
  /// official mock-up sample, `24378`.
  static const List<PlateSlot> _car5Slots = <PlateSlot>[
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(104, 81, 55, 126)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(164, 81, 55, 126)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(224, 81, 55, 126)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(284, 81, 55, 126)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(344, 81, 55, 126)),
    _carSideCodeHigh,
    _carSideCodeLow,
  ];

  /// Six number cells plus the two side-code cells.
  static const List<PlateSlot> _car6Slots = <PlateSlot>[
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(104, 91, 46, 106)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(154, 91, 46, 106)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(204, 91, 46, 106)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(254, 91, 46, 106)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(304, 91, 46, 106)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(354, 91, 46, 106)),
    _carSideCodeHigh,
    _carSideCodeLow,
  ];

  // --- Motorcycle: the same content reflowed into a square canvas. ----------
  //
  // Zone A becomes a full-width top band with اليمن and YEMEN side by side,
  // Zone B takes the middle, and Zone C2 becomes a full-width blue bottom band
  // with the side code on the left and the usage labels on the right. Zone C1's
  // stipple turns through a right angle and separates the number from the
  // bottom band. Every one of those is a change to a *spec*; not a line of
  // widget code differs between a car and a motorcycle.

  static const PlatePanel _motoPanel = PlatePanel(
    box: PlateBox(0, 206, 289, 82),
    flagScale: 0,
    captionScale: 1.1, // CALIBRATE
    // A big left inset is what pushes the caption to the right-hand end of the
    // band: `CountryPanel` aligns its caption to the start of the inner box,
    // and core exposes no alignment on a panel, so the inset is the lever.
    padding: EdgeInsets.fromLTRB(96, 12, 12, 12), // CALIBRATE
  );

  static const List<PlateLabel> _motoLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(16, 14, 110, 42), glyphHeight: 42),
    PlateLabel(text: 'YEMEN', box: PlateBox(150, 20, 120, 30), glyphHeight: 30),
  ];

  /// The stipple, horizontal, immediately above the blue bottom band. Seventeen
  /// dots on the same 16-unit pitch as the car's column.
  static const List<PlateRule> _motoStipple = <PlateRule>[
    PlateRule(box: PlateBox(16, 197, 5, 5)), // CALIBRATE dot pitch
    PlateRule(box: PlateBox(32, 197, 5, 5)),
    PlateRule(box: PlateBox(48, 197, 5, 5)),
    PlateRule(box: PlateBox(64, 197, 5, 5)),
    PlateRule(box: PlateBox(80, 197, 5, 5)),
    PlateRule(box: PlateBox(96, 197, 5, 5)),
    PlateRule(box: PlateBox(112, 197, 5, 5)),
    PlateRule(box: PlateBox(128, 197, 5, 5)),
    PlateRule(box: PlateBox(144, 197, 5, 5)),
    PlateRule(box: PlateBox(160, 197, 5, 5)),
    PlateRule(box: PlateBox(176, 197, 5, 5)),
    PlateRule(box: PlateBox(192, 197, 5, 5)),
    PlateRule(box: PlateBox(208, 197, 5, 5)),
    PlateRule(box: PlateBox(224, 197, 5, 5)),
    PlateRule(box: PlateBox(240, 197, 5, 5)),
    PlateRule(box: PlateBox(256, 197, 5, 5)),
    PlateRule(box: PlateBox(272, 197, 5, 5)),
  ];

  static const PlateSlot _motoSideCodeHigh = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(16, 214, 27, 60), // CALIBRATE
  );
  static const PlateSlot _motoSideCodeLow = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(48, 214, 27, 60), // CALIBRATE
  );

  static const List<PlateSlot> _moto4Slots = <PlateSlot>[
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(21, 63, 57, 130)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(84, 63, 57, 130)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(147, 63, 57, 130)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(210, 63, 57, 130)),
    _motoSideCodeHigh,
    _motoSideCodeLow,
  ];

  static const List<PlateSlot> _moto5Slots = <PlateSlot>[
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(16, 73, 48, 110)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(68, 73, 48, 110)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(120, 73, 48, 110)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(172, 73, 48, 110)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(224, 73, 48, 110)),
    _motoSideCodeHigh,
    _motoSideCodeLow,
  ];

  static const List<PlateSlot> _moto6Slots = <PlateSlot>[
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(17, 82, 40, 92)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(60, 82, 40, 92)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(103, 82, 40, 92)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(146, 82, 40, 92)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(189, 82, 40, 92)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(232, 82, 40, 92)),
    _motoSideCodeHigh,
    _motoSideCodeLow,
  ];

  // --- Text groups. ---------------------------------------------------------
  //
  // Slots are a flat list in reading order, so the two side-code cells come
  // after the number cells even though they sit in a different zone of the
  // plate. That is fine and it is what `textGroups` is for: the keys below are
  // what restores the semantics, and `YemenUnifiedValidator` reads the plate by
  // key rather than by position.

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

  // ---------------------------------------------------------------------------
  // The plates. Six geometries x five usages. Each is a const, because adding a
  // plate here means adding a const and never anything else.
  //
  // The only fields that vary with usage are `id` and `country` — System A
  // prints the same white plate for a private car and a police car, and puts
  // the difference in the two caption lines of the blue panel. If you are
  // tempted to give a usage its own colour, read `YemenThemes`.
  // ---------------------------------------------------------------------------

  /// A five-digit private car plate: the length of the official mock-up sample
  /// `24378`, and the plate to reach for first.
  static const PlateSpec car5Private = PlateSpec(
    id: 'ye.unified.car5.private',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car5Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit private car plate.
  static const PlateSpec car4Private = PlateSpec(
    id: 'ye.unified.car4.private',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car4Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit private car plate.
  static const PlateSpec car6Private = PlateSpec(
    id: 'ye.unified.car6.private',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car6Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit taxi/bus car plate.
  static const PlateSpec car4ForHire = PlateSpec(
    id: 'ye.unified.car4.forHire',
    country: YemenCountry.unifiedForHire,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car4Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A five-digit taxi/bus car plate.
  static const PlateSpec car5ForHire = PlateSpec(
    id: 'ye.unified.car5.forHire',
    country: YemenCountry.unifiedForHire,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car5Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit taxi/bus car plate.
  static const PlateSpec car6ForHire = PlateSpec(
    id: 'ye.unified.car6.forHire',
    country: YemenCountry.unifiedForHire,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car6Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit goods-vehicle car plate.
  static const PlateSpec car4Transport = PlateSpec(
    id: 'ye.unified.car4.transport',
    country: YemenCountry.unifiedTransport,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car4Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A five-digit goods-vehicle car plate.
  static const PlateSpec car5Transport = PlateSpec(
    id: 'ye.unified.car5.transport',
    country: YemenCountry.unifiedTransport,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car5Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit goods-vehicle car plate.
  static const PlateSpec car6Transport = PlateSpec(
    id: 'ye.unified.car6.transport',
    country: YemenCountry.unifiedTransport,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car6Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit government car plate.
  static const PlateSpec car4Government = PlateSpec(
    id: 'ye.unified.car4.government',
    country: YemenCountry.unifiedGovernment,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car4Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A five-digit government car plate.
  static const PlateSpec car5Government = PlateSpec(
    id: 'ye.unified.car5.government',
    country: YemenCountry.unifiedGovernment,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car5Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit government car plate.
  static const PlateSpec car6Government = PlateSpec(
    id: 'ye.unified.car6.government',
    country: YemenCountry.unifiedGovernment,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car6Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit police car plate.
  static const PlateSpec car4Police = PlateSpec(
    id: 'ye.unified.car4.police',
    country: YemenCountry.unifiedPolice,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car4Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A five-digit police car plate.
  static const PlateSpec car5Police = PlateSpec(
    id: 'ye.unified.car5.police',
    country: YemenCountry.unifiedPolice,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car5Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit police car plate.
  static const PlateSpec car6Police = PlateSpec(
    id: 'ye.unified.car6.police',
    country: YemenCountry.unifiedPolice,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _car6Slots,
    rules: _carStipple,
    labels: _carLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A five-digit private motorcycle plate.
  static const PlateSpec moto5Private = PlateSpec(
    id: 'ye.unified.moto5.private',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto5Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit private motorcycle plate.
  static const PlateSpec moto4Private = PlateSpec(
    id: 'ye.unified.moto4.private',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto4Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit private motorcycle plate.
  static const PlateSpec moto6Private = PlateSpec(
    id: 'ye.unified.moto6.private',
    country: YemenCountry.unifiedPrivate,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto6Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit taxi/bus motorcycle plate.
  static const PlateSpec moto4ForHire = PlateSpec(
    id: 'ye.unified.moto4.forHire',
    country: YemenCountry.unifiedForHire,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto4Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A five-digit taxi/bus motorcycle plate.
  static const PlateSpec moto5ForHire = PlateSpec(
    id: 'ye.unified.moto5.forHire',
    country: YemenCountry.unifiedForHire,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto5Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit taxi/bus motorcycle plate.
  static const PlateSpec moto6ForHire = PlateSpec(
    id: 'ye.unified.moto6.forHire',
    country: YemenCountry.unifiedForHire,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto6Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit goods-vehicle motorcycle plate.
  static const PlateSpec moto4Transport = PlateSpec(
    id: 'ye.unified.moto4.transport',
    country: YemenCountry.unifiedTransport,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto4Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A five-digit goods-vehicle motorcycle plate.
  static const PlateSpec moto5Transport = PlateSpec(
    id: 'ye.unified.moto5.transport',
    country: YemenCountry.unifiedTransport,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto5Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit goods-vehicle motorcycle plate.
  static const PlateSpec moto6Transport = PlateSpec(
    id: 'ye.unified.moto6.transport',
    country: YemenCountry.unifiedTransport,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto6Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit government motorcycle plate.
  static const PlateSpec moto4Government = PlateSpec(
    id: 'ye.unified.moto4.government',
    country: YemenCountry.unifiedGovernment,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto4Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A five-digit government motorcycle plate.
  static const PlateSpec moto5Government = PlateSpec(
    id: 'ye.unified.moto5.government',
    country: YemenCountry.unifiedGovernment,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto5Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit government motorcycle plate.
  static const PlateSpec moto6Government = PlateSpec(
    id: 'ye.unified.moto6.government',
    country: YemenCountry.unifiedGovernment,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto6Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A four-digit police motorcycle plate.
  static const PlateSpec moto4Police = PlateSpec(
    id: 'ye.unified.moto4.police',
    country: YemenCountry.unifiedPolice,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto4Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A five-digit police motorcycle plate.
  static const PlateSpec moto5Police = PlateSpec(
    id: 'ye.unified.moto5.police',
    country: YemenCountry.unifiedPolice,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto5Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// A six-digit police motorcycle plate.
  static const PlateSpec moto6Police = PlateSpec(
    id: 'ye.unified.moto6.police',
    country: YemenCountry.unifiedPolice,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _moto6Slots,
    rules: _motoStipple,
    labels: _motoLabels,
    textGroups: _groups6,
    borderWidthRatioOverride: _borderRatio,
  );

  // ---------------------------------------------------------------------------
  // Lookups. Const maps over the consts above, so nothing here builds a spec.
  // ---------------------------------------------------------------------------

  /// Every car plate, by usage and then by number length.
  static const Map<YemenUsage, Map<int, PlateSpec>> car =
      <YemenUsage, Map<int, PlateSpec>>{
        YemenUsage.private: <int, PlateSpec>{
          4: car4Private,
          5: car5Private,
          6: car6Private,
        },
        YemenUsage.forHire: <int, PlateSpec>{
          4: car4ForHire,
          5: car5ForHire,
          6: car6ForHire,
        },
        YemenUsage.transport: <int, PlateSpec>{
          4: car4Transport,
          5: car5Transport,
          6: car6Transport,
        },
        YemenUsage.government: <int, PlateSpec>{
          4: car4Government,
          5: car5Government,
          6: car6Government,
        },
        YemenUsage.police: <int, PlateSpec>{
          4: car4Police,
          5: car5Police,
          6: car6Police,
        },
      };

  /// Every motorcycle plate, by usage and then by number length.
  static const Map<YemenUsage, Map<int, PlateSpec>> moto =
      <YemenUsage, Map<int, PlateSpec>>{
        YemenUsage.private: <int, PlateSpec>{
          4: moto4Private,
          5: moto5Private,
          6: moto6Private,
        },
        YemenUsage.forHire: <int, PlateSpec>{
          4: moto4ForHire,
          5: moto5ForHire,
          6: moto6ForHire,
        },
        YemenUsage.transport: <int, PlateSpec>{
          4: moto4Transport,
          5: moto5Transport,
          6: moto6Transport,
        },
        YemenUsage.government: <int, PlateSpec>{
          4: moto4Government,
          5: moto5Government,
          6: moto6Government,
        },
        YemenUsage.police: <int, PlateSpec>{
          4: moto4Police,
          5: moto5Police,
          6: moto6Police,
        },
      };

  /// The plates for [usage], keyed by how many digits the vehicle number has.
  ///
  /// Empty for a usage System A does not issue — [YemenUsage.military]. Ask
  /// `YemenUsage.onUnified` first if you want to grey the option out rather
  /// than discover it here.
  ///
  /// **Pick the length before entry begins.** Handing a live `PlateCanvas` a
  /// spec with a different id resets its bloc and empties every slot; see the
  /// class doc.
  static Map<int, PlateSpec> byNumberLength(
    YemenUsage usage, {
    bool motorcycle = false,
  }) => (motorcycle ? moto : car)[usage] ?? const <int, PlateSpec>{};

  /// The number lengths a unified plate can have, shortest first.
  static const List<int> numberLengths = <int>[4, 5, 6];
}
