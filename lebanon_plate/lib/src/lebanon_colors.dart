import 'package:flutter/widgets.dart';

/// Every colour a Lebanese plate is printed in. Two geometries, eight fields
/// (one per `LebanonUsage`), all from photographs — marked `// CALIBRATE`.
/// Colours go into `LebanonThemes` and `LebanonCountry`, never into specs.
abstract final class LebanonColors {
  /// The blue band (same on every usage).
  static const Color band = Color(0xFF0D63B5); // CALIBRATE

  /// White ink on the band.
  static const Color bandInk = Color(0xFFFFFFFF); // CALIBRATE

  /// Private vehicles, and uncoloured letter classes.
  /// (Judicial, religious, parliament, motorcycles.)
  static const Color white = Color(0xFFFFFFFF); // CALIBRATE

  /// Consular vehicles (C).
  static const Color purple = Color(0xFF7B3F98); // CALIBRATE

  /// Diplomatic vehicles (D).
  static const Color orange = Color(0xFFE87722); // CALIBRATE

  /// Public institutions (مؤسسات), and formerly public transport.
  static const Color red = Color(0xFFC8102E); // CALIBRATE

  /// Driving instructor vehicles.
  static const Color yellow = Color(0xFFF6C400); // CALIBRATE

  /// Transit and temporary-use vehicles.
  static const Color green = Color(0xFF1B7A3D); // CALIBRATE

  /// Temporary registration plates.
  static const Color brown = Color(0xFF6B4423); // CALIBRATE

  /// Tourism vehicles.
  static const Color pink = Color(0xFFE8618C); // CALIBRATE

  /// Ink on light fields (white, yellow, orange, pink).
  static const Color darkInk = Color(0xFF111111); // CALIBRATE

  /// Ink on dark fields (purple, red, green, brown).
  static const Color lightInk = Color(0xFFFFFFFF); // CALIBRATE

  /// Frame colour.
  static const Color frame = Color(0xFF111111); // CALIBRATE

  /// Unfocused slot outline on light fields.
  static const Color inactiveOnLight = Color(0x66666666); // CALIBRATE

  /// Unfocused slot outline on dark fields.
  static const Color inactiveOnDark = Color(0x66FFFFFF); // CALIBRATE
}
