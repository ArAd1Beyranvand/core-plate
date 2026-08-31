import 'package:flutter/widgets.dart';

import 'plate_asset.dart';

/// Describes the country-specific chrome of a licence plate: which flag to
/// draw, the caption printed beside it, and the colours of the country panel.
///
/// This is the single place a country's chrome is described — a country is
/// data (a [PlateCountry] value), not a widget. [CountryPanel] and [PlateFlag]
/// read everything they need from here. The concrete country constants live in
/// their own files (`countries/…`) so a package split is a directory move.
@immutable
class PlateCountry {
  const PlateCountry({
    required this.code,
    required this.captionLines,
    required this.panelColor,
    required this.panelTextColor,
    this.flagAspectRatio = 7 / 4,
    this.flag,
  });

  /// ISO 3166-1 alpha-2 country code, lower-case. Used for equality and
  /// persistence.
  final String code;

  /// The lines of text printed on the panel beside the flag, top to bottom
  /// (e.g. `['EU']`). Always laid out LTR.
  final List<String> captionLines;

  /// Background colour of the country panel block.
  final Color panelColor;

  /// Text colour on the [panelColor] block.
  final Color panelTextColor;

  /// Width/height ratio of this country's flag, used to size it within
  /// [CountryPanel] without distortion or overflow.
  final double flagAspectRatio;

  /// The flag asset this country ships, or null for a country with no flag.
  /// [PlateFlag] renders nothing when it is null.
  final PlateAsset? flag;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlateCountry && other.code == code);

  @override
  int get hashCode => code.hashCode;
}
