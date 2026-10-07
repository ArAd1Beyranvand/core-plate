import 'package:plate_core/plate_core.dart';
import 'package:flutter/widgets.dart';

import '../common/yemen_alphabets.dart';
import '../common/yemen_country.dart';

/// System B — the 1993 format, still the larger share of the fleet. A top band
/// (اليمن + usage word) over a left/right split (governorate code + serial).
/// Colour-coded by usage (blue/yellow/red/green/black for private/hire/transport/govt/military);
/// colour lives in [YemenThemes], not here. One spec per layout (gov 1–2 digits × serial 4–6).
// TODO(northern-lengths): serial 1–3 digits are legal but unbuilt; add with a reference image.
abstract final class YemenNorthernPlates {
  // ---------------------------------------------------------------------------
  // Shared geometry.
  // ---------------------------------------------------------------------------

  // 540 x 288 (aspect 1.875) measured from an issued blue private plate.
  // Coordinates below are measured fractions multiplied out; comments give fraction, code gives units.
  static const double _carWidth = 540;
  static const double _height = 288;
  static const double _motoWidth = 289; // CALIBRATE: no photo available
  static const double _borderRatio = 0.035; // CALIBRATE: matches theme ratio

  // Car: top band, full-width rule, then one row split by vertical divider
  // (governorate left, serial right), measured off photograph:
  //   top band     y 0.038 .. 0.219
  //   rule         y 0.289 .. 0.314   full width
  //   divider      x 0.246 .. 0.260   from rule bottom to frame
  //   governorate  x 0.006 .. 0.246   y 0.331 .. 0.641
  //   serial       x 0.260 .. 0.983   y 0.331 .. 0.641
  //
  // Single row split by divider (not stacked). Big arabic row with small Latin
  // mirrors below (one value in two scripts, editable in both).

  /// اليمن on the left (x 0.076 .. 0.231). Separate label (not joined to usage word
  /// to keep bidi isolated). Box is wider than measured text and centred on it
  /// to account for platform font fallback width. Dash is its own label (not appended).
  static const List<PlateLabel> _carLabels = <PlateLabel>[];

  /// Usage word as the country panel caption (full width, x 0.027 .. 0.987,
  /// y 0.038 .. 0.219). Panel is transparent; the word prints on the field.
  /// captionScale fits down only, never up, so scale must size for fit to bind.
  static const PlatePanel _carPanel = PlatePanel(
    box: PlateBox(0, 6, 540, 62),
    flagScale: 0, // No flag on a Yemeni plate
    captionScale: 4.5,
    padding: EdgeInsets.fromLTRB(50, 3, 50, 0),
  );

  // Full-width divider under the top band (y 0.289 .. 0.314: 83 .. 90), then a
  // vertical one between governorate and serial cells (x 0.246 .. 0.260:
  // 133 .. 140) from that divider down to the frame. Same for every car
  // layout regardless of digit counts.
  static const PlateSection _carBackground = PlateSection.rows(<PlatePart>[
    PlatePart(PlateSection.plain, end: 86.5, divider: 7),
    PlatePart(
      PlateSection.columns(<PlatePart>[
        PlatePart(PlateSection.plain, end: 136.5, divider: 7),
        PlatePart(PlateSection.plain),
      ]),
    ),
  ]);

  // The governorate cell: x 0.006 .. 0.246 of the plate (3 .. 133), the same
  // 89-unit cap height as the serial cell beside it — unlike the old stacked
  // layout, the two are optically equal now, because the photograph shows one
  // row, not a smaller register over a larger one.
  //
  // On turning a measured cap height into a cell height: core sets a glyph at
  // `0.72 * cellHeight` and names no font family, so these render in Roboto,
  // whose cap is 0.711 em. A cell is therefore `0.512 * cellHeight` of cap.
  // This package cannot supply the plate's own square Kufic — see the
  // README's `## Fonts`.
  //
  // The tens cell is drawn over `YemenAlphabets.governorateTens` — three
  // characters, because a code that never exceeds 22 can only start 0, 1 or 2.
  // That restriction is an input affordance, not validation: entering 23 is
  // still possible through other paths and `YemenNorthernValidator` is what
  // rejects it.
  static const PlateSlot _carGovTens = PlateSlot(
    alphabet: YemenAlphabets.iranianGovernorateTens,
    box: PlateBox(24, 95, 44, 89),
  );
  static const PlateSlot _carGovUnits = PlateSlot(
    alphabet: YemenAlphabets.iranianDigits,
    box: PlateBox(68, 95, 44, 89),
  );

  /// A lone governorate digit, centred in the same cell the pair straddles.
  static const PlateSlot _carGovSingle = PlateSlot(
    alphabet: YemenAlphabets.iranianDigits,
    box: PlateBox(38, 95, 60, 89),
  );

  // The serial cell: x 0.260 .. 0.983 of the plate (140 .. 531), split evenly
  // across four, five or six digits. Cap height and top match the
  // governorate cell — both sit in the one row the photograph shows.
  //
  // All slots keep the cell's full share of the row's width rather than a
  // narrower glyph box with a gap, matching how the old serial register
  // divided its own width; a host supplying the plate's own condensed face
  // will show tighter digits, not overflow.

  // Serial span: x 140 .. 530. Each length divides the span evenly; all end at same right edge.
  static const double _serialLeft = 140;
  static const double _serialRight = 530;

  // Serial digits alone (without governorate cells).
  static List<PlateSlot> _carSerial(int count) => plateRegisterAcross(
    alphabet: YemenAlphabets.iranianDigits,
    count: count,
    left: _serialLeft,
    right: _serialRight,
    top: 95,
    height: 89,
  );

  static final List<PlateSlot> _carGov2Serial4 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    ..._carSerial(4),
  ];

  static final List<PlateSlot> _carGov2Serial5 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    ..._carSerial(5),
  ];

  static final List<PlateSlot> _carGov2Serial6 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    ..._carSerial(6),
  ];

  // One governorate digit, five-digit serial — the layout measured from the photograph.
  static final List<PlateSlot> _carGov1Serial5 = <PlateSlot>[
    _carGovSingle,
    ..._carSerial(5),
  ];

  // Small Latin echo row (y 0.697 .. 0.882, cap 0.185 = 53 units, box 104 units).
  // Box is deeper than cap to prevent clipping. Each mirror takes its source's x/width.
  static const double _echoTop = 175;
  static const double _echoHeight = 104;

  static const PlateMirror _carEchoGovTens = PlateMirror(
    source: 0,
    box: PlateBox(24, _echoTop, 44, _echoHeight),
    glyphHeight: _echoHeight,
    alphabet: YemenAlphabets.digits,
    editable: true,
  );
  static const PlateMirror _carEchoGovUnits = PlateMirror(
    source: 1,
    box: PlateBox(68, _echoTop, 44, _echoHeight),
    glyphHeight: _echoHeight,
    alphabet: YemenAlphabets.digits,
    editable: true,
  );

  // Echo under [_carGovSingle], straddling the pair's two cells.
  static const PlateMirror _carEchoGovSingle = PlateMirror(
    source: 0,
    box: PlateBox(38, _echoTop, 60, _echoHeight),
    glyphHeight: _echoHeight,
    alphabet: YemenAlphabets.digits,
    editable: true,
  );

  // Echo band under [count] serial digits. Same span and division as [_carSerial].
  static List<PlateMirror> _carEcho(int count, int firstSource) => plateEcho(
    sources: List<int>.generate(count, (i) => firstSource + i),
    left: _serialLeft,
    top: _echoTop,
    width: (_serialRight - _serialLeft) / count,
    height: _echoHeight,
    alphabet: YemenAlphabets.digits,
    editable: true,
  );

  static final List<PlateMirror> _carMirrorsGov2Serial4 = <PlateMirror>[
    _carEchoGovTens,
    _carEchoGovUnits,
    ..._carEcho(4, 2),
  ];

  static final List<PlateMirror> _carMirrorsGov2Serial5 = <PlateMirror>[
    _carEchoGovTens,
    _carEchoGovUnits,
    ..._carEcho(5, 2),
  ];

  static final List<PlateMirror> _carMirrorsGov2Serial6 = <PlateMirror>[
    _carEchoGovTens,
    _carEchoGovUnits,
    ..._carEcho(6, 2),
  ];

  static final List<PlateMirror> _carMirrorsGov1Serial5 = <PlateMirror>[
    _carEchoGovSingle,
    ..._carEcho(5, 1),
  ];

  // Motorcycle: row-and-divider structure from car, widths compressed to square canvas.
  // No photo available; x values are car's ratios renormalised, y values unchanged.
  // Vertical layout carries across 1:1 (both canvases 288 tall).

  // اليمن keeping 1 : 2.41 width ratio against usage word. Glyph height 42 (not 62)
  // to prevent clipping on the narrower canvas.
  static const List<PlateLabel> _motoLabels = <PlateLabel>[];

  static const PlatePanel _motoPanel = PlatePanel(
    box: PlateBox(0, 6, 289, 62),
    flagScale: 0,
    captionScale: 4.5,
    padding: EdgeInsets.fromLTRB(25, 3, 25, 0),
  );

  // Same row-and-divider structure as the car, renormalised onto the
  // narrower canvas: full-width rule under the top band, then one vertical
  // divider splitting a governorate cell (left) from a five-digit serial
  // cell (right) — no second horizontal rule inside the row.
  static const PlateSection _motoBackground = PlateSection.rows(<PlatePart>[
    PlatePart(PlateSection.plain, end: 86.5, divider: 7),
    PlatePart(
      PlateSection.columns(<PlatePart>[
        PlatePart(PlateSection.plain, end: 73, divider: 4),
        PlatePart(PlateSection.plain),
      ]),
    ),
  ]);

  /// The motorcycle serial's own span and pitch: five cells from x 75, stepping
  /// by 41.8. The cells are 42 wide, a fifth of a unit more than the stride, so
  /// this states its pitch rather than running flush.
  static const double _motoSerialLeft = 75;
  static const double _motoSerialPitch = 41.8;

  static final List<PlateSlot> _motoGov2Serial5 = <PlateSlot>[
    const PlateSlot(
      alphabet: YemenAlphabets.iranianGovernorateTens,
      box: PlateBox(13, 95, 24, 89),
    ),
    const PlateSlot(
      alphabet: YemenAlphabets.iranianDigits,
      box: PlateBox(37, 95, 24, 89),
    ),
    ...plateRegister(
      alphabet: YemenAlphabets.iranianDigits,
      count: 5,
      left: _motoSerialLeft,
      top: 95,
      width: 42,
      height: 89,
      pitch: _motoSerialPitch,
    ),
  ];

  /// The small Latin echo row on the motorcycle plate.
  ///
  /// Same band as the car's — y 175 .. 279, unchanged, because the vertical
  /// layout carries across both canvases untouched — and each mirror takes its
  /// source slot's x and width, as on the car.
  ///
  /// The glyph is set at 56 rather than the car's 104, and that is the same
  /// correction [_motoLabels] carries: a mirror renders as a `Text` in a fixed
  /// box, so a glyph wider than its box wraps and clips instead of overhanging.
  /// The governorate cells here are 24 units wide against the car's 44, and a
  /// Roboto digit runs about `0.41 * height` wide, so 104 would clip both of
  /// them. 56 fits the narrowest cell and is used across the row so the echo
  /// stays one size. Like every other horizontal number on this canvas it is
  /// derived, not measured — no photograph of a northern motorcycle plate was
  /// available.
  static const double _motoEchoHeight = 56;

  static final List<PlateMirror> _motoMirrorsGov2Serial5 = <PlateMirror>[
    const PlateMirror(
      source: 0,
      box: PlateBox(13, _echoTop, 24, _echoHeight),
      glyphHeight: _motoEchoHeight,
      alphabet: YemenAlphabets.digits,
      editable: true,
    ),
    const PlateMirror(
      source: 1,
      box: PlateBox(37, _echoTop, 24, _echoHeight),
      glyphHeight: _motoEchoHeight,
      alphabet: YemenAlphabets.digits,
      editable: true,
    ),
    // The same span and pitch as the serial above, so an echo cannot sit
    // anywhere but under the digit it echoes.
    ...plateEcho(
      sources: const <int>[2, 3, 4, 5, 6],
      left: _motoSerialLeft,
      top: _echoTop,
      width: 42,
      height: _echoHeight,
      pitch: _motoSerialPitch,
      glyphHeight: _motoEchoHeight,
      alphabet: YemenAlphabets.digits,
      editable: true,
    ),
  ];

  // --- Text groups. ---------------------------------------------------------

  static const List<PlateTextGroup> _groupsGov2Serial4 = <PlateTextGroup>[
    PlateTextGroup(<int>[0, 1], key: 'governorate'),
    PlateTextGroup(<int>[2, 3, 4, 5], key: 'serial'),
  ];
  static const List<PlateTextGroup> _groupsGov2Serial5 = <PlateTextGroup>[
    PlateTextGroup(<int>[0, 1], key: 'governorate'),
    PlateTextGroup(<int>[2, 3, 4, 5, 6], key: 'serial'),
  ];
  static const List<PlateTextGroup> _groupsGov2Serial6 = <PlateTextGroup>[
    PlateTextGroup(<int>[0, 1], key: 'governorate'),
    PlateTextGroup(<int>[2, 3, 4, 5, 6, 7], key: 'serial'),
  ];
  static const List<PlateTextGroup> _groupsGov1Serial5 = <PlateTextGroup>[
    PlateTextGroup(<int>[0], key: 'governorate'),
    PlateTextGroup(<int>[1, 2, 3, 4, 5], key: 'serial'),
  ];

  // ---------------------------------------------------------------------------
  // Car plates. One spec per geometry — four of them, where there used to be
  // four layouts crossed with five usages.
  //
  // **Usage is not a field of a spec.** It selects the country block (which
  // carries the usage word) and the theme (which carries the field colour), and
  // both are render-time inputs on `PlateCanvas`:
  //
  // ```dart
  // PlateCanvas(
  //   spec: YemenNorthernPlates.car(governorateDigits: 2, serialDigits: 5)!,
  //   country: YemenCountry.northernFor(usage),
  //   theme: YemenThemes.forNorthernUsage(usage),
  // )
  // ```
  //
  // Each spec names `YemenCountry.northernPrivate` as its own `country`, so a
  // caller that passes no override gets the ordinary case rather than a blank
  // top band. `PlateSpec.country` is a default, not a claim about the vehicle.
  // ---------------------------------------------------------------------------

  /// Two governorate digits, a five-digit serial — the layout the car
  /// photograph is measured from.
  static final PlateSpec carGov2Serial5 = PlateSpec(
    id: 'ye.northern.car.g2s5',
    country: YemenCountry.northernPrivate,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _carGov2Serial5,
    mirrors: _carMirrorsGov2Serial5,
    background: _carBackground,
    labels: _carLabels,
    textGroups: _groupsGov2Serial5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// One governorate digit, a five-digit serial.
  static final PlateSpec carGov1Serial5 = PlateSpec(
    id: 'ye.northern.car.g1s5',
    country: YemenCountry.northernPrivate,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _carGov1Serial5,
    mirrors: _carMirrorsGov1Serial5,
    background: _carBackground,
    labels: _carLabels,
    textGroups: _groupsGov1Serial5,
    borderWidthRatioOverride: _borderRatio,
  );

  /// Two governorate digits, a four-digit serial.
  static final PlateSpec carGov2Serial4 = PlateSpec(
    id: 'ye.northern.car.g2s4',
    country: YemenCountry.northernPrivate,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _carGov2Serial4,
    mirrors: _carMirrorsGov2Serial4,
    background: _carBackground,
    labels: _carLabels,
    textGroups: _groupsGov2Serial4,
    borderWidthRatioOverride: _borderRatio,
  );

  /// Two governorate digits, a six-digit serial.
  static final PlateSpec carGov2Serial6 = PlateSpec(
    id: 'ye.northern.car.g2s6',
    country: YemenCountry.northernPrivate,
    canvasWidth: _carWidth,
    canvasHeight: _height,
    panel: _carPanel,
    slots: _carGov2Serial6,
    mirrors: _carMirrorsGov2Serial6,
    background: _carBackground,
    labels: _carLabels,
    textGroups: _groupsGov2Serial6,
    borderWidthRatioOverride: _borderRatio,
  );

  // ---------------------------------------------------------------------------
  // Motorcycle plates — unverified.
  //
  // No official motorcycle design has been published for the northern system,
  // despite active registration campaigns run by the Sanaa traffic police under
  // Cabinet Decision No. 33 of 1446 AH and an equivalent process in Taiz. What
  // follows is the car's content rendered into the motorcycle form factor: the
  // same content, the same stacking, half the width. It is a reasonable guess
  // and it is a guess, so it is deprecated — not because it is going away, but
  // so that nothing silently trusts it and so it shows up in a grep.
  //
  // One colour note that does not generalise: Marib classifies motorcycles as
  // yellow. Other southern governorates publish no motorcycle colour, and
  // extrapolating Marib's rule to them would be inventing policy.
  // ---------------------------------------------------------------------------

  /// Two governorate digits, a five-digit serial, on the motorcycle canvas.
  @Deprecated('unverified geometry — calibrate against photographs')
  static final PlateSpec motoGov2Serial5 = PlateSpec(
    id: 'ye.northern.moto.g2s5',
    country: YemenCountry.northernPrivate,
    canvasWidth: _motoWidth,
    canvasHeight: _height,
    panel: _motoPanel,
    slots: _motoGov2Serial5,
    mirrors: _motoMirrorsGov2Serial5,
    background: _motoBackground,
    labels: _motoLabels,
    textGroups: _groupsGov2Serial5,
    borderWidthRatioOverride: _borderRatio,
  );

  // ---------------------------------------------------------------------------
  // Lookups. Keyed by geometry alone — there is no usage axis left to key on.
  // ---------------------------------------------------------------------------

  /// The car geometries this package builds, keyed by
  /// `(governorate digits, serial digits)`. A combination that is missing is
  /// missing on purpose; see the class-level TODO.
  static final Map<(int, int), PlateSpec> carGeometries =
      <(int, int), PlateSpec>{
        (2, 5): carGov2Serial5,
        (1, 5): carGov1Serial5,
        (2, 4): carGov2Serial4,
        (2, 6): carGov2Serial6,
      };

  /// The motorcycle geometries this package builds — one, and unverified.
  static final Map<(int, int), PlateSpec> motoGeometries =
      <(int, int), PlateSpec>{
        // ignore: deprecated_member_use_from_same_package
        (2, 5): motoGov2Serial5,
      };

  /// The northern car plate with this register shape, or null when the
  /// combination is not one this package builds.
  ///
  /// Usage is not a parameter. It selects the country block and the field
  /// colour, both of which the host passes to the canvas:
  /// `country: YemenCountry.northernFor(usage)`,
  /// `theme: YemenThemes.forNorthernUsage(usage)`.
  ///
  /// Swapping `spec:` on a live `PlateCanvas` between two of these carries the
  /// value across per `PlateCanvas.onSpecChange`. With `byGroupKey` a change of
  /// serial length keeps the serial and the governorate, truncating only the
  /// digits that no longer fit.
  static PlateSpec? car({
    required int governorateDigits,
    required int serialDigits,
  }) => carGeometries[(governorateDigits, serialDigits)];

  /// The northern motorcycle plate with this register shape, or null. Its
  /// geometry is unverified — see the section comment above [motoGov2Serial5].
  static PlateSpec? moto({
    required int governorateDigits,
    required int serialDigits,
  }) => motoGeometries[(governorateDigits, serialDigits)];
}
