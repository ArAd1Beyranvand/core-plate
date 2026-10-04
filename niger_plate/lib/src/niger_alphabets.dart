import 'package:plate_core/core_plate.dart';
import 'package:plate_alphabet/plate_alphabet.dart';

abstract final class NigerAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  /// The eight regions, by digit: 1 Agadez, 2 Diffa, 3 Dosso, 4 Maradi,
  /// 5 Tahoua, 6 Tillabéri, 7 Zinder, 8 Niamey.
  static const PlateAlphabet region = PlateAlphabet(
    id: 'ne.region',
    characters: <String>['1', '2', '3', '4', '5', '6', '7', '8'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  static const PlateAlphabet series = PlateAlphabet.latinUppercase;
}
