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

  // The military and police plates have no artwork; these are the modal
  // pixels of photographs (see `IndonesiaPlates.military`).

  /// The rim, divider, serial and crest of every TNI and Polri plate. Studio
  /// photograph of a Navy plate.
  static const Color serviceYellow = Color(0xFFFEB705);

  /// The square behind the TNI crest, and the field of a TNI headquarters
  /// plate. Same Navy photograph.
  static const Color serviceRed = Color(0xFFDA0000);

  /// Army. Sunlit plate; a shaded one reads 2A4336.
  static const Color armyGreen = Color(0xFF32664D);

  static const Color navyBlue = Color(0xFF0148B0);

  static const Color airForceBlue = Color(0xFF13254C);

  /// Police: a near-black with a blue cast, not [black].
  static const Color policeBlack = Color(0xFF2A2930);

  /// Placeholder ink for an empty slot on a dark field.
  static const Color inactiveOnDark = Color(0xFF8A8A8A);

  /// Placeholder ink for an empty slot on a light field.
  static const Color inactiveOnLight = Color(0xFFB0B0B0);
}
