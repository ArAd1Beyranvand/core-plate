import 'package:flutter/widgets.dart';

/// Every colour a Palestinian plate is printed in.
///
/// **No official hex is published for any of these.** Where a value was sampled
/// off a reference image the comment says which image; everywhere else it is a
/// plausible reading of a photograph and carries `// CALIBRATE`, which means:
/// this number is provisional, changing it is expected, and the golden tests
/// exist so that changing it shows up as a visible diff rather than a silent
/// one.
///
/// Colour never lives on a [PlateSpec] — a spec is geometry. These feed
/// `PSThemes`, and a host passes the theme.
abstract final class PSColors {
  /// The green a West Bank plate's border, digits, rules and `ف / P` block are
  /// printed in.
  ///
  /// Sampled from `palestine_plate/pics/reference_plate.png` — 29 397 pixels of
  /// the 520x260 image are exactly this value, so it is the plate's ink and not
  /// an anti-aliased edge.
  ///
  /// The first-pass brief for this package proposed `0xFF0F6B3C`, a darker,
  /// more saturated green taken from the flag rather than from a plate. The
  /// sample wins: it is measured, and it comes from the artefact being drawn.
  /// The flag's green survives — in
  /// `assets/flags/Flag_of_Palestine.svg`, where it belongs.
  static const Color green = Color(0xFF3C875D);

  /// The red a government (legacy usage `99`) or duty-exempt (legacy `31`)
  /// West Bank plate, and a Gaza government plate, are printed in.
  // CALIBRATE — no reference image in this repo shows a red Palestinian plate.
  static const Color red = Color(0xFFC8102E);

  /// The blue of a trade/test plate's field, and of a Gaza public-transport or
  /// municipality plate's glyphs.
  // CALIBRATE — no reference image; two different plates share one value here
  // purely because nothing attests that they differ.
  static const Color blue = Color(0xFF1B4F9C);

  /// The glyph colour of a Gaza commercial plate.
  // CALIBRATE — no reference image. Deliberately not `green`: the Gaza design
  // is not the West Bank design, and tying the two together would make a
  // recalibration of one silently move the other.
  static const Color gazaCommercialGreen = Color(0xFF0F7A3D);

  /// The plate field. Not calibrated because it is not a reading: every
  /// Palestinian plate in scope here is printed on white.
  static const Color white = Color(0xFFFFFFFF);

  /// The glyph colour of a Gaza private plate. Near-black rather than pure
  /// black, matching what `PlateTheme.standard` uses for ink.
  // CALIBRATE
  static const Color black = Color(0xFF0A0A0A);

  /// The outline a [PlateCanvas] gives an empty slot while the plate is being
  /// typed. Chrome for the input state, never printed on a real plate — so it
  /// is a soft tint of the ink rather than a measured colour.
  // CALIBRATE
  static const Color inactiveGreen = Color(0x669BC1AB);

  /// The same, for the schemes whose ink is not green.
  // CALIBRATE
  static const Color inactiveNeutral = Color(0x66666666);

  /// The same, on a dark field (the inverted public-transport plate and the
  /// blue trade plate), where a grey outline disappears.
  // CALIBRATE
  static const Color inactiveOnDark = Color(0x66FFFFFF);
}
