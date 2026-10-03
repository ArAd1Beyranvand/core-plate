import 'package:core_plate/core_plate.dart';

import 'bolivia_colors.dart';

/// Bolivia as a `PlateCountry`. No Bolivian plate prints a country block —
/// the flag is three bands on each spec — so every spec sets `noPanel` and
/// this carries the flag only for hosts that list countries.
abstract final class BoliviaCountry {
  static const PlateCountry bolivia = PlateCountry(
    code: 'bo',
    captionLines: <String>[],
    panelColor: BoliviaColors.flagGreen,
    panelTextColor: BoliviaColors.white,
    flagAspectRatio: 22 / 15,
    flag: SvgPlateAsset(
      'assets/flags/Flag_of_Bolivia.svg',
      package: 'bolivia_plate',
    ),
  );
}
