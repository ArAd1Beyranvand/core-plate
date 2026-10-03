import 'package:flutter/widgets.dart';

/// The colours an Algerian plate is printed in, sampled from the pixels of
/// the Wikipedia/Commons references (the modal colour of a region).
///
/// The front/rear artwork (`Plaque d'immatriculation - Algérie - véhicule
/// particulièr.png`) is clean vector work and is the source for the civil
/// colours. Values from photographs are marked `// CALIBRATE`.
abstract final class AlgeriaColors {
  /// Front plate field. Artwork; the 2018 photo of a front plate reads
  /// A09898 because it is aluminium in shade.
  static const Color white = Color(0xFFFFFFFF);

  /// Rear plate field. Artwork; the rear photo samples a greener F8D800.
  static const Color yellow = Color(0xFFFFC913);

  /// Digits and rim on civil plates. Artwork.
  static const Color black = Color(0xFF000000);

  /// Diplomatic field. **Not sampled** — no image of a diplomatic plate is
  /// on the page. This is the CSS `teal` of the article's example badge;
  /// the prose calls it "light teal".
  static const Color diplomaticTeal = Color(0xFF008080); // CALIBRATE

  /// Army field. `Algeria_plate_army_2018.jpg`, dusty black in sunlight.
  static const Color armyField = Color(0xFF302828); // CALIBRATE

  /// Army digits and rim: embossed bare aluminium. Same photo.
  static const Color armySilver = Color(0xFFC8B8B8); // CALIBRATE

  /// Flag green, from `Flag_of_Algeria.svg`.
  static const Color flagGreen = Color(0xFF006633);

  static const Color inactiveOnDark = Color(0xFF5A5A5A);
  static const Color inactiveOnLight = Color(0xFFB0B0B0);
}
