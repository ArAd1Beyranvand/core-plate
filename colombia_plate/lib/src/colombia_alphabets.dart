import 'package:plate_core/core_plate.dart';
import 'package:plate_alphabet/plate_alphabet.dart';

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
