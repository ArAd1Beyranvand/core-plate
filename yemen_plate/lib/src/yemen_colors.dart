import 'package:flutter/widgets.dart';

/// Every colour a Yemeni plate is printed in, in one file.
///
/// **All of these are unverified.** None was sampled from a photograph: the
/// 2026 unified plate is weeks old at the time of writing and its only public
/// image is a low-resolution ministry mock-up, and the 1993 northern plate's
/// five field colours are named in prose ("blue", "yellow", "red", "green",
/// "black") rather than specified. So every constant here carries a
/// `// CALIBRATE` and means "the right hue family, roughly the right value" —
/// not "this hex is on the plate".
///
/// Colour never goes into a [PlateSpec]. It goes into a `PlateTheme` (see
/// `YemenThemes`) and into the two `PlateCountry` colour fields, both of which
/// read from here. That separation is `core_plate`'s, and it is why a
/// recalibration of this file is a one-file change that leaves every spec
/// alone.
abstract final class YemenColors {
  // -------------------------------------------------------------------------
  // System A — the 2026 unified plate.
  //
  // The field is white for every usage. System A does not colour-code by use;
  // the usage is carried by the two text lines in the blue side panel and
  // nowhere else. Resist the symmetry with System B below.
  // -------------------------------------------------------------------------

  /// The white field, for every usage.
  static const Color unifiedField = Color(0xFFFFFFFF); // CALIBRATE

  /// Every glyph on the unified plate — the number, the country block, the
  /// side code and the usage lines alike.
  static const Color unifiedInk = Color(0xFF111111); // CALIBRATE

  /// The thick rounded outer frame. Now unreferenced — `YemenThemes.unified`
  /// prints the frame in [unifiedInk] via `PlateTheme.monochrome`. Kept as a
  /// distinct calibration target; candidate for removal in P9.
  static const Color unifiedFrame = Color(0xFF111111); // CALIBRATE

  /// The light blue of the right-hand side panel. The one System A colour the
  /// brief gives a hex for, and still a guess at the printed ink.
  static const Color unifiedSidePanel = Color(0xFF7FB2E5); // CALIBRATE

  // -------------------------------------------------------------------------
  // System B — the 1993 northern plate, where the field colour IS the usage.
  // -------------------------------------------------------------------------

  /// Private vehicles (خصوصي).
  static const Color blue = Color(0xFF1F5FA8); // CALIBRATE

  /// Taxis and buses (اجرة).
  static const Color yellow = Color(0xFFF2C200); // CALIBRATE

  /// Goods vehicles, pick-ups, trucks and trailers (نقل).
  static const Color red = Color(0xFFC0261F); // CALIBRATE

  /// Government vehicles.
  static const Color green = Color(0xFF14733E); // CALIBRATE

  /// The classic military field.
  static const Color black = Color(0xFF111111); // CALIBRATE

  /// The modern military field, which pairs white with [militaryRed].
  static const Color white = Color(0xFFFFFFFF); // CALIBRATE

  /// The ink of the modern (white + red) military form.
  static const Color militaryRed = Color(0xFFC0261F); // CALIBRATE

  // -------------------------------------------------------------------------
  // Ink. A northern plate prints black on the light fields and white on the
  // dark ones; the pairing is fixed per usage and lives in `YemenThemes`.
  // -------------------------------------------------------------------------

  /// Ink on the blue, yellow and red fields.
  static const Color darkInk = Color(0xFF111111); // CALIBRATE

  /// Ink on the green and black fields.
  static const Color lightInk = Color(0xFFFFFFFF); // CALIBRATE

  /// The unfocused-slot outline, in input mode only. Never plate chrome — it
  /// is `PlateTheme.inactiveColor`, which core paints under an empty field.
  static const Color inactiveOnLight = Color(0x66666666); // CALIBRATE

  /// The same, for a dark field where a grey outline would vanish.
  static const Color inactiveOnDark = Color(0x66FFFFFF); // CALIBRATE
}
