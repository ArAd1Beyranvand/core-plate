import 'package:plate_core/core_plate.dart';

import 'bolivia_colors.dart';

/// Bolivia as a `PlateCountry`. The flag is the state flag, with the coat of
/// arms: the PTA plate prints it, through a panel box exactly the flag's
/// shape. The special and Mercosur plates print the plain flag as three
/// bands and set `noPanel`.
abstract final class BoliviaCountry {
  static const PlateCountry bolivia = PlateCountry(
    code: 'bo',
    captionLines: <String>[],
    panelColor: BoliviaColors.flagGreen,
    panelTextColor: BoliviaColors.white,
    flagAspectRatio: 22 / 15,
    flag: SvgPlateAsset(
      'assets/flags/Flag_of_Bolivia_state.svg',
      package: 'bolivia_plate',
    ),
  );
}
