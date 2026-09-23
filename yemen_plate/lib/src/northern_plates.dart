import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'yemen_alphabets.dart';
import 'yemen_country.dart';

/// **System B** — the 1993 format, still in force across the Houthi-controlled
/// north, and the larger share of the fleet on the road, because
/// `YemenUnifiedPlates` only began rolling out in mid-2026.
///
/// This is not the legacy half of a legacy/current pair. Both systems are
/// current, in different geographies, with different serial grammars and
/// different colour semantics. Keeping them in two namespaces with nothing
/// shared between them is the point; there is no `YemenSystem` enum here and
/// there should not be one.
///
/// ### What the plate says
///
/// A top band over a single **left/right split**, not a stacked pair of
/// registers:
///
/// - a top band with `اليمن ـ` on the left and the usage word beside it;
/// - a full-width horizontal rule under the band;
/// - one row below the rule, divided by a vertical line into the
///   **governorate code** (1..22, one or two digits) on the left and the
///   **vehicle serial** (one to six digits, never zero-padded) on the right,
///   the two cells optically the same size.
///
/// ### Colour is the primary signal
///
/// Unlike System A, this system colour-codes by usage and the field colour is
/// what is read first: blue private, yellow for hire, red transport, green
/// government, black military. That colour lives in `YemenThemes`, never in a
/// spec, and `YemenThemes.forNorthernUsage` is how a host gets it. Pairing a
/// spec here with the wrong theme produces a plate in the wrong colour, which
/// on this system means a plate that claims to be a different kind of vehicle.
///
/// ### Which combinations exist
///
/// One or two governorate digits crossed with one to six serial digits is
/// twelve layouts, and enumerating all of them would be a wall of speculative
/// consts. Four car layouts are declared — the attested and useful subset —
/// plus one motorcycle layout. See [carGeometries] for the map and the
/// class-level TODO for what is missing.
///
/// There is one spec per *layout*, not per layout and usage: usage picks the
/// country block and the theme, which the host passes to the canvas. See the
/// comment over [carGov2Serial5].
// TODO(northern-lengths): the serial is documented as one to six digits, and
// only four, five and six are built here (with one and two governorate digits
// crossed only at five). Serials of one, two and three digits are legal and
// unbuilt; add them when a reference image shows how a short serial is centred
// in the lower register, rather than guessing at the tracking now.
abstract final class YemenNorthernPlates {
  // ---------------------------------------------------------------------------
  // Shared geometry.
  // ---------------------------------------------------------------------------

  /// 540 x 288 is an aspect of 1.875, against the 1.871 measured off a
  /// photograph of an issued blue private plate. Every car number below was
  /// measured from that photograph as a fraction of the plate and multiplied
  /// out; the comments give the fraction and the code gives the unit.
  static const double _carWidth = 540;
  static const double _height = 288;

  /// The motorcycle canvas is **not** measured — no photograph of a northern
  /// motorcycle plate was available, so it stays `// CALIBRATE` throughout.
  static const double _motoWidth = 289; // CALIBRATE

  /// Mirrors `YemenThemes._borderWidthRatio` onto every spec, so the frame
  /// keeps its thickness under a host that supplies its own theme. The frame is
  /// square, not rounded — that half of it is `plateRadiusRatio: 0` in the
  /// theme, which a spec has no field for.
  static const double _borderRatio = 0.035; // CALIBRATE

  // --- Car: top band, a full-width rule, then one row split by a vertical
  // --- divider into a governorate cell (left) and a serial cell (right). ----
  //
  // Measured off the photograph, as fractions of the plate:
  //
  //   top band     y 0.038 .. 0.219    اليمن x 0.076 .. 0.231
  //                                    خصوصي x 0.327 .. 0.703
  //   rule         y 0.289 .. 0.314    full width
  //   divider      x 0.246 .. 0.260    y 0.314 .. 0.979 (rule bottom to frame)
  //   governorate  x 0.006 .. 0.246    y 0.331 .. 0.641 (one cell, centred)
  //   serial       x 0.260 .. 0.983    y 0.331 .. 0.641 (five digits)
  //
  // This replaces an earlier guess at a *stacked* layout — governorate above
  // a rule, serial below it — which the photograph does not show. What it
  // shows instead is a single row: one rule under the top band, and one
  // vertical divider splitting that row into a narrow governorate cell and a
  // wide serial cell, side by side. There is no second horizontal rule inside
  // the row.
  //
  // The photograph also shows a small Latin-digit row under each big digit
  // (e.g. big "٢" over small "2"):
  //
  //   small Latin row  y 0.697 .. 0.882   same x and width as the big digit
  //
  // That row is built with `PlateMirror`, and it is still ONE value printed
  // twice — not two values. Both rows share the source slot's character: a
  // mirror names the slot it echoes and carries no position of its own, so
  // `slots.length`, `textGroups`, `isCompleted` and the validators are untouched
  // by it. What changed is that these mirrors are `editable`, so the small row
  // is a second register the user can type into as well as read: a keystroke in
  // either row writes the one shared value, and the other row re-renders it in
  // its own script. The big (iranian) row is the primary input row.
  //
  // Which row gets which numerals: the *slot* carries
  // `YemenAlphabets.iranianDigits`, so the big row prints (and now types) ٠..٩.
  // Each editable mirror names `YemenAlphabets.digits` to get the small row's
  // Latin ones. Storage stays ASCII on both rows — core folds a typed iranian
  // numeral back to its ASCII character (`PlateAlphabet.canonical`) — so the
  // numerals are a rendering, never a value.
  //
  // The big row now shows iranian numerals under the caret in `PlateMode.input`
  // too: core's `_TypedField` renders the alphabet's display form and folds it
  // back on commit, which closed the old TODO(national-numerals) this comment
  // used to warn about.

  /// `اليمن`, on the left of the top band.
  ///
  /// A separate [PlateLabel] from the usage word beside it, and not because the
  /// usage word varies: it is bidi. [PlateLabel] carries no `TextDirection` and
  /// core lays a label out exactly as given, so an Arabic string on its own is
  /// an isolated run that renders correctly. Joining two runs into one label
  /// would hand the bidi algorithm a paragraph to reorder.
  ///
  /// The measured run is x 0.076 .. 0.231, i.e. 41 .. 125, and 76 units of
  /// glyph is what fills the band's measured 0.181 of the plate (that band is
  /// deeper than a cap height: it includes the lam's ascender and the nun's
  /// tail).
  ///
  /// **The box is deliberately much wider than the measured run**, and centred
  /// on it rather than starting at it. Core renders a label as a plain `Text`
  /// inside a fixed-width `Positioned`, so a string wider than its box does not
  /// overhang — it wraps and clips. The measured 84 units is the width in the
  /// plate's own square Kufic; this package ships no font (see the README), so
  /// the string is actually shaped in whatever Arabic face the platform falls
  /// back to, which is wider and was clipping `اليمن` to `الي`. 140 units gives
  /// that fallback 66% of headroom and still clears the usage word at x 177,
  /// and `TextAlign.center` keeps the run on its measured centre either way.
  ///
  /// The dash between اليمن and the usage word (measured x 0.383 .. 0.417,
  /// i.e. 207 .. 225) is its own [PlateLabel] rather than appended to either
  /// neighbour's string: appending it to `اليمن` would put it on the wrong
  /// side of the word once an RTL run reorders, and appending it to the usage
  /// word would tie a fixed glyph to a word that changes with usage.
  static const List<PlateLabel> _carLabels = <PlateLabel>[];

  /// The usage word, as the country panel's caption.
  ///
  /// The panel paints nothing — `YemenCountry.northernPrivate` and friends set
  /// a fully transparent `panelColor`, because a northern plate has no coloured
  /// block; the word is printed straight onto the field. The panel is here only
  /// because [PlateCountry.captionLines] is the one place on a `const`
  /// [PlateSpec] where text can vary without the geometry varying too. See the
  /// `YemenCountry` class doc.
  ///
  /// x 0.027 .. 0.987, y 0.038 .. 0.219 — the full width of the plate for the
  /// caption text "الیمن - خصوصي", centered and scaled to fill the available space.
  ///
  /// [PlatePanel.captionScale] is a size to fit *down* from, not the rendered
  /// size: `CountryPanel` wraps the caption in a `FittedBox(scaleDown)`, which
  /// shrinks to the box but never grows to it. So the scale has to put the text
  /// over the box for the fit to bind and fill its measured width.
  static const PlatePanel _carPanel = PlatePanel(
    box: PlateBox(0, 6, 540, 62),
    // No flag on a Yemeni plate.
    flagScale: 0,
    captionScale: 4.5,
    padding: EdgeInsets.fromLTRB(50, 3, 50, 0),
  );

  // The full-width rule under the top band: y 0.289 .. 0.314 of the plate,
  // i.e. 83 and 7 units deep, x 0 .. 540 (the frame draws its own inset, so
  // this runs edge to edge rather than stopping short as the old registers'
  // rule did).
  static const List<PlateRule> _carRule = <PlateRule>[PlateRule(box: PlateBox(0, 83, 540, 7))];

  /// The vertical divider between the governorate cell and the serial cell.
  ///
  /// x 0.246 .. 0.260 (133 .. 140), y 0.314 .. 0.979 — from the rule's bottom
  /// edge down to just inside the frame, matching the photograph, where the
  /// divider does not cross into the top band above the rule.
  static const List<PlateRule> _carDivider = <PlateRule>[PlateRule(box: PlateBox(133, 90, 7, 192))];

  /// Both car rules together: the rule and the divider are the same on every
  /// car layout regardless of digit counts, unlike the old per-length rules
  /// that sized themselves to the serial block below them.
  static const List<PlateRule> _carRules = <PlateRule>[..._carRule, ..._carDivider];

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

  /// The span every serial length fills: x 140 .. 530.
  ///
  /// Stated once, as a span, because that is what the photograph measures. The
  /// cell width is then whatever `count` divides it into — 97.5, 78 or 65 — and
  /// no length can round to a different right edge than its siblings, which is
  /// exactly what the four-cell layout used to do.
  static const double _serialLeft = 140;
  static const double _serialRight = 530;

  /// The serial digits alone, without the governorate cells that precede them.
  static List<PlateSlot> _carSerial(int count) => plateRegisterAcross(
    alphabet: YemenAlphabets.iranianDigits,
    count: count,
    left: _serialLeft,
    right: _serialRight,
    top: 95,
    height: 89,
  );

  static final List<PlateSlot> _carGov2Serial4 = <PlateSlot>[_carGovTens, _carGovUnits, ..._carSerial(4)];

  static final List<PlateSlot> _carGov2Serial5 = <PlateSlot>[_carGovTens, _carGovUnits, ..._carSerial(5)];

  static final List<PlateSlot> _carGov2Serial6 = <PlateSlot>[_carGovTens, _carGovUnits, ..._carSerial(6)];

  /// One governorate digit, a five-digit serial — the layout the photograph
  /// is measured from: a single big digit in the left cell, five in the
  /// right, both in the one row under the rule.
  static final List<PlateSlot> _carGov1Serial5 = <PlateSlot>[_carGovSingle, ..._carSerial(5)];

  // --- The small Latin echo row. --------------------------------------------
  //
  // Measured y 0.697 .. 0.882 of the plate: a cap height of 0.185, i.e. 53
  // units. By the same conversion the big row uses — core sets a glyph at
  // `0.72 * height` and Roboto's cap is 0.711 em, so a box is `0.512 * height`
  // of cap — 53 units of cap wants a 104-unit box. The band's centre is at
  // 0.790 of 288, i.e. 227, so the box runs y 175 .. 279, comfortably inside
  // the frame.
  //
  // The box is deeper than the cap on purpose. Core renders a mirror as a
  // centred `Text` in a fixed `Positioned`, so anything taller or wider than
  // its box wraps and clips rather than overhanging — the same trap
  // [_carLabels] documents at length. 104 units leaves the line box room.
  //
  // Each mirror takes its source slot's x and width, so the small digit sits
  // under the big one it echoes.
  static const double _echoTop = 175;
  static const double _echoHeight = 104;

  /// One echo under [_carGovTens].
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

  /// The echo under [_carGovSingle], which straddles the pair's two cells.
  static const PlateMirror _carEchoGovSingle = PlateMirror(
    source: 0,
    box: PlateBox(38, _echoTop, 60, _echoHeight),
    glyphHeight: _echoHeight,
    alphabet: YemenAlphabets.digits,
    editable: true,
  );

  /// The echo band under a serial register of [count] digits, the first of them
  /// echoing slot [firstSource].
  ///
  /// The same span and the same division as [_carSerial], so an echo cannot sit
  /// anywhere but under the digit it echoes: the two used to be two hand-written
  /// copies of one arithmetic, and a copy is a place for them to disagree.
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

  static final List<PlateMirror> _carMirrorsGov1Serial5 = <PlateMirror>[_carEchoGovSingle, ..._carEcho(5, 1)];

  // --- Motorcycle. ----------------------------------------------------------
  //
  // The row-and-divider structure carries over unchanged from the car; only
  // the widths compress onto the square canvas.
  //
  // **No photograph of a northern motorcycle plate was available**, so none of
  // the horizontal numbers here are measured. What they are instead is derived,
  // and the derivation is worth stating because it is why they are no longer
  // marked `// CALIBRATE` one by one:
  //
  // - The **vertical** layout is the car's, unchanged. Both canvases are 288
  //   units tall, so every y fraction measured off the car photograph — top
  //   band 0.038, rule 0.289, the row 0.331 .. 0.641 — carries across as the
  //   same absolute unit. These are as good as the car's.
  // - The **horizontal** layout keeps the car's measured *ratios* and
  //   renormalises them onto the narrower canvas. The top band's two runs keep
  //   their 1 : 2.41 width ratio, so the usage word stays the larger of the
  //   two; the divider stays at the same fraction of the row's width.
  //
  // So this is a reflow of measured proportions rather than a record of a real
  // plate, and a photograph could still move the x numbers. The y numbers it
  // would leave alone.

  /// `اليمن`, keeping its 1 : 2.41 width ratio against the usage word.
  ///
  /// The glyph height is 42 rather than the band's 62, and that is the same
  /// correction [_carLabels] carries, applied the other way round. A label
  /// renders as a plain `Text` in a fixed-width box, so a string wider than its
  /// box **wraps and clips** — it does not overhang. On the car there was spare
  /// field to widen the box into; here there is not, because the usage word's
  /// panel starts at x 96 on a 289-unit canvas. So the string is set smaller
  /// instead: at `0.72 * 42` the run needs about 2.7 box-widths of the size
  /// core will paint it at, against the 2.56 the car renders correctly at.
  ///
  /// The measured band would set it at 67. It is not set there because a
  /// clipped `الي` is a worse likeness of the plate than a small `اليمن`.
  static const List<PlateLabel> _motoLabels = <PlateLabel>[];

  /// The caption text centered and scaled to fill the available width.
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
  static const List<PlateRule> _motoRule = <PlateRule>[PlateRule(box: PlateBox(0, 83, 289, 7))];
  static const List<PlateRule> _motoDivider = <PlateRule>[PlateRule(box: PlateBox(71, 90, 4, 192))];
  static const List<PlateRule> _motoRules = <PlateRule>[..._motoRule, ..._motoDivider];

  /// The motorcycle serial's own span and pitch: five cells from x 75, stepping
  /// by 41.8. The cells are 42 wide, a fifth of a unit more than the stride, so
  /// this states its pitch rather than running flush.
  static const double _motoSerialLeft = 75;
  static const double _motoSerialPitch = 41.8;

  static final List<PlateSlot> _motoGov2Serial5 = <PlateSlot>[
    const PlateSlot(alphabet: YemenAlphabets.iranianGovernorateTens, box: PlateBox(13, 95, 24, 89)),
    const PlateSlot(alphabet: YemenAlphabets.iranianDigits, box: PlateBox(37, 95, 24, 89)),
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
    rules: _carRules,
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
    rules: _carRules,
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
    rules: _carRules,
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
    rules: _carRules,
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
    rules: _motoRules,
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
  static final Map<(int, int), PlateSpec> carGeometries = <(int, int), PlateSpec>{
    (2, 5): carGov2Serial5,
    (1, 5): carGov1Serial5,
    (2, 4): carGov2Serial4,
    (2, 6): carGov2Serial6,
  };

  /// The motorcycle geometries this package builds — one, and unverified.
  static final Map<(int, int), PlateSpec> motoGeometries = <(int, int), PlateSpec>{
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
  static PlateSpec? car({required int governorateDigits, required int serialDigits}) =>
      carGeometries[(governorateDigits, serialDigits)];

  /// The northern motorcycle plate with this register shape, or null. Its
  /// geometry is unverified — see the section comment above [motoGov2Serial5].
  static PlateSpec? moto({required int governorateDigits, required int serialDigits}) =>
      motoGeometries[(governorateDigits, serialDigits)];
}
