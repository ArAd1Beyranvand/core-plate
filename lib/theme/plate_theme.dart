// The theme keeps a few deprecated colour tokens for backwards compatibility;
// its own constructor / copyWith / lerp still thread them through.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/widgets.dart';

/// The visual language of a real Iranian licence plate.
///
/// This is a pure data class — no widgets. All chrome colours are fixed to the
/// values sampled from real plate photos and must never be tinted by a caller's
/// accent colour. Only [activeColor] / [inactiveColor] are meant to vary, and
/// they are used solely for input-mode field outlines.
///
/// The `*Ratio` fields are all expressed as a fraction of the plate HEIGHT (not
/// absolute pixels), so a plate scales cleanly at any size.
@immutable
class PlateTheme {
  const PlateTheme({
    required this.plateBackground,
    required this.plateBorder,
    required this.ink,
    required this.dividerColor,
    required this.panelBlue,
    required this.panelText,
    required this.flagGreen,
    required this.flagWhite,
    required this.flagRed,
    required this.screwColor,
    required this.borderWidthRatio,
    required this.plateRadiusRatio,
    required this.panelWidthRatio,
    required this.dividerWidthRatio,
    required this.digitGapRatio,
    required this.carAspect,
    required this.motorcycleAspect,
    required this.activeColor,
    required this.inactiveColor,
  });

  /// Plate background (the white field digits sit on).
  final Color plateBackground;

  /// Outer plate border/edge colour.
  final Color plateBorder;

  /// Ink colour for digits and the letter.
  final Color ink;

  /// The vertical rule left of the province code.
  final Color dividerColor;

  /// The I.R. IRAN block background.
  ///
  /// Deprecated: panel colours are now country-specific and live on
  /// [PlateCountry.panelColor]. Kept for backwards compatibility.
  @Deprecated('Use PlateCountry.panelColor instead.')
  final Color panelBlue;

  /// Text on the [panelBlue] block.
  ///
  /// Deprecated: use [PlateCountry.panelTextColor] instead.
  @Deprecated('Use PlateCountry.panelTextColor instead.')
  final Color panelText;

  /// Flag green stripe.
  ///
  /// Deprecated: the flag is now rendered from a vector SVG (see [PlateFlag]),
  /// so the stripe colours are no longer read. Kept for compatibility.
  @Deprecated('The flag is now drawn from an SVG; this colour is unused.')
  final Color flagGreen;

  /// Flag white stripe.
  @Deprecated('The flag is now drawn from an SVG; this colour is unused.')
  final Color flagWhite;

  /// Flag red stripe.
  @Deprecated('The flag is now drawn from an SVG; this colour is unused.')
  final Color flagRed;

  /// The mounting screw heads.
  final Color screwColor;

  /// Outer border width, as a fraction of plate height.
  final double borderWidthRatio;

  /// Corner radius, as a fraction of plate height.
  final double plateRadiusRatio;

  /// Width of the I.R. IRAN panel, as a fraction of plate height.
  final double panelWidthRatio;

  /// Width of the vertical divider rule, as a fraction of plate height.
  final double dividerWidthRatio;

  /// Gap between adjacent digits, as a fraction of plate height.
  final double digitGapRatio;

  /// Aspect ratio (width / height) of a car plate: 520 / 110.
  final double carAspect;

  /// Aspect ratio (width / height) of a motorcycle plate: 175 / 110.
  final double motorcycleAspect;

  /// Outline colour for a completed input field. Input-mode only — never used
  /// for plate chrome.
  final Color activeColor;

  /// Outline colour for an empty/in-progress input field. Input-mode only.
  final Color inactiveColor;

  /// Standard Iranian plate theme, sampled from real plate photos.
  factory PlateTheme.standard() {
    return const PlateTheme(
      plateBackground: Color(0xFFFFFFFF),
      plateBorder: Color(0xFF111111),
      ink: Color(0xFF0A0A0A),
      dividerColor: Color(0xFF111111),
      panelBlue: Color(0xFF16479D),
      panelText: Color(0xFFFFFFFF),
      flagGreen: Color(0xFF239F40),
      flagWhite: Color(0xFFFFFFFF),
      flagRed: Color(0xFFDA0000),
      screwColor: Color(0xFFB9BDC2),
      borderWidthRatio: 0.04,
      plateRadiusRatio: 0.09,
      panelWidthRatio: 0.16,
      dividerWidthRatio: 0.02,
      digitGapRatio: 0.06,
      carAspect: 520 / 110,
      motorcycleAspect: 175 / 110,
      activeColor: Color(0xFF0A0A0A),
      inactiveColor: Color(0x66666666),
    );
  }

  PlateTheme copyWith({
    Color? plateBackground,
    Color? plateBorder,
    Color? ink,
    Color? dividerColor,
    Color? panelBlue,
    Color? panelText,
    Color? flagGreen,
    Color? flagWhite,
    Color? flagRed,
    Color? screwColor,
    double? borderWidthRatio,
    double? plateRadiusRatio,
    double? panelWidthRatio,
    double? dividerWidthRatio,
    double? digitGapRatio,
    double? carAspect,
    double? motorcycleAspect,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return PlateTheme(
      plateBackground: plateBackground ?? this.plateBackground,
      plateBorder: plateBorder ?? this.plateBorder,
      ink: ink ?? this.ink,
      dividerColor: dividerColor ?? this.dividerColor,
      panelBlue: panelBlue ?? this.panelBlue,
      panelText: panelText ?? this.panelText,
      flagGreen: flagGreen ?? this.flagGreen,
      flagWhite: flagWhite ?? this.flagWhite,
      flagRed: flagRed ?? this.flagRed,
      screwColor: screwColor ?? this.screwColor,
      borderWidthRatio: borderWidthRatio ?? this.borderWidthRatio,
      plateRadiusRatio: plateRadiusRatio ?? this.plateRadiusRatio,
      panelWidthRatio: panelWidthRatio ?? this.panelWidthRatio,
      dividerWidthRatio: dividerWidthRatio ?? this.dividerWidthRatio,
      digitGapRatio: digitGapRatio ?? this.digitGapRatio,
      carAspect: carAspect ?? this.carAspect,
      motorcycleAspect: motorcycleAspect ?? this.motorcycleAspect,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
    );
  }

  /// Linearly interpolate between two themes.
  static PlateTheme lerp(PlateTheme a, PlateTheme b, double t) {
    return PlateTheme(
      plateBackground: Color.lerp(a.plateBackground, b.plateBackground, t)!,
      plateBorder: Color.lerp(a.plateBorder, b.plateBorder, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      dividerColor: Color.lerp(a.dividerColor, b.dividerColor, t)!,
      panelBlue: Color.lerp(a.panelBlue, b.panelBlue, t)!,
      panelText: Color.lerp(a.panelText, b.panelText, t)!,
      flagGreen: Color.lerp(a.flagGreen, b.flagGreen, t)!,
      flagWhite: Color.lerp(a.flagWhite, b.flagWhite, t)!,
      flagRed: Color.lerp(a.flagRed, b.flagRed, t)!,
      screwColor: Color.lerp(a.screwColor, b.screwColor, t)!,
      borderWidthRatio: _lerpDouble(a.borderWidthRatio, b.borderWidthRatio, t),
      plateRadiusRatio: _lerpDouble(a.plateRadiusRatio, b.plateRadiusRatio, t),
      panelWidthRatio: _lerpDouble(a.panelWidthRatio, b.panelWidthRatio, t),
      dividerWidthRatio:
          _lerpDouble(a.dividerWidthRatio, b.dividerWidthRatio, t),
      digitGapRatio: _lerpDouble(a.digitGapRatio, b.digitGapRatio, t),
      carAspect: _lerpDouble(a.carAspect, b.carAspect, t),
      motorcycleAspect: _lerpDouble(a.motorcycleAspect, b.motorcycleAspect, t),
      activeColor: Color.lerp(a.activeColor, b.activeColor, t)!,
      inactiveColor: Color.lerp(a.inactiveColor, b.inactiveColor, t)!,
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  /// The nearest enclosing [PlateTheme], or [PlateTheme.standard] if none.
  static PlateTheme of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PlateThemeScope>();
    return scope?.theme ?? PlateTheme.standard();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlateTheme &&
        other.plateBackground == plateBackground &&
        other.plateBorder == plateBorder &&
        other.ink == ink &&
        other.dividerColor == dividerColor &&
        other.panelBlue == panelBlue &&
        other.panelText == panelText &&
        other.flagGreen == flagGreen &&
        other.flagWhite == flagWhite &&
        other.flagRed == flagRed &&
        other.screwColor == screwColor &&
        other.borderWidthRatio == borderWidthRatio &&
        other.plateRadiusRatio == plateRadiusRatio &&
        other.panelWidthRatio == panelWidthRatio &&
        other.dividerWidthRatio == dividerWidthRatio &&
        other.digitGapRatio == digitGapRatio &&
        other.carAspect == carAspect &&
        other.motorcycleAspect == motorcycleAspect &&
        other.activeColor == activeColor &&
        other.inactiveColor == inactiveColor;
  }

  @override
  int get hashCode => Object.hashAll([
        plateBackground,
        plateBorder,
        ink,
        dividerColor,
        panelBlue,
        panelText,
        flagGreen,
        flagWhite,
        flagRed,
        screwColor,
        borderWidthRatio,
        plateRadiusRatio,
        panelWidthRatio,
        dividerWidthRatio,
        digitGapRatio,
        carAspect,
        motorcycleAspect,
        activeColor,
        inactiveColor,
      ]);
}

/// Provides a [PlateTheme] to descendants via [PlateTheme.of].
class PlateThemeScope extends InheritedWidget {
  const PlateThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  final PlateTheme theme;

  @override
  bool updateShouldNotify(PlateThemeScope oldWidget) =>
      theme != oldWidget.theme;
}
