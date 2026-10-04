import 'package:plate_core/plate_core.dart';

import 'venezuela_colors.dart';

/// Venezuela as `core_plate`'s [PlateCountry].
///
/// No flag block and no caption: the flag is the background's stripes and the
/// country's name is a [PlateLabel] across the top, so every spec sets
/// `noPanel`.
abstract final class VenezuelaCountry {
  static const PlateCountry venezuela = PlateCountry(
    code: 've',
    captionLines: <String>[],
    panelColor: VenezuelaColors.blue,
    panelTextColor: VenezuelaColors.field,
  );
}
