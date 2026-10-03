import 'package:flutter/widgets.dart';

/// Nigerien plate colours, each the modal pixel of its region in the
/// Wikipedia artwork (`НІГЕР_НОМЕР_1.gif`, `НІГЕР_НОМЕР_2.gif`).
///
/// The article calls the commercial characters red; the artwork prints them
/// black, and the artwork is what is followed here.
abstract final class NigerColors {
  static const Color privateWhite = Color(0xFFFEFEFE);
  static const Color black = Color(0xFF000000);

  static const Color commercialOrange = Color(0xFFFE6A00);

  /// The grey dot between the series letter and the serial on the private
  /// plate.
  static const Color dot = Color(0xFF808080);

  /// The silver square in the same place on the commercial plate.
  static const Color seal = Color(0xFFC0C0C0);

  static const Color inactiveOnLight = Color(0x66666666);
  static const Color inactiveOnOrange = Color(0x66000000);
}
