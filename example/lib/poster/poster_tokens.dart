import 'package:flutter/material.dart';

/// Colour tokens from DESIGN_SPEC.md §1.
class PosterColors {
  const PosterColors._();

  // --- Ground / atmosphere --------------------------------------------------
  static const Color pageBlack = Color(0xFF050608);
  static const Color stageBlack = Color(0xFF07080B);

  static const Color groundRadialCore = Color(0xFF121620);
  static const Color groundRadialMid = Color(0xFF0A0B0E);
  static const Color groundRadialEdge = Color(0xFF050608);

  static const Color beamHi = Color(0x99B6CAE8); // rgba(182,202,232,.6)
  static const Color beamMid = Color(0x2894AFD6); // rgba(148,175,214,.16) @48% combined
  static const Color beamTint = Color(0x2E465C7C); // rgba(70,92,124,.18)
  static const Color roadMask = Color(0xB7030201); // rgba(3,2,1,.72)

  static const Color railLightCore = Color(0xE6CEDCF2); // rgba(206,220,242,.9)
  static const Color railLightMid = Color(0x3DBED0EC); // rgba(190,208,236,.24)

  static const Color roadStripe = Color(0xEBFFFFFF); // rgba(255,255,255,.92)

  static const Color sweepBodyStart = Color(0x05C4D6F0); // rgba(196,214,240,.02)
  static const Color sweepBodyMid = Color(0x29C6D8F2); // rgba(198,216,242,.16)
  static const Color sweepBodyEnd = Color(0x4DD2E0F6); // rgba(210,224,246,.3)

  static const Color sweepEdgeStart = Color(0x66E0EBFA); // rgba(224,235,250,.4)
  static const Color sweepEdgeMid = Color(0xFAE0EBFA); // rgba(224,235,250,.98)
  static const Color sweepEdgeEnd = Color(0x66E0EBFA); // rgba(224,235,250,.4)
  static const Color sweepEdgeGlow = Color(0xBFB8CBE9); // rgba(184,203,233,.75)

  static const Color groundShadowStart = Color(0xF2030201); // rgba(3,2,1,.95)
  static const Color groundShadowMid = Color(0x80050302); // rgba(5,3,2,.5)

  // --- Text ------------------------------------------------------------------
  static const Color inkDisplay1 = Color(0xFFEAF0FB);
  static const Color inkDisplay2 = Color(0xFFD6E1F1);
  static const Color inkDisplay3 = Color(0xFFC4D0E2);
  static const Color inkDisplay4 = Color(0xFF1A2130);
  static const Color inkDisplayCut = Color(0xFFBCD3F0);
  static const Color inkByline = Color(0xFFDEE7F4);
  static const Color inkMutedItalic = Color(0xFF8E9DB4);
  static const Color inkLink = Color(0xFFA9B3C7);
  static const Color inkMetaStrong = Color(0xFFA5B4C7);
  static const Color inkMetaWeak = Color(0xFF8592A3);
  static const Color inkStamp = Color(0xFFB3BECD);

  // --- Accent / signal --------------------------------------------------------
  static const Color accent = Color(0xFF7C5CFF);
  static const Color accentRail = Color(0x8C7C5CFF); // rgba(124,92,255,.55)
  static const Color accentRailGlow = Color(0xF27C5CFF); // rgba(124,92,255,.95)
  static const Color accentPipGlow = Color(0xF27C5CFF); // rgba(124,92,255,.95)
  static const Color pipIdle = Color(0x3DC8D4EC); // rgba(200,212,236,.24)
  static const Color flareRed = Color(0xFFF02C1E);
  static const Color flareInk = Color(0xFF1A0603);

  // --- Card decoration ---------------------------------------------------------
  static const Color cardBlueIr = Color(0xFF16479D);
  static const Color cardBlueDe = Color(0xFF003399);
  static const Color euStar = Color(0xFFF5D021);

  static const Color flagBrightGreen = Color(0xFF239F40);
  static const Color flagBrightWhite = Color(0xFFEDEFF3);
  static const Color flagBrightRed = Color(0xFFDA0000);

  static const Color flagMutedGreen = Color(0xFF1D7A36);
  static const Color flagMutedWhite = Color(0xFFB9B4A6);
  static const Color flagMutedRed = Color(0xFF9E1410);

  static const Color chipFace = Color(0xFFEDEFF3);
  static const Color chipInk = Color(0xFF12141B);

  // --- Card grounds ------------------------------------------------------------
  static const Color cardHeroIr = cardBlueIr;
  static const Color cardHeroDe = cardBlueDe;
  static const Color cardChipWhite = chipFace;
  static const Color metaStrip = Color(0xEB090806); // rgba(9,8,6,.92)

  // --- Compatibility names (do not drop) ---------------------------------------
  /// Read by the frozen `virtual_keypad.dart`.
  static const Color accentCompat = accent;

  /// Read by the frozen `virtual_keypad.dart`.
  static const Color hairlineCompat = Color(0x1AFFFFFF); // rgba(255,255,255,.10)

  /// Read by the frozen plate wiring in `showcase_screen.dart`.
  static const Color bgCompat = stageBlack;

  /// Read by the frozen plate wiring in `showcase_screen.dart`.
  static const Color invalidCompat = Color(0xFFF87171);
}

/// Named gradients from DESIGN_SPEC.md §1.
///
/// CSS `linear-gradient(158deg, a, b)` is measured clockwise from "to top"
/// (0deg = pointing up, 90deg = pointing right). 158deg points mostly down
/// and slightly right, so the gradient *starts* up-and-left of that (where
/// the light would come from) and *ends* down-and-right: begin ~= topLeft,
/// end ~= bottomRight, both nudged by the extra 22deg toward the top edge.
class PosterGradients {
  const PosterGradients._();

  /// `linear-gradient(158deg, #232C42, #0E1219)`
  static const LinearGradient cardSteel = LinearGradient(
    begin: Alignment(-0.62, -0.79),
    end: Alignment(0.62, 0.79),
    colors: [Color(0xFF232C42), Color(0xFF0E1219)],
  );

  /// `linear-gradient(158deg, #141926, #080A10)`
  static const LinearGradient cardDark = LinearGradient(
    begin: Alignment(-0.62, -0.79),
    end: Alignment(0.62, 0.79),
    colors: [Color(0xFF141926), Color(0xFF080A10)],
  );

  /// `linear-gradient(158deg, #131826, #080A10)` — variant used on card 04/12.
  static const LinearGradient cardDarkVariant = LinearGradient(
    begin: Alignment(-0.62, -0.79),
    end: Alignment(0.62, 0.79),
    colors: [Color(0xFF131826), Color(0xFF080A10)],
  );

  /// `linear-gradient(158deg, #1C2233, #0D1017)`
  static const LinearGradient cardChipDark = LinearGradient(
    begin: Alignment(-0.62, -0.79),
    end: Alignment(0.62, 0.79),
    colors: [Color(0xFF1C2233), Color(0xFF0D1017)],
  );

  /// `linear-gradient(158deg, #1B2131, #0C0F16)` — variant.
  static const LinearGradient cardChipDarkVariant = LinearGradient(
    begin: Alignment(-0.62, -0.79),
    end: Alignment(0.62, 0.79),
    colors: [Color(0xFF1B2131), Color(0xFF0C0F16)],
  );

  /// `linear-gradient(158deg, #1A2032, #0C0E16)`; hover ground → `#EDEFF3`.
  static const LinearGradient linkButton = LinearGradient(
    begin: Alignment(-0.62, -0.79),
    end: Alignment(0.62, 0.79),
    colors: [Color(0xFF1A2032), Color(0xFF0C0E16)],
  );

  static const Color linkButtonHover = Color(0xFFEDEFF3);
}

/// Font family names and variable-axis helpers from DESIGN_SPEC.md §2.
class PosterFonts {
  const PosterFonts._();

  static const String archivo = 'Archivo';
  static const String martianMono = 'MartianMono';
  static const String newsreader = 'Newsreader';
  static const String vazirmatn = 'Vazirmatn';

  /// `wdth 79` — the wordmark.
  static const List<FontVariation> wdth79 = [FontVariation('wdth', 79)];

  /// `wdth 84` — hero card titles (EN).
  static const List<FontVariation> wdth84 = [FontVariation('wdth', 84)];

  /// `wdth 86` — small card titles (EN).
  static const List<FontVariation> wdth86 = [FontVariation('wdth', 86)];

  /// `wdth 104` — index chips.
  static const List<FontVariation> wdth104 = [FontVariation('wdth', 104)];
}

/// Every text specimen in DESIGN_SPEC.md §2, expressed as a factory that
/// takes a fluid scale factor (see `PosterMetrics.f`) instead of an absolute
/// size, so no call site hardcodes design px.
class PosterType {
  const PosterType._();

  static TextStyle wordmark(double f) => TextStyle(
        fontFamily: PosterFonts.archivo,
        fontVariations: PosterFonts.wdth79,
        fontWeight: FontWeight.w900,
        fontSize: 176 * f,
        height: 0.86,
        letterSpacing: -0.045 * 176 * f,
      );

  static TextStyle bylineName(double f) => TextStyle(
        fontFamily: PosterFonts.martianMono,
        fontWeight: FontWeight.w800,
        fontSize: 17 * f,
        letterSpacing: 0.16 * 17 * f,
        color: PosterColors.inkByline,
      );

  static TextStyle bylineRole(double f) => TextStyle(
        fontFamily: PosterFonts.newsreader,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        fontSize: 15 * f,
        color: PosterColors.inkMutedItalic,
      );

  static TextStyle cardEyebrowHero(double f) => TextStyle(
        fontFamily: PosterFonts.martianMono,
        fontWeight: FontWeight.w700,
        fontSize: 13 * f,
        letterSpacing: 0.30 * 13 * f,
      );

  static TextStyle cardEyebrowSteel(double f) => TextStyle(
        fontFamily: PosterFonts.martianMono,
        fontWeight: FontWeight.w700,
        fontSize: 12 * f,
        letterSpacing: 0.28 * 12 * f,
        color: const Color(0xFF9FB6E4),
      );

  static TextStyle cardEyebrowDark(double f, {bool alt = false}) => TextStyle(
        fontFamily: PosterFonts.martianMono,
        fontWeight: FontWeight.w600,
        fontSize: 12 * f,
        letterSpacing: 0.24 * 12 * f,
        color: alt ? const Color(0xFF8B97AE) : const Color(0xFF8F9BB2),
      );

  /// Card title EN (hero). [size] must be in the 42–62px design range.
  static TextStyle cardTitleEnHero(double f, double size) => TextStyle(
        fontFamily: PosterFonts.archivo,
        fontVariations: PosterFonts.wdth84,
        fontWeight: FontWeight.w800,
        fontSize: size * f,
        height: size <= 50 ? 0.94 : 0.92,
        letterSpacing: -0.032 * size * f,
      );

  /// Card title EN (small). [size] must be in the 34–36px design range.
  static TextStyle cardTitleEnSmall(double f, double size) => TextStyle(
        fontFamily: PosterFonts.archivo,
        fontVariations: PosterFonts.wdth86,
        fontWeight: FontWeight.w800,
        fontSize: size * f,
        height: 0.96,
        letterSpacing: -0.025 * size * f,
      );

  /// Card title FA. [size] must be in the 34–50px design range.
  static TextStyle cardTitleFa(double f, double size) => TextStyle(
        fontFamily: PosterFonts.vazirmatn,
        fontWeight: FontWeight.w800,
        fontSize: size * f,
        height: size <= 40 ? 1.22 : 1.18,
      );

  /// Card body EN. [size] must be in the 18–24px design range.
  static TextStyle cardBodyEn(double f, double size) => TextStyle(
        fontFamily: PosterFonts.newsreader,
        fontWeight: FontWeight.w400,
        fontSize: size * f,
        height: size <= 20 ? 1.46 : 1.44,
      );

  /// Card body FA. [size] must be in the 19–23px design range.
  static TextStyle cardBodyFa(double f, double size) => TextStyle(
        fontFamily: PosterFonts.vazirmatn,
        fontWeight: FontWeight.w400,
        fontSize: size * f,
        height: size <= 20 ? 1.78 : 1.70,
      );

  /// Index chip. [size] must be in the 44–78px design range.
  static TextStyle indexChip(double f, double size) => TextStyle(
        fontFamily: PosterFonts.archivo,
        fontVariations: PosterFonts.wdth104,
        fontWeight: FontWeight.w800,
        fontSize: size * f,
      );

  static TextStyle linkLabel(double f) => TextStyle(
        fontFamily: PosterFonts.martianMono,
        fontWeight: FontWeight.w700,
        fontSize: 14 * f,
        letterSpacing: 0.20 * 14 * f,
      );

  static TextStyle metaStrong(double f) => TextStyle(
        fontFamily: PosterFonts.martianMono,
        fontWeight: FontWeight.w600,
        fontSize: 17 * f,
        letterSpacing: 0.14 * 17 * f,
        color: PosterColors.inkMetaStrong,
      );

  static TextStyle metaWeak(double f) => TextStyle(
        fontFamily: PosterFonts.martianMono,
        fontWeight: FontWeight.w500,
        fontSize: 15 * f,
        letterSpacing: 0.14 * 15 * f,
        color: PosterColors.inkMetaWeak,
      );

  static TextStyle stamp(double f) => TextStyle(
        fontFamily: PosterFonts.martianMono,
        fontWeight: FontWeight.w700,
        fontSize: 12 * f,
        height: 1.55,
        letterSpacing: 0.20 * 12 * f,
        color: PosterColors.inkStamp,
      );

  /// Red tag on card 09.
  static TextStyle redTag(double f) => TextStyle(
        fontFamily: PosterFonts.martianMono,
        fontWeight: FontWeight.w700,
        fontSize: 13 * f,
        letterSpacing: 0.20 * 13 * f,
        color: PosterColors.flareInk,
      );
}

/// Design tokens shared across the poster widgets, plus the four names the
/// frozen device-side files already read: [accent], [hairline], [bg] and
/// [invalid]. These four must not be renamed or removed — see
/// DESIGN_SPEC.md §1, "Compatibility names".
class PosterTokens {
  const PosterTokens._();

  static const Color accent = PosterColors.accentCompat;
  static const Color hairline = PosterColors.hairlineCompat;
  static const Color bg = PosterColors.bgCompat;
  static const Color invalid = PosterColors.invalidCompat;
}
