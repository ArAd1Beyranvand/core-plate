import 'package:core_plate/core_plate.dart';
import 'package:plate_alphabet/plate_alphabet.dart';

/// Algerian plates carry Western digits only — no letters, no Arabic-Indic
/// numerals, on every reference.
abstract final class AlgeriaAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;
}
