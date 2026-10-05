import 'package:plate_core/plate_core.dart';

import '../plate_alphabet.dart';

/// The characters a Libyan plate is composed of: Western digits only. The
/// category letter (`ز`, `ن`, `ر`, `ج`, `م`) is fixed by the plate's class,
/// and `ليبيا` / `هيئة سياسية` are fixed words, so all three are labels on
/// the spec rather than slots.
abstract final class LibyaAlphabets {
  static const PlateAlphabet digits = PlateAlphabetDigits.english;
}
