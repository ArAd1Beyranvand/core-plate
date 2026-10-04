import 'package:plate_core/core_plate.dart';

import 'cuba_alphabets.dart';

/// Judges a 2013 Cuban plate value. Reports, never throws, never bars a
/// keystroke.
///
/// Quiet until the first serial group has a digit. Checks the letter is an
/// issued series and the serial is the full digit count of the spec — six on
/// a car (`serial` + `serial2`), five on a motorcycle (`serial`).
class CubaValidator extends GatedPlateValidator {
  const CubaValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonLetterMissing = 'A plate starts with a letter.';
  static const String reasonLetterUnissued =
      'I, O, Q, S, W and Z are not issued.';
  static const String reasonSerialNotNumeric = 'The number is digits only.';
  static const String reasonSerialLength = 'The number fills every cell.';

  @override
  PlateValidation judge(PlateEntry entry) {
    final String letter = entry.group('letter');
    if (letter.isEmpty)
      return const PlateValidation.invalid(reasonLetterMissing);
    if (!CubaAlphabets.letters.accepts(letter)) {
      return const PlateValidation.invalid(reasonLetterUnissued);
    }
    final String serial = entry.group('serial') + entry.group('serial2');
    if (serial.length != entry.spec.slotCount - 1) {
      return const PlateValidation.invalid(reasonSerialLength);
    }
    if (!isDigits(serial))
      return const PlateValidation.invalid(reasonSerialNotNumeric);
    return const PlateValidation.valid();
  }
}
