import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The characters a UAE plate is composed of: western Arabic numerals for the
/// serial and the numeric codes of Abu Dhabi and Sharjah, Latin capitals for
/// the other five emirates' code letter.
///
/// The letter alphabet is the full Latin set. Which letters each emirate
/// actually issues is in [UaeValidators], which describes rather than
/// restricts.
abstract final class UaeAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  static const PlateAlphabet letters = PlateAlphabet(
    id: 'ae.letters',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}
