import 'package:core_plate/core_plate.dart';

import 'yemen_governorates.dart';

/// Judges a **System A** (2026 unified) plate value.
///
/// Like every [PlateValidator] it never prevents a keystroke and never throws;
/// it reports, and the host decides what to do with the report. A slot's
/// alphabet is what restricts input, and it does so silently.
///
/// It stays quiet until the side code has something in it. The side code is the
/// last register a user reaches — its two cells are the last slots on every
/// unified spec — so by the time it is non-empty the vehicle number has been
/// typed and there is something to judge. With nothing barring input, the red
/// state is the only feedback there is, and a plate that flashes red at its
/// first keystroke is worse than no validation at all.
///
/// ### What it does not check
///
/// The side code's two digits are checked for shape and nothing else. See
/// [reasonSideCodeLength] and the TODO in [validateFields].
class YemenUnifiedValidator extends PlateValidator {
  /// A stateless rule; hold one as a `const`.
  const YemenUnifiedValidator();

  /// Reported when the vehicle number holds something other than digits.
  static const String reasonNumberNotNumeric =
      'The vehicle number is digits only.';

  /// Reported when the vehicle number is outside four to six digits.
  static const String reasonNumberLength =
      'The vehicle number is four to six digits.';

  /// Reported when the side code holds something other than digits.
  static const String reasonSideCodeNotNumeric = 'The side code is digits only.';

  /// Reported when the side code is not exactly two digits.
  static const String reasonSideCodeLength = 'The side code is two digits.';

  static final RegExp _digits = RegExp(r'^[0-9]+$');

  /// The shortest and longest vehicle number this system prints.
  static const int minNumberLength = 4;
  static const int maxNumberLength = 6;

  @override
  PlateValidation validate(PlateEntry entry) {
    final String sideCode = entry.group('sideCode');
    if (sideCode.isEmpty) return const PlateValidation.valid();

    return validateFields(
      number: entry.group('number'),
      sideCode: sideCode,
    );
  }

  /// The rule without a spec: pass the two registers in directly.
  ///
  /// [number] is the vehicle number in the plate's main zone, four to six
  /// digits. [sideCode] is the two-digit code stacked in the blue side panel.
  ///
  /// The side code is checked for shape only, and that is a gap rather than a
  /// decision.
  // TODO(side-code): the two digits are widely described as encoding the
  // governorate and the year of issue, but no source pins down which digit is
  // which, whether the governorate half uses the 1..22 numbering
  // `YemenGovernorate` carries, or how a year is compressed into one digit.
  // Until one does, a range check here would be a guess wearing the clothes of
  // a rule, so the code stays opaque: two digits, any two digits.
  static PlateValidation validateFields({
    required String number,
    required String sideCode,
  }) {
    if (number.isNotEmpty && !_digits.hasMatch(number)) {
      return const PlateValidation.invalid(reasonNumberNotNumeric);
    }
    if (number.length < minNumberLength || number.length > maxNumberLength) {
      return const PlateValidation.invalid(reasonNumberLength);
    }

    if (!_digits.hasMatch(sideCode)) {
      return const PlateValidation.invalid(reasonSideCodeNotNumeric);
    }
    if (sideCode.length != 2) {
      return const PlateValidation.invalid(reasonSideCodeLength);
    }

    return const PlateValidation.valid();
  }
}

/// Judges a **System B** (1993 northern) plate value.
///
/// Quiet until the serial has something in it, for the reason
/// [YemenUnifiedValidator] is quiet until the side code does: the serial is the
/// lower register and the last one reached, so by then the governorate code
/// above it has been entered.
///
/// This validator checks more than its unified counterpart, because System B's
/// grammar is documented where System A's side code is not: the governorate
/// code is a real number in a real range, and the serial is never zero-padded.
class YemenNorthernValidator extends PlateValidator {
  /// A stateless rule; hold one as a `const`.
  const YemenNorthernValidator();

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

  static final RegExp _digits = RegExp(r'^[0-9]+$');

  /// The shortest and longest serial this system prints.
  static const int minSerialLength = 1;
  static const int maxSerialLength = 6;

  @override
  PlateValidation validate(PlateEntry entry) {
    final String serial = entry.group('serial');
    if (serial.isEmpty) return const PlateValidation.valid();

    return validateFields(
      governorate: entry.group('governorate'),
      serial: serial,
    );
  }

  /// The rule without a spec: pass the two registers in directly.
  ///
  /// [governorate] is the upper register — one or two digits, and `'05'` and
  /// `'5'` are the same code, because a two-cell register pads a single-digit
  /// code to fill itself. [serial] is the lower register.
  ///
  /// The serial's leading-zero rule runs the other way: the serial register is
  /// sized to the serial, so a plate showing `04213` is showing a five-digit
  /// serial that begins with a zero, which this system does not issue.
  static PlateValidation validateFields({
    required String governorate,
    required String serial,
  }) {
    if (governorate.isEmpty || governorate.length > 2) {
      return const PlateValidation.invalid(reasonGovernorateLength);
    }
    if (!_digits.hasMatch(governorate)) {
      return const PlateValidation.invalid(reasonGovernorateNotNumeric);
    }
    final int code = int.parse(governorate);
    if (code < YemenGovernorate.minCode || code > YemenGovernorate.maxCode) {
      return const PlateValidation.invalid(reasonGovernorateRange);
    }

    if (serial.length < minSerialLength || serial.length > maxSerialLength) {
      return const PlateValidation.invalid(reasonSerialLength);
    }
    if (!_digits.hasMatch(serial)) {
      return const PlateValidation.invalid(reasonSerialNotNumeric);
    }
    if (serial.startsWith('0')) {
      return const PlateValidation.invalid(reasonSerialLeadingZero);
    }

    return const PlateValidation.valid();
  }
}
