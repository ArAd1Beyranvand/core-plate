import 'package:plate_core/core_plate.dart';

import 'yemen_governorates.dart';

/// Judges a System A (2026 unified) plate value. Gated on the side code
/// (the last register) so validation starts only after the vehicle number is entered.
/// Checks only the side code's shape, not its semantics (see TODO in [validateFields]).
class YemenUnifiedValidator extends GatedPlateValidator {
  /// A stateless rule; hold one as a `const`.
  const YemenUnifiedValidator();

  @override
  String get gateGroup => 'sideCode';

  /// Reported when the vehicle number holds something other than digits.
  static const String reasonNumberNotNumeric =
      'The vehicle number is digits only.';

  /// Reported when the vehicle number is outside four to six digits.
  static const String reasonNumberLength =
      'The vehicle number is four to six digits.';

  /// Reported when the side code holds something other than digits.
  static const String reasonSideCodeNotNumeric =
      'The side code is digits only.';

  /// Reported when the side code is not exactly two digits.
  static const String reasonSideCodeLength = 'The side code is two digits.';

  /// The shortest and longest vehicle number this system prints.
  static const int minNumberLength = 4;
  static const int maxNumberLength = 6;

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    number: entry.group('number'),
    sideCode: entry.group('sideCode'),
  );

  /// [number] is 4–6 digits; [sideCode] is the two-digit code in the blue panel.
  /// Side code is checked for shape only (see TODO in [validateFields]).
  // TODO(side-code): no source pins down which digit encodes what; stay opaque.
  static PlateValidation validateFields({
    required String number,
    required String sideCode,
  }) {
    if (number.isNotEmpty && !isDigits(number)) {
      return const PlateValidation.invalid(reasonNumberNotNumeric);
    }
    if (number.length < minNumberLength || number.length > maxNumberLength) {
      return const PlateValidation.invalid(reasonNumberLength);
    }

    if (!isDigits(sideCode)) {
      return const PlateValidation.invalid(reasonSideCodeNotNumeric);
    }
    if (sideCode.length != 2) {
      return const PlateValidation.invalid(reasonSideCodeLength);
    }

    return const PlateValidation.valid();
  }
}

/// Judges a System B (1993 northern) plate value. Gated on the serial (the last
/// register). Checks more than [YemenUnifiedValidator] because System B's grammar
/// is documented: governorate code 1..22, serial never zero-padded.
class YemenNorthernValidator extends GatedPlateValidator {
  /// A stateless rule; hold one as a `const`.
  const YemenNorthernValidator();

  @override
  String get gateGroup => 'serial';

  /// Reported when the governorate register holds something other than digits.
  static const String reasonGovernorateNotNumeric =
      'The governorate code is digits only.';

  /// Reported when the governorate register is empty or longer than two
  /// digits.
  static const String reasonGovernorateLength =
      'The governorate code is one or two digits.';

  /// Reported when the governorate code is outside 1..22.
  static const String reasonGovernorateRange =
      'The governorate code is 1 to 22.';

  /// Reported when the serial holds something other than digits.
  static const String reasonSerialNotNumeric = 'The serial is digits only.';

  /// Reported when the serial is empty or longer than six digits.
  static const String reasonSerialLength = 'The serial is one to six digits.';

  /// Reported when the serial starts with a zero.
  static const String reasonSerialLeadingZero =
      'The serial is not padded with leading zeros.';

  /// The shortest and longest serial this system prints.
  static const int minSerialLength = 1;
  static const int maxSerialLength = 6;

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    governorate: entry.group('governorate'),
    serial: entry.group('serial'),
  );

  /// [governorate] is the upper register (1–2 digits); [serial] is the lower.
  /// Governorate: `'05'` and `'5'` are the same (two-cell padding). Serial: no leading zeros.
  static PlateValidation validateFields({
    required String governorate,
    required String serial,
  }) {
    if (governorate.isEmpty || governorate.length > 2) {
      return const PlateValidation.invalid(reasonGovernorateLength);
    }
    if (!isDigits(governorate)) {
      return const PlateValidation.invalid(reasonGovernorateNotNumeric);
    }
    final int code = int.parse(governorate);
    if (code < YemenGovernorate.minCode || code > YemenGovernorate.maxCode) {
      return const PlateValidation.invalid(reasonGovernorateRange);
    }

    if (serial.length < minSerialLength || serial.length > maxSerialLength) {
      return const PlateValidation.invalid(reasonSerialLength);
    }
    if (!isDigits(serial)) {
      return const PlateValidation.invalid(reasonSerialNotNumeric);
    }
    if (serial.startsWith('0')) {
      return const PlateValidation.invalid(reasonSerialLeadingZero);
    }

    return const PlateValidation.valid();
  }
}
