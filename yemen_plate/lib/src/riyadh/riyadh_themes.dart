import 'package:plate_core/plate_core.dart';

import 'riyadh_colors.dart';

/// Black on white for every category; only the strip's colour differs, and that
/// is the country's (`RiyadhCountry`).
///
/// Frame width is measured: the reference frames are ~4.5 of 110 units thick.
/// The corner radius is not measured.
abstract final class RiyadhThemes {
  static const PlateTheme standard = PlateTheme.monochrome(
    field: RiyadhColors.white,
    ink: RiyadhColors.ink,
    inactive: RiyadhColors.inactive,
    borderWidthRatio: 0.041,
    plateRadiusRatio: 0.08,
  );
}
