import 'package:flutter/widgets.dart';

/// The colours of Tunisian plates, sampled from the article's photographs
/// (median of the field and of the eroded ink mask, inside the rim). There is
/// no vector artwork and the ATTT publishes no values, so these carry each
/// photo's lighting; where several photos show one paint, the median of them.
abstract final class TunisiaColors {
  /// Field of the ordinary, military and temporary plates: the median of the
  /// standard (302721), military (1B171E) and temporary (26262A) photos.
  static const Color black = Color(0xFF262621);

  /// Ink on every dark plate: the median of five photos (D1C2B5 … FFFFFF).
  static const Color white = Color(0xFFDDDACD);

  /// The pressed aluminium rim of the ordinary and rental plates: median of
  /// four photos (898882 … E4E6F9).
  static const Color rimSilver = Color(0xFFB3B6B2);

  /// Rental field. The article's "blue".
  static const Color rentalBlue = Color(0xFF054980);

  /// Government plate: field and ink.
  static const Color governmentWhite = Color(0xFFF0EEF1);
  static const Color governmentRed = Color(0xFFC72431);

  /// Diplomatic plate: field and ink. The field is a white in partial shade.
  static const Color diplomaticWhite = Color(0xFFE7E7E7);
  static const Color diplomaticBlack = Color(0xFF1B1B1D);

  /// The official flag red (`#e70013` in the Wikimedia SVG), for hosts.
  static const Color flagRed = Color(0xFFE70013);

  static const Color inactiveOnDark = Color(0xFF8A8A8A);
  static const Color inactiveOnLight = Color(0xFFB0B0B0);
}
