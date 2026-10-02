import 'package:core_plate/core_plate.dart';
import 'package:plate_alphabet/plate_alphabet.dart';

/// The two alphabets of a 2013 plate: one series letter, then Latin digits.
abstract final class CubaAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  /// The series letter. I, O, Q, S, W and Z are not issued, to avoid confusing
  /// them with digits and with each other.
  static const PlateAlphabet letters = PlateAlphabet(
    id: 'cu.letters',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', //
      'L', 'M', 'N', 'P', 'R', 'T', 'U', 'V', 'X', 'Y',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// The letters that mean something. Every other letter is an unassigned
  /// series.
  static const Map<String, String> letterMeanings = <String, String>{
    'A': 'Official',
    'C': 'Diplomatic',
    'D': 'Diplomatic',
    'E': 'Diplomatic',
    'F': 'Armed forces (FAR)',
    'K': 'Foreigners',
    'M': 'Interior ministry (MININT)',
    'T': 'Rented to tourism',
  };
}
