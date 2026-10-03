import 'package:flutter_test/flutter_test.dart';
import 'package:mali_plate/mali_plate.dart';

void main() {
  group('Mali Plates', () {
    test('standard plate spec exists', () {
      final spec = MaliPlates.all['standard']!();
      expect(spec.slots.length, 8);
    });

    test('validator exists', () {
      const validator = MaliValidator();
      expect(validator.gateGroup, 'serial');
    });

    test('theme exists', () {
      expect(MaliThemes.standard.ink, MaliColors.black);
    });
  });
}
