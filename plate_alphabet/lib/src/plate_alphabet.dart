import 'package:flutter/widgets.dart';
import 'package:plate_core/plate_core.dart';

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

/// A–Z typed straight from the keyboard, for plates whose letter slots take
/// any Latin letter. [PlateAlphabetLetters.latinAll] is the picker variant.
abstract final class PlateAlphabetLatin {
  static const PlateAlphabet typed = PlateAlphabet(
    id: 'alphabet.latin.typed',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}

/// Belarus: the Latin letters that share a shape with a Cyrillic one, so a
/// plate reads the same in either script, and the fixed-letter slots.
abstract final class PlateAlphabetBelarus {
  static const PlateAlphabet letters = PlateAlphabet(
    id: 'by.letters',
    characters: <String>[
      'A',
      'B',
      'E',
      'I',
      'K',
      'M',
      'H',
      'O',
      'P',
      'C',
      'T',
      'X',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// The region digit after the dash: 1–7 for the regions and Minsk city,
  /// 8 for the 2020s overflow series, 0 for the Ministry of Defence.
  static const PlateAlphabet region = PlateAlphabet(
    id: 'by.region',
    characters: <String>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  /// The leading `E` of an electric vehicle's number.
  static const PlateAlphabet electric = PlateAlphabet(
    id: 'by.electric',
    characters: <String>['E'],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// First letter of a diplomatic plate: always `C`.
  static const PlateAlphabet diplomaticFirst = PlateAlphabet(
    id: 'by.diplomatic.first',
    characters: <String>['C'],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// Second letter: `D` for diplomatic corps, `C` for consular.
  static const PlateAlphabet diplomaticSecond = PlateAlphabet(
    id: 'by.diplomatic.second',
    characters: <String>['C', 'D'],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}

/// North Korea: the two-syllable Hangul region abbreviation, one value per
/// slot. The thirteen controlled regions listed on Wikipedia, then the seven
/// South Korean provinces the state still issues codes for. 링김 appears on a
/// 1990s government plate on the reference sheet but in no list, so it is kept
/// as an observed historical code.
abstract final class PlateAlphabetKorea {
  static const PlateAlphabet northRegions = PlateAlphabet(
    id: 'kp.region',
    characters: <String>[
      '평양', '라선', '평남', '평북', '자강', '황남', '황북', //
      '강원', '함남', '함북', '량강', '남포', '개성',
      '충남', '충북', '경기', '경남', '경북', '전남', '전북',
      '링김',
    ],
    input: AlphabetInput.chosen,
    isNumeric: false,
  );
}

/// Namibia: the letters the town codes use, and the personalised plates'
/// letters-and-digits set.
abstract final class PlateAlphabetNamibia {
  /// Every letter appearing in a town code on the article's list (`W`, `WB`,
  /// `KM`, `SH`, …). Advisory: the code itself is checked by the validator.
  static const PlateAlphabet region = PlateAlphabet(
    id: 'na.region',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'G', 'H', 'J', 'K', 'L', //
      'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V', 'W',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// A personalised plate's characters: up to seven letters or digits.
  static const PlateAlphabet personalised = PlateAlphabet(
    id: 'na.personalised',
    characters: <String>[
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', //
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}
