import 'package:flutter/widgets.dart';

/// The colours a Malaysian plate is printed in, sampled from the pixels of
/// the Wikipedia/Commons references (the modal colour of a region, not one
/// pixel). The article's inline "plates" are CSS badges and were not used.
///
/// Photographs are marked `// CALIBRATE`: plastic ages and aluminium gets
/// dirty, so those values are what the plates in the photos look like, not a
/// published standard. JPJ publishes no colour values.
abstract final class MalaysiaColors {
  /// The black field of a standard plate. Penang PFQ 5217 photo.
  static const Color black = Color(0xFF1C1C1C); // CALIBRATE

  /// The white characters on [black]. Penang photo; an aged, warm white.
  static const Color lightInk = Color(0xFFE8E0D0); // CALIBRATE

  /// The taxi (kereta sewa) field. The Kedah taxi photo samples a light
  /// grey-blue, the KL one a dirtier 687068; both are reflective aluminium seen
  /// under daylight, and the article calls it white.
  static const Color taxiField = Color(0xFF808088); // CALIBRATE

  /// Black characters on a taxi or JPJePlate field.
  static const Color darkInk = Color(0xFF000000);

  /// The diplomatic red, sampled on the lit half of the 99-64-DC photo (the
  /// shadowed half samples 6D2F34).
  static const Color diplomaticRed = Color(0xFFA8363C); // CALIBRATE

  /// The light characters on [diplomaticRed]. Same photo.
  static const Color diplomaticInk = Color(0xFFD4CCD0); // CALIBRATE

  /// JPJePlate field. From the JPJePlate artwork.
  static const Color evField = Color(0xFFFFFFFF);

  /// JPJePlate green identification strip. From the artwork.
  static const Color evGreen = Color(0xFF8DBF22);

  /// The grey security strip beside the green one. From the artwork.
  static const Color evSecureStrip = Color(0xFFF1F1F1);

  /// Placeholder ink for an empty slot on a dark field.
  static const Color inactiveOnDark = Color(0xFF5A5A5A);

  /// Placeholder ink for an empty slot on a light field.
  static const Color inactiveOnLight = Color(0xFFB0B0B0);
}
