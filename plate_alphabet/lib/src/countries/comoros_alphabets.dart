import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The characters a Comorian plate is composed of: Latin capitals and Western
/// digits (`1284 A 73`). The `COMORES` caption on the square plate is a label
/// on the spec, not a slot.
abstract final class ComorosAlphabets {
  static const PlateAlphabet letters = PlateAlphabet.latinUppercase;
  static const PlateAlphabet digits = PlateAlphabetDigits.english;
}
