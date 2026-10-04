import 'package:plate_core/plate_core.dart';

import 'colombia_colors.dart';

/// Colombia as a `PlateCountry`. No Colombian plate prints a flag, so every
/// spec sets `noPanel`.
abstract final class ColombiaCountry {
  static const PlateCountry colombia = PlateCountry(
    code: 'co',
    captionLines: <String>[],
    panelColor: ColombiaColors.privateYellow,
    panelTextColor: ColombiaColors.privateBlack,
  );
}
