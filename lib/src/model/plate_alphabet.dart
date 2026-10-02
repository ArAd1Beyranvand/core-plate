import 'package:flutter/widgets.dart';

/// The set of characters a plate slot will accept, and how they are rendered.
///
/// A slot is not "a digit slot" or "a letter slot" — it is a slot over an
/// alphabet. Digits and letters differ only in [characters] and [input].
@immutable
class PlateAlphabet {
  const PlateAlphabet({
    required this.id,
    required this.characters,
    required this.input,
    required this.isNumeric,
    this.glyphs = const <String, String>{},
    this.direction = TextDirection.ltr,
    this.placeholder = '?',
  });

  /// Stable identifier. Two alphabets are equal iff their ids match, so ids
  /// must be unique across a spec — the same contract [PlateSpec.id] carries.
  final String id;

  /// Every legal character, in canonical (storage) form. Order is the order a
  /// picker presents them in.
  final List<String> characters;

  final AlphabetInput input;

  /// Storage form -> display form; empty means the two are the same. This is
  /// where national numerals live.
  final Map<String, String> glyphs;

  /// A property of the script, not something to infer from the characters.
  final TextDirection direction;

  /// Glyph shown in an empty chosen slot. A script with its own question mark
  /// declares it here.
  final String placeholder;

  /// Whether [value] is legal in either form — storage (`'5'`) or display
  /// glyph (`'۵'`). Someone typing on a national keyboard sends the glyph.
  bool accepts(String value) => characters.contains(canonical(value));

  /// [value] folded back to storage form (`'۵' -> '5'`); the inverse of [render]
  /// over [glyphs]. Anything that is not a glyph of this alphabet is returned
  /// unchanged, except that a lowercase letter whose uppercase form is legal
  /// folds to that uppercase form (`'a' -> 'A'`).
  String canonical(String value) {
    if (characters.contains(value)) return value;
    for (final entry in glyphs.entries) {
      // A glyph shared by two storage chars (e.g. Afghan `P`/`D` both printing
      // `ش`) folds to the one declared first, matching the order [characters]
      // lists them in.
      if (entry.value == value) return entry.key;
    }
    final upper = value.toUpperCase();
    if (upper != value && characters.contains(upper)) return upper;
    return value;
  }

  /// The display form of [value]; falls back to [value] itself.
  String render(String value) => glyphs[value] ?? value;

  /// True when every legal character is an ASCII digit; picks the numeric
  /// keyboard. Declared rather than derived from [characters] because a `const`
  /// constructor cannot compute it and this sits on the slot build path.
  final bool isNumeric;

  @override
  bool operator ==(Object other) => identical(this, other) || (other is PlateAlphabet && other.id == id);

  @override
  int get hashCode => id.hashCode;

  static const PlateAlphabet latinDigits = PlateAlphabet(
    id: 'latin.digits',
    characters: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
    input: AlphabetInput.typed,
    isNumeric: true,
  );

  static const PlateAlphabet latinUppercase = PlateAlphabet(
    id: 'latin.upper',
    characters: [
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
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );
}

/// How a character reaches a slot.
enum AlphabetInput {
  /// Typed straight into a TextField (digits, Latin letters).
  typed,

  /// Selected from a picker, or fed in by the host, because the character is
  /// not on a normal keyboard (e.g. plate letters from a national script).
  chosen,
}
