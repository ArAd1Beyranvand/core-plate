import 'package:flutter/widgets.dart';
import 'package:plate_core/core_plate.dart';

/// Ready-made digit alphabets shared across all licence plate packages.
///
/// Each stores ASCII `0-9` and differs only in how it renders — the pattern
/// the core package's national-numeral support is built on (a key shows and
/// reports its glyph, core folds it back to `'5'` on the way in). A country
/// package should reference one of these rather than restating the ten glyphs,
/// so digit fields render and behave consistently across the board.
abstract final class PlateAlphabetDigits {
  /// The English-numeral alphabet: ASCII `0-9`, rendered as itself.
  static const PlateAlphabet english = PlateAlphabet.latinDigits;

  /// The Iranian-numeral alphabet: ASCII `0-9` rendered `۰..۹`.
  /// Used by Iran and other Persian-script regions.
  static const PlateAlphabet iranian = PlateAlphabet(
    id: 'alphabet.fa.digits',
    characters: <String>['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
    glyphs: <String, String>{
      '0': '۰',
      '1': '۱',
      '2': '۲',
      '3': '۳',
      '4': '۴',
      '5': '۵',
      '6': '۶',
      '7': '۷',
      '8': '۸',
      '9': '۹',
    },
  );

  /// ASCII `0-9` rendered as Eastern Arabic numerals `٠..٩` — the figures
  /// Yemen and Afghanistan print, distinct from the Persian variants above
  /// (`٤` vs `۴`).
  static const PlateAlphabet iranshahr = PlateAlphabet(
    id: 'alphabet.ar.iranianDigits',
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
}

/// Ready-made letter alphabets shared across all licence plate packages.
///
/// Full character sets that country packages can subset to their needs.
abstract final class PlateAlphabetLetters {
  /// All Persian/Farsi and Arabic-script letters used across plates.
  /// Country packages subset this for their specific needs (e.g., Iran uses
  /// 13 of these for private vehicle series letters).
  static const PlateAlphabet persianAll = PlateAlphabet(
    id: 'alphabet.fa.all',
    characters: <String>[
      'ا',
      'ب',
      'پ',
      'ت',
      'ث',
      'ج',
      'چ',
      'ح',
      'خ',
      'د',
      'ذ',
      'ر',
      'ز',
      'ژ',
      'س',
      'ش',
      'ص',
      'ض',
      'ط',
      'ظ',
      'ع',
      'غ',
      'ف',
      'ق',
      'ک',
      'گ',
      'ل',
      'م',
      'ن',
      'و',
      'ه',
      'ة',
      'ی',
    ],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// All Latin uppercase letters used across plates, including extended
  /// characters (German umlauts Ä Ö Ü, and Lebanon's MP digraph).
  /// Country packages subset this for their specific needs.
  static const PlateAlphabet latinAll = PlateAlphabet(
    id: 'alphabet.latin.all',
    characters: <String>[
      'A',
      'B',
      'C',
      'D',
      'E',
      'F',
      'G',
      'H',
      'I',
      'J',
      'K',
      'L',
      'M',
      'N',
      'O',
      'P',
      'Q',
      'R',
      'S',
      'T',
      'U',
      'V',
      'W',
      'X',
      'Y',
      'Z',
      'Ä',
      'Ö',
      'Ü',
      'MP',
    ],
    input: AlphabetInput.chosen,
    isNumeric: false,
    placeholder: '?',
  );
}
