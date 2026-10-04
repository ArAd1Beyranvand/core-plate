import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// Colombian plates carry Western digits and Latin capitals.
abstract final class ColombiaAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;
  static const PlateAlphabet letters = PlateAlphabet.latinUppercase;

  /// A cell that only ever holds [letter]: the `O` of an official plate, the
  /// `CC` of a consular one.
  static PlateAlphabet fixed(String letter) => PlateAlphabet(
    id: 'co.fixed.$letter',
    characters: <String>[letter],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}
