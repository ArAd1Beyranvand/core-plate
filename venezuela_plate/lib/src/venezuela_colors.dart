import 'package:flutter/widgets.dart';

/// Every colour a Venezuelan plate is printed in. No clean artwork exists, so
/// each is sampled from the three frontal photographs on Wikipedia (AB174SK
/// Lara, AA064ST Trujillo, AE328KG Carabobo), with every photograph first
/// scaled so its white field reads `FFFFFF`. Each is a calibration target.
/// Colours go into `VenezuelaThemes`, never into specs.
abstract final class VenezuelaColors {
  static const Color field = Color(0xFFFFFFFF);

  /// Characters and frame: the darkest 8% of the serial, `313A69`, `211E3F`,
  /// `4A3F5F` balanced; the median. A navy, not a black.
  static const Color ink = Color(0xFF313A5F); // CALIBRATE

  /// REPUBLICA BOLIVARIANA DE VENEZUELA: `2E6DCF`, `3996FF`, `4074EE`
  /// balanced; the median. Brighter than the ink.
  static const Color caption = Color(0xFF3974EE); // CALIBRATE

  /// The flag at full strength: the median of each band sampled at the
  /// plate's ends, where the white fog does not reach (six samples per band
  /// across the three photographs). The pale print over the middle —
  /// `FFF1B7`, `92B4F8`, `EE999F` — is roughly these under the spec's fog.
  static const Color yellow = Color(0xFFFFE96B); // CALIBRATE
  static const Color blue = Color(0xFF2C88F9); // CALIBRATE
  static const Color red = Color(0xFFE0353A); // CALIBRATE

  /// Unfocused slot outline.
  static const Color inactive = Color(0x66666666);
}
