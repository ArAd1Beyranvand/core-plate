import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The alphabets behind Lao slots.
///
/// [letters] is the 27 consonants of the modern Lao alphabet, in Lao
/// dictionary order. Every photographed register is two consonants and the
/// article's class-letter lists (ກ … ຮ) are all consonants; which consonant
/// may lead is a rule for `LaosPlateValidator`, which reports rather than
/// bars. Plates print Western digits.
abstract final class LaosAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  static const PlateAlphabet letters = PlateAlphabet(
    id: 'la.letters',
    characters: <String>[
      'ກ', 'ຂ', 'ຄ', 'ງ', 'ຈ', 'ສ', 'ຊ', 'ຍ', 'ດ', 'ຕ', 'ຖ', 'ທ', 'ນ', 'ບ', //
      'ປ', 'ຜ', 'ຝ', 'ພ', 'ຟ', 'ມ', 'ຢ', 'ຣ', 'ລ', 'ວ', 'ຫ', 'ອ', 'ຮ',
    ],
    input: AlphabetInput.chosen,
    isNumeric: false,
  );
}
