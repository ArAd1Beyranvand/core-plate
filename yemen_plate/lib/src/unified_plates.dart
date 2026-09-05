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
  /// **This is the honest option of the two available, and it is verbose.**
  /// `core_plate` has [PlateRule], which paints one solid box, and no stippled
  /// or dashed primitive; the alternatives were a single solid rule with a
  /// `TODO` saying the stipple is unimplemented, or this — a column of sixteen
  /// short rules, one per dot. This one wins because it is *data*: the dots are
  /// where they are said to be, a recalibration of the pitch is an edit to this
  /// list, and nothing was added to `core_plate` to make it work.
  ///
  /// The strip's x is measured (0.818 .. 0.827, so 838 wide 9). The pitch is
  /// not: at the photograph's resolution the dashes blur into a near-solid
  /// hairline, and 24 dots on a 12-unit pitch is what reproduces that reading
  /// rather than a count of anything. Hence `// CALIBRATE` on the pitch alone.
  static const List<PlateRule> _carStipple = <PlateRule>[
    PlateRule(box: PlateBox(838, 1, 9, 7)), // CALIBRATE dot pitch
    PlateRule(box: PlateBox(838, 13, 9, 7)),
    PlateRule(box: PlateBox(838, 25, 9, 7)),
    PlateRule(box: PlateBox(838, 37, 9, 7)),
    PlateRule(box: PlateBox(838, 49, 9, 7)),
    PlateRule(box: PlateBox(838, 61, 9, 7)),
    PlateRule(box: PlateBox(838, 73, 9, 7)),
    PlateRule(box: PlateBox(838, 85, 9, 7)),
    PlateRule(box: PlateBox(838, 97, 9, 7)),
    PlateRule(box: PlateBox(838, 109, 9, 7)),
    PlateRule(box: PlateBox(838, 121, 9, 7)),
    PlateRule(box: PlateBox(838, 133, 9, 7)),
    PlateRule(box: PlateBox(838, 145, 9, 7)),
    PlateRule(box: PlateBox(838, 157, 9, 7)),
    PlateRule(box: PlateBox(838, 169, 9, 7)),
    PlateRule(box: PlateBox(838, 181, 9, 7)),
    PlateRule(box: PlateBox(838, 193, 9, 7)),
    PlateRule(box: PlateBox(838, 205, 9, 7)),
    PlateRule(box: PlateBox(838, 217, 9, 7)),
    PlateRule(box: PlateBox(838, 229, 9, 7)),
    PlateRule(box: PlateBox(838, 241, 9, 7)),
    PlateRule(box: PlateBox(838, 253, 9, 7)),
    PlateRule(box: PlateBox(838, 265, 9, 7)),
    PlateRule(box: PlateBox(838, 277, 9, 7)),
  ];

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
  static const List<PlateSlot> _car4Slots = <PlateSlot>[
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(292, 14, 135, 264)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(427, 14, 135, 264)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(562, 14, 135, 264)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(697, 14, 135, 264)),
    _carSideCodeHigh,
    _carSideCodeLow,
  ];

  /// Five number cells plus the two side-code cells — the length of the
  /// photographed plate, `24378`.
  static const List<PlateSlot> _car5Slots = <PlateSlot>[
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(292, 15, 108, 258)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(400, 15, 108, 258)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(508, 15, 108, 258)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(616, 15, 108, 258)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(724, 15, 108, 258)),
    _carSideCodeHigh,
    _carSideCodeLow,
  ];

  /// Six number cells plus the two side-code cells.
  static const List<PlateSlot> _car6Slots = <PlateSlot>[
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(292, 31, 90, 215)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(382, 31, 90, 215)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(472, 31, 90, 215)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(562, 31, 90, 215)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(652, 31, 90, 215)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(742, 31, 90, 215)),
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
  static const List<PlateRule> _motoStipple = <PlateRule>[
    PlateRule(box: PlateBox(15, 197, 5, 5)), // CALIBRATE dot pitch
    PlateRule(box: PlateBox(27, 197, 5, 5)),
    PlateRule(box: PlateBox(39, 197, 5, 5)),
    PlateRule(box: PlateBox(51, 197, 5, 5)),
    PlateRule(box: PlateBox(63, 197, 5, 5)),
    PlateRule(box: PlateBox(75, 197, 5, 5)),
    PlateRule(box: PlateBox(87, 197, 5, 5)),
    PlateRule(box: PlateBox(99, 197, 5, 5)),
    PlateRule(box: PlateBox(111, 197, 5, 5)),
    PlateRule(box: PlateBox(123, 197, 5, 5)),
    PlateRule(box: PlateBox(135, 197, 5, 5)),
    PlateRule(box: PlateBox(147, 197, 5, 5)),
    PlateRule(box: PlateBox(159, 197, 5, 5)),
    PlateRule(box: PlateBox(171, 197, 5, 5)),
    PlateRule(box: PlateBox(183, 197, 5, 5)),
    PlateRule(box: PlateBox(195, 197, 5, 5)),
    PlateRule(box: PlateBox(207, 197, 5, 5)),
    PlateRule(box: PlateBox(219, 197, 5, 5)),
    PlateRule(box: PlateBox(231, 197, 5, 5)),
    PlateRule(box: PlateBox(243, 197, 5, 5)),
    PlateRule(box: PlateBox(255, 197, 5, 5)),
    PlateRule(box: PlateBox(267, 197, 5, 5)),
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _carHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
    canvasHeight: _motoHeight,
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
  /// Handing a live `PlateCanvas` a spec with a different id carries the value
  /// across per `PlateCanvas.onSpecChange`; with `byGroupKey` a change of
  /// length keeps the digits that still fit. See the class doc.
  static Map<int, PlateSpec> byNumberLength(
    YemenUsage usage, {
    bool motorcycle = false,
  }) => (motorcycle ? moto : car)[usage] ?? const <int, PlateSpec>{};

  /// The number lengths a unified plate can have, shortest first.
  static const List<int> numberLengths = <int>[4, 5, 6];
}
