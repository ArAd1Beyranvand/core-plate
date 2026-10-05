import 'package:plate_core/plate_core.dart';

import 'laos_colors.dart';

/// Laos as a `PlateCountry`. The plate carries no flag or country block —
/// the top row is the province's name — so every spec sets `noPanel`.
abstract final class LaosCountry {
  static const PlateCountry laos = PlateCountry(
    code: 'la',
    captionLines: <String>[],
    panelColor: LaosColors.white,
    panelTextColor: LaosColors.black,
  );
}
