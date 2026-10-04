import 'package:plate_core/core_plate.dart';

import 'sudan_colors.dart';

/// Sudan as a `PlateCountry`. The plate prints no flag; SUDAN / السودان are
/// labels on the spec, so every spec sets `noPanel`.
abstract final class SudanCountry {
  static const PlateCountry sudan = PlateCountry(
    code: 'sd',
    captionLines: <String>[],
    panelColor: SudanColors.hologram,
    panelTextColor: SudanColors.privateBlack,
  );
}
