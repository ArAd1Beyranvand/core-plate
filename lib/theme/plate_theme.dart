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
    required this.borderWidthRatio,
    required this.plateRadiusRatio,
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

  /// Outer border width, as a fraction of plate height.
  final double borderWidthRatio;

  /// Corner radius, as a fraction of plate height.
  final double plateRadiusRatio;

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
      plateBorder: Color(0xFF000000),
      ink: Color(0xFF0A0A0A),
      dividerColor: Color(0xFF000000),
      borderWidthRatio: 0.04,
      plateRadiusRatio: 0.12,
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
    double? borderWidthRatio,
    double? plateRadiusRatio,
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
      borderWidthRatio: borderWidthRatio ?? this.borderWidthRatio,
      plateRadiusRatio: plateRadiusRatio ?? this.plateRadiusRatio,
      carAspect: carAspect ?? this.carAspect,
      motorcycleAspect: motorcycleAspect ?? this.motorcycleAspect,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
    );
  }

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
        other.borderWidthRatio == borderWidthRatio &&
        other.plateRadiusRatio == plateRadiusRatio &&
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
        borderWidthRatio,
        plateRadiusRatio,
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
