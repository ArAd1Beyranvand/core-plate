import 'package:plate_core/plate_core.dart';

import 'vietnam_colors.dart';

/// Vietnam as a `PlateCountry`. A Vietnamese plate carries no flag, caption or
/// country block, so every spec sets `noPanel`; the colours are only the
/// required placeholders.
abstract final class VietnamCountry {
  static const PlateCountry vietnam = PlateCountry(
    code: 'vn',
    captionLines: <String>[],
    panelColor: VietnamColors.white,
    panelTextColor: VietnamColors.black,
  );
}
