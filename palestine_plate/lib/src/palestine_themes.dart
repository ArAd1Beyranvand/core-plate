import 'package:core_plate/core_plate.dart';

import 'palestine_colors.dart';
import 'palestine_usage.dart';

/// The colour schemes a Palestinian plate is printed in, and the lookups that
/// derive one from a plate's usage.
///
/// **Colour is derived, never chosen.** A host does not decide that this plate
/// is green; it knows the plate is a private car and asks [forUsage]. That is
/// the whole reason [PSUsage] exists as a separate axis from [PlateSpec].
///
/// [PlateSpec] carries no theme field — a spec describes geometry, a theme
/// describes colour, and `core_plate` keeps them apart deliberately — so a
/// theme cannot be attached to a spec and picked up automatically. The host
/// passes it:
///
/// ```dart
/// PlateCanvas(
///   spec: PSWestBankPlates.modernCar,
///   theme: PSThemes.forUsage(PSUsage.private),
///   onChooseCharacter: PlateCharacterPicker.show,
/// );
/// ```
///
/// or wraps the canvas in a `PlateThemeScope`.
///
/// ## The ratios
///
/// Every theme here uses `borderWidthRatio: 0.027` and
/// `plateRadiusRatio: 0.10`, both measured off
/// `palestine_plate/pics/reference_plate.png` — 7px of border and 26px of
/// corner radius on a 260px-tall image. They are the only geometry in this
/// package that comes from a photograph rather than from proportion, and they
/// are the same on every scheme because nothing suggests the colour changes the
/// printing. `PlateTheme.standard()`'s 0.04 / 0.12 would be a visibly heavier,
/// rounder plate.
///
/// The specs repeat the border figure in [PlateSpec.borderWidthRatioOverride],
/// so the geometry survives a host that supplies a theme of its own.
abstract final class PSThemes {
  // --- West Bank -----------------------------------------------------------

  /// Green on white: private, leased and police plates. The ordinary
  /// Palestinian plate, and the one the reference photograph shows.
  static const PlateTheme greenOnWhite = PlateTheme(
    plateBackground: PSColors.white,
    plateBorder: PSColors.green,
    ink: PSColors.green,
    dividerColor: PSColors.green,
    borderWidthRatio: 0.027,
    plateRadiusRatio: 0.10,
    activeColor: PSColors.green,
    inactiveColor: PSColors.inactiveGreen,
  );

  /// White on green: public transport — taxi, service and bus. The one West
  /// Bank scheme that **inverts** the plate rather than recolouring the ink.
  static const PlateTheme whiteOnGreen = PlateTheme(
    plateBackground: PSColors.green,
    plateBorder: PSColors.white,
    ink: PSColors.white,
    dividerColor: PSColors.white,
    borderWidthRatio: 0.027,
    plateRadiusRatio: 0.10,
    activeColor: PSColors.white,
    inactiveColor: PSColors.inactiveOnDark,
  );

  /// Red on white: Palestinian Authority government vehicles (legacy usage
  /// `99`) and duty-exempt vehicles — ambulance, fire, civil defence (`31`).
  static const PlateTheme redOnWhite = PlateTheme(
    plateBackground: PSColors.white,
    plateBorder: PSColors.red,
    ink: PSColors.red,
    dividerColor: PSColors.red,
    borderWidthRatio: 0.027,
    plateRadiusRatio: 0.10,
    activeColor: PSColors.red,
    inactiveColor: PSColors.inactiveNeutral,
  );

  /// White on blue: the dealer and inspection (trade / test) plate. Pair it
  /// with `PSWestBankPlates.modernTrade`, which is the only spec that carries
  /// the `اختبار` / `במבחן` header the scheme needs.
  static const PlateTheme whiteOnBlue = PlateTheme(
    plateBackground: PSColors.blue,
    plateBorder: PSColors.white,
    ink: PSColors.white,
    dividerColor: PSColors.white,
    borderWidthRatio: 0.027,
    plateRadiusRatio: 0.10,
    activeColor: PSColors.white,
    inactiveColor: PSColors.inactiveOnDark,
  );

  /// The theme a plate of this usage is printed in. Colour is *derived* from
  /// usage — a host never picks a theme directly.
  ///
  /// [PSUsage.commercial] and [PSUsage.municipality] are Gaza-only classes with
  /// no West Bank equivalent, so they resolve to their Gaza themes; every other
  /// arm is a West Bank scheme. For a Gaza plate whose usage you have as two
  /// digits, [forGazaUsageCode] is the direct route and does not need the
  /// intermediate [PSUsage] at all.
  static PlateTheme forUsage(PSUsage usage) => switch (usage) {
    PSUsage.private => greenOnWhite,
    PSUsage.leased => greenOnWhite,
    PSUsage.police => greenOnWhite,
    PSUsage.publicTransport => whiteOnGreen,
    PSUsage.government => redOnWhite,
    PSUsage.exempt => redOnWhite,
    PSUsage.tradePlate => whiteOnBlue,
    PSUsage.commercial => gazaGreen,
    PSUsage.municipality => gazaBlue,
  };

  // --- Gaza ----------------------------------------------------------------

  // Gaza is a different design, not a recolouring of the West Bank's. **The
  // field is always white**; only the glyphs, the border and the rules change.
  // In particular the plate does not invert for public transport the way the
  // West Bank's does, so there is no `whiteOnX` Gaza theme and adding one would
  // be inventing a plate.

  /// Black glyphs: Gaza private cars, usage codes `00`–`09`.
  static const PlateTheme gazaBlack = PlateTheme(
    plateBackground: PSColors.white,
    plateBorder: PSColors.black,
    ink: PSColors.black,
    dividerColor: PSColors.black,
    borderWidthRatio: 0.027,
    plateRadiusRatio: 0.10,
    activeColor: PSColors.black,
    inactiveColor: PSColors.inactiveNeutral,
  );

  /// Green glyphs: Gaza commercial vehicles and trucks, `10`–`19`.
  static const PlateTheme gazaGreen = PlateTheme(
    plateBackground: PSColors.white,
    plateBorder: PSColors.gazaCommercialGreen,
    ink: PSColors.gazaCommercialGreen,
    dividerColor: PSColors.gazaCommercialGreen,
    borderWidthRatio: 0.027,
    plateRadiusRatio: 0.10,
    activeColor: PSColors.gazaCommercialGreen,
    inactiveColor: PSColors.inactiveGreen,
  );

  /// Blue glyphs: Gaza public transport and taxis (`20`–`29`) and municipality
  /// vehicles (`40`–`49`).
  static const PlateTheme gazaBlue = PlateTheme(
    plateBackground: PSColors.white,
    plateBorder: PSColors.blue,
    ink: PSColors.blue,
    dividerColor: PSColors.blue,
    borderWidthRatio: 0.027,
    plateRadiusRatio: 0.10,
    activeColor: PSColors.blue,
    inactiveColor: PSColors.inactiveNeutral,
  );

  /// Red glyphs: Gaza government vehicles — police, Ministry of Health
  /// ambulances — `50`–`59`.
  static const PlateTheme gazaRed = PlateTheme(
    plateBackground: PSColors.white,
    plateBorder: PSColors.red,
    ink: PSColors.red,
    dividerColor: PSColors.red,
    borderWidthRatio: 0.027,
    plateRadiusRatio: 0.10,
    activeColor: PSColors.red,
    inactiveColor: PSColors.inactiveNeutral,
  );

  /// The theme a Gaza plate ending in [code] is printed in, or null when
  /// [code] is not a legal Gaza usage class (`30`–`39` and `60`–`99` are
  /// unallocated).
  ///
  /// Null rather than a fallback theme: an out-of-range code is an invalid
  /// plate, and quietly painting it black would hide that. A host that wants
  /// to render one anyway picks a theme itself and knows it is guessing.
  static PlateTheme? forGazaUsageCode(String code) {
    final usage = PSGazaUsage.forCode(code);
    return switch (usage) {
      PSUsage.private => gazaBlack,
      PSUsage.commercial => gazaGreen,
      PSUsage.publicTransport => gazaBlue,
      PSUsage.municipality => gazaBlue,
      PSUsage.government => gazaRed,
      _ => null,
    };
  }
}
