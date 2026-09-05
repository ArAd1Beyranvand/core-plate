import 'package:core_plate/core_plate.dart';

/// The alphabets a Yemeni plate slot is drawn over.
///
/// Every slot on both systems is a Latin digit, so [PlateAlphabet.latinDigits]
/// would cover most of them. They are restated here under `ye.` ids for the
/// reason `debugValidateSpec` cares about: [governorateTens] is a *restricted*
/// digit set — the tens place of a code that never exceeds 22 — and core
/// asserts that within one spec no id ever stands for two character/glyph sets
/// and no two ids ever share one. Declaring both here keeps that relationship
/// visible in one file instead of half-inherited from core.
///
/// The northern plate prints its number twice, so each of those two also has an
/// eastern-numeral twin: [easternDigits] and [easternGovernorateTens], which
/// accept the same ASCII characters and differ only in how they render.
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
  /// The restriction exists so a host driving an on-screen pad greys out the
  /// seven keys that can never be right here.
  static const PlateAlphabet governorateTens = PlateAlphabet(
    id: 'ye.govTens',
    characters: <String>['0', '1', '2'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  /// The same ten digits, printed as eastern Arabic numerals.
  ///
  /// **Storage stays ASCII.** [PlateAlphabet.characters] is the accepted set,
  /// so this alphabet accepts `'7'` and prints `'٧'`; every value in a bloc,
  /// a validator or a `toString` is still a Latin digit, and nothing downstream
  /// has to know a plate renders in another numeral system. The transform lives
  /// entirely in [PlateAlphabet.glyphs], which is what that field is for.
  ///
  /// This shares its character list with [digits] and differs only in glyphs.
  /// That is legal: `debugValidateSpec` keys its consistency check on
  /// characters *and* glyphs, precisely so an alphabet that accepts the same
  /// input but renders it differently can exist alongside its Latin twin.
  static const PlateAlphabet easternDigits = PlateAlphabet(
    id: 'ye.easternDigits',
    characters: <String>['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
    glyphs: <String, String>{
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    },
  );

  /// [governorateTens] in eastern numerals — the tens place of a northern
  /// governorate code, on a plate whose big row is printed in Arabic figures.
  ///
  /// A separate id from [easternDigits] for the same reason [governorateTens]
  /// is separate from [digits]: the restricted character list is what tells a
  /// host's pad which keys can never be right here.
  static const PlateAlphabet easternGovernorateTens = PlateAlphabet(
    id: 'ye.easternGovTens',
    characters: <String>['0', '1', '2'],
    input: AlphabetInput.typed,
    isNumeric: true,
    glyphs: <String, String>{'0': '٠', '1': '١', '2': '٢'},
  );
}
