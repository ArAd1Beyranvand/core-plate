import 'package:plate_core/plate_core.dart';

import 'sudan_alphabets.dart';

/// Judges a `SudanPlates` value. Reports, never bars a keystroke.
///
/// What the sources fix: a single class digit (seen 1, 3, 4, 7, 8 — its
/// meaning is not documented, and it is not the usage, since `4` appears on
/// both a private and a taxi plate), a state code, and a serial of four or
/// five digits.
class SudanValidator extends GatedPlateValidator {
  const SudanValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonClass = 'The class is one digit.';
  static const String reasonState = 'Unknown state code.';
  static const String reasonSerial = 'The serial is four or five digits.';

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    classDigit: entry.group('class'),
    state: entry.group('state'),
    serial: entry.group('serial'),
  );

  static PlateValidation validateFields({
    required String classDigit,
    required String state,
    required String serial,
  }) {
    if (!isDigitsOfLength(classDigit, 1)) {
      return const PlateValidation.invalid(reasonClass);
    }
    if (!SudanAlphabets.stateLatin.characters.contains(state)) {
      return const PlateValidation.invalid(reasonState);
    }
    if (!isDigitsOfLength(serial, 4) && !isDigitsOfLength(serial, 5)) {
      return const PlateValidation.invalid(reasonSerial);
    }
    return const PlateValidation.valid();
  }
}
