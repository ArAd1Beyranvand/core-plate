import 'package:plate_core/plate_core.dart';
import 'package:plate_alphabet/plate_alphabet.dart' show IndonesiaAlphabets;

/// The area codes the article lists as in use, by police region. Non-motorised
/// codes (SB, YB, YK, KS) are included: they are issued plates.
abstract final class IndonesiaAreaCodes {
  static const Set<String> all = <String>{
    // Sumatra
    'BL', 'BB', 'BK', 'BA', 'BM', 'BP', 'BH', 'BD', 'BG', 'BN', 'BE', //
    // Java
    'A', 'B', 'F', 'T', 'E', 'D', 'Z', 'R', 'G', 'H', 'K', 'AA', 'AD', 'AB',
    'AE', 'AG', 'S', 'W', 'L', 'M', 'N', 'P',
    // Kalimantan
    'KB', 'KH', 'DA', 'KT', 'KU',
    // Sulawesi
    'DL', 'DB', 'DM', 'DN', 'DC', 'DP', 'DW', 'DD', 'DT',
    // Nusa Tenggara
    'DK', 'DR', 'EA', 'ED', 'EB', 'DH',
    // Maluku and Papua
    'DE', 'DG', 'PA', 'PB', 'PG', 'PS', 'PT', 'PY',
    // Non-motorised
    'SB', 'YB', 'YK', 'KS',
  };
}

/// Judges a registration on an `IndonesiaPlates.car` or `motorcycle` spec.
/// Reports, never bars a keystroke.
///
/// Checks what the article states: the area code is one it lists; the number
/// runs 1–9999 with no leading zero; the suffix is at most three letters; the
/// expiry month is 01–12. Does not check which suffixes a region issues.
class IndonesiaValidator extends GatedPlateValidator {
  const IndonesiaValidator();

  @override
  String get gateGroup => 'number';

  static const String reasonArea = 'Not an Indonesian area code.';
  static const String reasonNumber = 'The number is 1 to 9999.';
  static const String reasonLeadingZero = 'The number has no leading zero.';
  static const String reasonSuffix = 'The suffix is up to three letters.';
  static const String reasonMonth = 'The expiry month is 01 to 12.';

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    prefix: entry.group('prefix'),
    number: entry.group('number'),
    suffix: entry.group('suffix'),
    month: entry.group('month'),
  );

  static PlateValidation validateFields({
    required String prefix,
    required String number,
    String suffix = '',
    String month = '',
  }) {
    if (!IndonesiaAreaCodes.all.contains(prefix)) {
      return const PlateValidation.invalid(reasonArea);
    }
    if (number.isEmpty || number.length > 4 || !isDigits(number)) {
      return const PlateValidation.invalid(reasonNumber);
    }
    if (number.startsWith('0')) {
      return const PlateValidation.invalid(reasonLeadingZero);
    }
    if (suffix.length > 3) {
      return const PlateValidation.invalid(reasonSuffix);
    }
    if (month.isNotEmpty) {
      final int? m = int.tryParse(month);
      if (month.length != 2 || m == null || m < 1 || m > 12) {
        return const PlateValidation.invalid(reasonMonth);
      }
    }
    return const PlateValidation.valid();
  }
}

/// Judges an `IndonesiaPlates.diplomatic` value: `CD` or `CC`, the mission's
/// number and the vehicle's.
class IndonesiaDiplomaticValidator extends GatedPlateValidator {
  const IndonesiaDiplomaticValidator();

  @override
  String get gateGroup => 'serial';

  static const String reasonMission = 'The code is CD or CC.';
  static const String reasonDigits = 'Both numbers are digits.';

  @override
  PlateValidation judge(PlateEntry entry) {
    if (!const <String>['CD', 'CC'].contains(entry.group('mission'))) {
      return const PlateValidation.invalid(reasonMission);
    }
    if (!isDigits(entry.group('country')) || !isDigits(entry.group('serial'))) {
      return const PlateValidation.invalid(reasonDigits);
    }
    return const PlateValidation.valid();
  }
}

/// Judges an `IndonesiaPlates.military` or `police` value: a 1–99999 number
/// with no leading zero, a two-digit suffix and, on a police plate, a region
/// numeral the alphabet lists.
class IndonesiaServiceValidator extends GatedPlateValidator {
  const IndonesiaServiceValidator();

  @override
  String get gateGroup => 'number';

  static const String reasonNumber = 'The number is 1 to 99999.';
  static const String reasonSuffix = 'The suffix is two digits.';
  static const String reasonRegion = 'Not a police region numeral.';

  @override
  PlateValidation judge(PlateEntry entry) {
    final String number = entry.group('number');
    if (number.isEmpty || !isDigits(number) || number.startsWith('0')) {
      return const PlateValidation.invalid(reasonNumber);
    }
    final String suffix = entry.group('suffix');
    if (suffix.length != 2 || !isDigits(suffix)) {
      return const PlateValidation.invalid(reasonSuffix);
    }
    if (entry.spec.textGroups.any((g) => g.key == 'region') &&
        !IndonesiaAlphabets.policeRegions.characters.contains(
          entry.group('region'),
        )) {
      return const PlateValidation.invalid(reasonRegion);
    }
    return const PlateValidation.valid();
  }
}
