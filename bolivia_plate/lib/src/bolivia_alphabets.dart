import 'package:plate_core/plate_core.dart';
import 'package:plate_alphabet/plate_alphabet.dart';

/// Bolivian plates carry Western digits and Latin capitals.
abstract final class BoliviaAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;
  static const PlateAlphabet letters = PlateAlphabet.latinUppercase;

  /// The department letter in the PTA plate's box, as the article lists
  /// them: Cochabamba, Chuquisaca, El Beni, La Paz, Oruro, Pando, Potosí,
  /// Santa Cruz, Tarija.
  static const PlateAlphabet departments = PlateAlphabet(
    id: 'bo.department',
    characters: <String>['C', 'H', 'B', 'L', 'O', 'N', 'P', 'S', 'T'],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}
