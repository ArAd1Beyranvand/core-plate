import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The characters a Brazilian Mercosul plate is composed of: Western digits
/// and all 26 Latin capitals. The article's series table runs every letter
/// (`QAA`, `KAV`, `WYZ` alike), and the converted fifth position is a letter
/// too, so there is no subset to restrict to.
abstract final class BrazilAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;
  static const PlateAlphabet letters = PlateAlphabet.latinUppercase;
}
