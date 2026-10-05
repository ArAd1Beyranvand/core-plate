import 'package:flutter/widgets.dart';

/// The colours a Vietnamese plate is printed in. QCVN 08:2024/BCA gives
/// colour names and CIE chromaticity limits, not RGB, so each value is the
/// modal colour of a region of the reference images (4–8 level quantisation).
abstract final class VietnamColors {
  /// The white field and the black print on it: the regulation's drawings
  /// (`2020 Vietnamese vehicle reg. plate - Cars.jpg`), sampled 020202.
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// The commercial field: the taxi plate on `Newone - Silver VinFast Limo
  /// Green G7 taxi 01.jpg`, 140k field pixels, mean F7DF23. The regulation's
  /// daytime chromaticity box centres near E3AA00; the photograph is lit
  /// by streetlight and reads lighter.
  static const Color yellow = Color(0xFFF7DF23);

  /// The state field: `Vietnam Government plate 02.jpg`, 2.9M field pixels,
  /// mean 5277C8. A daylight photograph of retroreflective sheeting, so paler
  /// than the regulation's deep blue (chromaticity centre near 0060A5).
  static const Color blue = Color(0xFF5277C8);

  /// The characters on [blue] and [red]. The blue plate's raised numerals
  /// photograph D3D5DA under overcast; the standard and the military scan say
  /// white.
  static const Color whiteInk = Color(0xFFFFFFFF);

  /// The military field, the red of the 2021 Ministry of National Defence
  /// template (`…military vehicle plate templates (colorized).jpg`), 53k
  /// pixels at 92% modal CE1226. The scan is colourised, so this is the
  /// artwork's red, not a measurement of sheeting.
  static const Color red = Color(0xFFCE1226);

  /// The NG / QT code: the red of `В’ЄТНАМСЬКИЙ НОМЕР QT.gif`, FE0202.
  static const Color codeRed = Color(0xFFFF0000);

  static const Color inactiveOnLight = Color(0xFFB0B0B0);
  static const Color inactiveOnDark = Color(0xFF5A5A5A);
}
