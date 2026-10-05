import 'package:plate_core/plate_core.dart';

import 'vietnam_missions.dart';

/// The number, whole: a dot or dash splits it into `number`, `number2`.
String _number(PlateEntry entry) =>
    entry.group('number') + entry.group('number2') + entry.group('number3');

/// Judges a civil, temporary or motorcycle plate: a province code, a series
/// and a number. Reports, never bars a keystroke.
///
/// Checks what QCVN 08:2024/BCA and the article state: the province code is
/// two digits from 11 up (there is no 00 to 10), the series is letters from
/// the issued alphabet, and the number is 4 or 5 digits. Does not check which
/// province codes or series have actually been issued.
class VietnamValidator extends GatedPlateValidator {
  const VietnamValidator();

  @override
  String get gateGroup => 'number';

  static const String reasonProvince = 'The province code is 11 to 99.';
  static const String reasonSeries = 'The series is missing.';
  static const String reasonNumber = 'The number is 4 or 5 digits.';

  @override
  PlateValidation judge(PlateEntry entry) {
    final String province = entry.group('province');
    final int? code = int.tryParse(province);
    if (province.length != 2 || code == null || code < 11) {
      return const PlateValidation.invalid(reasonProvince);
    }
    if (entry.group('series').isEmpty) {
      return const PlateValidation.invalid(reasonSeries);
    }
    final String number = _number(entry);
    if (number.length < 4 || number.length > 5 || !isDigits(number)) {
      return const PlateValidation.invalid(reasonNumber);
    }
    return const PlateValidation.valid();
  }
}

/// Judges a diplomatic, international-organisation or foreigner plate: the
/// province, the mission's three-digit code and a two-digit number. Refuses
/// the codes in [VietnamMissions.refused].
class VietnamForeignValidator extends GatedPlateValidator {
  const VietnamForeignValidator();

  @override
  String get gateGroup => 'number';

  static const String reasonMission = 'The mission code is three digits.';
  static const String reasonNumber = 'The number is two digits.';

  @override
  PlateValidation judge(PlateEntry entry) {
    final String mission = entry.group('mission');
    if (VietnamMissions.isRefused(mission)) {
      return const PlateValidation.invalid(VietnamMissions.notFound);
    }
    if (mission.length != 3 || !isDigits(mission)) {
      return const PlateValidation.invalid(reasonMission);
    }
    final String number = _number(entry);
    if (number.length != 2 || !isDigits(number)) {
      return const PlateValidation.invalid(reasonNumber);
    }
    return const PlateValidation.valid();
  }
}

/// Judges a military plate: a two-letter unit code and the number.
class VietnamMilitaryValidator extends GatedPlateValidator {
  const VietnamMilitaryValidator();

  @override
  String get gateGroup => 'number';

  static const String reasonUnit = 'The unit code is two letters.';
  static const String reasonNumber = 'The number is 3 or 4 digits.';

  @override
  PlateValidation judge(PlateEntry entry) {
    if (entry.group('unit').length != 2) {
      return const PlateValidation.invalid(reasonUnit);
    }
    final String number = _number(entry);
    if (number.length < 3 || number.length > 4 || !isDigits(number)) {
      return const PlateValidation.invalid(reasonNumber);
    }
    return const PlateValidation.valid();
  }
}
