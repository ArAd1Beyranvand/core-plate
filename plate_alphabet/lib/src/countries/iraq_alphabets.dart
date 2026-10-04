import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The characters an Iraqi plate is composed of.
///
/// The 2022/2024 series is the first to print in the Latin alphabet and
/// western Arabic numerals; everything before it used Arabic script and
/// eastern Arabic numerals. These are the current series only.
abstract final class IraqAlphabets {
  /// Western Arabic numerals — what the current series prints, for both the
  /// governorate code and the serial.
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  /// The single class letter between the governorate code and the serial.
  ///
  /// The current series does not publish a restricted set, and the reference
  /// artwork prints "G", which the preceding Arabic series did not have. So
  /// this is the full Latin alphabet; the narrower historical set is
  /// [IraqValidators.arabicSeriesLetters], which describes rather than
  /// restricts.
  static const PlateAlphabet letters = PlateAlphabet(
    id: 'iq.letters',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}
