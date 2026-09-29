import 'package:core_plate/core_plate.dart';
import 'package:plate_alphabet/plate_alphabet.dart';

import 'lebanon_letters.dart';

/// Two alphabets: [letters] (first slot) and [digits] (remaining slots).
/// Both Latin; band text (لبنان, usage word) is not in slots.
///
/// Digits come from [PlateAlphabetDigits.english] (shared across all packages).
abstract final class LebanonAlphabets {
  /// The ten Latin digits, behind every slot but the first.
  /// Use [PlateAlphabetDigits.english] instead of defining locally.
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  /// Seventeen letters, including `MP` (two glyphs). Chosen input because `MP`
  /// is two chars; picker is better UI for a closed, meaningful list anyway.
  static const PlateAlphabet letters = PlateAlphabet(
    id: 'lb.letters',
    characters: LebanonLetter.characters,
    input: AlphabetInput.chosen,
    isNumeric: false,
  );
}
