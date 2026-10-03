import 'package:flutter/widgets.dart';

/// Every colour an Indian plate is printed in, sampled as the modal pixel of
/// each region of the colour-class artwork supplied with the task (private,
/// commercial, rental, embassy and electric plates). Wikipedia's colour table
/// gives only CSS keywords, so it decides which colour goes where, never the
/// value. Colours go into `IndiaThemes`, never into specs.
abstract final class IndiaColors {
  static const Color white = Color(0xFFFFFFFF);

  /// Characters on light fields, every frame, and the rental field.
  static const Color black = Color(0xFF1D1D1B);

  /// Commercial field and rental ink: `FFFF01`, a pure yellow.
  static const Color yellow = Color(0xFFFFFF01);

  /// The diplomatic field: `86C0FF`, a pale sky blue, not a royal blue.
  static const Color blue = Color(0xFF86C0FF);

  /// The electric field: `3BA936`.
  static const Color green = Color(0xFF3BA936);

  /// The red of the artwork's red plate, `DB351F`. Used for the trade field
  /// and the temporary and military-police ink, which the artwork does not
  /// show; the temporary-plate photograph's ink is the same orange-red.
  static const Color red = Color(0xFFDB351F);

  /// Unfocused slot outline.
  static const Color inactive = Color(0x66666666);
}
