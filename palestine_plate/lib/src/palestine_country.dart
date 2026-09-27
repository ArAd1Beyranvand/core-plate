import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'palestine_colors.dart';

/// Country blocks on Palestinian plates. West Bank carries `ف` / `P` in ink;
/// Gaza carries the flag. Multiple consts for West Bank because ink varies by
/// usage; all use `code: 'ps'` and render-time composition with theme and usage.
abstract final class PSCountries {
  /// `ف / P` in green (ordinary West Bank plate). Rule between the two lines
  /// lives on the spec, not the country, since [CountryPanel] only paints caption.
  static const PlateCountry westBankGreenInk = PlateCountry(
    code: 'ps',
    captionLines: ['ف', 'P'],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.green,
    flag: null,
  );

  /// `ف / P` in white for dark fields (public transport, trade plates).
  static const PlateCountry westBankWhiteInk = PlateCountry(
    code: 'ps',
    captionLines: ['ف', 'P'],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.white,
    flag: null,
  );

  /// `ف / P` in red (government and duty-exempt plates).
  static const PlateCountry westBankRedInk = PlateCountry(
    code: 'ps',
    captionLines: ['ف', 'P'],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.red,
    flag: null,
  );

  /// `ف  P` on one line (two-line motorcycle plate). Necessary because
  /// [CountryPanel] stacks lines vertically only. Divider omitted: would depend
  /// on font metrics this package doesn't ship.
  static const PlateCountry westBankGreenInkInline = PlateCountry(
    code: 'ps',
    captionLines: ['ف  P'],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.green,
    flag: null,
  );

  /// Empty country block (one-line motorcycle plate). Identity block drawn by
  /// spec as labels and rule, not by country panel. Compares equal to other
  /// West Bank consts via `code: 'ps'`.
  static const PlateCountry westBankGreenInkBlank = PlateCountry(
    code: 'ps',
    captionLines: [],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.green,
    flag: null,
  );

  /// Gaza 2012–2021: flag rotated, aspect 1:2 (vertical on plate's right strip).
  static const PlateCountry gaza2012 = PlateCountry(
    code: 'ps',
    captionLines: [],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.black,
    flagAspectRatio: 1 / 2,
    flag: SvgPlateAsset('assets/flags/Flag_of_Palestine_vertical.svg', package: 'palestine_plate'),
  );

  /// Gaza, 2021 onward: the flag the right way up, at its official 2:1 ratio.
  static const PlateCountry gaza2021 = PlateCountry(
    code: 'ps',
    captionLines: [],
    panelColor: Color(0x00000000),
    panelTextColor: PSColors.black,
    flagAspectRatio: 2 / 1,
    flag: SvgPlateAsset('assets/flags/Flag_of_Palestine.svg', package: 'palestine_plate'),
  );
}
