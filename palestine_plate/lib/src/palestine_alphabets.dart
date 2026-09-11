import 'package:core_plate/core_plate.dart';

/// The character sets a Palestinian plate slot can be drawn over.
///
/// Palestinian plates are printed in Latin digits and Latin capitals, so
/// [PlateAlphabet.latinDigits] would do for the numeric slots. Every alphabet
/// is re-declared here anyway, under `ps.` ids, and the reason is
/// `debugValidateSpec`: within one spec no id may stand for two different
/// character lists, **and no two distinct ids may share one list**. These
/// alphabets are related by containment — [districtDigits] is a subset of
/// [digits], [gazaPrefix] is a subset of both — so which slot gets which set is
/// load-bearing, and keeping them in one file makes that visible instead of
/// half-inherited from core.
///
/// The second half of that assertion is why there is no `usageDigits` here. A
/// usage slot accepts exactly `0`–`9`, which is [digits]' list; minting a
/// second id for the same characters would trip `debugValidateSpec` on every
/// spec that used both. When two slots take the same characters they take the
/// same alphabet, and the difference between them lives in the spec's
/// [PlateTextGroup] keys, where a validator can read it.
///
/// Every alphabet here is LTR — [PlateAlphabet.direction] stays at its default.
/// A Palestinian plate's serial is Latin, and reads left to right, on both
/// sides of the Green Line.
abstract final class PSAlphabets {
  /// `0`–`9`: the serial, and both digits of a legacy or Gaza usage class.
  static const PlateAlphabet digits = PlateAlphabet(
    id: 'ps.digits',
    characters: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  /// The legacy West Bank district codes: `1`, `3`–`9`.
  ///
  /// `0` and `2` are missing because they are not legal district codes, and an
  /// alphabet is the set of characters a slot *accepts* — so they are barred at
  /// the alphabet, not by the validator. (The validator rejects them too, for
  /// a value that arrived from somewhere other than a slot.)
  static const PlateAlphabet districtDigits = PlateAlphabet(
    id: 'ps.districtDigits',
    characters: ['1', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  /// The thirteen issued governorate letters, in allocation order: `A B C D E
  /// F G H J K L M N`.
  ///
  /// **`chosen`, not `typed`, and that is the point.** A typed slot puts a
  /// keyboard in front of the user, and a keyboard offers `I` and `O` — which
  /// are never issued — alongside `P`–`T`, which were allocated to Gaza and
  /// never issued either. A chosen slot opens a picker over exactly this list,
  /// so whatever picker the host supplies shows thirteen letters and the
  /// illegal ones are not on screen to be pressed. The validator still names
  /// them, for a value that did not come from the picker.
  ///
  /// See [PSGovernorate] for what each letter means and why the sequence jumps
  /// from `H` to `J`.
  static const PlateAlphabet governorateLetters = PlateAlphabet(
    id: 'ps.governorateLetters',
    characters: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N'],
    input: AlphabetInput.chosen,
    isNumeric: false,
  );

  /// The one character a Gaza plate can begin with: `3`.
  ///
  /// A one-character alphabet, so the literal is enforced by the alphabet
  /// rather than by the validator — there is no keystroke that puts anything
  /// else in that slot. The digit is inherited from the pre-2012 Palestinian
  /// Authority scheme, where `3` meant "Gaza Strip, registered after 1995", and
  /// was deliberately retained when Gaza took its numbering independent in
  /// 2012.
  ///
  /// `PSGazaValidator` checks it anyway, and that is not redundant: a value can
  /// reach a validator from a database row or a scan result, and never touch a
  /// slot.
  static const PlateAlphabet gazaPrefix = PlateAlphabet(
    id: 'ps.gazaPrefix',
    characters: ['3'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );
}
