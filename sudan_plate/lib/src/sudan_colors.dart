import 'package:flutter/widgets.dart';

/// Sudanese plate colours, each sampled as the modal pixel of its region.
///
/// Private: the Wikipedia artwork (`License_Plate_-_Sudan.png`). Bus-and-taxi
/// and commercial: worldlicenseplates.com's 2009-series photographs
/// (`AF_SUDA_OT-B.jpg`, `AF_SUDA_OT-C.jpg`), so those carry lighting.
abstract final class SudanColors {
  static const Color privateWhite = Color(0xFFFCFCFC);
  static const Color privateBlack = Color(0xFF000000);

  /// A teal, not the "green" a caption would call it.
  static const Color transportTeal = Color(0xFF067470);
  static const Color transportWhite = Color(0xFFFCFCFC);

  static const Color commercialBlack = Color(0xFF000000);
  static const Color commercialWhite = Color(0xFFFCFCFC);

  /// The hologram strip between the state code and the serial — foil, so the
  /// same on every livery. Sampled off the artwork; the factory photograph
  /// reads darker (`0x787878`) under its lighting.
  static const Color hologram = Color(0xFF999999);

  static const Color inactiveOnLight = Color(0x66666666);
  static const Color inactiveOnDark = Color(0x66FFFFFF);
}
