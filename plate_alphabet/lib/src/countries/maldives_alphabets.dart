import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The alphabets behind Maldivian slots.
///
/// [letters] is all of A–Z: the article restricts nothing but the category
/// code, and that rule lives in `MaldivesPlateValidator`, which reports rather
/// than bars. The type letter (`P`, `C`, `G`, `S`, `T`, `D`) is fixed by the
/// plate's category, so it is a label on the spec, not a slot.
abstract final class MaldivesAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  static const PlateAlphabet letters = PlateAlphabet(
    id: 'mv.letters',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}
