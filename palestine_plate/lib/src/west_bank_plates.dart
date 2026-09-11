import 'package:flutter/widgets.dart';
import 'package:core_plate/core_plate.dart';

import 'palestine_alphabets.dart';
import 'palestine_country.dart';
import 'palestine_usage.dart';

/// The West Bank plate designs.
///
/// Two serial schemes share one visual template, and they are two specs rather
/// than one because they differ in slot count and in what the trailing group
/// accepts:
///
/// - **[modernCar]** (issued since July 2018) — `D · DDDD · L`. One digit, a
///   four-digit running serial, and one Latin capital naming the governorate.
///   Six characters. **It encodes no usage**: a host that needs one supplies it
///   separately and `PSUsage.private` is the sensible default.
/// - **[legacyCar]** (1994 – July 2018, and still very common on the road) —
///   `D · DDDD · DD`. A district code, four digits, and a two-digit usage
///   class. Seven digits, no letters. The usage class is what drives colour.
///
/// ## Geometry
///
/// The one-line 520 x 110 layout is measured off
/// `palestine_plate/pics/reference_plate.png`, a 520 x 260 render of
/// `1·0234·H` — which is a modern-scheme plate, so [modernCar]'s horizontal
/// positions are the reference's own, unit for unit. Everything else is
/// derived from it and marked `// CALIBRATE`:
///
/// - **Vertical positions are not the reference's.** That image is 2:1, and a
///   real single-line plate is closer to 4.7:1, so its glyph band scaled down
///   directly would be far too shallow. Instead the band keeps the reference's
///   *proportion* — its cap band is 43.5% of the image height — which on a 110
///   canvas is a 92-tall cell.
/// - The seven-glyph layouts (legacy, Gaza) reuse the reference's cell-to-gap
///   ratio at a smaller pitch, because seven cells do not fit at six cells'
///   pitch.
/// - [modernMoto] is the **second measured plate** in this file: it has a
///   reference of its own,
///   `pics/License_Plate_-_Palestine_-_Motorcycle_-_2018_-_1-Line_Design.png`,
///   and its canvas is that image's pixels 1:1. It is not this template
///   rescaled — see its own doc.
/// - Every other form factor is provisional throughout.
///
/// ## The raised dots
///
/// The groups are separated by a printed `·`, not by whitespace. This is a
/// departure from the "leave a gap" instruction in this package's brief, and
/// the reference photograph is why: it clearly shows a dot between `1` and
/// `0234` and between `0234` and `H`, and its gaps happen to measure almost
/// exactly the 0.6-glyph-width the brief asks for — so the dot sits *inside*
/// the gap rather than replacing it. Both are true and the dot is attested.
///
/// A dot is a [PlateLabel], not a [PlateRule]: it is printed in the same ink as
/// the digits and scales with them, which is what a label does.
///
/// ## Colour
///
/// None of these specs carries a colour. [PlateSpec] has no theme field; the
/// host passes `PSThemes.forUsage(usage)`. Where the *ink* changes — the
/// inverted public-transport plate, the red government plate — the `ف / P`
/// block has to change with it, and it does: the host hands
/// `PSWestBankPlates.legacyCountryForUsage(usage)` to `PlateCanvas.country`
/// beside the theme, and the block is recoloured at render time. One spec,
/// [legacyCar], covers every legacy usage.
///
/// Motorcycles use the identical serial grammar and are legally private
/// vehicles. [modernMoto] and [modernMotoTwoLine] are form factors, not a
/// usage — do not add a `PSUsage.motorcycle`. Both put `P` and `ف` side by
/// side rather than stacked, because neither is tall enough for the car
/// plate's vertical strip; [modernMoto] additionally keeps the divider between
/// them, since its reference image fixes the divider's x.
abstract final class PSWestBankPlates {
  // -------------------------------------------------------------------------
  // Shared 520 x 110 furniture. Const lists, so the colour-scheme variants
  // below are ten lines each instead of a copy of the whole plate.
  // -------------------------------------------------------------------------

  /// The full-height rule between the serial and the `ف / P` block.
  /// x from the reference (its rule is 5 units wide at x=441); y spans the
  /// plate face clear of the ~3-unit border.
  static const List<PlateRule> _carRules = [
    PlateRule(box: PlateBox(441, 8, 5, 94)),
    // The short horizontal rule between `ف` and `P`. `CountryPanel` paints a
    // flag and a caption and nothing else, so this cannot live on the country
    // — it is a rule on the spec, drawn over the block. Its y is where the two
    // caption lines meet: 48% down the block, measured off the reference.
    PlateRule(box: PlateBox(452, 51, 46, 5)),
  ];

  /// The `ف / P` block. Not a coloured panel slab — it is ink on the plate
  /// face — so the box sits flush where the printing does and there is no seam
  /// to hide under the border.
  ///
  /// `flagScale: 0` because there is no flag: hand the caption the block's
  /// whole height rather than reserving a strip for a null image.
  /// `captionScale: 1.9` puts two 24-unit lines at 45.6 each, filling the
  /// 94-tall block.
  static const PlatePanel _carPanel = PlatePanel(
    box: PlateBox(452, 8, 46, 94), // CALIBRATE — x measured, y proportional.
    flagScale: 0,
    captionScale: 1.9,
    padding: EdgeInsets.symmetric(vertical: 5),
  );

  // -------------------------------------------------------------------------
  // Modern: D · DDDD · L
  // -------------------------------------------------------------------------

  /// Cells are 55 x 92 on a 59-unit pitch, with a 33-unit gap between groups.
  /// Widths and x positions are the reference's; the 92 height is its cap band
  /// as a fraction of plate height (43.5%) rather than its absolute pixels.
  ///
  /// Three groups, and only the middle one is a register: the region digit and
  /// the governorate letter are isolated cells with a gap either side, so they
  /// stay literals.
  static final List<PlateSlot> _modernCarSlots = [
    const PlateSlot(
      alphabet: PSAlphabets.digits,
      box: PlateBox(19.5, 9, 55, 92),
    ),
    ...plateRegister(
      alphabet: PSAlphabets.digits,
      count: 4,
      left: 109.5,
      top: 9,
      width: 55,
      height: 92,
      pitch: 59,
    ),
    const PlateSlot(
      alphabet: PSAlphabets.governorateLetters,
      box: PlateBox(375.5, 9, 55, 92),
    ),
  ];

  /// Dot geometry follows one rule everywhere in this file, so a band's height
  /// determines it: box top at 30% into the band, box 0.35 x 0.40 of the band
  /// height, glyph 0.55 of it. Reproduces `palestine_plate`'s hand-tuned
  /// numbers exactly when applied to its band.
  static const List<PlateLabel> _modernCarLabels = [
    PlateLabel(text: '·', box: PlateBox(71.4, 36.6, 32.2, 36.8), glyphHeight: 50.6),
    PlateLabel(text: '·', box: PlateBox(344.4, 36.6, 32.2, 36.8), glyphHeight: 50.6),
  ];

  static const List<PlateTextGroup> _modernGroups = [
    PlateTextGroup([0], key: 'region'),
    PlateTextGroup([1, 2, 3, 4], key: 'serial'),
    PlateTextGroup([5], key: 'governorate'),
  ];

  /// The standard West Bank car plate issued since July 2018.
  ///
  /// Pair it with `PSThemes.forUsage(...)`; on the default black-on-white theme
  /// the layout still holds — [PlateSpec.borderWidthRatioOverride] carries the
  /// plate's thinner border independently of the theme — but the plate is the
  /// wrong colour.
  static final PlateSpec modernCar = PlateSpec(
    id: 'ps.wb.modern.car',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: _carPanel,
    // 0.027 * 110 = 2.97 units of border: 7px on the 260-tall reference.
    // Repeated here as well as in every PSThemes const so the geometry survives
    // a host that supplies its own theme.
    borderWidthRatioOverride: 0.027,
    slots: _modernCarSlots,
    rules: _carRules,
    labels: _modernCarLabels,
    textGroups: _modernGroups,
  );

  // -------------------------------------------------------------------------
  // Legacy: D · DDDD · DD
  // -------------------------------------------------------------------------

  /// Seven cells where the modern plate has six, so 47 x 92 on a 51-unit pitch
  /// with 28-unit gaps — the reference's 4-unit inter-cell space and its
  /// gap-to-cell ratio, at the pitch seven glyphs leave room for.
  // CALIBRATE — derived, not measured; no seven-glyph reference image exists.
  static final List<PlateSlot> _legacyCarSlots = [
    const PlateSlot(
      alphabet: PSAlphabets.districtDigits,
      box: PlateBox(20, 9, 47, 92),
    ),
    ...plateRegister(
      alphabet: PSAlphabets.digits,
      count: 4,
      left: 95,
      top: 9,
      width: 47,
      height: 92,
      pitch: 51,
    ),
    // The usage pair, past the second gap. Two cells at the serial's own
    // pitch, but a group of their own.
    const PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(323, 9, 47, 92)),
    const PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(374, 9, 47, 92)),
  ];

  static const List<PlateLabel> _legacyCarLabels = [
    PlateLabel(text: '·', box: PlateBox(64.9, 36.6, 32.2, 36.8), glyphHeight: 50.6),
    PlateLabel(text: '·', box: PlateBox(292.9, 36.6, 32.2, 36.8), glyphHeight: 50.6),
  ];

  static const List<PlateTextGroup> _legacyGroups = [
    PlateTextGroup([0], key: 'district'),
    PlateTextGroup([1, 2, 3, 4], key: 'serial'),
    PlateTextGroup([5, 6], key: 'usage'),
  ];

  /// The pre-2018 West Bank car plate. Green on white by default — the private,
  /// leased and (by convention) police colouring — and recoloured for other
  /// usages by handing [legacyCountryForUsage] to `PlateCanvas.country`.
  ///
  /// The trailing pair is a usage class, so a host that has the plate's value
  /// can derive both the usage and the colour from it:
  /// `PSLegacyUsage.forCode(spec.valueOfGroup('usage', values))`.
  static final PlateSpec legacyCar = PlateSpec(
    id: 'ps.wb.legacy.car',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: _carPanel,
    borderWidthRatioOverride: 0.027,
    slots: _legacyCarSlots,
    rules: _carRules,
    labels: _legacyCarLabels,
    textGroups: _legacyGroups,
  );

  /// The `ف / P` block a legacy plate of this usage is printed in — the value a
  /// host hands to `PlateCanvas.country` beside the theme from
  /// `PSThemes.forUsage`.
  ///
  /// Geometry is identical across every legacy usage; only the ink changes,
  /// and ink is a render-time choice.
  static PlateCountry legacyCountryForUsage(PSUsage usage) => switch (usage) {
    PSUsage.publicTransport || PSUsage.tradePlate => PSCountries.westBankWhiteInk,
    PSUsage.government || PSUsage.exempt => PSCountries.westBankRedInk,
    _ => PSCountries.westBankGreenInk,
  };

  // -------------------------------------------------------------------------
  // Two-line 300 x 150, for imported vehicles whose bumper cannot take a
  // one-line plate. Groups 1 and 2 on line 1, group 3 on line 2; the identity
  // strip stays on the right, full height.
  // -------------------------------------------------------------------------

  // CALIBRATE — the whole two-line layout is provisional. No reference image.
  static const List<PlateRule> _twoLineRules = [
    PlateRule(box: PlateBox(232, 10, 5, 130)),
    PlateRule(box: PlateBox(243, 71, 50, 5)),
  ];

  static const PlatePanel _twoLinePanel = PlatePanel(
    box: PlateBox(243, 10, 50, 130),
    flagScale: 0,
    // 24 * 2.6 = 62.4 per line, so two lines fill the 130-tall block.
    captionScale: 2.6,
    padding: EdgeInsets.symmetric(vertical: 5),
  );

  static const List<PlateLabel> _twoLineLabels = [
    PlateLabel(text: '·', box: PlateBox(50, 30, 21, 24), glyphHeight: 33),
  ];

  /// [modernCar] wrapped onto two lines. `D DDDD` above, the governorate letter
  /// below.
  static final PlateSpec modernCarTwoLine = PlateSpec(
    id: 'ps.wb.modern.car2l',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 300,
    canvasHeight: 150,
    panel: _twoLinePanel,
    borderWidthRatioOverride: 0.027,
    slots: [
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(16.5, 12, 34, 60),
      ),
      ...plateRegister(
        alphabet: PSAlphabets.digits,
        count: 4,
        left: 70.5,
        top: 12,
        width: 34,
        height: 60,
        pitch: 37,
      ),
      // Line 2: the governorate letter, centred on the serial field.
      const PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(99, 80, 34, 60),
      ),
    ],
    rules: _twoLineRules,
    labels: _twoLineLabels,
    textGroups: _modernGroups,
  );

  /// [legacyCar] wrapped onto two lines. `D DDDD` above, the two usage digits
  /// below.
  static final PlateSpec legacyCarTwoLine = PlateSpec(
    id: 'ps.wb.legacy.car2l',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 300,
    canvasHeight: 150,
    panel: _twoLinePanel,
    borderWidthRatioOverride: 0.027,
    slots: [
      const PlateSlot(
        alphabet: PSAlphabets.districtDigits,
        box: PlateBox(16.5, 12, 34, 60),
      ),
      ...plateRegister(
        alphabet: PSAlphabets.digits,
        count: 4,
        left: 70.5,
        top: 12,
        width: 34,
        height: 60,
        pitch: 37,
      ),
      // Line 2: the usage pair.
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(80.5, 80, 34, 60),
      ),
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(117.5, 80, 34, 60),
      ),
    ],
    rules: _twoLineRules,
    labels: _twoLineLabels,
    textGroups: _legacyGroups,
  );

  // -------------------------------------------------------------------------
  // Motorcycles. Same serial grammar, same legal class (private) — a form
  // factor, not a usage.
  // -------------------------------------------------------------------------

  /// The one-line motorcycle plate — **the one plate in this file besides
  /// [modernCar] whose geometry is measured rather than derived.**
  ///
  /// The reference is
  /// `pics/License_Plate_-_Palestine_-_Motorcycle_-_2018_-_1-Line_Design.png`,
  /// a 250 x 123 render of `2·0345·L`, and the canvas is that image's own
  /// pixels 1:1 — so every number below is the reference's, unit for unit,
  /// with no `// CALIBRATE` on any of them.
  ///
  /// ## It is not [modernCar] rescaled
  ///
  /// It was, before the reference turned up, and the reference says otherwise.
  /// A motorcycle plate is nearly square-ish (2:1 rather than the car's 4.7:1),
  /// so the identity block cannot sit in a tall strip on the right — there is
  /// no width for it beside six glyphs. Instead:
  ///
  /// - the serial runs the **full width** of the plate, x 12.5 to 235, and
  /// - `P` and `ف` sit **side by side in a header band above it**, centred on
  ///   the plate (their combined ink spans x 99–153 on a 250-wide plate), with
  ///   a short **vertical** divider between them.
  ///
  /// Note the order: **`P` on the left, `ف` on the right** — the mirror of the
  /// stacked `ف`-over-`P` block on the car plate, and measured off the
  /// photograph rather than assumed.
  ///
  /// ## Why the block is labels rather than the country panel
  ///
  /// [CountryPanel] stacks [PlateCountry.captionLines] vertically and offers no
  /// horizontal arrangement, and the one-string workaround
  /// ([PSCountries.westBankGreenInkInline]) puts the divider at an x that
  /// depends on font metrics this package does not ship. Here the divider's x
  /// is *known* — 121, measured — so the two glyphs are [PlateLabel]s at their
  /// measured positions, the divider is a [PlateRule] at its own, and the panel
  /// draws nothing: hence [PSCountries.westBankGreenInkBlank] and the zero-size
  /// panel box.
  ///
  /// Two labels rather than one string also keeps `P` left of `ف`. Each label
  /// is an isolated bidi run — the same property [modernTrade] relies on, and
  /// for the same reason.
  static final PlateSpec modernMoto = PlateSpec(
    id: 'ps.wb.modern.moto',
    country: PSCountries.westBankGreenInkBlank,
    canvasWidth: 250,
    canvasHeight: 123,
    // The panel draws nothing; the identity block is the labels and rule below.
    panel: PlatePanel(
      box: PlateBox(0, 0, 0, 0),
      flagScale: 0,
      captionScale: 0,
      padding: EdgeInsets.zero,
    ),
    // 4 units of border on a 123-tall plate, measured off the reference.
    borderWidthRatioOverride: 0.0325,
    // Cells 30 x 62 at y=47, each centred on its glyph's measured centre:
    // 27.5, 75, 107, 139, 171, 220. The serial group's pitch is a steady 32;
    // the gaps either side of it are 48.5 and 49.
    //
    // The first serial centre was written as 75.5, which made the run's pitches
    // 31.5, 32, 32 — a half-unit of measurement noise frozen into the geometry.
    // It is 75 as of this register, so the four cells are one pitch throughout;
    // see the CHANGELOG.
    slots: [
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(12.5, 47, 30, 62),
      ),
      ...plateRegister(
        alphabet: PSAlphabets.digits,
        count: 4,
        left: 60,
        top: 47,
        width: 30,
        height: 62,
        pitch: 32,
      ),
      const PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(205, 47, 30, 62),
      ),
    ],
    rules: const [
      // The divider between `P` and `ف`: 3 wide at x=121, spanning the header
      // band. Vertical here, where the car plate's equivalent is horizontal.
      PlateRule(box: PlateBox(121, 11, 3, 28)),
    ],
    labels: [
      // The header band, y 10..38. `P` first so it lays out on the left.
      PlateLabel(text: 'P', box: PlateBox(95.5, 10, 24, 28), glyphHeight: 28),
      PlateLabel(text: 'ف', box: PlateBox(127.5, 10, 28, 28), glyphHeight: 28),
      // Dots on this file's usual proportions, which the reference confirms:
      // box top 30% into the 62-tall band, box 0.35 x 0.40 of it, glyph 0.55.
      // Puts them at centre y=78, exactly where the reference's ink sits.
      PlateLabel(text: '·', box: PlateBox(40.15, 65.6, 21.7, 24.8), glyphHeight: 34.1),
      PlateLabel(text: '·', box: PlateBox(184.65, 65.6, 21.7, 24.8), glyphHeight: 34.1),
    ],
    textGroups: _modernGroups,
  );

  /// The near-square 165 x 165 motorcycle plate: the serial wraps onto two
  /// lines and the identity block moves to a **full-width band across the
  /// bottom**, with `ف` and `P` side by side.
  ///
  /// It uses [PSCountries.westBankGreenInkInline] rather than the usual
  /// country, because `CountryPanel` stacks caption lines vertically and has no
  /// horizontal arrangement — see that const for the detail, and for why the
  /// `ف / P` divider is omitted on this form factor.
  // CALIBRATE — provisional throughout; no reference image, and the band
  // arrangement itself is unverified.
  static final PlateSpec modernMotoTwoLine = PlateSpec(
    id: 'ps.wb.modern.moto2l',
    country: PSCountries.westBankGreenInkInline,
    canvasWidth: 165,
    canvasHeight: 165,
    panel: PlatePanel(
      box: PlateBox(45, 118, 75, 38),
      flagScale: 0,
      captionScale: 1.5,
      padding: EdgeInsets.zero,
    ),
    borderWidthRatioOverride: 0.027,
    slots: [
      const PlateSlot(
        alphabet: PSAlphabets.digits,
        box: PlateBox(12.5, 14, 24, 46),
      ),
      ...plateRegister(
        alphabet: PSAlphabets.digits,
        count: 4,
        left: 50.5,
        top: 14,
        width: 24,
        height: 46,
        pitch: 26,
      ),
      const PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(70.5, 64, 24, 46),
      ),
    ],
    rules: const [
      // The analogue of the one-line plate's vertical rule: on a stacked
      // layout the serial and the identity band are separated horizontally.
      PlateRule(box: PlateBox(12, 113, 141, 3)),
    ],
    labels: [
      PlateLabel(text: '·', box: PlateBox(35.45, 27.8, 16.1, 18.4), glyphHeight: 25.3),
    ],
    textGroups: _modernGroups,
  );

  // -------------------------------------------------------------------------
  // Trade / test.
  // -------------------------------------------------------------------------

  /// The dealer and inspection plate: a blue field, white text, and a header
  /// row above the serial reading `اختبار` on the left and `במבחן` on the
  /// right. The serial takes the lower ~65% of the plate; the identity strip is
  /// retained.
  ///
  /// Pair it with `PSThemes.whiteOnBlue` (which is also what
  /// `PSThemes.forUsage(PSUsage.tradePlate)` returns).
  ///
  /// **The header is two [PlateLabel]s, and must stay two.** [PlateLabel] has
  /// no `TextDirection` field — `core_plate` lays a label out as given — so
  /// each label is an isolated run and renders correctly on its own. Concatenate
  /// the Arabic and the Hebrew into one string and the bidi algorithm reorders
  /// them *against each other*: two RTL runs in one paragraph resolve to a
  /// single RTL sequence, and the label that should be on the left ends up on
  /// the right. Two labels, two boxes, no shared paragraph, no reordering.
  ///
  /// A `const`, not a named constructor. There are no constructors in this
  /// package — a plate is a const, and adding one is adding a const.
  // CALIBRATE — provisional throughout; no reference image for the trade plate.
  static final PlateSpec modernTrade = PlateSpec(
    id: 'ps.wb.modern.trade',
    country: PSCountries.westBankWhiteInk,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: _carPanel,
    borderWidthRatioOverride: 0.027,
    slots: [
      const PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(43, 38, 48, 64)),
      ...plateRegister(
        alphabet: PSAlphabets.digits,
        count: 4,
        left: 120,
        top: 38,
        width: 48,
        height: 64,
        pitch: 51,
      ),
      const PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(350, 38, 48, 64),
      ),
    ],
    rules: _carRules,
    labels: const [
      // Left half of the header row: "test" in Arabic.
      PlateLabel(text: 'اختبار', box: PlateBox(20, 8, 200, 26), glyphHeight: 26),
      // Right half: "under test" in Hebrew. A separate label — see the doc.
      PlateLabel(text: 'במבחן', box: PlateBox(230, 8, 200, 26), glyphHeight: 26),
      PlateLabel(text: '·', box: PlateBox(94.3, 57.2, 22.4, 25.6), glyphHeight: 35.2),
      PlateLabel(text: '·', box: PlateBox(324.3, 57.2, 22.4, 25.6), glyphHeight: 35.2),
    ],
    textGroups: _modernGroups,
  );

  /// Every spec this class declares, in declaration order. Handy for a spec
  /// picker, and for the golden tests, which iterate it rather than listing the
  /// plates a second time.
  static final List<PlateSpec> all = [
    modernCar,
    legacyCar,
    modernCarTwoLine,
    legacyCarTwoLine,
    modernMoto,
    modernMotoTwoLine,
    modernTrade,
  ];
}
