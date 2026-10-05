import 'package:flutter/widgets.dart';

/// The colours of the 2001 Lao plates.
///
/// Every reference is a photograph, not artwork, so a raw sample is the
/// paint times the light: white fields read anywhere from `ABABAB` to
/// `D7D6D7`. Each value below is the median of the stroke interiors (eroded
/// 9 px, so edges and emboss shading drop out) of one flattened photo,
/// rescaled per channel so that a known white in the same photo — the white
/// field, the white ink, the emblem sticker, or the car's white paint —
/// comes out `FFFFFF`. The photo and the white each value used is named.
abstract final class LaosColors {
  /// Private field. `Laos_Private_Car…`, against its emblem sticker: `FFDC00`.
  static const Color yellow = Color(0xFFFFDC00);

  /// Private EV field. `Laos_Private_Electric_Car…`, against its sticker:
  /// `FFAF00`. White-balanced the same way as [yellow] it is still 45 lower
  /// in green — an amber, not the private plate's yellow — so the two are
  /// kept apart. Whether that is the paint or the overcast sky in one of the
  /// two photos, one photo each cannot tell.
  static const Color amber = Color(0xFFFFAF00);

  /// Government field. `Laos_Government_Car…`, against its white ink:
  /// `1E81F5`.
  static const Color governmentBlue = Color(0xFF1E81F5);

  /// Taxable-company ink and frame. `Laos_Taxable_Company_Car…`, against its
  /// white field: `01A3F7`, a sky blue.
  static const Color taxableBlue = Color(0xFF01A3F7);

  /// International-organisation field. `Laos_diplomatic…`, against the
  /// white car body under the plate (its sticker is in shade): `D0D0D0`.
  static const Color silver = Color(0xFFD0D0D0);

  /// International-organisation ink and frame, same photo: `38A5EF`. Paler
  /// and greyer than [taxableBlue]; a second blue.
  static const Color paleBlue = Color(0xFF38A5EF);

  /// Police field. `License_plates_of_Laos`, against its white ink: `DC303C`.
  static const Color red = Color(0xFFDC303C);

  /// The black ink of the private, company and temporary plates: the median
  /// of their four corrected samples (`383639`, `1F1C1C`, `252324`,
  /// `444146`), which differ by the sheen on embossed paint, not by colour.
  static const Color black = Color(0xFF2D2B2D);

  static const Color white = Color(0xFFFFFFFF);

  /// The 2024 EV badge. `Laos_Private_Electric_Car…`, against the badge's own
  /// white letters: `2CCF47`. The company EV photo's badge samples a paler
  /// `82D47A`, its red and blue lifted equally — glare on a glossy sticker.
  static const Color evGreen = Color(0xFF2CCF47);

  static const Color inactive = Color(0xFFB0B0B0);
}
