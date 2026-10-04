import 'package:plate_core/plate_core.dart';

/// The alphabets a Tajik plate slot is drawn over.
///
/// **A Tajik plate is printed in Latin letters, but the register is a Cyrillic
/// one wearing Latin shapes.** The country writes Tajik in Cyrillic, and the
/// letters chosen for plates are the fifteen whose Cyrillic and Latin forms
/// coincide — `А В Е К М Н О Р С Т Х`, which a Tajik reads as Cyrillic and a
/// foreigner reads as `A B E K M H O P C T X`, plus `D J Z Y`, added with the
/// 2014 redesign, which have no such double life and are plain Latin. That is
/// why [letters] is stored and rendered in Latin and carries no
/// [PlateAlphabet.glyphs]: at plate scale there is nothing to transliterate.
abstract final class TajikistanAlphabets {
  /// The letters a civilian number may carry: the eleven shape-sharing ones and
  /// the four Latin additions of 2014.
  ///
  /// `H` is here as the Latin partner of Cyrillic `Н`, and `P` as the partner of
  /// `Р` — a resemblance in shape, not in sound. The set is closed: a letter
  /// outside it is not a Tajik plate letter, which is what
  /// `TajikistanPlateValidator` enforces.
  static const PlateAlphabet letters = PlateAlphabet(
    id: 'tj.letters',
    characters: <String>[
      'A',
      'B',
      'C',
      'D',
      'E',
      'H',
      'J',
      'K',
      'M',
      'O',
      'P',
      'T',
      'X',
      'Y',
      'Z',
    ],
    input: AlphabetInput.typed,
    isNumeric: false,
  );

  /// The class code on a diplomatic plate: `CD` for the corps, `CMD` for a head
  /// of mission, and the single letters `D`, `T` and `S` for the graded ranks
  /// below.
  ///
  /// Its own alphabet, and the one place in this package a "letter" is more than
  /// one glyph: `CMD` is a single choice a slot renders as three characters, not
  /// three letters typed in a row, which is why the input is
  /// [AlphabetInput.chosen] and the slot that carries it is set wide.
  static const PlateAlphabet diplomaticClass = PlateAlphabet(
    id: 'tj.diplomaticClass',
    characters: <String>['CD', 'CMD', 'D', 'T', 'S'],
    input: AlphabetInput.chosen,
    isNumeric: false,
  );
}
