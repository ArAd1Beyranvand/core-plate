import 'package:core_plate/core_plate.dart';
import 'package:cuba_plate/cuba_plate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PlateValidation judge(PlateSpec spec, String value) => const CubaValidator().validate(
    PlateEntry(spec: spec, values: <String?>[for (final c in value.split('')) c]),
  );

  test('every spec passes debugValidateSpec', () {
    for (final spec in CubaPlates.all) {
      expect(debugValidateSpec(spec), isTrue);
    }
  });

  test('the two cars share every slot and differ only in background', () {
    for (var i = 0; i < CubaPlates.car.slotCount; i++) {
      final a = CubaPlates.car.slots[i].box, b = CubaPlates.carLegalEntity.slots[i].box;
      expect(<double>[b.left, b.top, b.width, b.height], <double>[a.left, a.top, a.width, a.height]);
    }
    expect(CubaPlates.car.background.paintsPanel, isFalse);
    expect(CubaPlates.carLegalEntity.background.paintsPanel, isTrue);
  });

  test('validator', () {
    expect(judge(CubaPlates.car, 'P025245').isValid, isTrue);
    expect(judge(CubaPlates.motorcycle, 'P28588').isValid, isTrue);
    expect(judge(CubaPlates.car, 'O025245').isValid, isFalse);
    expect(judge(CubaPlates.car, 'P02524').isValid, isFalse);
    expect(judge(CubaPlates.car, 'P').isValid, isTrue, reason: 'quiet until the serial starts');
  });
}
