import 'package:flutter/widgets.dart';

/// Every colour a Lebanese plate is printed in, in one file.
///
/// Lebanon's system is unusual among the packages in this repo: it has **two
/// geometries and many colours**, where its neighbours have many geometries and
/// few colours. A private car, a taxi, a consular car, a diplomatic car, a
/// driving school car and a tourist car are all the same plate — a letter, six
/// digits, a blue band with the cedar — printed on a different field. So the
/// interesting axis here is this file, and `LebanonThemes` is little more than
/// one `PlateTheme.monochrome` per entry below.
///
/// **Every constant is `// CALIBRATE`.** The published sources name the colours
/// in prose — "purple", "orange", "red", "yellow", "green", "brown", "pink" —
/// and no standard gives a hex or an ink reference. Each value here is the
/// right hue family at roughly the right value, read off photographs. None is a
/// measurement.
///
/// Colour never goes into a [PlateSpec]. It goes into a `PlateTheme` (see
/// `LebanonThemes`) and into the two `PlateCountry` colour fields. That
/// separation is `core_plate`'s, and it is why recalibrating this file leaves
/// every spec alone.
abstract final class LebanonColors {
  // -------------------------------------------------------------------------
  // The band. Shared by every plate of every colour, which is the point of it:
  // the field says what the vehicle is for, the band says what country it is
  // from, and the two are independent.
  // -------------------------------------------------------------------------

  /// The blue identification band — the left strip on a one-line plate, the top
  /// strip on a two-line one.
  static const Color band = Color(0xFF0D63B5); // CALIBRATE

  /// لبنان, the sect/usage word, and the cedar, all printed white on the band.
  static const Color bandInk = Color(0xFFFFFFFF); // CALIBRATE

  // -------------------------------------------------------------------------
  // Fields. One per usage class — see `LebanonUsage`, which is the enumeration
  // these belong to.
  // -------------------------------------------------------------------------

  /// Private vehicles, and every letter class that is not colour-coded:
  /// judicial, religious, parliament, motorcycles.
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

  // -------------------------------------------------------------------------
  // Ink. A Lebanese plate prints black on the light fields and white on the
  // dark ones; the pairing is fixed per usage and lives in `LebanonThemes`.
  // -------------------------------------------------------------------------

  /// Ink on the white, yellow, orange and pink fields.
  static const Color darkInk = Color(0xFF111111); // CALIBRATE

  /// Ink on the purple, red, green and brown fields.
  static const Color lightInk = Color(0xFFFFFFFF); // CALIBRATE

  /// The frame around the face. Black on every plate, including the dark
  /// fields, where it reads as a thin separation from the vehicle rather than
  /// as a frame.
  static const Color frame = Color(0xFF111111); // CALIBRATE

  /// The unfocused-slot outline, in input mode only. Never plate chrome — it is
  /// `PlateTheme.inactiveColor`, which core paints under an empty field.
  static const Color inactiveOnLight = Color(0x66666666); // CALIBRATE

  /// The same, for a dark field where a grey outline would vanish.
  static const Color inactiveOnDark = Color(0x66FFFFFF); // CALIBRATE
}
