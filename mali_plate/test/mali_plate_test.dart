import 'package:flutter_test/flutter_test.dart';
import 'package:mali_plate/mali_plate.dart';

void main() {
  group('Mali Plates', () {
    test('standard plate spec exists', () {
      final spec = MaliPlates.all['standard']!();
      expect(spec.slots.length, 8);
    });

    test('validator accepts valid format', () {
      final valid = MaliValidators.validate('AB1234MD');
      expect(valid, true);
    });

    test('validator rejects invalid formats', () {
      expect(MaliValidators.validate('1234ABMD'), false);
      expect(MaliValidators.validate('AB12MD'), false);
      expect(MaliValidators.validate('AB1234'), false);
    });
  });
}
