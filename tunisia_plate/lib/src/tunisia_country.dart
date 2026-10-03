import 'package:core_plate/core_plate.dart';

import 'tunisia_colors.dart';

/// Tunisia as a `PlateCountry`. No Tunisian plate prints a country block —
/// the military plate's flag is a decal on the spec — so every spec sets
/// `noPanel` and this carries the flag only for hosts that list countries.
abstract final class TunisiaCountry {
  static const PlateCountry tunisia = PlateCountry(
    code: 'tn',
    captionLines: <String>[],
    panelColor: TunisiaColors.flagRed,
    panelTextColor: TunisiaColors.white,
    flagAspectRatio: 3 / 2,
    flag: SvgPlateAsset(
      'assets/flags/Flag_of_Tunisia.svg',
      package: 'tunisia_plate',
    ),
  );
}
