import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'yemen_alphabets.dart';
import 'yemen_country.dart';
import 'yemen_usage.dart';

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
/// twelve layouts per usage, and enumerating all of them would be a wall of
/// speculative consts. Four car layouts are declared — the attested and useful
/// subset — plus one motorcycle layout. See [byDigits] for the map and the
/// class-level TODO for what is missing.
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
  // The photograph also shows a small Latin-digit echo under each big digit
  // (e.g. big "٢" over small "2"):
  //
  //   small Latin row  y 0.697 .. 0.882   same x and width as the big digit
  //
  // That echo is built with `PlateMirror`, and it is deliberately not a second
  // row of slots. One number is printed twice; a second row of slots would be
  // two values, two focus stops and two entries in every text group for one
  // fact. A mirror names the slot it echoes and renders that slot's value
  // read-only, so `slots.length`, `textGroups`, `isCompleted`, focus traversal
  // and the validators are all untouched by it.
  //
  // Which row gets which numerals: the *slot* carries
  // `YemenAlphabets.easternDigits`, so the big row prints ٠..٩. A mirror with
  // no alphabet of its own renders through the source slot's, which here would
  // print the eastern figures a second time, so each mirror names
  // `YemenAlphabets.digits` to get the small row's Latin ones. Storage stays
  // ASCII on both rows; the numerals are a rendering, never a value.
  //
  // KNOWN LIMITATION, not fixable here: in `PlateMode.input` the big row still
  // shows ASCII while typing. `_TypedField` in core's `plate_slot_item.dart`
  // paints `controller.text` directly and never calls `alphabet.render` — only
  // `_GlyphSlot` and `_ChosenSlot` do — so the eastern numerals appear in
  // `PlateMode.display` and not under the caret. That is core's existing
  // TODO(national-numerals); see it rather than working around it here.

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
  static const List<PlateLabel> _carLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(13, 6, 140, 62), glyphHeight: 76),
    PlateLabel(text: 'ـ', box: PlateBox(153, 6, 24, 62), glyphHeight: 62),
  ];

  /// The usage word, as the country panel's caption.
  ///
  /// The panel paints nothing — `YemenCountry.northernPrivate` and friends set
  /// a fully transparent `panelColor`, because a northern plate has no coloured
  /// block; the word is printed straight onto the field. The panel is here only
  /// because [PlateCountry.captionLines] is the one place on a `const`
  /// [PlateSpec] where text can vary without the geometry varying too. See the
  /// `YemenCountry` class doc.
  ///
  /// x 0.327 .. 0.703, y 0.038 .. 0.219 — the measured box of the usage word,
  /// which is the wider of the two runs in the top band.
  ///
  /// [PlatePanel.captionScale] is a size to fit *down* from, not the rendered
  /// size: `CountryPanel` wraps the caption in a `FittedBox(scaleDown)`, which
  /// shrinks to the box but never grows to it. So the scale has to put the text
  /// over the box for the fit to bind and the word to fill its measured width;
  /// 3.0 does that for every usage word in `YemenCountry`, the longest of which
  /// is خصوصي.
  static const PlatePanel _carPanel = PlatePanel(
    box: PlateBox(177, 6, 203, 62),
    // No flag on a Yemeni plate.
    flagScale: 0,
    captionScale: 3.0,
    padding: EdgeInsets.zero,
  );

  // The full-width rule under the top band: y 0.289 .. 0.314 of the plate,
  // i.e. 83 and 7 units deep, x 0 .. 540 (the frame draws its own inset, so
  // this runs edge to edge rather than stopping short as the old registers'
  // rule did).
  static const List<PlateRule> _carRule = <PlateRule>[
    PlateRule(box: PlateBox(0, 83, 540, 7)),
  ];

  /// The vertical divider between the governorate cell and the serial cell.
  ///
  /// x 0.246 .. 0.260 (133 .. 140), y 0.314 .. 0.979 — from the rule's bottom
  /// edge down to just inside the frame, matching the photograph, where the
  /// divider does not cross into the top band above the rule.
  static const List<PlateRule> _carDivider = <PlateRule>[
    PlateRule(box: PlateBox(133, 90, 7, 192)),
  ];

  /// Both car rules together: the rule and the divider are the same on every
  /// car layout regardless of digit counts, unlike the old per-length rules
  /// that sized themselves to the serial block below them.
  static const List<PlateRule> _carRules = <PlateRule>[
    ..._carRule,
    ..._carDivider,
  ];

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
    alphabet: YemenAlphabets.easternGovernorateTens,
    box: PlateBox(24, 95, 44, 89),
  );
  static const PlateSlot _carGovUnits = PlateSlot(
    alphabet: YemenAlphabets.easternDigits,
    box: PlateBox(68, 95, 44, 89),
  );

  /// A lone governorate digit, centred in the same cell the pair straddles.
  static const PlateSlot _carGovSingle = PlateSlot(
    alphabet: YemenAlphabets.easternDigits,
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

  static const List<PlateSlot> _carGov2Serial4 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(140, 95, 98, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(238, 95, 98, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(335, 95, 98, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(433, 95, 98, 89)),
  ];

  static const List<PlateSlot> _carGov2Serial5 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(140, 95, 78, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(218, 95, 78, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(296, 95, 78, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(374, 95, 78, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(452, 95, 78, 89)),
  ];

  static const List<PlateSlot> _carGov2Serial6 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(140, 95, 65, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(205, 95, 65, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(270, 95, 65, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(335, 95, 65, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(400, 95, 65, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(465, 95, 65, 89)),
  ];

  /// One governorate digit, a five-digit serial — the layout the photograph
  /// is measured from: a single big digit in the left cell, five in the
  /// right, both in the one row under the rule.
  static const List<PlateSlot> _carGov1Serial5 = <PlateSlot>[
    _carGovSingle,
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(140, 95, 78, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(218, 95, 78, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(296, 95, 78, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(374, 95, 78, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(452, 95, 78, 89)),
  ];

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
  );
  static const PlateMirror _carEchoGovUnits = PlateMirror(
    source: 1,
    box: PlateBox(68, _echoTop, 44, _echoHeight),
    glyphHeight: _echoHeight,
    alphabet: YemenAlphabets.digits,
  );

  /// The echo under [_carGovSingle], which straddles the pair's two cells.
  static const PlateMirror _carEchoGovSingle = PlateMirror(
    source: 0,
    box: PlateBox(38, _echoTop, 60, _echoHeight),
    glyphHeight: _echoHeight,
    alphabet: YemenAlphabets.digits,
  );

  static const List<PlateMirror> _carMirrorsGov2Serial4 = <PlateMirror>[
    _carEchoGovTens,
    _carEchoGovUnits,
    PlateMirror(
      source: 2,
      box: PlateBox(140, _echoTop, 98, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 3,
      box: PlateBox(238, _echoTop, 98, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 4,
      box: PlateBox(335, _echoTop, 98, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 5,
      box: PlateBox(433, _echoTop, 98, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
  ];

  static const List<PlateMirror> _carMirrorsGov2Serial5 = <PlateMirror>[
    _carEchoGovTens,
    _carEchoGovUnits,
    PlateMirror(
      source: 2,
      box: PlateBox(140, _echoTop, 78, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 3,
      box: PlateBox(218, _echoTop, 78, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 4,
      box: PlateBox(296, _echoTop, 78, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 5,
      box: PlateBox(374, _echoTop, 78, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 6,
      box: PlateBox(452, _echoTop, 78, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
  ];

  static const List<PlateMirror> _carMirrorsGov2Serial6 = <PlateMirror>[
    _carEchoGovTens,
    _carEchoGovUnits,
    PlateMirror(
      source: 2,
      box: PlateBox(140, _echoTop, 65, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 3,
      box: PlateBox(205, _echoTop, 65, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 4,
      box: PlateBox(270, _echoTop, 65, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 5,
      box: PlateBox(335, _echoTop, 65, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 6,
      box: PlateBox(400, _echoTop, 65, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 7,
      box: PlateBox(465, _echoTop, 65, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
  ];

  static const List<PlateMirror> _carMirrorsGov1Serial5 = <PlateMirror>[
    _carEchoGovSingle,
    PlateMirror(
      source: 1,
      box: PlateBox(140, _echoTop, 78, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 2,
      box: PlateBox(218, _echoTop, 78, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 3,
      box: PlateBox(296, _echoTop, 78, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 4,
      box: PlateBox(374, _echoTop, 78, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 5,
      box: PlateBox(452, _echoTop, 78, _echoHeight),
      glyphHeight: _echoHeight,
      alphabet: YemenAlphabets.digits,
    ),
  ];

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
  static const List<PlateLabel> _motoLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(14, 16, 82, 42), glyphHeight: 42),
    PlateLabel(text: 'ـ', box: PlateBox(88, 16, 14, 42), glyphHeight: 42),
  ];

  /// The usage word. Larger than `اليمن`, as on the car — see the note on
  /// [_carPanel] for why `captionScale` is a size to fit down from.
  static const PlatePanel _motoPanel = PlatePanel(
    box: PlateBox(96, 6, 179, 62),
    flagScale: 0,
    captionScale: 3.0,
    padding: EdgeInsets.zero,
  );

  // Same row-and-divider structure as the car, renormalised onto the
  // narrower canvas: full-width rule under the top band, then one vertical
  // divider splitting a governorate cell (left) from a five-digit serial
  // cell (right) — no second horizontal rule inside the row.
  static const List<PlateRule> _motoRule = <PlateRule>[
    PlateRule(box: PlateBox(0, 83, 289, 7)),
  ];
  static const List<PlateRule> _motoDivider = <PlateRule>[
    PlateRule(box: PlateBox(71, 90, 4, 192)),
  ];
  static const List<PlateRule> _motoRules = <PlateRule>[
    ..._motoRule,
    ..._motoDivider,
  ];

  static const List<PlateSlot> _motoGov2Serial5 = <PlateSlot>[
    PlateSlot(
      alphabet: YemenAlphabets.easternGovernorateTens,
      box: PlateBox(13, 95, 24, 89),
    ),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(37, 95, 24, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(75, 95, 42, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(117, 95, 42, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(159, 95, 42, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(200, 95, 42, 89)),
    PlateSlot(alphabet: YemenAlphabets.easternDigits, box: PlateBox(242, 95, 42, 89)),
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

  static const List<PlateMirror> _motoMirrorsGov2Serial5 = <PlateMirror>[
    PlateMirror(
      source: 0,
      box: PlateBox(13, _echoTop, 24, _echoHeight),
      glyphHeight: _motoEchoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 1,
      box: PlateBox(37, _echoTop, 24, _echoHeight),
      glyphHeight: _motoEchoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 2,
      box: PlateBox(75, _echoTop, 42, _echoHeight),
      glyphHeight: _motoEchoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 3,
      box: PlateBox(117, _echoTop, 42, _echoHeight),
      glyphHeight: _motoEchoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 4,
      box: PlateBox(159, _echoTop, 42, _echoHeight),
      glyphHeight: _motoEchoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 5,
      box: PlateBox(200, _echoTop, 42, _echoHeight),
      glyphHeight: _motoEchoHeight,
      alphabet: YemenAlphabets.digits,
    ),
    PlateMirror(
      source: 6,
      box: PlateBox(242, _echoTop, 42, _echoHeight),
      glyphHeight: _motoEchoHeight,
      alphabet: YemenAlphabets.digits,
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
  // Car plates. Four layouts x five usages, and the only fields that vary with
  // usage are `id` and `country` — the country carrying the usage word, and the
  // field colour coming from the theme.
  // ---------------------------------------------------------------------------

  /// Two governorate digits, a five-digit serial, private (blue).
  static const PlateSpec carGov2Serial5Private = PlateSpec(
    id: 'ye.northern.car.g2s5.private',
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

  /// One governorate digit, a five-digit serial, private (blue).
  static const PlateSpec carGov1Serial5Private = PlateSpec(
    id: 'ye.northern.car.g1s5.private',
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

  /// Two governorate digits, a four-digit serial, private (blue).
  static const PlateSpec carGov2Serial4Private = PlateSpec(
    id: 'ye.northern.car.g2s4.private',
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

  /// Two governorate digits, a six-digit serial, private (blue).
  static const PlateSpec carGov2Serial6Private = PlateSpec(
    id: 'ye.northern.car.g2s6.private',
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

  /// Two governorate digits, a five-digit serial, for hire (yellow).
  static const PlateSpec carGov2Serial5ForHire = PlateSpec(
    id: 'ye.northern.car.g2s5.forHire',
    country: YemenCountry.northernForHire,
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

  /// One governorate digit, a five-digit serial, for hire (yellow).
  static const PlateSpec carGov1Serial5ForHire = PlateSpec(
    id: 'ye.northern.car.g1s5.forHire',
    country: YemenCountry.northernForHire,
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

  /// Two governorate digits, a four-digit serial, for hire (yellow).
  static const PlateSpec carGov2Serial4ForHire = PlateSpec(
    id: 'ye.northern.car.g2s4.forHire',
    country: YemenCountry.northernForHire,
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

  /// Two governorate digits, a six-digit serial, for hire (yellow).
  static const PlateSpec carGov2Serial6ForHire = PlateSpec(
    id: 'ye.northern.car.g2s6.forHire',
    country: YemenCountry.northernForHire,
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

  /// Two governorate digits, a five-digit serial, transport (red).
  static const PlateSpec carGov2Serial5Transport = PlateSpec(
    id: 'ye.northern.car.g2s5.transport',
    country: YemenCountry.northernTransport,
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

  /// One governorate digit, a five-digit serial, transport (red).
  static const PlateSpec carGov1Serial5Transport = PlateSpec(
    id: 'ye.northern.car.g1s5.transport',
    country: YemenCountry.northernTransport,
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

  /// Two governorate digits, a four-digit serial, transport (red).
  static const PlateSpec carGov2Serial4Transport = PlateSpec(
    id: 'ye.northern.car.g2s4.transport',
    country: YemenCountry.northernTransport,
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

  /// Two governorate digits, a six-digit serial, transport (red).
  static const PlateSpec carGov2Serial6Transport = PlateSpec(
    id: 'ye.northern.car.g2s6.transport',
    country: YemenCountry.northernTransport,
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

  /// Two governorate digits, a five-digit serial, government (green).
  static const PlateSpec carGov2Serial5Government = PlateSpec(
    id: 'ye.northern.car.g2s5.government',
    country: YemenCountry.northernGovernment,
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

  /// One governorate digit, a five-digit serial, government (green).
  static const PlateSpec carGov1Serial5Government = PlateSpec(
    id: 'ye.northern.car.g1s5.government',
    country: YemenCountry.northernGovernment,
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

  /// Two governorate digits, a four-digit serial, government (green).
  static const PlateSpec carGov2Serial4Government = PlateSpec(
    id: 'ye.northern.car.g2s4.government',
    country: YemenCountry.northernGovernment,
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

  /// Two governorate digits, a six-digit serial, government (green).
  static const PlateSpec carGov2Serial6Government = PlateSpec(
    id: 'ye.northern.car.g2s6.government',
    country: YemenCountry.northernGovernment,
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

  /// Two governorate digits, a five-digit serial, military.
  ///
  /// The military country block carries no usage word, so this spec is the
  /// same plate under either printing: `YemenThemes.northernMilitaryClassic`
  /// paints it white on black, `.northernMilitaryModern` red on white. The
  /// style is a theme choice, which is why there is one military spec per
  /// layout rather than two.
  static const PlateSpec carGov2Serial5Military = PlateSpec(
    id: 'ye.northern.car.g2s5.military',
    country: YemenCountry.northernMilitaryClassic,
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

  /// One governorate digit, a five-digit serial, military.
  static const PlateSpec carGov1Serial5Military = PlateSpec(
    id: 'ye.northern.car.g1s5.military',
    country: YemenCountry.northernMilitaryClassic,
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

  /// Two governorate digits, a four-digit serial, military.
  static const PlateSpec carGov2Serial4Military = PlateSpec(
    id: 'ye.northern.car.g2s4.military',
    country: YemenCountry.northernMilitaryClassic,
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

  /// Two governorate digits, a six-digit serial, military.
  static const PlateSpec carGov2Serial6Military = PlateSpec(
    id: 'ye.northern.car.g2s6.military',
    country: YemenCountry.northernMilitaryClassic,
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
  // Motorcycle plates — every one of them unverified.
  //
  // No official motorcycle design has been published for the northern system,
  // despite active registration campaigns run by the Sanaa traffic police under
  // Cabinet Decision No. 33 of 1446 AH and an equivalent process in Taiz. What
  // follows is Template B rendered into the motorcycle form factor: the same
  // content, the same stacking, half the width. It is a reasonable guess and it
  // is a guess, so it is deprecated — not because it is going away, but so that
  // nothing silently trusts it and so it shows up in a grep.
  //
  // One colour note that does not generalise: Marib classifies motorcycles as
  // yellow. Other southern governorates publish no motorcycle colour, and
  // extrapolating Marib's rule to them would be inventing policy.
  // ---------------------------------------------------------------------------

  /// Two governorate digits, a five-digit serial, private (blue).
  @Deprecated('unverified geometry — calibrate against photographs')
  static const PlateSpec motoGov2Serial5Private = PlateSpec(
    id: 'ye.northern.moto.g2s5.private',
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

  /// Two governorate digits, a five-digit serial, for hire (yellow).
  @Deprecated('unverified geometry — calibrate against photographs')
  static const PlateSpec motoGov2Serial5ForHire = PlateSpec(
    id: 'ye.northern.moto.g2s5.forHire',
    country: YemenCountry.northernForHire,
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

  /// Two governorate digits, a five-digit serial, transport (red).
  @Deprecated('unverified geometry — calibrate against photographs')
  static const PlateSpec motoGov2Serial5Transport = PlateSpec(
    id: 'ye.northern.moto.g2s5.transport',
    country: YemenCountry.northernTransport,
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

  /// Two governorate digits, a five-digit serial, government (green).
  @Deprecated('unverified geometry — calibrate against photographs')
  static const PlateSpec motoGov2Serial5Government = PlateSpec(
    id: 'ye.northern.moto.g2s5.government',
    country: YemenCountry.northernGovernment,
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

  /// Two governorate digits, a five-digit serial, military.
  @Deprecated('unverified geometry — calibrate against photographs')
  static const PlateSpec motoGov2Serial5Military = PlateSpec(
    id: 'ye.northern.moto.g2s5.military',
    country: YemenCountry.northernMilitaryClassic,
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
  // Lookups.
  // ---------------------------------------------------------------------------

  /// Every car plate, by usage and then by `(governorate digits, serial
  /// digits)`.
  static const Map<YemenUsage, Map<(int, int), PlateSpec>> car =
      <YemenUsage, Map<(int, int), PlateSpec>>{
        YemenUsage.private: <(int, int), PlateSpec>{
          (2, 5): carGov2Serial5Private,
          (1, 5): carGov1Serial5Private,
          (2, 4): carGov2Serial4Private,
          (2, 6): carGov2Serial6Private,
        },
        YemenUsage.forHire: <(int, int), PlateSpec>{
          (2, 5): carGov2Serial5ForHire,
          (1, 5): carGov1Serial5ForHire,
          (2, 4): carGov2Serial4ForHire,
          (2, 6): carGov2Serial6ForHire,
        },
        YemenUsage.transport: <(int, int), PlateSpec>{
          (2, 5): carGov2Serial5Transport,
          (1, 5): carGov1Serial5Transport,
          (2, 4): carGov2Serial4Transport,
          (2, 6): carGov2Serial6Transport,
        },
        YemenUsage.government: <(int, int), PlateSpec>{
          (2, 5): carGov2Serial5Government,
          (1, 5): carGov1Serial5Government,
          (2, 4): carGov2Serial4Government,
          (2, 6): carGov2Serial6Government,
        },
        YemenUsage.military: <(int, int), PlateSpec>{
          (2, 5): carGov2Serial5Military,
          (1, 5): carGov1Serial5Military,
          (2, 4): carGov2Serial4Military,
          (2, 6): carGov2Serial6Military,
        },
      };

  /// Every motorcycle plate, by usage and then by `(governorate digits, serial
  /// digits)`. One layout each, and all of it unverified — see the section
  /// comment above the moto consts.
  // ignore: deprecated_member_use_from_same_package
  static const Map<YemenUsage, Map<(int, int), PlateSpec>> moto =
      <YemenUsage, Map<(int, int), PlateSpec>>{
        // ignore: deprecated_member_use_from_same_package
        YemenUsage.private: <(int, int), PlateSpec>{
          (2, 5): motoGov2Serial5Private,
        },
        // ignore: deprecated_member_use_from_same_package
        YemenUsage.forHire: <(int, int), PlateSpec>{
          (2, 5): motoGov2Serial5ForHire,
        },
        // ignore: deprecated_member_use_from_same_package
        YemenUsage.transport: <(int, int), PlateSpec>{
          (2, 5): motoGov2Serial5Transport,
        },
        // ignore: deprecated_member_use_from_same_package
        YemenUsage.government: <(int, int), PlateSpec>{
          (2, 5): motoGov2Serial5Government,
        },
        // ignore: deprecated_member_use_from_same_package
        YemenUsage.military: <(int, int), PlateSpec>{
          (2, 5): motoGov2Serial5Military,
        },
      };

  /// The plates for [usage], keyed by `(governorate digits, serial digits)`.
  ///
  /// Empty for [YemenUsage.police], which System B does not issue; ask
  /// `YemenUsage.onNorthern` first if you want to grey the option out.
  ///
  /// The keys are the combinations this package actually builds — four for a
  /// car, one for a motorcycle. A combination that is missing is missing on
  /// purpose; see the class-level TODO.
  ///
  /// **Pick the two lengths before entry begins.** Swapping `spec:` on a live
  /// `PlateCanvas` resets the bloc, because the slot count changes with either
  /// length.
  static Map<(int, int), PlateSpec> byDigits(
    YemenUsage usage, {
    bool motorcycle = false,
  }) =>
      (motorcycle ? moto : car)[usage] ?? const <(int, int), PlateSpec>{};
}
