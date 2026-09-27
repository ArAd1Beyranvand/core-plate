import 'package:core_plate/core_plate.dart';

import 'lebanon_letters.dart';

/// Two alphabets: [letters] (first slot) and [digits] (remaining slots).
/// Both Latin; band text (لبنان, usage word) is not in slots.
abstract final class LebanonAlphabets {
  /// The ten Latin digits, behind every slot but the first.
  static const PlateAlphabet digits = PlateAlphabet(
    id: 'lb.digits',
    characters: <String>['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  /// Seventeen letters, including `MP` (two glyphs). Chosen input because `MP`
  /// is two chars; picker is better UI for a closed, meaningful list anyway.
  static const PlateAlphabet letters = PlateAlphabet(
    id: 'lb.letters',
    characters: LebanonLetter.characters,
    input: AlphabetInput.chosen,
    isNumeric: false,
  );
}
