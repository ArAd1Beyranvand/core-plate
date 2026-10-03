import 'package:flutter/widgets.dart';

/// The colours of Bolivian plates.
///
/// Sampled where the article has a picture: the PTA plate from the photo
/// `Matrícula_automovilística_Bolivia_2006_1852PHD_La_Paz.jpg` (median of the
/// blue ink mask, modal colour of the field), the diplomatic plate from
/// `KennzeichenBolivienCD.jpg`, the Mercosur plate from its artwork. The rest
/// have no picture and are marked as such.
abstract final class BoliviaColors {
  /// PTA field and ink. The rim is pressed in the ink.
  static const Color white = Color(0xFFF4F4F0);
  static const Color blue = Color(0xFF2F4DC5);

  /// Diplomatic (`CD`) field and ink. The photo's red is sun-faded; this is
  /// what its pixels say, not the paint when new.
  static const Color diplomaticWhite = Color(0xFFFCF8F6);
  static const Color diplomaticRed = Color(0xFFF26771);

  /// Mercosur band, sampled from the artwork, and its black ink.
  static const Color mercosurBlue = Color(0xFF004088);
  static const Color mercosurBlack = Color(0xFF111111);
  static const Color mercosurWhite = Color(0xFFFCFCFC);

  /// The flag's stripes, from the Wikimedia SVG (`Flag_of_Bolivia.svg`). The
  /// plates print the flag; the photo's are the same hues, over-exposed.
  static const Color flagRed = Color(0xFFD52B1E);
  static const Color flagYellow = Color(0xFFF9E300);
  static const Color flagGreen = Color(0xFF007934);

  /// Not photographed. The article gives only "white on blue" (consular),
  /// "black on yellow" (international mission) and "white on green"
  /// (international organisation). Placeholders until a photo turns up: the
  /// PTA blue, and a yellow and a green kept clear of the flag's so its
  /// stripes stay visible on the field.
  static const Color consularBlue = blue;
  static const Color missionYellow = Color(0xFFFFC72C);
  static const Color organizationGreen = Color(0xFF0B9A55);
  static const Color black = Color(0xFF1B1B1D);

  static const Color inactiveOnDark = Color(0xFF8A8A8A);
  static const Color inactiveOnLight = Color(0xFFB0B0B0);
}
