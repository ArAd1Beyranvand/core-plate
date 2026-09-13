import 'package:flutter/widgets.dart';

import 'plate_asset.dart';

/// Describes the country-specific chrome of a licence plate: which flag to
/// draw, the caption printed beside it, and the colours of the country panel.
///
/// This is the single place a country's chrome is described — a country is
/// data (a [PlateCountry] value), not a widget. [CountryPanel] and [PlateFlag]
/// read everything they need from here. The concrete country constants live in
/// each country's own package, not in this one.
///
/// A country value is data a *renderer* is handed, not an attribute a spec is
/// stuck with. `PlateSpec.country` is the default route, not the only one:
/// `PlateCanvas.country` and `PlateView.country` override it at render time,
/// exactly as a passed `theme` overrides the inherited one. A design whose
/// panel colours or caption vary along a runtime axis the spec does not encode
/// — a vehicle's usage class, say — passes the block there rather than minting
/// a second spec that differs in this one field.
@immutable
class PlateCountry {
  const PlateCountry({
    required this.code,
    required this.captionLines,
    required this.panelColor,
    required this.panelTextColor,
    this.flagAspectRatio = 7 / 4,
    this.flag,
    this.flagBorderColor,
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

  /// A thin outline stroked around the flag's own rectangle, or null for no
  /// outline. Some countries' flags are printed on a plate with a fine dark
  /// border around them (Bahrain's, for one); most have none.
  final Color? flagBorderColor;

  @override
  bool operator ==(Object other) => identical(this, other) || (other is PlateCountry && other.code == code);

  @override
  int get hashCode => code.hashCode;
}
