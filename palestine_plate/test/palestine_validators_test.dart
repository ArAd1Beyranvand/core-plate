import 'package:core_plate/core_plate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palestine_plate/palestine_plate.dart';

void main() {
  group('PSWestBankModernValidator', () {
    test('valid plate', () {
      final v = PSWestBankModernValidator.validateFields(
        region: '1',
        serial: '0234',
        governorate: 'H',
      );
      expect(v.isValid, isTrue);
    });

    test('the H -> J gap: J is legal, I is not', () {
      expect(
        PSWestBankModernValidator.validateFields(
          region: '1',
          serial: '0234',
          governorate: 'J',
        ).isValid,
        isTrue,
      );
      expect(
        PSWestBankModernValidator.validateFields(
          region: '1',
          serial: '0234',
          governorate: 'I',
        ),
        const PlateValidation.invalid(
          PSWestBankModernValidator.illegalLetterIO,
        ),
      );
    });

    test('O is rejected as a confusable letter', () {
      expect(
        PSWestBankModernValidator.validateFields(
          region: '1',
          serial: '0234',
          governorate: 'O',
        ),
        const PlateValidation.invalid(
          PSWestBankModernValidator.illegalLetterIO,
        ),
      );
    });

    test('P-T are rejected as reserved Gaza letters', () {
      for (final letter in PSGovernorate.reservedGazaLetters) {
        expect(
          PSWestBankModernValidator.validateFields(
            region: '1',
            serial: '0234',
            governorate: letter,
          ),
          const PlateValidation.invalid(
            PSWestBankModernValidator.reservedGazaLetter,
          ),
          reason: letter,
        );
      }
    });

    test('region must be one digit', () {
      expect(
        PSWestBankModernValidator.validateFields(
          region: '12',
          serial: '0234',
          governorate: 'H',
        ),
        const PlateValidation.invalid(PSWestBankModernValidator.invalidRegion),
      );
    });

    test('serial must be four digits', () {
      expect(
        PSWestBankModernValidator.validateFields(
          region: '1',
          serial: '234',
          governorate: 'H',
        ),
        const PlateValidation.invalid(PSWestBankModernValidator.invalidSerial),
      );
    });

    test('quiet until the governorate group is reached', () {
      final spec = PSWestBankPlates.modernCar;
      final entry = PlateEntry(
        spec: spec,
        values: ['1', '0', '2', '3', '4', null],
      );
      expect(const PSWestBankModernValidator().validate(entry).isValid, isTrue);
    });
  });

  group('PSWestBankLegacyValidator', () {
    test('valid private plate', () {
      expect(
        PSWestBankLegacyValidator.validateFields(
          district: '4',
          serial: '0234',
          usage: '41',
        ).isValid,
        isTrue,
      );
    });

    test('district 0 and 2 are rejected', () {
      for (final d in ['0', '2']) {
        expect(
          PSWestBankLegacyValidator.validateFields(
            district: d,
            serial: '0234',
            usage: '41',
          ),
          const PlateValidation.invalid(
            PSWestBankLegacyValidator.invalidDistrictCode,
          ),
          reason: d,
        );
      }
    });

    test('usage 99 validates and maps to the government theme', () {
      final v = PSWestBankLegacyValidator.validateFields(
        district: '4',
        serial: '0234',
        usage: '99',
      );
      expect(v.isValid, isTrue);
      expect(PSLegacyUsage.forCode('99'), PSUsage.government);
      expect(PSThemes.forUsage(PSUsage.government), PSThemes.redOnWhite);
    });

    test('an out-of-range usage code is invalid', () {
      for (final u in ['00', '33', '89']) {
        expect(
          PSWestBankLegacyValidator.validateFields(
            district: '4',
            serial: '0234',
            usage: u,
          ),
          const PlateValidation.invalid(
            PSWestBankLegacyValidator.invalidUsageCode,
          ),
          reason: u,
        );
      }
    });

    test('quiet until the usage group is reached', () {
      final spec = PSWestBankPlates.legacyCar;
      final entry = PlateEntry(
        spec: spec,
        values: ['4', '0', '2', '3', '4', null, null],
      );
      expect(const PSWestBankLegacyValidator().validate(entry).isValid, isTrue);
    });
  });

  group('PSGazaValidator', () {
    test('valid plate', () {
      expect(
        PSGazaValidator.validateFields(
          prefix: '3',
          serial: '0234',
          usage: '05',
        ).isValid,
        isTrue,
      );
    });

    test('prefix must be 3', () {
      for (final p in ['1', '0', '9']) {
        expect(
          PSGazaValidator.validateFields(
            prefix: p,
            serial: '0234',
            usage: '05',
          ),
          const PlateValidation.invalid(PSGazaValidator.gazaPrefixNotThree),
          reason: p,
        );
      }
    });

    test('30-39 and 60-99 are unallocated and rejected', () {
      for (final u in ['30', '39', '60', '99']) {
        expect(
          PSGazaValidator.validateFields(prefix: '3', serial: '0234', usage: u),
          const PlateValidation.invalid(PSGazaValidator.invalidUsageCode),
          reason: u,
        );
      }
    });

    test('every legal Gaza usage code validates', () {
      for (final u in PSGazaUsage.codes) {
        expect(
          PSGazaValidator.validateFields(
            prefix: '3',
            serial: '0234',
            usage: u,
          ).isValid,
          isTrue,
          reason: u,
        );
      }
    });

    test('quiet until the usage group is reached', () {
      final spec = PSGazaPlates.car2012;
      final entry = PlateEntry(
        spec: spec,
        values: ['3', '0', '2', '3', '4', null, null],
      );
      expect(const PSGazaValidator().validate(entry).isValid, isTrue);
    });
  });

  test('a modern plate with no usage supplied defaults to private', () {
    // The modern scheme encodes no usage at all; a host supplies PSUsage
    // separately, and PSUsage.private is that default.
    expect(PSThemes.forUsage(PSUsage.private), PSThemes.greenOnWhite);
  });
}
