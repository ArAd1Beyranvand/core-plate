import 'package:plate_core/core_plate.dart';

import 'lebanon_letters.dart';

/// Judges a Lebanese plate value. Reports, never throws, never bars a keystroke.
///
/// Waits until serial is non-empty to validate (letter is slot 0). Checks:
/// letter is valid (closed set), serial is 1–6 digits, MP serial is 1–128.
/// Does not check: number value/allocation, leading zeros, obsolete letters
/// (K). All intentional: there is no published block allocation or per-town
/// range; K plates are on the road.
class LebanonValidator extends GatedPlateValidator {
  /// A stateless rule; hold one as a `const`.
  const LebanonValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonLetterMissing = 'A plate starts with a letter.';
  static const String reasonLetterUnknown =
      'That is not a Lebanese plate letter.';
  static const String reasonSerialNotNumeric = 'The number is digits only.';
  static const String reasonSerialLength = 'The number is one to six digits.';
  static const String reasonParliamentRange =
      'A parliament plate is numbered 1 to 128.';

  static const int minSerialLength = 1;
  static const int maxSerialLength = 6;
  static const int maxParliamentNumber = 128;

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    letter: entry.group('letter'),
    serial: entry.group('serial'),
  );

  static PlateValidation validateFields({
    required String letter,
    required String serial,
  }) {
    if (letter.isEmpty) {
      return const PlateValidation.invalid(reasonLetterMissing);
    }
    final LebanonLetter? code = LebanonLetter.fromCharacter(letter);
    if (code == null) {
      return const PlateValidation.invalid(reasonLetterUnknown);
    }

    if (serial.length < minSerialLength || serial.length > maxSerialLength) {
      return const PlateValidation.invalid(reasonSerialLength);
    }
    if (!isDigits(serial)) {
      return const PlateValidation.invalid(reasonSerialNotNumeric);
    }

    if (code == LebanonLetter.mp) {
      final int number = int.parse(serial);
      if (number < 1 || number > maxParliamentNumber) {
        return const PlateValidation.invalid(reasonParliamentRange);
      }
    }

    return const PlateValidation.valid();
  }
}
