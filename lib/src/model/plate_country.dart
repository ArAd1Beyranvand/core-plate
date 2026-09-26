import 'package:flutter/widgets.dart';

import 'plate_asset.dart';

/// The country-specific chrome of a licence plate: the flag, the caption beside
/// it, and the country panel's colours. Concrete constants live in each
/// country's own package.
///
/// `PlateSpec.country` is only the default: `PlateCanvas.country` overrides it
/// at render time, so a panel that varies along an axis the spec does not
/// encode — a vehicle's usage class, say — needs no second spec.
@immutable
class PlateCountry {
  const PlateCountry({
    required this.code,
    required this.captionLines,
    required this.panelColor,
    required this.panelTextColor,
    this.headingLines = const <String>[],
    this.flagAspectRatio = 7 / 4,
    this.flag,
    this.flagBorderColor,
  });

  /// ISO 3166-1 alpha-2, lower-case. The sole basis of [operator ==].
  final String code;

  /// Printed beside the flag, top to bottom. Always laid out LTR.
  final List<String> captionLines;

  /// Lines printed on the *far* side of the flag from [captionLines] — above it
  /// in a vertical panel, before it in a horizontal one.
  ///
  /// For a panel of three parts rather than two, where the flag has to come
  /// between two runs of wording: an Afghan plate stacks the province name, the
  /// emblem, then the province's Latin code. [CountryPanel] splits the room
  /// left after the flag between the two when both are present.
  final List<String> headingLines;

  final Color panelColor;
  final Color panelTextColor;

  /// Sizes the flag within [CountryPanel] without distortion.
  final double flagAspectRatio;

  /// Null for a country with no flag; [PlateFlag] then renders nothing.
  final PlateAsset? flag;

  /// A fine outline some countries print around the flag (Bahrain's, for one).
  final Color? flagBorderColor;

  @override
  bool operator ==(Object other) => identical(this, other) || (other is PlateCountry && other.code == code);

  @override
  int get hashCode => code.hashCode;
}
