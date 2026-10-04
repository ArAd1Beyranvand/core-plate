import 'package:plate_core/core_plate.dart';

import 'bolivia_alphabets.dart';

/// Judges a `BoliviaPlates.standard` value. Reports, never bars a keystroke.
///
/// Checks what the article states: the PTA number is three or four digits
/// and three letters (`0XX AAA` on older vehicles to `64XX AAA` by December
/// 2024), and the box holds one of the nine department letters.
class BoliviaValidator extends GatedPlateValidator {
  const BoliviaValidator();

  @override
  String get gateGroup => 'letters';

  static const String reasonNumber = 'The number is three or four digits.';
  static const String reasonLetters = 'The series is three letters.';
  static const String reasonDepartment =
      'The department is one of C H B L O N P S T.';

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    number: entry.group('number'),
    letters: entry.group('letters'),
    department: entry.group('department'),
  );

  static PlateValidation validateFields({
    required String number,
    required String letters,
    required String department,
  }) {
    if ((number.length != 3 && number.length != 4) || !isDigits(number)) {
      return const PlateValidation.invalid(reasonNumber);
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(letters)) {
      return const PlateValidation.invalid(reasonLetters);
    }
    if (!BoliviaAlphabets.departments.characters.contains(department)) {
      return const PlateValidation.invalid(reasonDepartment);
    }
    return const PlateValidation.valid();
  }
}

/// Judges a `BoliviaPlates.special` value: two two-digit numbers, the
/// mission's country and the vehicle's rank.
class BoliviaSpecialValidator extends GatedPlateValidator {
  const BoliviaSpecialValidator();

  @override
  String get gateGroup => 'rank';

  static const String reasonDigits = 'Both numbers are two digits.';

  @override
  PlateValidation judge(PlateEntry entry) =>
      isDigitsOfLength(entry.group('country'), 2) &&
          isDigitsOfLength(entry.group('rank'), 2)
      ? const PlateValidation.valid()
      : const PlateValidation.invalid(reasonDigits);
}

/// Judges a `BoliviaPlates.mercosur` value: two letters and five digits.
class BoliviaMercosurValidator extends GatedPlateValidator {
  const BoliviaMercosurValidator();

  @override
  String get gateGroup => 'number';

  static const String reasonLetters = 'The series is two letters.';
  static const String reasonNumber = 'The number is five digits.';

  @override
  PlateValidation judge(PlateEntry entry) {
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(entry.group('letters'))) {
      return const PlateValidation.invalid(reasonLetters);
    }
    if (!isDigitsOfLength(entry.group('number'), 5)) {
      return const PlateValidation.invalid(reasonNumber);
    }
    return const PlateValidation.valid();
  }
}
