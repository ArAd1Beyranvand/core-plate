import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'niger_colors.dart';
import 'niger_usage.dart';

/// Black ink and a black frame on either field.
///
/// Measured off the artwork normalised to 520×110: the frame is ~3.1 mm,
/// 0.028 of the height, and the outer corner ~6.5 mm, 0.06. The artwork also
/// leaves a 1.6 mm margin of field outside the frame, which is not drawn.
abstract final class NigerThemes {
  static PlateTheme _livery({required Color field, required Color inactive}) =>
      PlateTheme(
        plateBackground: field,
        plateBorder: NigerColors.black,
        ink: NigerColors.black,
        dividerColor: NigerColors.black,
        borderWidthRatio: 0.028,
        plateRadiusRatio: 0.06,
        activeColor: NigerColors.black,
        inactiveColor: inactive,
        alertColor: const Color(0xFFD32F2F),
      );

  static final PlateTheme private = _livery(
    field: NigerColors.privateWhite,
    inactive: NigerColors.inactiveOnLight,
  );

  static final PlateTheme commercial = _livery(
    field: NigerColors.commercialOrange,
    inactive: NigerColors.inactiveOnOrange,
  );

  static PlateTheme forUsage(NigerUsage usage) => switch (usage) {
    NigerUsage.private => private,
    NigerUsage.commercial => commercial,
  };
}
