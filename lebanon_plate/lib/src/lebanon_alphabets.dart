import 'package:core_plate/core_plate.dart';

import 'lebanon_letters.dart';

/// The alphabets a Lebanese plate slot is drawn over. There are two.
///
/// A Lebanese plate is the simplest grammar in this repo: one letter, then
/// digits. So there is [letters] for the first slot and [digits] for the rest,
/// and no third.
///
/// Both are Latin. Lebanon prints its serials in Latin figures and its letters
/// in Latin capitals — the only Arabic on the face is لبنان and the usage word,
/// and those are band text, not slots — so unlike its neighbours this package
/// ships no iranian-numeral twin.
abstract final class LebanonAlphabets {
  /// The ten Latin digits, behind every slot but the first.
  static const PlateAlphabet digits = PlateAlphabet(
    id: 'lb.digits',
    characters: <String>['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  /// The seventeen plate letters, including the two-glyph `MP`.
  ///
  /// [AlphabetInput.chosen], not [AlphabetInput.typed], and the reason is `MP`:
  /// a typed slot takes one character per keystroke, and `MP` is two. Making the
  /// whole alphabet chosen keeps one alphabet for one slot rather than splitting
  /// the letter cell into a typed set and a picked exception — and a picker is
  /// the better UI here anyway, since the letter is a closed list of seventeen
  /// whose meaning (a town, a class) a user is choosing rather than spelling.
  ///
  /// The character list is `LebanonLetter.characters`, so the alphabet and the
  /// enum cannot drift.
  static const PlateAlphabet letters = PlateAlphabet(
    id: 'lb.letters',
    characters: LebanonLetter.characters,
    input: AlphabetInput.chosen,
    isNumeric: false,
  );
}
