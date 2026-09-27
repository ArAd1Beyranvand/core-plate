import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Visual styling: chrome colours and ratios. All chrome colours are fixed to
/// values sampled from real plates and must never be tinted by a caller's
/// accent colour. Only [activeColor] / [inactiveColor] vary and are used solely
/// for input-mode field outlines.
///
/// The `*Ratio` fields are fractions of the plate HEIGHT, so it scales cleanly.
@immutable
class PlateTheme {
  const PlateTheme({
    required this.plateBackground,
    required this.plateBorder,
    required this.ink,
    required this.dividerColor,
    required this.borderWidthRatio,
    required this.plateRadiusRatio,
    required this.activeColor,
    required this.inactiveColor,
    this.alertColor = const Color(0xFFF87171),
  });

  final Color plateBackground;
  final Color plateBorder;
  final Color ink;
  final Color dividerColor;
  final double borderWidthRatio;
  final double plateRadiusRatio;

  /// Outline colour for a completed input field; input-mode only.
  final Color activeColor;

  /// Outline colour for an empty/in-progress input field; input-mode only.
  final Color inactiveColor;

  /// Outline colour a [PlateCanvas] paints when validating and the plate is
  /// invalid; input-mode only.
  final Color alertColor;

  /// Standard white-face / black-frame plate theme, sampled from real plate
  /// photos.
  factory PlateTheme.standard() {
    return const PlateTheme(
      plateBackground: Color(0xFFFFFFFF),
      plateBorder: Color(0xFF000000),
      ink: Color(0xFF0A0A0A),
      dividerColor: Color(0xFF000000),
      borderWidthRatio: 0.04,
      plateRadiusRatio: 0.12,
      activeColor: Color(0xFF0A0A0A),
      inactiveColor: Color(0x66666666),
    );
  }

  /// A plate printed in one ink on one field. [ink] is the border, glyphs,
  /// rules and completed-field outline — a real plate does not print its
  /// divider in a different colour from its digits.
  ///
  /// [inactive] is input chrome only: the outline under an empty field. It is
  /// never printed, so it takes no default.
  const PlateTheme.monochrome({
    required Color field,
    required Color ink,
    required Color inactive,
    required double borderWidthRatio,
    required double plateRadiusRatio,
    Color alertColor = const Color(0xFFF87171),
  }) : this(
         plateBackground: field,
         plateBorder: ink,
         ink: ink,
         dividerColor: ink,
         borderWidthRatio: borderWidthRatio,
         plateRadiusRatio: plateRadiusRatio,
         activeColor: ink,
         inactiveColor: inactive,
         alertColor: alertColor,
       );

  PlateTheme copyWith({
    Color? plateBackground,
    Color? plateBorder,
    Color? ink,
    Color? dividerColor,
    double? borderWidthRatio,
    double? plateRadiusRatio,
    Color? activeColor,
    Color? inactiveColor,
    Color? alertColor,
  }) {
    return PlateTheme(
      plateBackground: plateBackground ?? this.plateBackground,
      plateBorder: plateBorder ?? this.plateBorder,
      ink: ink ?? this.ink,
      dividerColor: dividerColor ?? this.dividerColor,
      borderWidthRatio: borderWidthRatio ?? this.borderWidthRatio,
      plateRadiusRatio: plateRadiusRatio ?? this.plateRadiusRatio,
      activeColor: activeColor ?? this.activeColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      alertColor: alertColor ?? this.alertColor,
    );
  }

  /// Text style for plate glyphs (digits/letters) at a given slot height.
  TextStyle glyphStyle(double slotHeight, Color color) =>
      TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: slotHeight * 0.72, height: 1.0);

  /// The nearest enclosing [PlateTheme], or [PlateTheme.standard] if none.
  static PlateTheme of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PlateThemeScope>();
    return scope?.theme ?? PlateTheme.standard();
  }

  List<Object?> get _props => [
    plateBackground,
    plateBorder,
    ink,
    dividerColor,
    borderWidthRatio,
    plateRadiusRatio,
    activeColor,
    inactiveColor,
    alertColor,
  ];

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlateTheme && listEquals(other._props, _props);

  @override
  int get hashCode => Object.hashAll(_props);
}

/// Provides a [PlateTheme] to descendants via [PlateTheme.of].
class PlateThemeScope extends InheritedWidget {
  const PlateThemeScope({super.key, required this.theme, required super.child});

  final PlateTheme theme;

  @override
  bool updateShouldNotify(PlateThemeScope oldWidget) => theme != oldWidget.theme;
}
