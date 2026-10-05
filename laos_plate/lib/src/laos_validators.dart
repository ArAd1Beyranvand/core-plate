import 'package:plate_core/plate_core.dart';

/// The consonants the article says may lead a provincial register, by the
/// vehicle they mark. The second consonant and the digits are a running
/// register with no stated rule.
abstract final class LaosClassLetters {
  static const Set<String> passengerCar = <String>{
    'ກ', 'ຂ', 'ຄ', 'ນ', 'ມ', 'ຣ', 'ລ', 'ວ', 'ຫ', 'ອ', 'ຮ', //
  };
  static const Set<String> motorbike = <String>{'ຈ', 'ຍ', 'ດ', 'ຕ', 'ທ'};
  static const Set<String> tricycle = <String>{'ສ'};
  static const Set<String> heavyTruck = <String>{'ບ'};

  static const Set<String> all = <String>{
    ...passengerCar,
    ...motorbike,
    ...tricycle,
    ...heavyTruck,
  };
}

/// Judges a provincial plate: two consonants, the first a class letter, and
/// four digits. Reports, never bars a keystroke.
class LaosValidator extends GatedPlateValidator {
  const LaosValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonLetters = 'The register is two consonants.';
  static const String reasonClass =
      'The first consonant is not a vehicle-class letter.';
  static const String reasonSerial = 'The number is four digits.';

  @override
  PlateValidation judge(PlateEntry entry) {
    final String letters = entry.group('letters');
    if (letters.runes.length != 2) {
      return const PlateValidation.invalid(reasonLetters);
    }
    if (!LaosClassLetters.all.contains(
      String.fromCharCode(letters.runes.first),
    )) {
      return const PlateValidation.invalid(reasonClass);
    }
    if (!isDigitsOfLength(entry.group('serial'), 4)) {
      return const PlateValidation.invalid(reasonSerial);
    }
    return const PlateValidation.valid();
  }
}

/// Judges a temporary plate: two consonants, a digit and three digits, and
/// an expiry printed 2-4-2. The photographed `10-2024-01` does not show which
/// end is the day, so only the shape is checked.
class LaosTemporaryValidator extends GatedPlateValidator {
  const LaosTemporaryValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonLetters = 'The register is two consonants.';
  static const String reasonSerial = 'The number is one digit and three.';
  static const String reasonExpiry = 'The expiry date is 2-4-2 digits.';

  @override
  PlateValidation judge(PlateEntry entry) {
    if (entry.group('letters').runes.length != 2) {
      return const PlateValidation.invalid(reasonLetters);
    }
    if (!isDigitsOfLength(entry.group('digit'), 1) ||
        !isDigitsOfLength(entry.group('serial'), 3)) {
      return const PlateValidation.invalid(reasonSerial);
    }
    if (!isDigitsOfLength(entry.group('expiryLead'), 2) ||
        !isDigitsOfLength(entry.group('expiryYear'), 4) ||
        !isDigitsOfLength(entry.group('expiryTail'), 2)) {
      return const PlateValidation.invalid(reasonExpiry);
    }
    return const PlateValidation.valid();
  }
}

/// Judges a prefixed plate: two-and-two digits on the international
/// organisations' plates, four on the police and defence plates.
class LaosPrefixedValidator extends GatedPlateValidator {
  const LaosPrefixedValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonCode = 'The code is two digits.';
  static const String reasonSerial = 'The number is two or four digits.';

  @override
  PlateValidation judge(PlateEntry entry) {
    final String serial = entry.group('serial');
    if (entry.spec.indicesOfGroup('code').isNotEmpty) {
      if (!isDigitsOfLength(entry.group('code'), 2)) {
        return const PlateValidation.invalid(reasonCode);
      }
      if (!isDigitsOfLength(serial, 2)) {
        return const PlateValidation.invalid(reasonSerial);
      }
    } else if (!isDigitsOfLength(serial, 4)) {
      return const PlateValidation.invalid(reasonSerial);
    }
    return const PlateValidation.valid();
  }
}
