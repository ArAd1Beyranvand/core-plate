import 'package:plate_core/plate_core.dart';

import 'india_colors.dart';

/// India as `core_plate`'s [PlateCountry].
///
/// No panel: the HSRP's chakra and IND are a decal and a label on the private
/// specs, so every spec sets `noPanel`.
abstract final class IndiaCountry {
  static const PlateCountry india = PlateCountry(
    code: 'in',
    captionLines: <String>[],
    panelColor: IndiaColors.white,
    panelTextColor: IndiaColors.black,
  );
}
