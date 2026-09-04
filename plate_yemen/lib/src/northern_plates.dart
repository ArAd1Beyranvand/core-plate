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
/// A **stacked two-register** layout, not a left/right split:
///
/// - a top band with `اليمن` on the left and the usage word beside it;
/// - the **governorate code** (1..22, one or two digits) in the upper
///   register;
/// - a full-width horizontal rule;
/// - the **vehicle serial** (one to six digits, never zero-padded) in the
///   lower register, optically larger than the code above it.
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

  // --- Car: top band, then two registers split by a rule. -------------------
  //
  // Measured off the photograph, as fractions of the plate:
  //
  //   top band     y 0.038 .. 0.219    اليمن x 0.076 .. 0.231
  //                                    خصوصي x 0.327 .. 0.703
  //   governorate  y 0.344 .. 0.482    x 0.440 .. 0.561, pitch 0.072
  //   rule         y 0.584 .. 0.609    x 0.268 .. 0.732
  //   serial       y 0.715 .. 0.892    x 0.282 .. 0.713 (five digits)
  //
  // Two things the photograph settles that the previous guess had wrong. The
  // usage word is the *larger* of the two runs in the top band and takes more
  // than twice the width of اليمن, where this file used to set them nearly
  // equal. And both registers are centred on the plate's midline — the
  // governorate on x 0.50, the serial on x 0.497 — rather than sitting left.

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
  static const List<PlateLabel> _carLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(13, 6, 140, 62), glyphHeight: 76),
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

  // The governorate register. Two cells at 39 x 78, or one centred.
  //
  // The tens cell is drawn over `YemenAlphabets.governorateTens` — three
  // characters, because a code that never exceeds 22 can only start 0, 1 or 2.
  // That restriction is an input affordance, not validation: entering 23 is
  // still possible through other paths and `YemenNorthernValidator` is what
  // rejects it.
  // The pair is centred on the plate's midline: the measured glyphs sit at
  // x 0.440 .. 0.561 on a 0.072 pitch, so 39-unit cells at 231 and 270. The
  // cell height is the measured cap, 0.139 of the plate, divided by core's
  // 0.512 cap-per-cell — see the note on the serial register.
  static const PlateSlot _carGovTens = PlateSlot(
    alphabet: YemenAlphabets.governorateTens,
    box: PlateBox(231, 80, 39, 78),
  );
  static const PlateSlot _carGovUnits = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(270, 80, 39, 78),
  );

  /// A lone governorate digit, centred on the same midline the pair straddles.
  static const PlateSlot _carGovSingle = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(250, 80, 39, 78),
  );

  /// The rule between the registers, sized to the width of the serial block
  /// below it — which is why there is one per serial length rather than one
  /// shared const.
  ///
  /// y 0.584 .. 0.609 of the plate, so 168 and 7 units deep. The photograph's
  /// rule runs x 0.268 .. 0.732, which is the five-digit serial block plus
  /// about 9 units of overhang at each end; the four- and six-digit rules keep
  /// that overhang against their own blocks.
  static const List<PlateRule> _carRule4 = <PlateRule>[
    PlateRule(box: PlateBox(166, 168, 205, 7)),
  ];
  static const List<PlateRule> _carRule5 = <PlateRule>[
    PlateRule(box: PlateBox(143, 168, 251, 7)),
  ];
  static const List<PlateRule> _carRule6 = <PlateRule>[
    PlateRule(box: PlateBox(120, 168, 298, 7)),
  ];

  // The serial register: 47 x 99 cells against the governorate's 39 x 78, so
  // the lower register really is optically larger, and now by a measured ratio
  // rather than a guessed one — caps of 0.177 and 0.139 of the plate.
  //
  // On turning a measured cap height into a cell height: core sets a glyph at
  // `0.72 * cellHeight` and names no font family, so these render in Roboto,
  // whose cap is 0.711 em. A cell is therefore `0.512 * cellHeight` of cap, and
  // every cell height here is the measured cap divided by that. The same
  // arithmetic gives a digit advance of `0.41 * cellHeight`, which is what the
  // pitches below are checked against — 41 units of advance in a 47-unit cell
  // for the serial, 32 in 39 for the governorate.
  //
  // Unlike the unified plate, nothing here is width-bound: the northern
  // registers are short enough that Roboto fits at the measured cap. The real
  // plates are set in a square Kufic that is narrower still, so a host that
  // supplies one will see the digits sit tighter, not overflow. This package
  // cannot supply a font — see the README's `## Fonts`.
  //
  // All four blocks are centred on x 268.6, the measured midline of the serial.
  //
  // The serial's cells sit 3 units above where the measurement puts them —
  // cap top 0.695 against a measured 0.715 — and that is deliberate. Centring
  // the cell on the measured cap band would put its bottom edge at 0.975 of
  // the plate, past the frame's inner edge at 0.965. A glyph would still land
  // correctly, because a slot centres its text, but the underline an input
  // slot draws at the cell's bottom would fall under the frame and vanish. The
  // 3 units buy that underline back at a cost of 2% of the plate.

  static const List<PlateSlot> _carGov2Serial4 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(175, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(222, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(269, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(315, 176, 47, 99),
    ),
  ];

  static const List<PlateSlot> _carGov2Serial5 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(152, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(199, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(245, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(292, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(338, 176, 47, 99),
    ),
  ];

  static const List<PlateSlot> _carGov2Serial6 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(129, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(175, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(222, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(269, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(315, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(362, 176, 47, 99),
    ),
  ];

  static const List<PlateSlot> _carGov1Serial5 = <PlateSlot>[
    _carGovSingle,
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(152, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(199, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(245, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(292, 176, 47, 99),
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(338, 176, 47, 99),
    ),
  ];

  // --- Motorcycle. ----------------------------------------------------------
  //
  // The northern layout is already stacked, so it compresses into the square
  // canvas without reflowing: the top band stays, the rule stays, and the two
  // registers shrink.
  //
  // **No photograph of a northern motorcycle plate was available**, so none of
  // the horizontal numbers here are measured. What they are instead is derived,
  // and the derivation is worth stating because it is why they are no longer
  // marked `// CALIBRATE` one by one:
  //
  // - The **vertical** layout is the car's, unchanged. Both canvases are 288
  //   units tall, so every y fraction measured off the car photograph — top
  //   band 0.038, governorate 0.344, rule 0.584, serial 0.715 — carries across
  //   as the same absolute unit. These are as good as the car's.
  // - The **horizontal** layout keeps the car's measured *ratios* and
  //   renormalises them onto the narrower canvas. The top band's two runs keep
  //   their 1 : 2.41 width ratio, so the usage word stays the larger of the
  //   two; the registers stay centred on the plate's midline.
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
  ];

  /// The usage word. Larger than `اليمن`, as on the car — see the note on
  /// [_carPanel] for why `captionScale` is a size to fit down from.
  static const PlatePanel _motoPanel = PlatePanel(
    box: PlateBox(96, 6, 179, 62),
    flagScale: 0,
    captionScale: 3.0,
    padding: EdgeInsets.zero,
  );

  static const List<PlateRule> _motoRule5 = <PlateRule>[
    PlateRule(box: PlateBox(14, 168, 261, 7)),
  ];

  static const List<PlateSlot> _motoGov2Serial5 = <PlateSlot>[
    PlateSlot(
      alphabet: YemenAlphabets.governorateTens,
      box: PlateBox(106, 80, 39, 78),
    ),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(144, 80, 39, 78)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(18, 176, 49, 99)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(69, 176, 49, 99)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(119, 176, 49, 99)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(170, 176, 49, 99)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(220, 176, 49, 99)),
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
    rules: _carRule5,
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
    rules: _carRule5,
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
    rules: _carRule4,
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
    rules: _carRule6,
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
    rules: _carRule5,
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
    rules: _carRule5,
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
    rules: _carRule4,
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
    rules: _carRule6,
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
    rules: _carRule5,
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
    rules: _carRule5,
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
    rules: _carRule4,
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
    rules: _carRule6,
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
    rules: _carRule5,
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
    rules: _carRule5,
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
    rules: _carRule4,
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
    rules: _carRule6,
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
    rules: _carRule5,
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
    rules: _carRule5,
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
    rules: _carRule4,
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
    rules: _carRule6,
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
    rules: _motoRule5,
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
    rules: _motoRule5,
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
    rules: _motoRule5,
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
    rules: _motoRule5,
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
    rules: _motoRule5,
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
