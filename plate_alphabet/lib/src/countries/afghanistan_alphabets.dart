import 'package:flutter/widgets.dart';
import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The alphabets an Afghan plate slot is drawn over.
///
/// Two pairs, and each pair is one value printed twice. **An Afghan plate says
/// everything twice** — the serial in Eastern Arabic numerals above and in
/// Latin figures below, the class as a Persian letter above and a Latin code
/// below — and neither pair is two values that happen to agree. It is one
/// value with two presentations, which is what [PlateMirror] is for and why
/// every `…Latin` / `iranshahr…` twin below accepts exactly the same characters
/// as the alphabet it twins and differs only in [PlateAlphabet.glyphs].
///
/// **Storage stays ASCII throughout.** A serial digit is stored `'7'` whatever
/// numeral it prints as, and a class is stored `'P'` whether it prints `ش` or
/// `PRV`. Nothing downstream — a bloc, a validator, a `toString` — has to know
/// the plate renders in two scripts.
///
/// `debugValidateSpec` keys its consistency check on characters *and* glyphs
/// precisely so these twins can sit in one spec: same list, different rendering,
/// different id.
abstract final class AfghanistanAlphabets {
  /// The ten digits of the serial, as they are stored and as the lower register
  /// prints them. Use [PlateAlphabetDigits.english] instead of defining locally.
  static const PlateAlphabet digits = PlateAlphabetDigits.english;

  /// The same ten digits, printed as Eastern Arabic numerals — the upper
  /// register of every Afghan plate.
  ///
  /// Eastern Arabic (`٤`, `٥`, `٦`) and not the Persian variants (`۴`, `۵`,
  /// `۶`): the plates photographed for the Wikipedia article print the Arabic
  /// forms, and Dari uses them.
  /// Use [PlateAlphabetDigits.iranshahr] instead of defining locally.
  static const PlateAlphabet iranianDigits = PlateAlphabetDigits.iranshahr;

  /// The vehicle class, as the upper register prints it: one Persian letter.
  ///
  /// The characters are ASCII mnemonics and never appear on a plate. They are
  /// the storage form of a value with two presentations — `'P'` prints `ش`
  /// here and `PRV` through [classLatin] — and picking Latin keys keeps a
  /// stored plate readable in a log and sortable in a database.
  ///
  /// Seven, not the eleven classes the article tabulates. Diplomatic,
  /// governmental and United Nations plates carry no class register at all:
  /// the diplomatic plate prints `CD` as fixed wording with no Persian
  /// counterpart, the governmental one prints a dash in both registers, and
  /// the UN one prints nothing. A spec without the register is the honest way
  /// to say that; a character that renders to the empty string is not.
  ///
  /// [AlphabetInput.chosen], not typed: `ش` is not on a keyboard and a class is
  /// picked from a list of seven, not spelled.
  static const PlateAlphabet vehicleClass = PlateAlphabet(
    id: 'af.class',
    characters: <String>['P', 'D', 'T', 'B', 'L', 'M', 'R'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    direction: TextDirection.rtl,
    glyphs: <String, String>{
      'P': 'ش', // private
      'D': 'ش', // private duplicate — see classLatin
      'T': 'ت', // taxi
      'B': 'ب', // bus
      'L': 'ل', // lorry
      'M': 'م', // motorcycle
      'R': 'ر', // rickshaw
    },
  );

  /// The same class, as the lower register prints it: the Latin code.
  ///
  /// This is where `P` and `D` come apart. Both print `ش` above — the duplicate
  /// plate adds a stacked `م/ث` beside it that is too small to set as a glyph
  /// at plate scale and is not reproduced — so the Persian register cannot tell
  /// a duplicate from a private plate and the Latin one can: `PRV` against
  /// `DUPL`. That is a fact about the plate, not a shortcut here.
  ///
  /// Four of the seven render to themselves and so carry no [PlateAlphabet.glyphs]
  /// entry at all; [PlateAlphabet.render] falls through to the stored character.
  static const PlateAlphabet classLatin = PlateAlphabet(
    id: 'af.classLatin',
    characters: <String>['P', 'D', 'T', 'B', 'L', 'M', 'R'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    glyphs: <String, String>{'P': 'PRV', 'D': 'DUPL', 'R': 'TRC'},
  );

  /// The category on a cross-border international plate: `BUS`, `TAXI` or
  /// `CARGO`, spelled out in full and in Latin only.
  ///
  /// Its own alphabet and not a restriction of [classLatin], because it is a
  /// different vocabulary rather than a subset of one: the international plate
  /// names the service the vehicle runs (`CARGO`), where a domestic plate names
  /// the class the vehicle is registered as (`L` for a lorry).
  static const PlateAlphabet internationalCategory = PlateAlphabet(
    id: 'af.intlCategory',
    characters: <String>['B', 'T', 'C'],
    input: AlphabetInput.chosen,
    isNumeric: false,
    glyphs: <String, String>{'B': 'BUS', 'T': 'TAXI', 'C': 'CARGO'},
  );
}
