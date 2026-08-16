import 'package:flutter/widgets.dart';

/// Describes the country-specific chrome of a licence plate: which flag to
/// draw, the caption printed beside it, and the colours of the country panel.
///
/// This is the single place to add a new country — adding one is data (a new
/// [PlateCountry] constant), not a new widget. [CountryPanel] and [PlateFlag]
/// read everything they need from here.
@immutable
class PlateCountry {
  const PlateCountry({
    required this.code,
    required this.captionLines,
    required this.panelColor,
    required this.panelTextColor,
  });

  /// ISO 3166-1 alpha-2 country code (e.g. `ir`), used to look up the flag.
  final String code;

  /// The lines of text printed on the panel beside the flag, top to bottom
  /// (e.g. `['I.R.', 'IRAN']`). Always laid out LTR.
  final List<String> captionLines;

  /// Background colour of the country panel block.
  final Color panelColor;

  /// Text colour on the [panelColor] block.
  final Color panelTextColor;

  /// The Islamic Republic of Iran, as it appears on a standard plate: a blue
  /// panel with white "I.R." / "IRAN" text beside the flag.
  static const PlateCountry iran = PlateCountry(
    code: 'ir',
    captionLines: ['I.R.', 'IRAN'],
    panelColor: Color(0xFF16479D),
    panelTextColor: Color(0xFFFFFFFF),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlateCountry &&
        other.code == code &&
        _listEquals(other.captionLines, captionLines) &&
        other.panelColor == panelColor &&
        other.panelTextColor == panelTextColor;
  }

  @override
  int get hashCode => Object.hash(
        code,
        Object.hashAll(captionLines),
        panelColor,
        panelTextColor,
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
