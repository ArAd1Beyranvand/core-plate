import 'package:plate_core/plate_core.dart';
import 'package:flutter/widgets.dart';

import 'sudan_colors.dart';
import 'sudan_usage.dart';

/// The Sudanese liveries: one ink on one field; the frame and the rule under
/// the name band are both in the ink.
///
/// Measured off the artwork normalised to 320×160: the frame is ~3.1 mm, 0.019
/// of the height, and the outer corner ~9 mm, 0.055.
abstract final class SudanThemes {
  static PlateTheme _livery({
    required Color field,
    required Color ink,
    required Color inactive,
  }) => PlateTheme(
    plateBackground: field,
    plateBorder: ink,
    ink: ink,
    dividerColor: ink,
    borderWidthRatio: 0.019,
    plateRadiusRatio: 0.055,
    activeColor: ink,
    inactiveColor: inactive,
    alertColor: const Color(0xFFD32F2F),
  );

  static final PlateTheme private = _livery(
    field: SudanColors.privateWhite,
    ink: SudanColors.privateBlack,
    inactive: SudanColors.inactiveOnLight,
  );

  static final PlateTheme transport = _livery(
    field: SudanColors.transportTeal,
    ink: SudanColors.transportWhite,
    inactive: SudanColors.inactiveOnDark,
  );

  static final PlateTheme commercial = _livery(
    field: SudanColors.commercialBlack,
    ink: SudanColors.commercialWhite,
    inactive: SudanColors.inactiveOnDark,
  );

  static PlateTheme forUsage(SudanUsage usage) => switch (usage) {
    SudanUsage.private => private,
    SudanUsage.transport => transport,
    SudanUsage.commercial => commercial,
  };
}
