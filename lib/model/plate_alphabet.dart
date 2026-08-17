import 'package:flutter/foundation.dart';

/// The set of characters a plate slot will accept, and how they are rendered.
///
/// A slot is not "a digit slot" or "a letter slot" — it is a slot over an
/// alphabet. Digits and letters differ only in [characters] and [input].
@immutable
class PlateAlphabet {
  const PlateAlphabet({
    required this.characters,
    required this.input,
    this.glyphs = const <String, String>{},
  });

  /// Every legal character, in canonical (storage) form. Order is the order a
  /// picker presents them in.
  final List<String> characters;

  /// How the user supplies a character from this alphabet.
  final AlphabetInput input;

  /// Storage form -> display form. Empty means display == storage.
  /// This is where national numerals live.
  final Map<String, String> glyphs;

  bool accepts(String value) => characters.contains(value);

  /// The display form of [value]; falls back to [value] itself.
  String render(String value) => glyphs[value] ?? value;

  static const PlateAlphabet latinDigits = PlateAlphabet(
    characters: ['0','1','2','3','4','5','6','7','8','9'],
    input: AlphabetInput.typed,
  );

  static const PlateAlphabet persianDigits = PlateAlphabet(
    characters: ['0','1','2','3','4','5','6','7','8','9'],
    input: AlphabetInput.typed,
    glyphs: {
      '0':'۰','1':'۱','2':'۲','3':'۳','4':'۴',
      '5':'۵','6':'۶','7':'۷','8':'۸','9':'۹',
    },
  );

  static const PlateAlphabet persianPlateLetters = PlateAlphabet(
    characters: ['ب','ح','د','س','ص','ط','ق','ل','م','ن','و','ه','ی','ت','ژ','گ'],
    input: AlphabetInput.chosen,
  );

  static const PlateAlphabet latinUppercase = PlateAlphabet(
    characters: ['A','B','C','D','E','F','G','H','I','J','K','L','M',
                 'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
    input: AlphabetInput.typed,
  );
}

/// How a character reaches a slot.
enum AlphabetInput {
  /// Typed straight into a TextField (digits, Latin letters).
  typed,

  /// Selected from a picker, or fed in by the host, because the character is
  /// not on a normal keyboard (Persian plate letters).
  chosen,
}
