import 'package:flutter/widgets.dart';

/// Every colour a Palestinian plate is printed in. No official hex is published;
/// values marked `// CALIBRATE` are provisional and expected to change based on
/// reference photographs.
abstract final class PSColors {
  /// West Bank plate ink. Sampled from `palestine_plate/pics/reference_plate.png`.
  static const Color green = Color(0xFF3C875D);

  /// Government and duty-exempt West Bank plates, Gaza government plates.
  // CALIBRATE — no reference image.
  static const Color red = Color(0xFFC8102E);

  /// Trade plate field, Gaza public-transport and municipality glyphs.
  // CALIBRATE — no reference image.
  static const Color blue = Color(0xFF1B4F9C);

  /// Gaza commercial plate glyphs.
  // CALIBRATE — distinct from `green` to avoid silent recalibration coupling.
  static const Color gazaCommercialGreen = Color(0xFF0F7A3D);

  /// Plate field (every Palestinian plate in scope is printed on white).
  static const Color white = Color(0xFFFFFFFF);

  /// Gaza private plate glyphs (near-black for consistency with PlateTheme.standard).
  // CALIBRATE
  static const Color black = Color(0xFF0A0A0A);

  /// Unfilled slot outline when input is active (soft tint of green ink).
  // CALIBRATE
  static const Color inactiveGreen = Color(0x669BC1AB);

  /// Unfilled slot outline when ink is not green.
  // CALIBRATE
  static const Color inactiveNeutral = Color(0x66666666);

  /// Unfilled slot outline on dark fields (public transport, trade plates).
  // CALIBRATE
  static const Color inactiveOnDark = Color(0x66FFFFFF);
}
