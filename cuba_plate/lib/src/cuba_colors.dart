import 'package:flutter/widgets.dart';

/// Every colour a Cuban plate is printed in. All are sampled from photographs
/// on the Wikipedia article (no clean artwork exists), so each is a
/// calibration target. Colours go into `CubaThemes` and `CubaCountry`, never
/// into specs.
abstract final class CubaColors {
  /// The field. Every 2013 plate is white; the photographs sample `E0DADA`
  /// and `DEE3F6`, which are the same white under two white balances.
  static const Color field = Color(0xFFFFFFFF);

  /// Characters, frame and dividers: the median dark pixel of the serials in
  /// the three photographs (`48454A`, `29292F`, `302D2B`), nearest the two
  /// that are not washed out by glare.
  static const Color ink = Color(0xFF302E30); // CALIBRATE

  /// The legal-entity strip. The two photographs disagree once their whites
  /// are balanced (`3192FF` on K 000 807, `0E56D6` on T 003 526); this is
  /// their mean. It is a bright Euroband-like blue, not a navy.
  static const Color band = Color(0xFF1F74EB); // CALIBRATE

  /// CUBA on the blue strip.
  static const Color bandInk = Color(0xFFFFFFFF);

  /// Unfocused slot outline.
  static const Color inactive = Color(0x66666666);
}
