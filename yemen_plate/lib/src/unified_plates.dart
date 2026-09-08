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
/// side panel — a country block, which the host hands to `PlateCanvas` at
/// render time. So each geometry appears **once**, and the usage axis is
/// `YemenCountry.unifiedFor(usage)` passed alongside the spec.
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
/// [car] and [moto] taking a length, and hence the caveat that goes with them:
///
/// > **Swapping `spec:` on a live `PlateCanvas` carries the value across** as
/// > `PlateCanvas.onSpecChange` directs. With `byGroupKey` a change of number
/// > length keeps the digits already entered and truncates only those the
/// > shorter plate has no slot for, so a host can let the length change mid
/// > entry.
///
/// One spec still cannot cover every length — the count itself differs, and a
/// slot either exists or it does not — but the register-matching migration
/// means splitting the geometries no longer costs the input entered so far.
///
/// ### Geometry
///
/// The car canvas is 1024 x 292 — an aspect ratio of 3.51, measured off a
/// photograph of an issued plate rather than taken from a standard. Every
/// number below that is not marked otherwise was measured from that photograph
/// as a fraction of the plate's width or height and then multiplied out, so the
/// comments give the fraction and the code gives the unit:
///
/// | element        | measured                              |
/// | -------------- | ------------------------------------- |
/// | country block  | x 0.027 .. 0.276                      |
/// | vehicle number | x 0.304 .. 0.777, cap top 0.197 h 0.557 |
/// | stipple strip  | x 0.818 .. 0.827                      |
/// | blue panel     | x 0.827 .. 0.987                      |
/// | side code      | x 0.876 .. 0.947, y 0.149 .. 0.374    |
/// | usage caption  | y 0.590 .. 0.775                      |
///
/// The motorcycle canvas is 289 x 288 and is **not** measured — no photograph
/// of a unified motorcycle plate was available, so it stays `// CALIBRATE`
/// throughout and is a reflow of the car's content, not a record of anything.
///
/// ### Why the digits are shorter here than in the photograph
///
/// The plate's cap height is 0.557 of the plate; the digits below reach about
/// 0.46, and the gap is the font. Core sets a glyph at `0.72 * cellHeight` and
/// names no family (see the README's `## Fonts`), so these render in Roboto,
/// whose cap is 0.711 em and whose digit advance is 0.562 em. A cell is
/// therefore `0.512 * cellHeight` of cap but `0.41 * cellHeight` of width, and
/// the real plate's FE-Schrift is far narrower than that. Matching the cap
/// exactly would need a cell 318 units tall on a 292-unit canvas — the glyphs
/// would fit, and their underlines would fall off the plate.
///
/// So height is traded for width: the number zone is widened past the
/// photograph's 0.777 to 0.812 (it has nothing but white space to its right
/// until the stipple), and the cell is then the largest that fits both the
/// canvas and its own share of that zone. Four and five digits are bound by the
/// canvas and reach 0.46; six are bound by width and reach 0.38.
abstract final class YemenUnifiedPlates {
  // ---------------------------------------------------------------------------
  // Shared geometry. Declared once and referenced by every spec below, so a
  // recalibration is one edit rather than thirty, and so each spec const is
  // short enough to read as what it is: a geometry crossed with a usage.
  // ---------------------------------------------------------------------------

  /// 1024 x 292 is the measured 3.51 aspect ratio at a round width.
  static const double _carWidth = 1024;
  static const double _carHeight = 292;

  /// The motorcycle plate keeps its own square-ish canvas, and unlike the car's
  /// it is a guess: no photograph of one was available.
  static const double _motoWidth = 289; // CALIBRATE
  static const double _motoHeight = 288; // CALIBRATE

  /// Matches `YemenThemes._borderWidthRatio`, and is repeated on every spec via
  /// [PlateSpec.borderWidthRatioOverride] so the geometry survives a host that
  /// supplies its own theme.
  static const double _borderRatio = 0.035; // CALIBRATE

  // --- Car: the four zones, left to right on a 1024-wide canvas. ------------
  //
  //   A  country block   x  28 ..  283   (0.027 .. 0.276)
  //   B  vehicle number  x 292 ..  832   (0.285 .. 0.812, widened — see above)
  //   C1 stipple strip   x 838 ..  847   (0.818 .. 0.827)
  //   C2 blue panel      x 847 .. 1024   (0.827 .. 0.987, run to the edge)

  /// Zone C2. The blue slab down the right edge, overlapping the frame on the
  /// three edges it touches rather than sitting flush at the border thickness:
  /// core clips panel paint back to the rounded face, so extending it under the
  /// frame kills the hairline seam a flush edge leaves once the whole canvas is
  /// scaled. That overlap is why the box runs to 1024 where the photograph's
  /// blue stops at 0.987 — the last 1.3% is under the frame.
  ///
  /// The padding is what puts the usage caption at y 0.590 .. 0.775, clear of
  /// the side-code cells above it: `CountryPanel` lays a flag out at the top
  /// and the caption at the bottom, and with `flagScale: 0` the caption is
  /// handed the whole inner box, so the inner box is where the caption goes.
  /// The top inset is therefore the caption's measured top.
  static const PlatePanel _carPanel = PlatePanel(
    box: PlateBox(847, 0, 177, _carHeight),
    // No flag on a Yemeni plate; do not reserve a strip for a null image.
    flagScale: 0,
    captionScale: 1.6,
    // Top 172 = 0.590 * 292, bottom 66 leaves the caption its measured 0.185.
    padding: EdgeInsets.fromLTRB(22, 172, 16, 66),
  );

  /// Zone A. Two labels, not one.
  ///
  /// `اليمن` and `YEMEN` are kept as separate [PlateLabel]s rather than joined
  /// into one string with a newline, and the reason is bidi: [PlateLabel] has
  /// no `TextDirection` and core lays a label out exactly as given, so an
  /// Arabic label on its own is an isolated run and renders correctly, while
  /// concatenating it with a Latin one would hand the bidi algorithm a mixed
  /// paragraph and let it reorder the two.
  ///
  /// Both labels span the block's measured x 0.027 .. 0.276, i.e. 28 .. 283.
  ///
  /// `YEMEN`'s glyph height is the measurement: its cap band is 0.175 of the
  /// plate, or 51 units, and core's cap is `0.512 * glyphHeight`. `اليمن` is
  /// set larger because its measured band (0.220) includes the ascender of the
  /// lam and the tail of the nun, which a cap height does not.
  static const List<PlateLabel> _carLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(28, 60, 255, 96), glyphHeight: 118),
    PlateLabel(text: 'YEMEN', box: PlateBox(28, 156, 255, 76), glyphHeight: 100),
  ];

  /// Zone C1 — the narrow stippled strip immediately left of the blue panel.
  ///
  /// `core_plate` has [PlateRule], which paints one solid box, and no stippled
  /// or dashed primitive; the alternatives were a single solid rule with a
  /// `TODO` saying the stipple is unimplemented, or this — a column of short
  /// rules, one per dot. This one wins because it is *data*: the dots are where
  /// they are said to be, a recalibration of the pitch is an edit to one number,
  /// and nothing was added to `core_plate` to make it work.
  ///
  /// It used to be twenty-four literals in twenty-six lines — a for-loop
  /// unrolled by hand. [plateStipple] is that loop, so the pitch is now stated
  /// once instead of being implied by twenty-four `top` values.
  ///
  /// The strip's x is measured (0.818 .. 0.827, so 838 wide 9). The pitch is
  /// not: at the photograph's resolution the dashes blur into a near-solid
  /// hairline, and 24 dots on a 12-unit pitch is what reproduces that reading
  /// rather than a count of anything. Hence `// CALIBRATE` on the pitch alone.
  static final List<PlateRule> _carStipple = plateStipple(
    count: 24,
    left: 838,
    top: 1,
    width: 9,
    height: 7,
    stepY: 12, // CALIBRATE dot pitch
  );

  // The two side-code cells, in the blue panel's upper third.
  //
  // The photograph puts the pair's glyphs at x 0.876 .. 0.947 on a 40-unit
  // pitch, with a cap of 0.225 of the plate. A 40-unit pitch cannot hold a
  // Roboto digit at that cap (it would want 53 of advance), so the pair keeps
  // its measured centre — x 933 — and is widened to a 52-unit pitch either side
  // of it. The cell height then follows from the pitch, and the cap lands at
  // 0.218 against the measured 0.225.
  static const PlateSlot _carSideCodeHigh = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(881, 14, 52, 124),
  );
  static const PlateSlot _carSideCodeLow = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(933, 14, 52, 124),
  );

  /// Four number cells plus the two side-code cells.
  ///
  /// **On cell size**, and why the three lengths do not share one: see the
  /// class doc's note on the font. The cell is the largest that fits both the
  /// canvas — 264 units between the frames — and its own share of the widened
  /// number zone, x 292 .. 832. Four digits get a 135-unit share and are bound
  /// by the canvas; six get 90 and are bound by that.
  ///
  /// Cell tops centre each cell's cap on the photograph's cap band, which runs
  /// y 0.197 .. 0.754, clamped off the frame.
  /// The number register is stated by the span it fills — x 292 .. 832 — rather
  /// than by cell width, so four, five and six cells all end flush at the same
  /// right edge and the width is arithmetic rather than a typed number: 135,
  /// 108, 90. Only the cell's top and height differ per length.
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

  /// Five number cells plus the two side-code cells — the length of the
  /// photographed plate, `24378`.
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

  /// Six number cells plus the two side-code cells.
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
    // A size to fit *down* from, not the rendered size — see [_carPanel].
    captionScale: 2.0, // CALIBRATE
    // A big left inset is what pushes the caption to the right-hand end of the
    // band: `CountryPanel` aligns its caption to the start of the inner box,
    // and core exposes no alignment on a panel, so the inset is the lever.
    padding: EdgeInsets.fromLTRB(96, 12, 12, 12), // CALIBRATE
  );

  static const List<PlateLabel> _motoLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(16, 14, 110, 42), glyphHeight: 42),
    PlateLabel(text: 'YEMEN', box: PlateBox(150, 20, 120, 30), glyphHeight: 30),
  ];

  /// The stipple, horizontal, immediately above the blue bottom band.
  ///
  /// Twenty-two dots on the car's 12-unit pitch, so the two plates read as the
  /// same printing. The pitch is the car's `// CALIBRATE` value, inherited: the
  /// car's strip position is measured but its dot spacing is not.
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

  /// Unlike the car's, the motorcycle registers are gapped rather than flush —
  /// the cells are narrower than their stride — so each states its pitch.
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
  // The plates. One spec per geometry — six of them, where there used to be six
  // geometries crossed with five usages.
  //
  // **Usage is not a field of a spec.** System A prints the same white plate
  // for a private car and a police car and puts the difference in the two
  // caption lines of the blue panel, so usage selects the country block, which
  // the host passes at render time:
  //
  // ```dart
  // PlateCanvas(
  //   spec: YemenUnifiedPlates.car(numberDigits: 5)!,
  //   country: YemenCountry.unifiedFor(usage),
  //   theme: YemenThemes.forUnifiedUsage(usage),
  // )
  // ```
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

  /// The plates for [usage], keyed by how many digits the vehicle number has.
  ///
  /// Still empty for [YemenUsage.military], which System A does not issue — but
  /// every usage System A *does* issue now returns the same geometries, because
  /// the usage never varied the geometry in the first place.
  @Deprecated(
    'Usage no longer selects a spec — it selects a country block. '
    'Use car()/moto() and pass YemenCountry.unifiedFor(usage) to the canvas. '
    'Will be removed in 0.4.0.',
  )
  static Map<int, PlateSpec> byNumberLength(
    YemenUsage usage, {
    bool motorcycle = false,
  }) => usage.onUnified
      ? (motorcycle ? motoGeometries : carGeometries)
      : const <int, PlateSpec>{};

  /// The number lengths a unified plate can have, shortest first.
  static const List<int> numberLengths = <int>[4, 5, 6];
}
