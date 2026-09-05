import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'palestine_colors.dart';

/// The country block on a Palestinian plate — of which there are two, because
/// there are two designs.
///
/// A West Bank plate carries no flag. The block right of the vertical rule is
/// `ف` over `P`, printed in the plate's own ink on the plate's own field: not a
/// coloured slab of its own, just lettering. `P` is **Portugal's**
/// code, used unofficially because Palestine has no assigned international
/// vehicle code. It is a literal glyph on the plate, never the result of a
/// country-code lookup, and nothing here should be tempted to resolve it.
///
/// A Gaza plate carries the flag and no caption at all.
///
/// ## Why there are several West Bank consts
///
/// [PlateCountry] carries colours and [PlateSpec] carries a country, so a
/// country const is pinned to one colour scheme — which collides head-on with
/// a design whose colour is derived from usage. The resolution is one const per
/// **ink** colour, with [PlateCountry.panelColor] left transparent so the plate
/// face shows through whatever the host's [PlateTheme] paints it:
///
/// - [westBankGreenInk] — private, leased, police.
/// - [westBankWhiteInk] — public transport (inverted, white on green) and the
///   trade plate (white on blue). One const covers both: the block is white
///   lettering on the field in each case, and the field's colour is the theme's
///   business, not the country's.
/// - [westBankRedInk] — government and duty-exempt.
///
/// Transparent rather than a literal white is what collapses six schemes into
/// three. It is a small departure from the way `palestine_plate` wrote the same
/// block (it used opaque white, which is right on a white plate and paints a
/// white hole in a green one).
///
/// All of them use `code: 'ps'`, so they compare equal — [PlateCountry]'s
/// equality is over the code, and this is one country.
abstract final class PSCountries {
  /// The `ف / P` block in green: the ordinary West Bank plate.
  ///
  /// The short horizontal rule between the two lines is **not** part of this
  /// value. [CountryPanel] paints a flag and a caption and nothing else, so the
  /// rule is a [PlateRule] on the spec, drawn over the block. Carried over
  /// deliberately from `palestine_plate`, which found the same thing.
  static const PlateCountry westBankGreenInk = PlateCountry(
    code: 'ps',
    captionLines: ['ف', 'P'],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.green,
    flag: null,
  );

  /// The same block in white, for the two schemes printed on a dark field: the
  /// inverted public-transport plate and the blue trade plate.
  static const PlateCountry westBankWhiteInk = PlateCountry(
    code: 'ps',
    captionLines: ['ف', 'P'],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.white,
    flag: null,
  );

  /// The same block in red, for government and duty-exempt plates.
  static const PlateCountry westBankRedInk = PlateCountry(
    code: 'ps',
    captionLines: ['ف', 'P'],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.red,
    flag: null,
  );

  /// [westBankGreenInk] with `ف` and `P` on **one line**, for the near-square
  /// two-line motorcycle plate, where the block is a wide, shallow band across
  /// the bottom rather than a tall strip on the right.
  ///
  /// A separate const because [CountryPanel] lays [PlateCountry.captionLines]
  /// out as a `Column` — top to bottom, always — and offers no horizontal
  /// arrangement. Two entries in a 37-unit-tall band would be two tiny stacked
  /// lines, not the side-by-side pair the plate has. Putting both glyphs in one
  /// string is the only way to get them beside each other today; see
  /// "core_plate limitations" in README.md.
  ///
  /// One consequence: the divider between `ف` and `P` is omitted here. On the
  /// tall block it is a horizontal [PlateRule] at a known y; between two glyphs
  /// on one line it would be a vertical rule at an x that depends on the text
  /// metrics of a font this package does not ship, and a rule in the wrong
  /// place is worse than none.
  // TODO(palestine_plate): confirm against a photograph that the two-line moto
  // plate really does set ف and P side by side, and whether a divider survives.
  static const PlateCountry westBankGreenInkInline = PlateCountry(
    code: 'ps',
    captionLines: ['ف  P'],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.green,
    flag: null,
  );

  /// [westBankGreenInk] with **no caption and no flag**, for the one-line
  /// motorcycle plate.
  ///
  /// That plate sets `P` and `ف` side by side with a vertical divider between
  /// them, at positions measured off
  /// `pics/License_Plate_-_Palestine_-_Motorcycle_-_2018_-_1-Line_Design.png`.
  /// [CountryPanel] cannot draw that: it lays [PlateCountry.captionLines] out
  /// as a `Column`, and putting both glyphs in one string (the
  /// [westBankGreenInkInline] trick) leaves the divider at an x that depends on
  /// font metrics this package does not ship.
  ///
  /// So `PSWestBankPlates.modernMoto` prints the two glyphs as [PlateLabel]s at
  /// their measured x, and the divider as a [PlateRule] at its measured x, and
  /// the country panel draws nothing at all. Two labels rather than one is also
  /// what keeps `P` on the left of `ف`: each label is an isolated bidi run, the
  /// same reason the trade plate's `اختبار` and `במבחן` must stay two labels.
  ///
  /// Everything else — the code, the ink — matches [westBankGreenInk], so this
  /// still compares equal to every other West Bank const.
  static const PlateCountry westBankGreenInkBlank = PlateCountry(
    code: 'ps',
    captionLines: [],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.green,
    flag: null,
  );

  /// Gaza, 2012–2021: the flag turned a quarter turn, filling a tall strip on
  /// the right of the plate.
  ///
  /// [PlateCountry.captionLines] is empty — the flag is the whole block, and
  /// there is no `ف / P` on a Gaza plate. The aspect ratio is the *rotated*
  /// one, 1:2, matching the pre-rotated asset: `core_plate` has no rotation
  /// hook, so the turn is baked into the SVG rather than applied at render
  /// time.
  ///
  /// [PlateCountry.panelColor] is transparent for the same reason as the West
  /// Bank consts, though here it is only tidiness: a Gaza plate's field is
  /// always white.
  static const PlateCountry gaza2012 = PlateCountry(
    code: 'ps',
    captionLines: [],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.black,
    flagAspectRatio: 1 / 2,
    flag: SvgPlateAsset(
      'assets/flags/Flag_of_Palestine_vertical.svg',
      package: 'palestine_plate',
    ),
  );

  /// Gaza, 2021 onward: the flag the right way up, at its official 2:1 ratio.
  static const PlateCountry gaza2021 = PlateCountry(
    code: 'ps',
    captionLines: [],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.black,
    flagAspectRatio: 2 / 1,
    flag: SvgPlateAsset(
      'assets/flags/Flag_of_Palestine.svg',
      package: 'palestine_plate',
    ),
  );
}
