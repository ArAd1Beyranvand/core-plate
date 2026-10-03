import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';

import 'india_colors.dart';

/// One theme per row of the article's colour table. Every one is a single ink
/// on a single field inside the same black frame, so they are one helper.
abstract final class IndiaThemes {
  /// The frame is 8–9 px of 183 in the artwork: 5.25–5.9 of 120.
  static const double borderWidthRatio = 0.047;

  /// ~10 px corners on 183 px plates, read off the frame's top row.
  static const double _plateRadiusRatio = 0.055; // CALIBRATE

  static PlateTheme _theme(Color field, Color ink) => PlateTheme(
    plateBackground: field,
    plateBorder: IndiaColors.black,
    ink: ink,
    dividerColor: ink,
    borderWidthRatio: borderWidthRatio,
    plateRadiusRatio: _plateRadiusRatio,
    activeColor: ink,
    inactiveColor: IndiaColors.inactive,
    alertColor: const Color(0xFFD32F2F),
  );

  /// Black on white. Also Bharat- and vintage-series plates.
  static final PlateTheme private = _theme(
    IndiaColors.white,
    IndiaColors.black,
  );

  /// Black on yellow.
  static final PlateTheme transport = _theme(
    IndiaColors.yellow,
    IndiaColors.black,
  );

  /// Yellow on black: self-drive rental.
  static final PlateTheme rental = _theme(
    IndiaColors.black,
    IndiaColors.yellow,
  );

  /// White on green: private electric, and armed-forces electric.
  static final PlateTheme electric = _theme(
    IndiaColors.green,
    IndiaColors.white,
  );

  /// Yellow on green: transport and rental electric.
  static final PlateTheme electricTransport = _theme(
    IndiaColors.green,
    IndiaColors.yellow,
  );

  /// White on blue: embassy, UN and international organisation.
  static final PlateTheme diplomatic = _theme(
    IndiaColors.blue,
    IndiaColors.white,
  );

  /// Yellow on blue: consulate.
  static final PlateTheme consular = _theme(
    IndiaColors.blue,
    IndiaColors.yellow,
  );

  /// White on black: armed forces.
  static final PlateTheme military = _theme(
    IndiaColors.black,
    IndiaColors.white,
  );

  /// Red on white: military police.
  static final PlateTheme militaryPolice = _theme(
    IndiaColors.white,
    IndiaColors.red,
  );

  /// Red on yellow: temporary registration.
  static final PlateTheme temporary = _theme(
    IndiaColors.yellow,
    IndiaColors.red,
  );

  /// White on red: trade certificate.
  static final PlateTheme trade = _theme(IndiaColors.red, IndiaColors.white);
}
