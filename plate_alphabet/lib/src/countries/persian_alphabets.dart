import 'package:flutter/widgets.dart';
import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The Persian alphabets a plate slot can be drawn over.
///
/// Digits come from [PlateAlphabetDigits.iranian] (shared across all packages);
/// letters live here because they are constrained by plate validation rules.
///
/// The difference in the letter series matches the whole *Letter series* table
/// on the Wikipedia article:
/// - [privateLetters] — the thirteen-letter county series a **private** plate
///   picks from. Genuine choices, so `AlphabetInput.chosen` opens a picker.
/// - one single-character alphabet per non-private class ([taxiLetter],
///   [policeLetter], …). Their letter is fixed for the class, so there is
///   nothing to pick; they are still `AlphabetInput.chosen` so that the slot
///   cannot be typed into and emptied.
abstract final class PersianAlphabets {
  /// Digits: shared via [PlateAlphabetDigits.iranian] in plate_alphabet.
  /// Use that instead of defining locally.
  static const PlateAlphabet digits = PlateAlphabetDigits.iranian;

  /// The thirteen letters a **private** plate's series letter can be, in the
  /// order the article's table lists them.
  ///
  /// Only these thirteen. `ت`, `ع`, `ک`, `پ`, `ث`, `ز`, `ژ`, `ش`, `ف`, `گ` and
  /// `الف` all appear on Iranian plates, but each is reserved to one non-private
  /// class and is fixed for every plate in it — offering them in this picker
  /// would let a user build a private plate that cannot legally exist.
  static const PlateAlphabet privateLetters = PlateAlphabet(
    id: 'fa.privateLetters',
    characters: [
      'ب',
      'ج',
      'د',
      'س',
      'ص',
      'ط',
      'ق',
      'ل',
      'م',
      'ن',
      'و',
      'ه',
      'ی',
    ],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// The wheelchair symbol ♿︎ a disabled driver's plate carries where a private
  /// plate carries its county letter.
  ///
  /// Stored as `ژ` and rendered as `♿︎`, because that is what the article's
  /// footnote says the two are: "while the actual wheelchair symbol ♿︎ is shown
  /// on license plates of private vehicles of people with disability, on the
  /// police digital database, the letter `ژ` is used as a placeholder". The
  /// database form is the storage form and the symbol is the display form —
  /// precisely the split [PlateAlphabet.glyphs] exists for, so a plate read back
  /// out of this package reads `ژ` and matches the registry.
  static const PlateAlphabet disabledSymbol = PlateAlphabet(
    id: 'fa.disabledSymbol',
    characters: ['ژ'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '♿︎',
    glyphs: {'ژ': '♿︎'},
  );

  // Below: one alphabet per class whose series letter is fixed. They are
  // written out rather than produced by a helper because a `const` value cannot
  // come from a function call — and they must be `const` so the specs that use
  // them stay const-constructible.
  //
  // Every one is `chosen`, not `typed`, even though there is nothing to choose:
  // a typed slot is a slot the user can clear, and the letter on a taxi plate is
  // not theirs to clear. A picker over a one-character alphabet has exactly one
  // answer, so opening it is a no-op rather than a decision.

  /// `ت`, for تاکسی. Printed under the Latin word TAXI, which the taxi spec
  /// carries as a [PlateLabel] — the wording is chrome, not a value.
  static const PlateAlphabet taxiLetter = PlateAlphabet(
    id: 'fa.taxiLetter',
    characters: ['ت'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// `ع`, for عمومی — public transport.
  static const PlateAlphabet publicLetter = PlateAlphabet(
    id: 'fa.publicLetter',
    characters: ['ع'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// `ک`, for کشاورزی — agricultural vehicles.
  static const PlateAlphabet agriculturalLetter = PlateAlphabet(
    id: 'fa.agriculturalLetter',
    characters: ['ک'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// `الف` — the name of the first letter of the alphabet, spelled out, which
  /// is how a government plate prints it. One character to this package even
  /// though it is three code points: it is one position on the plate.
  static const PlateAlphabet governmentLetter = PlateAlphabet(
    id: 'fa.governmentLetter',
    characters: ['الف'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// `پ`, for پلیس — FARAJA police.
  static const PlateAlphabet policeLetter = PlateAlphabet(
    id: 'fa.policeLetter',
    characters: ['پ'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// `ث` — IRGC (Army Police).
  static const PlateAlphabet irgcLetter = PlateAlphabet(
    id: 'fa.irgcLetter',
    characters: ['ث'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// `ش` — Islamic Republic of Iran Army.
  static const PlateAlphabet armyLetter = PlateAlphabet(
    id: 'fa.armyLetter',
    characters: ['ش'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// `ز` — Ministry of Defence and Armed Forces Logistics.
  static const PlateAlphabet defenceLetter = PlateAlphabet(
    id: 'fa.defenceLetter',
    characters: ['ز'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// `ف` — General Staff of the Armed Forces.
  static const PlateAlphabet generalStaffLetter = PlateAlphabet(
    id: 'fa.generalStaffLetter',
    characters: ['ف'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// `گ` — temporary passage, the plate a newly built car wears.
  static const PlateAlphabet temporaryLetter = PlateAlphabet(
    id: 'fa.temporaryLetter',
    characters: ['گ'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
  );

  /// Latin `D` — diplomatic and consular corps. The one class whose series
  /// letter is genuinely Latin rather than a transliteration, so it reads LTR.
  static const PlateAlphabet politicalLetter = PlateAlphabet(
    id: 'fa.politicalLetter',
    characters: ['D'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    placeholder: '?',
  );

  /// Latin `S` — international-organisation service plates. See
  /// [politicalLetter].
  static const PlateAlphabet serviceLetter = PlateAlphabet(
    id: 'fa.serviceLetter',
    characters: ['S'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    placeholder: '?',
  );
}
