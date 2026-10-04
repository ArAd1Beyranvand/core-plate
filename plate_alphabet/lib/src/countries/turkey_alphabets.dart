import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The characters a Turkish plate is composed of: western Arabic numerals for
/// the province code and the serial, and the serial letters.
///
/// The serial letters are the Turkish alphabet less `Ç Ş İ Ö Ü Ğ`, plus none
/// of the Latin `Q W X`, per Wikipedia's "Vehicle registration plates of
/// Turkey" — 23 letters. `I` is the dotless capital, which Turkish and Latin
/// share.
abstract final class TurkeyAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  static const PlateAlphabet letters = PlateAlphabet(
    id: 'tr.letters',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', //
      'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'Y', 'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}
