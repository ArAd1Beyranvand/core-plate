import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The alphabets behind Indonesian slots. Latin letters and Western digits on
/// every current plate.
abstract final class IndonesiaAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  static const PlateAlphabet letters = PlateAlphabet(
    id: 'id.letters',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// The code opening a foreign-mission plate: diplomatic or consular corps.
  static const PlateAlphabet missionCodes = PlateAlphabet(
    id: 'id.missionCodes',
    characters: <String>['CD', 'CC'],
    input: AlphabetInput.chosen,
    isNumeric: false,
  );
}
