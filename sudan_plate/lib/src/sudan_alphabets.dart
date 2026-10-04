import 'package:plate_core/core_plate.dart';
import 'package:flutter/widgets.dart';
import 'package:plate_alphabet/plate_alphabet.dart';

/// The alphabets a Sudanese plate slot is drawn over.
///
/// Every value is stored once, in Latin, and each row of the plate is that
/// value through a different alphabet: the big Arabic row through the glyph
/// maps below, the small Latin row through the same characters with none. So
/// the state code `KH` prints `خ` above and `KH` below, and typing in either
/// row writes the other.
abstract final class SudanAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;
  static const PlateAlphabet arabicDigits = PlateAlphabetDigits.iranshahr;

  /// State codes seen on a 2009-series plate, Latin as printed on the lower
  /// row: `KH` Khartoum (artwork, factory sample, worldlicenseplates),
  /// `G` Al Jazirah and `RS` Red Sea (worldlicenseplates).
  // TODO(sudan-states): the other states' codes; none are sourced.
  static const List<String> _states = <String>['KH', 'G', 'RS'];

  static const PlateAlphabet stateLatin = PlateAlphabet(
    id: 'sd.state.latin',
    characters: _states,
    input: AlphabetInput.chosen,
    isNumeric: false,
  );

  /// [stateLatin] as the upper row prints it. Red Sea is two letters, spaced
  /// apart as on the photographed plate (`٨ ب ح` over `8RS`) — unjoined by a
  /// zero-width non-joiner, since any space pushes ب into the class digit.
  static const PlateAlphabet stateArabic = PlateAlphabet(
    id: 'sd.state.arabic',
    characters: _states,
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
    glyphs: <String, String>{'KH': 'خ', 'G': 'ج', 'RS': 'ب\u200Cح'},
  );
}
