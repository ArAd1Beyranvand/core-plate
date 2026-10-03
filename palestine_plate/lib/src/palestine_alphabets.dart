import 'package:core_plate/core_plate.dart';
import 'package:plate_alphabet/plate_alphabet.dart';

/// Character sets for Palestinian plate slots. Each alphabet has a unique id
/// (required by `debugValidateSpec`) despite overlap, so the slot-to-set mapping
/// is explicit and visible. LTR throughout: serials are Latin, read left to right.
///
/// Digits come from [PlateAlphabetDigits.english] (shared across all packages).
abstract final class PSAlphabets {
  /// `0`–`9`: the serial, and both digits of a legacy or Gaza usage class.
  /// Use [PlateAlphabetDigits.english] instead of defining locally.
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  /// Legacy West Bank district codes: `1`, `3`–`9`. `0` and `2` are illegal
  /// and barred at alphabet level, not just by validator.
  static const PlateAlphabet districtDigits = PlateAlphabet(
    id: 'ps.districtDigits',
    characters: ['1', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  /// Thirteen issued governorate letters: `A B C D E F G H J K L M N`.
  /// `chosen` not `typed`: prevents keyboard offering illegal letters `I`, `O`,
  /// and reserved Gaza letters `P`–`T`. See [PSGovernorate] for the sequence.
  static const PlateAlphabet governorateLetters = PlateAlphabet(
    id: 'ps.governorateLetters',
    characters: [
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'J',
      'K',
      'L',
      'M',
      'N',
    ],
    input: AlphabetInput.chosen,
    isNumeric: false,
  );

  /// Gaza plate prefix: literal `3` only. `chosen` not `typed` for display-only
  /// behaviour. Inherited from pre-2012 PA scheme and deliberately retained.
  static const PlateAlphabet gazaPrefix = PlateAlphabet(
    id: 'ps.gazaPrefix',
    characters: ['3'],
    input: AlphabetInput.chosen,
    isNumeric: true,
  );
}
