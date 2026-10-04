import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The characters a Somali plate is composed of: Latin capitals and Western
/// digits (`AD 4657`). The `SOM` and `الصومال` captions are labels on the
/// spec, not slots.
abstract final class SomaliaAlphabets {
  static const PlateAlphabet letters = PlateAlphabet.latinUppercase;
  static const PlateAlphabet digits = PlateAlphabetDigits.english;
}
