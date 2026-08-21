import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number/model/plate_spec.dart';

void main() {
  group('debugValidateSpec', () {
    test('passes for irCar', () {
      expect(debugValidateSpec(PlateSpecs.irCar), isTrue);
    });

    test('passes for irBicycle', () {
      expect(debugValidateSpec(PlateSpecs.irBicycle), isTrue);
    });

    test('passes for deCar', () {
      expect(debugValidateSpec(PlateSpecs.deCar), isTrue);
    });
  });

  group('PlateSpec.valueOfGroup on deCar', () {
    test('concatenates values at a group\'s indices', () {
      final values = <String?>['D', 'A', 'X', '1', '9', '5', '3'];
      expect(PlateSpecs.deCar.valueOfGroup('district', values), 'DA');
      expect(PlateSpecs.deCar.valueOfGroup('letters', values), 'X');
      expect(PlateSpecs.deCar.valueOfGroup('serial', values), '1953');
    });

    test('unset slots render as empty string', () {
      final values = <String?>['D', null, null, null, null, null, null];
      expect(PlateSpecs.deCar.valueOfGroup('district', values), 'D');
      expect(PlateSpecs.deCar.valueOfGroup('serial', values), '');
    });

    test('returns empty string for a key with no matching group', () {
      final values = <String?>['D', 'A', 'X', '1', '9', '5', '3'];
      expect(PlateSpecs.deCar.valueOfGroup('nonexistent', values), '');
    });
  });
}
