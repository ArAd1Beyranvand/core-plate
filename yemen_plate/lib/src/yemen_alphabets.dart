import 'package:core_plate/core_plate.dart';

/// The alphabets a Yemeni plate slot is drawn over. All restate core's sets
/// under `ye.` ids so no id stands for two character/glyph pairs and no two ids
/// share one set (required by debugValidateSpec). [governorateTens] is restricted
/// (codes 1..22); northern plates print numbers twice (big + small mirror mirrors),
/// each with a Latin and an Iranian variant. Side code reuses [digits] (meaning from text group).
abstract final class YemenAlphabets {
  /// Ten Latin digits; nearly every slot on both systems.
  static const PlateAlphabet digits = PlateAlphabet(
    id: 'ye.digits',
    characters: <String>['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  /// Tens place of a northern governorate code (1..22, so 0/1/2 only).
  /// Restricts input (not validation); lets a host's pad grey out impossible keys.
  static const PlateAlphabet governorateTens = PlateAlphabet(
    id: 'ye.govTens',
    characters: <String>['0', '1', '2'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  /// Same ten digits, printed as Iranian Arabic numerals. Storage stays ASCII;
  /// the transform lives in [PlateAlphabet.glyphs]. Shares characters with [digits],
  /// differs only in glyphs (legal per debugValidateSpec).
  static const PlateAlphabet iranianDigits = PlateAlphabet(
    id: 'ye.iranianDigits',
    characters: <String>['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
    glyphs: <String, String>{
      '0': '٠', '1': '١', '2': '٢', '3': '٣', '4': '٤',
      '5': '٥', '6': '٦', '7': '٧', '8': '٨', '9': '٩',
    },
  );

  /// [governorateTens] in Iranian numerals (tens place on big row of northern plate).
  /// Separate id from [iranianDigits] because restricted character set tells the pad
  /// which keys can never be right here.
  static const PlateAlphabet iranianGovernorateTens = PlateAlphabet(
    id: 'ye.iranianGovTens',
    characters: <String>['0', '1', '2'],
    input: AlphabetInput.typed,
    isNumeric: true,
    glyphs: <String, String>{'0': '٠', '1': '١', '2': '٢'},
  );
}
