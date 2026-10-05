import 'package:flutter/widgets.dart';
import 'package:plate_core/plate_core.dart';

import 'laos_colors.dart';

/// One ink on one field, the frame in the ink.
///
/// Measured off the flattened photos (340×150): the frame line's inner edge
/// sits 6.6 in from the plate edge (sides 6.2–7.5, median 6.6), so the border
/// is 6.6/150 = 0.044 of the height; the corners round at 12 (diagonal
/// readings 9.4–13.7, median 11.9), 0.08. A 1–2 unit rim of field shows
/// outside the line on most plates; at that size it is within the corner fit's
/// error, so the border runs to the edge and keeps the rounded corners.
abstract final class LaosThemes {
  /// Private plates.
  static final PlateTheme yellow = _ink(LaosColors.yellow, LaosColors.black);

  /// Private EV plates.
  static final PlateTheme amber = _ink(LaosColors.amber, LaosColors.black);

  /// Government plates.
  static final PlateTheme government = _ink(
    LaosColors.governmentBlue,
    LaosColors.white,
  );

  /// Company plates, with or without the EV badge, and temporary plates.
  static final PlateTheme white = _ink(LaosColors.white, LaosColors.black);

  /// Taxable-company plates.
  static final PlateTheme taxable = _ink(
    LaosColors.white,
    LaosColors.taxableBlue,
  );

  /// International-organisation plates: diplomatic, foreign guest, UN and
  /// international financial institution.
  static final PlateTheme international = _ink(
    LaosColors.silver,
    LaosColors.paleBlue,
  );

  /// Public-security and national-defence plates.
  static final PlateTheme security = _ink(LaosColors.red, LaosColors.white);
}

PlateTheme _ink(Color field, Color ink) => PlateTheme.monochrome(
  field: field,
  ink: ink,
  inactive: LaosColors.inactive,
  borderWidthRatio: 0.044,
  plateRadiusRatio: 0.08,
);
