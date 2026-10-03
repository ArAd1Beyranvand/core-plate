import 'package:flutter/widgets.dart';

/// The colours of Colombian plates, each the median of the region's pixels.
///
/// The private plate is sampled from clean artwork (`NAZ 827 ARMENIA`); every
/// other colour is from a photograph in the article and carries its lighting.
/// The three diplomatic-staff blues are three photographs the article calls
/// "blue" alike; their pixels disagree, so they stay three colours.
abstract final class ColombiaColors {
  /// Private: black on yellow. Artwork.
  static const Color privateYellow = Color(0xFFFFC600);
  static const Color privateBlack = Color(0xFF000000);

  /// Public service (`Servicio Público`): black on white. The San Andrés
  /// photo's white is a warm cream.
  static const Color commercialWhite = Color(0xFFDCD5BE);
  static const Color commercialBlack = Color(0xFF2B2A27);

  /// Official: white on a teal, not the "green" the article says.
  static const Color officialTeal = Color(0xFF169192);
  static const Color officialWhite = Color(0xFFF1FDFF);

  /// Antique: dark ink on white, the side strips and `ANTIGUO` in a cyan.
  static const Color antiqueWhite = Color(0xFFFFFEFA);
  static const Color antiqueInk = Color(0xFF3F1828);
  static const Color antiqueBlue = Color(0xFF0FB4F7);

  /// Consular corps (`CC`), international organisation (`OI`) and
  /// administrative staff (`AT`): white on blue, three photographs.
  static const Color consularBlue = Color(0xFF506A9D);
  static const Color consularWhite = Color(0xFFDEDDE9);
  static const Color organizationBlue = Color(0xFF001372);
  static const Color organizationWhite = Color(0xFFA7C7E6);
  static const Color staffBlue = Color(0xFF1652AA);
  static const Color staffWhite = Color(0xFFF2FBFF);

  /// National Police: green on white.
  static const Color policeWhite = Color(0xFFEAE9E7);
  static const Color policeGreen = Color(0xFF0D695A);

  /// Diplomatic corps (the new plate): dark grey on white under a blue band
  /// lettered in navy, in a dark rim.
  static const Color diplomaticWhite = Color(0xFFF6F2E9);
  static const Color diplomaticInk = Color(0xFF544D47);
  static const Color diplomaticBand = Color(0xFF367295);
  static const Color diplomaticNavy = Color(0xFF122639);
  static const Color diplomaticRim = Color(0xFF131216);

  /// Not photographed: the article gives "white on red" for the tank truck.
  /// A placeholder red. The trailer's "white on green" reuses the official
  /// teal, the colour the article gives both.
  static const Color tankRed = Color(0xFFC8102E);

  /// The screw holes, showing what is behind the plate. Artwork.
  static const Color hole = Color(0xFFFFFFFF);

  static const Color inactiveOnDark = Color(0xFF8A8A8A);
  static const Color inactiveOnLight = Color(0xFFB0B0B0);
}
