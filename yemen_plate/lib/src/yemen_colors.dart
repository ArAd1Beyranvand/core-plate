import 'package:flutter/widgets.dart';

/// Every colour a Yemeni plate is printed in. All unverified (// CALIBRATE).
/// Colours are not in specs; they go into [PlateTheme] and [PlateCountry],
/// so a recalibration here is a one-file change.
abstract final class YemenColors {
  // System A: white field for every usage. Usage lives in the blue panel captions.

  static const Color unifiedField = Color(0xFFFFFFFF); // CALIBRATE
  static const Color unifiedInk = Color(0xFF111111); // CALIBRATE (all glyphs)
  static const Color unifiedFrame = Color(0xFF111111); // CALIBRATE
  static const Color unifiedSidePanel = Color(
    0xFF7FB2E5,
  ); // CALIBRATE (the one hex the brief gave)

  // System B: field colour IS the usage (blue/yellow/red/green/black).
  // Black/white ink per field brightness; pairings in YemenThemes.
  static const Color blue = Color(0xFF1F5FA8); // CALIBRATE (خصوصي)
  static const Color yellow = Color(0xFFF2C200); // CALIBRATE (اجرة)
  static const Color red = Color(0xFFC0261F); // CALIBRATE (نقل)
  static const Color green = Color(0xFF14733E); // CALIBRATE (government)
  static const Color black = Color(0xFF111111); // CALIBRATE (military classic)
  static const Color white = Color(0xFFFFFFFF); // CALIBRATE (military modern)
  static const Color militaryRed = Color(0xFFC0261F); // CALIBRATE (modern ink)

  static const Color darkInk = Color(
    0xFF111111,
  ); // CALIBRATE (blue/yellow/red fields)
  static const Color lightInk = Color(
    0xFFFFFFFF,
  ); // CALIBRATE (green/black fields)
  static const Color inactiveOnLight = Color(
    0x66666666,
  ); // CALIBRATE (outline, input mode)
  static const Color inactiveOnDark = Color(
    0x66FFFFFF,
  ); // CALIBRATE (outline, dark field)

  // The southern governorates (Hadhramaut, Al Mahrah, Shabwah, Marib, Taiz).
  // Modal pixels of the Wikipedia artwork, identical across governorates —
  // not calibration targets like the rest of this file.
  static const Color southernBlue = Color(0xFF0079C1);
  static const Color southernYellow = Color(0xFFFFC913);
  static const Color southernRed = Color(0xFFED1C24);
  static const Color southernGreen = Color(0xFF01A06A);
  static const Color southernInk = Color(0xFF000000);
  static const Color southernField = Color(0xFFFFFFFF);
}
