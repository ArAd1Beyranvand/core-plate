import 'package:plate_core/core_plate.dart';

import 'lebanon_colors.dart';
import 'lebanon_usage.dart';

/// Lebanon's blue band, as `core_plate`'s [PlateCountry].
///
/// All have `code: 'lb'` so they compare equal by [PlateCountry] semantics —
/// distinguish by [PlateSpec.id]. The band carries the usage word;
/// لبنان is a [PlateLabel] on the spec, not here. The band is the same blue
/// on every usage (colour-coding is the field, not the band).
abstract final class LebanonCountry {
  /// The blue band with no usage word — لبنان alone, which the spec prints.
  ///
  /// The right block for a class whose printed Arabic no source names (see
  /// `LebanonUsage.arabic`), and what [forUsage] returns for all of them.
  static const PlateCountry band = PlateCountry(
    code: 'lb',
    captionLines: <String>[],
    panelColor: LebanonColors.band,
    panelTextColor: LebanonColors.bandInk,
    flag: SvgPlateAsset('assets/cedar.svg', package: 'lebanon_plate'),
    flagAspectRatio: 1.0,
  );

  /// The band on a private plate, captioned خصوصي.
  static const PlateCountry private = PlateCountry(
    code: 'lb',
    captionLines: <String>['خصوصي'],
    panelColor: LebanonColors.band,
    panelTextColor: LebanonColors.bandInk,
    flag: SvgPlateAsset('assets/cedar.svg', package: 'lebanon_plate'),
    flagAspectRatio: 1.0,
  );

  /// The band on a public-institution plate, captioned مؤسسات.
  static const PlateCountry publicInstitution = PlateCountry(
    code: 'lb',
    captionLines: <String>['مؤسسات'],
    panelColor: LebanonColors.band,
    panelTextColor: LebanonColors.bandInk,
    flag: SvgPlateAsset('assets/cedar.svg', package: 'lebanon_plate'),
    flagAspectRatio: 1.0,
  );

  /// The band captioned for [usage], or uncaptioned when the Arabic word is not
  /// attested. Check [LebanonUsage.arabic] to grey an option out.
  static PlateCountry forUsage(LebanonUsage usage) => switch (usage.arabic) {
    'خصوصي' => private,
    'مؤسسات' => publicInstitution,
    _ => band,
  };
}
