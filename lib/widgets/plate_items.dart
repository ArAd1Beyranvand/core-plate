import 'package:flutter/widgets.dart';

/// The single source of truth for plate glyph styling.
class PlateDigit {
  const PlateDigit._();
  static TextStyle styleFor(double slotHeight, Color color) => TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: slotHeight * 0.72,
        height: 1.0,
      );
}
