import 'package:plate_core/plate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:india_plate/india_plate.dart';

void main() {
  PlateValidation judge(PlateSpec spec, String value) =>
      const IndiaValidator().validate(
        PlateEntry(
          spec: spec,
          values: <String?>[for (final c in value.split('')) c],
        ),
      );

  test('every spec passes debugValidateSpec', () {
    for (final spec in IndiaPlates.all) {
      expect(debugValidateSpec(spec), isTrue);
    }
  });

  test('fixed characters render into the text, not the slots', () {
    final spec = IndiaPlates.bharat;
    expect(spec.slotCount, 8);
    final values = <String?>[for (final c in '212345AA'.split('')) c];
    expect(
      spec.effectiveTextGroups
          .map((g) => spec.renderGroup(g, values))
          .join(' '),
      '21 BH2345 AA',
    );
  });

  test('validator', () {
    expect(judge(IndiaPlates.private, 'MH20DV2366').isValid, isTrue);
    expect(judge(IndiaPlates.private, 'XX20DV2366').isValid, isFalse);
    expect(judge(IndiaPlates.private, 'MH00DV2366').isValid, isFalse);
    expect(judge(IndiaPlates.private, 'MH20DV0000').isValid, isFalse);
    expect(
      judge(IndiaPlates.private, 'XX20').isValid,
      isTrue,
      reason: 'quiet until full',
    );
    expect(judge(IndiaPlates.temporary, '1323KL5986KA').isValid, isFalse);
    expect(judge(IndiaPlates.temporary, '1123KL5986KA').isValid, isTrue);
    expect(judge(IndiaPlates.military, '02B084821H').isValid, isTrue);
    expect(judge(IndiaPlates.military, '02I084821H').isValid, isFalse);
    expect(judge(IndiaPlates.diplomatic, '052CD0019').isValid, isTrue);
    expect(judge(IndiaPlates.diplomatic, '052XX0019').isValid, isFalse);
    expect(judge(IndiaPlates.trade, 'UP16K00020073').isValid, isFalse);
  });
}
