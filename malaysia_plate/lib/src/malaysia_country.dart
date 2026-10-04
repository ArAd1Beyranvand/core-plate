import 'package:plate_core/plate_core.dart';

import 'malaysia_colors.dart';

/// Malaysia as a `PlateCountry`. Only the JPJePlate prints a country block —
/// the green strip with the flag over `MAL`. Every other Malaysian plate is
/// frameless type on a plain field and its specs set `noPanel`.
abstract final class MalaysiaCountry {
  static const PlateCountry malaysia = PlateCountry(
    code: 'my',
    // MAL is a label on the JPJePlate spec, placed where the artwork has it.
    captionLines: <String>[],
    panelColor: MalaysiaColors.evGreen,
    // Black on the green, sampled from the artwork's MAL.
    panelTextColor: MalaysiaColors.darkInk,
    flagAspectRatio: 2,
    flag: SvgPlateAsset(
      'assets/flags/Flag_of_Malaysia.svg',
      package: 'malaysia_plate',
    ),
  );
}
