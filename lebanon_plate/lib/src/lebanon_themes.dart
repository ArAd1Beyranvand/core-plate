import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'lebanon_colors.dart';
import 'lebanon_usage.dart';

/// The `PlateTheme`s a Lebanese plate is printed in — one per usage class.
///
/// This is the file Lebanon is interesting for. Two geometries, eight fields:
/// the plate that tells you a car is consular, diplomatic, a driving school's
/// or a tourist's is the *same plate* in a different colour, so the usage axis
/// lands almost entirely here rather than in `LebanonPlates`.
///
/// Colour never lives on a [PlateSpec] — a spec is geometry, a theme is colour,
/// and `core_plate` keeps them apart — so the host passes one:
///
/// ```dart
/// PlateCanvas(
///   spec: LebanonPlates.oneLine,
///   country: LebanonCountry.forUsage(LebanonUsage.diplomatic),
///   theme: LebanonThemes.forUsage(LebanonUsage.diplomatic),
///   ...
/// )
/// ```
///
/// Each theme pairs a field from `LebanonColors` with the ink that field takes:
/// dark on the four light fields, light on the four dark ones. That pairing is
/// the only judgement in this file, and it is the one part of it that is not
/// straight from the sources — a plate is printed in whatever contrasts.
abstract final class LebanonThemes {
  /// Border thickness as a fraction of plate height. Lebanese plates carry a
  /// thin black frame set well inside the edge, unlike the thick frames of the
  /// region's other formats.
  static const double _borderWidthRatio = 0.022; // CALIBRATE

  /// The corner radius, as a fraction of plate height. A Lebanese plate is
  /// barely rounded.
  static const double _plateRadiusRatio = 0.045; // CALIBRATE

  static PlateTheme _field({required Color field, required Color ink, required Color inactive}) => PlateTheme(
    plateBackground: field,
    plateBorder: LebanonColors.frame,
    ink: ink,
    // The band is a country panel, not a rule, and no spec in this package
    // declares a PlateRule — so the divider colour is never painted. It matches
    // the frame so that a host adding its own rule to a derived spec gets
    // something that belongs on the plate.
    dividerColor: LebanonColors.frame,
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: _plateRadiusRatio,
    activeColor: ink,
    inactiveColor: inactive,
    alertColor: const Color(0xFFD32F2F),
  );

  /// Private vehicles, and every letter-coded class without a colour of its
  /// own: judicial, religious, parliament, motorcycle. Black on white.
  static final PlateTheme private = _field(
    field: LebanonColors.white,
    ink: LebanonColors.darkInk,
    inactive: LebanonColors.inactiveOnLight,
  );

  /// Consular vehicles. White on purple.
  static final PlateTheme consular = _field(
    field: LebanonColors.purple,
    ink: LebanonColors.lightInk,
    inactive: LebanonColors.inactiveOnDark,
  );

  /// Diplomatic vehicles. Black on orange.
  static final PlateTheme diplomatic = _field(
    field: LebanonColors.orange,
    ink: LebanonColors.darkInk,
    inactive: LebanonColors.inactiveOnLight,
  );

  /// Public institutions (مؤسسات). White on red.
  static final PlateTheme publicInstitution = _field(
    field: LebanonColors.red,
    ink: LebanonColors.lightInk,
    inactive: LebanonColors.inactiveOnDark,
  );

  /// Driving instructor vehicles. Black on yellow.
  static final PlateTheme drivingSchool = _field(
    field: LebanonColors.yellow,
    ink: LebanonColors.darkInk,
    inactive: LebanonColors.inactiveOnLight,
  );

  /// Transit and temporary-use vehicles. White on green.
  static final PlateTheme transit = _field(
    field: LebanonColors.green,
    ink: LebanonColors.lightInk,
    inactive: LebanonColors.inactiveOnDark,
  );

  /// Temporary registration. White on brown.
  static final PlateTheme temporary = _field(
    field: LebanonColors.brown,
    ink: LebanonColors.lightInk,
    inactive: LebanonColors.inactiveOnDark,
  );

  /// Tourism vehicles. Black on pink.
  static final PlateTheme tourism = _field(
    field: LebanonColors.pink,
    ink: LebanonColors.darkInk,
    inactive: LebanonColors.inactiveOnLight,
  );

  /// The theme for [usage] — the lookup a host calls instead of picking a
  /// colour.
  ///
  /// [LebanonUsage.publicTransport] resolves to [publicInstitution]'s red,
  /// which is an inheritance rather than an attestation: `P` plates were split
  /// out of the red `M` series and no source consulted names their current
  /// field. See the TODO on that enum value.
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
