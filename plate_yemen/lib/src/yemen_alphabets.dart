import 'package:core_plate/core_plate.dart';

/// The alphabets a Yemeni plate slot is drawn over.
///
/// Every slot on both systems is a Latin digit, so [PlateAlphabet.latinDigits]
/// would cover most of them. They are restated here under `ye.` ids for the
/// reason `debugValidateSpec` cares about: [governorateTens] is a *restricted*
/// digit set — the tens place of a code that never exceeds 22 — and core
/// asserts that within one spec no id ever stands for two character lists and
/// no two ids ever share one list. Declaring both here keeps that relationship
/// visible in one file instead of half-inherited from core.
///
/// Note what is deliberately **not** here. There is no `sideCodeDigits`: the
/// System A side code accepts all ten digits, exactly as [digits] does, and
/// minting a second id for the same list is the specific thing
/// `debugValidateSpec` fails a spec for. The side code reuses [digits], and its
/// meaning comes from its text group, not from its alphabet.
abstract final class YemenAlphabets {
  /// The ten Latin digits, and the alphabet behind nearly every slot on both
  /// systems.
  static const PlateAlphabet digits = PlateAlphabet(
    id: 'ye.digits',
    characters: <String>['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  /// The tens place of a northern governorate code.
  ///
  /// Codes run 1..22, so the leading digit of a two-cell register can only be
  /// `0`, `1` or `2`. Restricting the alphabet is not validation — a slot's
  /// alphabet says what may be *entered*, and core silently drops a character
  /// the alphabet does not accept rather than reporting it — so `23` is still
  /// reachable and still invalid, and `YemenNorthernValidator` is what says so.
  /// The restriction exists so a `plate_keypad` host greys out the seven keys
  /// that can never be right here.
  static const PlateAlphabet governorateTens = PlateAlphabet(
    id: 'ye.govTens',
    characters: <String>['0', '1', '2'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );
}
