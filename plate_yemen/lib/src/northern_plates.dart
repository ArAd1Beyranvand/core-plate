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

  static const double _carWidth = 520; // CALIBRATE
  static const double _motoWidth = 289; // CALIBRATE
  static const double _height = 288; // CALIBRATE

  /// Mirrors `YemenThemes._borderWidthRatio` onto every spec, so the frame
  /// keeps its thickness under a host that supplies its own theme. The frame is
  /// square, not rounded — that half of it is `plateRadiusRatio: 0` in the
  /// theme, which a spec has no field for.
  static const double _borderRatio = 0.035; // CALIBRATE

  // --- Car: top band, then two registers split by a rule. -------------------
  //
  //   top band     y   0 ..  81   (~28% of height)
  //   governorate  y  86 .. 158
  //   rule         y 166 .. 174   (~3% of height)
  //   serial       y 178 .. 272

  /// `اليمن`, on the left of the top band.
  ///
  /// A separate [PlateLabel] from the usage word beside it, and not because the
  /// usage word varies: it is bidi. [PlateLabel] carries no `TextDirection` and
  /// core lays a label out exactly as given, so an Arabic string on its own is
  /// an isolated run that renders correctly. Joining two runs into one label
  /// would hand the bidi algorithm a paragraph to reorder.
  static const List<PlateLabel> _carLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(28, 18, 130, 50), glyphHeight: 50),
  ];

  /// The usage word, as the country panel's caption.
  ///
  /// The panel paints nothing — `YemenCountry.northernPrivate` and friends set
  /// a fully transparent `panelColor`, because a northern plate has no coloured
  /// block; the word is printed straight onto the field. The panel is here only
  /// because [PlateCountry.captionLines] is the one place on a `const`
  /// [PlateSpec] where text can vary without the geometry varying too. See the
  /// `YemenCountry` class doc.
  static const PlatePanel _carPanel = PlatePanel(
    box: PlateBox(170, 18, 210, 50), // CALIBRATE
    // No flag on a Yemeni plate.
    flagScale: 0,
    captionScale: 1.9, // CALIBRATE
    padding: EdgeInsets.zero,
  );

  // The governorate register. Two cells at 32 x 72, or one centred.
  //
  // The tens cell is drawn over `YemenAlphabets.governorateTens` — three
  // characters, because a code that never exceeds 22 can only start 0, 1 or 2.
  // That restriction is a keypad affordance, not validation: entering 23 is
  // still possible through other paths and `YemenNorthernValidator` is what
  // rejects it.
  static const PlateSlot _carGovTens = PlateSlot(
    alphabet: YemenAlphabets.governorateTens,
    box: PlateBox(226, 86, 32, 72), // CALIBRATE
  );
  static const PlateSlot _carGovUnits = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(262, 86, 32, 72), // CALIBRATE
  );
  static const PlateSlot _carGovSingle = PlateSlot(
    alphabet: YemenAlphabets.digits,
    box: PlateBox(244, 86, 32, 72), // CALIBRATE
  );

  /// The rule between the registers, sized to the width of the serial block
  /// below it — which is why there is one per serial length rather than one
  /// shared const. `~3%` of 288 is 8.6 units; 8 is the shipped value.
  static const List<PlateRule> _carRule4 = <PlateRule>[
    PlateRule(box: PlateBox(166, 166, 187, 8)), // CALIBRATE
  ];
  static const List<PlateRule> _carRule5 = <PlateRule>[
    PlateRule(box: PlateBox(143, 166, 233, 8)), // CALIBRATE
  ];
  static const List<PlateRule> _carRule6 = <PlateRule>[
    PlateRule(box: PlateBox(120, 166, 279, 8)), // CALIBRATE
  ];

  // The serial register: 41 x 94 cells, taller than the 32 x 72 of the code
  // above. Reference images show the lower register optically larger, and the
  // ratio below is that reading, not a measurement.
  //
  // CALIBRATE: the register split, and the size difference between them.
  //
  // On cell width: core sets a glyph at `0.72 * cellHeight` and a weight-700
  // digit runs about 0.57 em, so a cell holds its digit at about 0.44 of its
  // own height. These plates are set in FE-Schrift, which is far narrower than
  // that, so a host that supplies the real face will see the digits sit looser
  // in their cells than a photograph does. This package cannot supply a font —
  // see the README's `## Fonts`.

  static const List<PlateSlot> _carGov2Serial4 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(170, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(216, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(262, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(308, 178, 41, 94)),
  ];

  static const List<PlateSlot> _carGov2Serial5 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(147, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(193, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(239, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(285, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(331, 178, 41, 94)),
  ];

  static const List<PlateSlot> _carGov2Serial6 = <PlateSlot>[
    _carGovTens,
    _carGovUnits,
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(124, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(170, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(216, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(262, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(308, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(354, 178, 41, 94)),
  ];

  static const List<PlateSlot> _carGov1Serial5 = <PlateSlot>[
    _carGovSingle,
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(147, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(193, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(239, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(285, 178, 41, 94)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(331, 178, 41, 94)),
  ];

  // --- Motorcycle. ----------------------------------------------------------
  //
  // The northern layout is already stacked, so it compresses into the square
  // canvas without reflowing: the top band stays, the rule stays, and the two
  // registers shrink. See the @Deprecated note on every moto const below.

  static const List<PlateLabel> _motoLabels = <PlateLabel>[
    PlateLabel(text: 'اليمن', box: PlateBox(14, 14, 110, 44), glyphHeight: 44),
  ];

  static const PlatePanel _motoPanel = PlatePanel(
    box: PlateBox(134, 14, 140, 44), // CALIBRATE
    flagScale: 0,
    captionScale: 1.6, // CALIBRATE
    padding: EdgeInsets.zero,
  );

  static const List<PlateRule> _motoRule5 = <PlateRule>[
    PlateRule(box: PlateBox(35, 158, 219, 8)), // CALIBRATE
  ];

  static const List<PlateSlot> _motoGov2Serial5 = <PlateSlot>[
    PlateSlot(
      alphabet: YemenAlphabets.governorateTens,
      box: PlateBox(113, 82, 29, 66), // CALIBRATE
    ),
    PlateSlot(
      alphabet: YemenAlphabets.digits,
      box: PlateBox(146, 82, 29, 66), // CALIBRATE
    ),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(39, 172, 39, 88)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(82, 172, 39, 88)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(125, 172, 39, 88)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(168, 172, 39, 88)),
    PlateSlot(alphabet: YemenAlphabets.digits, box: PlateBox(211, 172, 39, 88)),
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
