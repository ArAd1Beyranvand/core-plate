import 'package:plate_core/plate_core.dart';

import 'indonesia_colors.dart';

/// Indonesia as a `PlateCountry`. No current Indonesian plate prints a
/// country block or flag, so every spec sets `noPanel`.
abstract final class IndonesiaCountry {
  static const PlateCountry indonesia = PlateCountry(
    code: 'id',
    captionLines: <String>[],
    panelColor: IndonesiaColors.governmentRed,
    panelTextColor: IndonesiaColors.white,
    flagAspectRatio: 3 / 2,
  );
}
