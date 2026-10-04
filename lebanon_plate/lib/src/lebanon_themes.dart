import 'package:plate_core/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'lebanon_colors.dart';
import 'lebanon_usage.dart';

/// One `PlateTheme` per `LebanonUsage`. Pairs a field colour with its ink:
/// dark on light fields, light on dark ones. The usage axis lives here
/// (geometry is in `LebanonPlates`), so the host passes both the spec and
/// a theme from `forUsage(usage)`.
abstract final class LebanonThemes {
  /// Border thickness as a fraction of plate height. Lebanese plates carry a
  /// thin black frame set well inside the edge, unlike the thick frames of the
  /// region's other formats.
  static const double _borderWidthRatio = 0.022; // CALIBRATE

  /// The corner radius, as a fraction of plate height. A Lebanese plate is
  /// barely rounded.
  static const double _plateRadiusRatio = 0.045; // CALIBRATE

  static PlateTheme _field({
    required Color field,
    required Color ink,
    required Color inactive,
  }) => PlateTheme(
    plateBackground: field,
    plateBorder: LebanonColors.frame,
    ink: ink,
    dividerColor: LebanonColors.frame,
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: _plateRadiusRatio,
    activeColor: ink,
    inactiveColor: inactive,
    alertColor: const Color(0xFFD32F2F),
  );

  static final PlateTheme private = _field(
    field: LebanonColors.white,
    ink: LebanonColors.darkInk,
    inactive: LebanonColors.inactiveOnLight,
  );

  static final PlateTheme consular = _field(
    field: LebanonColors.purple,
    ink: LebanonColors.lightInk,
    inactive: LebanonColors.inactiveOnDark,
  );

  static final PlateTheme diplomatic = _field(
    field: LebanonColors.orange,
    ink: LebanonColors.darkInk,
    inactive: LebanonColors.inactiveOnLight,
  );

  static final PlateTheme publicInstitution = _field(
    field: LebanonColors.red,
    ink: LebanonColors.lightInk,
    inactive: LebanonColors.inactiveOnDark,
  );

  static final PlateTheme drivingSchool = _field(
    field: LebanonColors.yellow,
    ink: LebanonColors.darkInk,
    inactive: LebanonColors.inactiveOnLight,
  );

  static final PlateTheme transit = _field(
    field: LebanonColors.green,
    ink: LebanonColors.lightInk,
    inactive: LebanonColors.inactiveOnDark,
  );

  static final PlateTheme temporary = _field(
    field: LebanonColors.brown,
    ink: LebanonColors.lightInk,
    inactive: LebanonColors.inactiveOnDark,
  );

  static final PlateTheme tourism = _field(
    field: LebanonColors.pink,
    ink: LebanonColors.darkInk,
    inactive: LebanonColors.inactiveOnLight,
  );

  /// The theme for [usage]. [publicTransport] inherits [publicInstitution]'s
  /// red (unattested; see TODO on `LebanonUsage.publicTransport`).
  static PlateTheme forUsage(LebanonUsage usage) => switch (usage) {
    LebanonUsage.private => private,
    LebanonUsage.consular => consular,
    LebanonUsage.diplomatic => diplomatic,
    LebanonUsage.publicInstitution => publicInstitution,
    LebanonUsage.publicTransport => publicInstitution,
    LebanonUsage.drivingSchool => drivingSchool,
    LebanonUsage.transit => transit,
    LebanonUsage.temporary => temporary,
    LebanonUsage.tourism => tourism,
  };
}
