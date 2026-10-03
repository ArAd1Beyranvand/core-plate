import 'package:core_plate/core_plate.dart';
import 'package:plate_alphabet/plate_alphabet.dart';

/// Tunisian plates carry Western digits only. Their Arabic and Latin words —
/// تونس, the diplomatic codes, the temporary suffixes — are fixed by the
/// plate type, so they are labels on the spec, not slots.
abstract final class TunisiaAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;
}
