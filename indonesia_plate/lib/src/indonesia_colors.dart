import 'package:flutter/widgets.dart';

/// The colours of the 2023 Indonesian series, read from the `fill` attributes
/// of the Wikimedia "2023 Indonesian plate" SVGs — exact values, not sampled
/// pixels. The article's "green" is a [ftzGreen] of 00AA55; its "blue trim" is
/// [evBlue].
///
/// Korlantas publishes no colour values, so these are the artwork's.
abstract final class IndonesiaColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Public transport and commercial vehicles.
  static const Color publicYellow = Color(0xFFFFBB00);

  /// Government vehicles, fire service and government ambulances.
  static const Color governmentRed = Color(0xFFDD0000);

  /// Free-trade-zone vehicles (Batam).
  static const Color ftzGreen = Color(0xFF00AA55);

  /// The electric-vehicle band behind the expiry row.
  static const Color evBlue = Color(0xFF00AAEE);

  /// Placeholder ink for an empty slot on a dark field.
  static const Color inactiveOnDark = Color(0xFF8A8A8A);

  /// Placeholder ink for an empty slot on a light field.
  static const Color inactiveOnLight = Color(0xFFB0B0B0);
}
