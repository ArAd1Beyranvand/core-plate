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
/// block has to change with it, and [PlateCountry] carries its own colours, so
/// those schemes get their own spec consts: [legacyCarPublicTransport] and
/// [legacyCarGovernment], with [legacyCarForUsage] as the lookup.
///
/// Motorcycles use the identical serial grammar and are legally private
/// vehicles. [modernMoto] and [modernMotoTwoLine] are form factors, not a
/// usage — do not add a `PSUsage.motorcycle`.
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
    PlateRule(box: PlateBox(452, 53, 46, 3)),
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
    padding: EdgeInsets.zero,
  );

  // -------------------------------------------------------------------------
  // Modern: D · DDDD · L
  // -------------------------------------------------------------------------

  /// Cells are 55 x 92 on a 59-unit pitch, with a 33-unit gap between groups.
  /// Widths and x positions are the reference's; the 92 height is its cap band
  /// as a fraction of plate height (43.5%) rather than its absolute pixels.
  static const List<PlateSlot> _modernCarSlots = [
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(19.5, 9, 55, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(109.5, 9, 55, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(168.5, 9, 55, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(227.5, 9, 55, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(286.5, 9, 55, 92)),
    PlateSlot(
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
  static const PlateSpec modernCar = PlateSpec(
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
  static const List<PlateSlot> _legacyCarSlots = [
    PlateSlot(
      alphabet: PSAlphabets.districtDigits,
      box: PlateBox(20, 9, 47, 92),
    ),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(95, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(146, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(197, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(248, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(323, 9, 47, 92)),
    PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(374, 9, 47, 92)),
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

  /// The pre-2018 West Bank car plate, green on white — the private, leased and
  /// (by convention) police colouring.
  ///
  /// The trailing pair is a usage class, so a host that has the plate's value
  /// can derive both the usage and the colour from it:
  /// `PSLegacyUsage.forCode(spec.valueOfGroup('usage', values))`.
  static const PlateSpec legacyCar = PlateSpec(
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

  /// [legacyCar] with the `ف / P` block in white, for the inverted
  /// public-transport plate (usage `30`). Pair with `PSThemes.whiteOnGreen`.
  ///
  /// A whole second spec for one colour because [PlateCountry] carries its own
  /// text colour and [PlateSpec] carries a country: there is no way to recolour
  /// the block from the theme. **Swapping to it mid-entry resets the bloc** —
  /// see the note on [legacyCarForUsage].
  static const PlateSpec legacyCarPublicTransport = PlateSpec(
    id: 'ps.wb.legacy.car.publicTransport',
    country: PSCountries.westBankWhiteInk,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: _carPanel,
    borderWidthRatioOverride: 0.027,
    slots: _legacyCarSlots,
    rules: _carRules,
    labels: _legacyCarLabels,
    textGroups: _legacyGroups,
  );

  /// [legacyCar] with the block in red, for government (`99`) and duty-exempt
  /// (`31`) plates. Pair with `PSThemes.redOnWhite`.
  static const PlateSpec legacyCarGovernment = PlateSpec(
    id: 'ps.wb.legacy.car.government',
    country: PSCountries.westBankRedInk,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: _carPanel,
    borderWidthRatioOverride: 0.027,
    slots: _legacyCarSlots,
    rules: _carRules,
    labels: _legacyCarLabels,
    textGroups: _legacyGroups,
  );

  /// The one-line legacy spec whose `ف / P` block matches [usage]'s ink.
  ///
  /// **This is a display-time choice, not an input-time one.** Every spec it
  /// returns has the same seven slots and the same geometry, but a different
  /// [PlateSpec.id] — and swapping `spec:` on a live [PlateCanvas] dispatches
  /// `SpecIsChanged`, which empties the bloc. Resolve the usage before building
  /// the canvas, or re-seed the values yourself afterwards. The example does
  /// the latter.
  static PlateSpec legacyCarForUsage(PSUsage usage) => switch (usage) {
    PSUsage.publicTransport => legacyCarPublicTransport,
    PSUsage.government || PSUsage.exempt => legacyCarGovernment,
    _ => legacyCar,
  };

  // -------------------------------------------------------------------------
  // Two-line 300 x 150, for imported vehicles whose bumper cannot take a
  // one-line plate. Groups 1 and 2 on line 1, group 3 on line 2; the identity
  // strip stays on the right, full height.
  // -------------------------------------------------------------------------

  // CALIBRATE — the whole two-line layout is provisional. No reference image.
  static const List<PlateRule> _twoLineRules = [
    PlateRule(box: PlateBox(232, 10, 5, 130)),
    PlateRule(box: PlateBox(243, 72, 50, 4)),
  ];

  static const PlatePanel _twoLinePanel = PlatePanel(
    box: PlateBox(243, 10, 50, 130),
    flagScale: 0,
    // 24 * 2.6 = 62.4 per line, so two lines fill the 130-tall block.
    captionScale: 2.6,
    padding: EdgeInsets.zero,
  );

  static const List<PlateLabel> _twoLineLabels = [
    PlateLabel(text: '·', box: PlateBox(50, 30, 21, 24), glyphHeight: 33),
  ];

  /// [modernCar] wrapped onto two lines. `D DDDD` above, the governorate letter
  /// below.
  static const PlateSpec modernCarTwoLine = PlateSpec(
    id: 'ps.wb.modern.car2l',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 300,
    canvasHeight: 150,
    panel: _twoLinePanel,
    borderWidthRatioOverride: 0.027,
    slots: [
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(16.5, 12, 34, 60)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(70.5, 12, 34, 60)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(107.5, 12, 34, 60)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(144.5, 12, 34, 60)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(181.5, 12, 34, 60)),
      // Line 2: the governorate letter, centred on the serial field.
      PlateSlot(
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
  static const PlateSpec legacyCarTwoLine = PlateSpec(
    id: 'ps.wb.legacy.car2l',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 300,
    canvasHeight: 150,
    panel: _twoLinePanel,
    borderWidthRatioOverride: 0.027,
    slots: [
      PlateSlot(
        alphabet: PSAlphabets.districtDigits,
        box: PlateBox(16.5, 12, 34, 60),
      ),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(70.5, 12, 34, 60)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(107.5, 12, 34, 60)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(144.5, 12, 34, 60)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(181.5, 12, 34, 60)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(80.5, 80, 34, 60)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(117.5, 80, 34, 60)),
    ],
    rules: _twoLineRules,
    labels: _twoLineLabels,
    textGroups: _legacyGroups,
  );

  // -------------------------------------------------------------------------
  // Motorcycles. Same serial grammar, same legal class (private) — a form
  // factor, not a usage.
  // -------------------------------------------------------------------------

  /// [modernCar] rescaled onto a 200 x 100 motorcycle plate.
  // CALIBRATE — provisional throughout; no reference image.
  static const PlateSpec modernMoto = PlateSpec(
    id: 'ps.wb.modern.moto',
    country: PSCountries.westBankGreenInk,
    canvasWidth: 200,
    canvasHeight: 100,
    panel: PlatePanel(
      box: PlateBox(148, 7, 44, 86),
      flagScale: 0,
      captionScale: 1.75,
      padding: EdgeInsets.zero,
    ),
    borderWidthRatioOverride: 0.027,
    slots: [
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(6, 9, 17, 82)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(33, 9, 17, 82)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(52, 9, 17, 82)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(71, 9, 17, 82)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(90, 9, 17, 82)),
      PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(117, 9, 17, 82),
      ),
    ],
    rules: [
      PlateRule(box: PlateBox(140, 7, 3, 86)),
      PlateRule(box: PlateBox(148, 48, 44, 3)),
    ],
    labels: [
      PlateLabel(text: '·', box: PlateBox(13.65, 33.6, 28.7, 32.8), glyphHeight: 45.1),
      PlateLabel(text: '·', box: PlateBox(97.65, 33.6, 28.7, 32.8), glyphHeight: 45.1),
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
  static const PlateSpec modernMotoTwoLine = PlateSpec(
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
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(12.5, 14, 24, 46)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(50.5, 14, 24, 46)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(76.5, 14, 24, 46)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(102.5, 14, 24, 46)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(128.5, 14, 24, 46)),
      PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(70.5, 64, 24, 46),
      ),
    ],
    rules: [
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
  static const PlateSpec modernTrade = PlateSpec(
    id: 'ps.wb.modern.trade',
    country: PSCountries.westBankWhiteInk,
    canvasWidth: 520,
    canvasHeight: 110,
    panel: _carPanel,
    borderWidthRatioOverride: 0.027,
    slots: [
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(43, 38, 48, 64)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(120, 38, 48, 64)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(171, 38, 48, 64)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(222, 38, 48, 64)),
      PlateSlot(alphabet: PSAlphabets.digits, box: PlateBox(273, 38, 48, 64)),
      PlateSlot(
        alphabet: PSAlphabets.governorateLetters,
        box: PlateBox(350, 38, 48, 64),
      ),
    ],
    rules: _carRules,
    labels: [
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
  static const List<PlateSpec> all = [
    modernCar,
    legacyCar,
    legacyCarPublicTransport,
    legacyCarGovernment,
    modernCarTwoLine,
    legacyCarTwoLine,
    modernMoto,
    modernMotoTwoLine,
    modernTrade,
  ];
}
