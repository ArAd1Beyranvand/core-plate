import 'package:flutter/widgets.dart';
import 'package:plate_core/plate_core.dart';

/// Oman's plate letter, printed twice: Latin below, Arabic above. Every value
/// is stored once, in Latin; [arabic] is the same characters through the glyph
/// map, so typing in either row writes the other.
///
/// Digits are Western on the current series.
abstract final class PlateAlphabetOman {
  /// The letters seen on 2001-series plates: `A` (article photograph), `B`/`M`
  /// (private artwork), `K` (taxi artwork).
  // TODO(oman-letters): the rest of the issued letters; none are sourced.
  static const List<String> _letters = <String>['A', 'B', 'K', 'M'];

  static const PlateAlphabet letters = PlateAlphabet(
    id: 'om.letter.latin',
    characters: _letters,
    input: AlphabetInput.chosen,
    isNumeric: false,
  );

  /// [letters] as the upper row prints it.
  static const PlateAlphabet arabic = PlateAlphabet(
    id: 'om.letter.arabic',
    characters: _letters,
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    placeholder: '؟',
    glyphs: <String, String>{'A': 'ا', 'B': 'ب', 'K': 'ك', 'M': 'م'},
  );
}
