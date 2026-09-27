import 'package:core_plate/core_plate.dart';

import 'palestine_governorates.dart';
import 'palestine_usage.dart';

/// Modern West Bank plate validator (D·DDDD·L, post-July-2018).
/// Different last group (letter vs digits) requires separate validator. Stays quiet
/// until governorate group filled (avoid flashing red on incomplete entry).
class PSWestBankModernValidator extends GatedPlateValidator {
  const PSWestBankModernValidator();

  @override
  String get gateGroup => 'governorate';

  static const String invalidRegion = 'Region code must be one digit.';
  static const String invalidSerial = 'Serial must be four digits.';

  /// H→J gap; I,O never issued. See PSGovernorate.
  static const String illegalLetterIO = 'The letters I and O are never issued; H is followed by J.';

  /// P–T allocated to pre-2012 Gaza; never issued West Bank.
  static const String reservedGazaLetter = 'P, Q, R, S and T were allocated to Gaza and never issued.';

  static const String invalidGovernorate = 'Governorate letter must be one of A-N (I and O excluded).';

  @override
  PlateValidation judge(PlateEntry entry) => validateFields(
    region: entry.group('region'),
    serial: entry.group('serial'),
    governorate: entry.group('governorate'),
  );

  /// Validation without spec (used by PSSerialGenerator and tests).
  static PlateValidation validateFields({required String region, required String serial, required String governorate}) {
    if (!isDigitsOfLength(region, 1)) {
      return const PlateValidation.invalid(invalidRegion);
    }
    if (!isDigitsOfLength(serial, 4)) {
      return const PlateValidation.invalid(invalidSerial);
    }
    if (PSGovernorate.confusableLetters.contains(governorate)) {
      return const PlateValidation.invalid(illegalLetterIO);
    }
    if (PSGovernorate.reservedGazaLetters.contains(governorate)) {
      return const PlateValidation.invalid(reservedGazaLetter);
    }
    if (governorate.length != 1 || !PSGovernorate.letters.contains(governorate)) {
      return const PlateValidation.invalid(invalidGovernorate);
    }
    return const PlateValidation.valid();
  }
}

/// Legacy West Bank plate validator (D·DDDD·DD, 1994–July-2018).
/// Stays quiet until usage group filled (see PSWestBankModernValidator).
class PSWestBankLegacyValidator extends GatedPlateValidator {
  const PSWestBankLegacyValidator();

  @override
  String get gateGroup => 'usage';

  /// 0,2 not legal (see PSLegacyUsage.districts).
  static const String invalidDistrictCode = 'District code must be 1 or 3-9 (0 and 2 are never issued).';

  static const String invalidSerial = 'Serial must be four digits.';

  static const String invalidUsageCode = 'Usage code is not a legal class (see PSLegacyUsage.codes).';

  @override
  PlateValidation judge(PlateEntry entry) =>
      validateFields(district: entry.group('district'), serial: entry.group('serial'), usage: entry.group('usage'));

  static PlateValidation validateFields({required String district, required String serial, required String usage}) {
    if (district.length != 1 || !PSLegacyUsage.districtCodes.contains(district)) {
      return const PlateValidation.invalid(invalidDistrictCode);
    }
    if (!isDigitsOfLength(serial, 4)) {
      return const PlateValidation.invalid(invalidSerial);
    }
    if (PSLegacyUsage.forCode(usage) == null) {
      return const PlateValidation.invalid(invalidUsageCode);
    }
    return const PlateValidation.valid();
  }
}

/// Gaza plate validator (3·DDDD·DD).
/// Stays quiet until usage group filled (see PSWestBankModernValidator).
class PSGazaValidator extends GatedPlateValidator {
  const PSGazaValidator();

  @override
  String get gateGroup => 'usage';

  static const String gazaPrefixNotThree = 'A Gaza plate always begins with 3.';

  static const String invalidSerial = 'Serial must be four digits.';

  static const String invalidUsageCode = 'Usage code is not a legal Gaza class (00-29 or 40-59).';

  @override
  PlateValidation judge(PlateEntry entry) =>
      validateFields(prefix: entry.group('prefix'), serial: entry.group('serial'), usage: entry.group('usage'));

  static PlateValidation validateFields({required String prefix, required String serial, required String usage}) {
    if (prefix != '3') {
      return const PlateValidation.invalid(gazaPrefixNotThree);
    }
    if (!isDigitsOfLength(serial, 4)) {
      return const PlateValidation.invalid(invalidSerial);
    }
    if (PSGazaUsage.forCode(usage) == null) {
      return const PlateValidation.invalid(invalidUsageCode);
    }
    return const PlateValidation.valid();
  }
}
