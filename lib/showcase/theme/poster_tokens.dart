import 'package:flutter/material.dart';

/// Visual design tokens for the dark "spec poster" showcase.
///
/// Pure constants — colours, opacities and text styles shared across the
/// poster widgets. No layout concerns live here.
class PosterTokens {
  const PosterTokens._();

  // --- Background -----------------------------------------------------------
  static const Color bg = Color(0xFF05080B);
  static const Color bgTop = Color(0xFF070B10);

  // --- Accent ---------------------------------------------------------------
  static const Color accent = Color(0xFF6EE7B7);
  static const Color accentDim = Color(0x666EE7B7); // 40%
  static const Color accentGlow = Color(0x2E6EE7B7); // 18%

  // --- Text & lines ---------------------------------------------------------
  static const Color titleColor = Color(0xFFFFFFFF);
  static const Color bodyColor = Color(0xFF97A3AF);
  static const Color hairline = Color(0x0FFFFFFF); // white @ 6%

  // --- Fonts ----------------------------------------------------------------
  /// Platform default serif family.
  static const String serifFamily = 'serif';

  // --- Text styles ----------------------------------------------------------
  static const TextStyle eyebrow = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.5,
    color: accent,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: serifFamily,
    color: titleColor,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.55,
    fontFamily: serifFamily,
    color: bodyColor,
  );

  static const TextStyle headerName = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: titleColor,
    letterSpacing: -0.2,
  );

  static const TextStyle headerRole = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w300,
    color: Color(0xFF7C8894),
  );

  static const TextStyle footerMeta = TextStyle(
    fontSize: 14,
    fontFamily: serifFamily,
    color: bodyColor,
  );
}
