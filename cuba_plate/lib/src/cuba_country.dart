import 'package:plate_core/plate_core.dart';

import 'cuba_colors.dart';

/// Cuba as `core_plate`'s [PlateCountry].
///
/// No flag and no caption: the word CUBA is a stacked [PlateLabel] on each
/// spec, positioned to the measured ink, and every spec sets `noPanel`. The
/// panel colour is still meaningful — it is what the legal-entity strip's
/// `PlateFill.panel` resolves to.
abstract final class CubaCountry {
  static const PlateCountry cuba = PlateCountry(
    code: 'cu',
    captionLines: <String>[],
    panelColor: CubaColors.band,
    panelTextColor: CubaColors.bandInk,
  );
}
