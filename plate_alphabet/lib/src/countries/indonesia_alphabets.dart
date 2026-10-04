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

  /// The police-region numeral over the serial of a Polri plate: the
  /// Roman numbers I to XXXV, one per regional command.
  static const PlateAlphabet policeRegions = PlateAlphabet(
    id: 'id.policeRegions',
    characters: <String>[
      'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', //
      'X', 'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII',
      'XIX', 'XX', 'XXI', 'XXII', 'XXIII', 'XXIV', 'XXV', 'XXVI', 'XXVII',
      'XXVIII', 'XXIX', 'XXX', 'XXXI', 'XXXII', 'XXXIII', 'XXXIV', 'XXXV',
    ],
    input: AlphabetInput.chosen,
    isNumeric: false,
  );
}
