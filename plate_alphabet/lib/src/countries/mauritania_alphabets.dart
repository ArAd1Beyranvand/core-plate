import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The characters a Mauritanian plate is composed of: Western digits and
/// Latin capitals. Since 2017 the letter pair may be Arabic instead, from an
/// official list of 17 pairs; that flipped Arabic form is not implemented.
abstract final class MauritaniaAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;
  static const PlateAlphabet letters = PlateAlphabet.latinUppercase;
}
