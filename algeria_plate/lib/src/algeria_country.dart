import 'package:plate_core/plate_core.dart';

import 'algeria_colors.dart';

/// Algeria as a `PlateCountry`. No Algerian plate prints a country block —
/// the army plate's flag is a round decal on the spec — so every spec sets
/// `noPanel` and this carries only the flag for hosts that list countries.
abstract final class AlgeriaCountry {
  static const PlateCountry algeria = PlateCountry(
    code: 'dz',
    captionLines: <String>[],
    panelColor: AlgeriaColors.flagGreen,
    panelTextColor: AlgeriaColors.white,
    flagAspectRatio: 3 / 2,
    flag: SvgPlateAsset(
      'assets/flags/Flag_of_Algeria.svg',
      package: 'algeria_plate',
    ),
  );
}
