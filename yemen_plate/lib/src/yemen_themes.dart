import 'package:core_plate/core_plate.dart';

import 'yemen_colors.dart';
import 'yemen_usage.dart';

/// The `PlateTheme`s a Yemeni plate is printed in.
///
/// Colour never lives on a [PlateSpec] — a spec is geometry, a theme is
/// colour, and `core_plate` keeps them apart — so the host passes one:
///
/// ```dart
/// PlateCanvas(
///   spec: YemenNorthernPlates.carGov2Serial5Private,
///   theme: YemenThemes.forNorthernUsage(YemenUsage.private),
///   ...
/// )
/// ```
///
/// The two systems use colour in opposite ways, and that asymmetry is the
/// whole reason there is one theme on one side of this file and six on the
/// other:
///
/// - **System A (2026 unified)** does not colour-code by usage at all. The
///   field is white for a private car, a taxi, a truck, a government car and a
///   police car alike; the usage is the text in the blue side panel. There is
///   therefore exactly one unified theme, and adding usage colours to it would
///   be inventing a system that does not exist.
/// - **System B (1993 northern)** colour-codes by usage as its *primary*
///   signal — the field colour is what a traffic officer reads first, and the
///   Arabic word beside اليمن only confirms it. So there is one theme per
///   scheme, and [forNorthernUsage] is how a host gets the right one without
///   ever naming a colour.
///
/// Every colour comes from `YemenColors`, and every one of those is
/// `// CALIBRATE`. The ratios below are calibration targets too.
abstract final class YemenThemes {
  /// Border thickness as a fraction of plate height. Both systems use a thick
  /// frame; this is roughly 10 units on the 288-unit canvas.
  static const double _borderWidthRatio = 0.035; // CALIBRATE

  /// The unified plate's frame is a **rounded** rectangle; the northern
  /// plate's is square.
  static const double _unifiedRadiusRatio = 0.055; // CALIBRATE

  /// The one System A theme: black on white, rounded frame, for all five
  /// usages.
  ///
  /// [PlateTheme.dividerColor] is what the stippled separator strip in
  /// `YemenUnifiedPlates` is painted in — that strip is a column of
  /// [PlateRule]s, and core paints every rule in the divider colour.
  static const PlateTheme unified = PlateTheme(
    plateBackground: YemenColors.unifiedField,
    plateBorder: YemenColors.unifiedFrame,
    ink: YemenColors.unifiedInk,
    dividerColor: YemenColors.unifiedInk,
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: _unifiedRadiusRatio,
    activeColor: YemenColors.unifiedInk,
    inactiveColor: YemenColors.inactiveOnLight,
  );

  /// Private vehicles: black on blue.
  static const PlateTheme northernPrivate = PlateTheme(
    plateBackground: YemenColors.blue,
    plateBorder: YemenColors.darkInk,
    ink: YemenColors.darkInk,
    dividerColor: YemenColors.darkInk,
    borderWidthRatio: _borderWidthRatio,
    // Square corners: the northern plate is a rectangle.
    plateRadiusRatio: 0,
    activeColor: YemenColors.darkInk,
    inactiveColor: YemenColors.inactiveOnDark,
  );

  /// Taxis and buses: black on yellow.
  static const PlateTheme northernForHire = PlateTheme(
    plateBackground: YemenColors.yellow,
    plateBorder: YemenColors.darkInk,
    ink: YemenColors.darkInk,
    dividerColor: YemenColors.darkInk,
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: 0,
    activeColor: YemenColors.darkInk,
    inactiveColor: YemenColors.inactiveOnLight,
  );

  /// Goods vehicles: black on red.
  static const PlateTheme northernTransport = PlateTheme(
    plateBackground: YemenColors.red,
    plateBorder: YemenColors.darkInk,
    ink: YemenColors.darkInk,
    dividerColor: YemenColors.darkInk,
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: 0,
    activeColor: YemenColors.darkInk,
    inactiveColor: YemenColors.inactiveOnDark,
  );

  /// Government vehicles: white on green.
  static const PlateTheme northernGovernment = PlateTheme(
    plateBackground: YemenColors.green,
    plateBorder: YemenColors.lightInk,
    ink: YemenColors.lightInk,
    dividerColor: YemenColors.lightInk,
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: 0,
    activeColor: YemenColors.lightInk,
    inactiveColor: YemenColors.inactiveOnDark,
  );

  /// The long-standing military printing: white on black.
  static const PlateTheme northernMilitaryClassic = PlateTheme(
    plateBackground: YemenColors.black,
    plateBorder: YemenColors.lightInk,
    ink: YemenColors.lightInk,
    dividerColor: YemenColors.lightInk,
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: 0,
    activeColor: YemenColors.lightInk,
    inactiveColor: YemenColors.inactiveOnDark,
  );

  /// The newer military printing: red on white.
  static const PlateTheme northernMilitaryModern = PlateTheme(
    plateBackground: YemenColors.white,
    plateBorder: YemenColors.militaryRed,
    ink: YemenColors.militaryRed,
    dividerColor: YemenColors.militaryRed,
    borderWidthRatio: _borderWidthRatio,
    plateRadiusRatio: 0,
    activeColor: YemenColors.militaryRed,
    inactiveColor: YemenColors.inactiveOnLight,
  );

  /// The northern theme for [usage] — the lookup a host calls instead of
  /// picking a colour.
  ///
  /// [style] is read only when [usage] is [YemenUsage.military]; it is the one
  /// place where the same usage has two printings, and it is a style rather
  /// than a sixth usage because both forms mean "military" and differ in
  /// nothing but the two colours.
  ///
  /// [YemenUsage.police] is not a northern class (see [YemenUsage.onNorthern]);
  /// it resolves to [northernGovernment] rather than throwing, so a usage
  /// picker shared between the two systems keeps working when the system
  /// switch flips.
  static PlateTheme forNorthernUsage(
    YemenUsage usage, {
    YemenMilitaryStyle style = YemenMilitaryStyle.classic,
  }) => switch (usage) {
    YemenUsage.private => northernPrivate,
    YemenUsage.forHire => northernForHire,
    YemenUsage.transport => northernTransport,
    YemenUsage.government => northernGovernment,
    YemenUsage.police => northernGovernment,
    YemenUsage.military => switch (style) {
      YemenMilitaryStyle.classic => northernMilitaryClassic,
      YemenMilitaryStyle.modern => northernMilitaryModern,
    },
  };

  /// The unified theme, whatever the usage.
  ///
  /// A one-armed lookup, and it earns its place: it makes the "System A does
  /// not recolour by usage" rule explicit at the call site instead of leaving
  /// a reader to wonder whether the host forgot to pass a usage through.
  static PlateTheme forUnifiedUsage(YemenUsage usage) => unified;
}
