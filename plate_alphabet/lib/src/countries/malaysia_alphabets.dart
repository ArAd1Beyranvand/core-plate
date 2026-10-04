import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The alphabets behind Malaysian slots.
///
/// [letters] is all of A–Z, including I, O and Z: the series rules that never
/// issue I and O, and reserve Z for the military, live in `MalaysiaValidator`,
/// which reports rather than bars. A keypad that refused Z could not type a
/// military plate.
abstract final class MalaysiaAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  static const PlateAlphabet letters = PlateAlphabet(
    id: 'my.letters',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// The two-letter code ending a diplomatic plate: diplomatic corps,
  /// consular corps, United Nations, international organisation.
  static const PlateAlphabet missionCodes = PlateAlphabet(
    id: 'my.missionCodes',
    characters: <String>['DC', 'CC', 'UN', 'PA'],
    input: AlphabetInput.chosen,
    isNumeric: false,
  );
}
