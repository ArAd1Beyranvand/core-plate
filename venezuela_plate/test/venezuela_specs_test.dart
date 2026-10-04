import 'package:plate_core/plate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:venezuela_plate/venezuela_plate.dart';

void main() {
  PlateValidation judge(String value) => const VenezuelaValidator().validate(
    PlateEntry(
      spec: VenezuelaPlates.car,
      values: <String?>[for (final c in value.split('')) c],
    ),
  );

  test('every spec passes debugValidateSpec', () {
    for (final spec in VenezuelaPlates.all) {
      expect(debugValidateSpec(spec), isTrue);
    }
  });

  test('every state letter has a name, and only those', () {
    expect(
      VenezuelaAlphabets.stateNames.keys,
      VenezuelaAlphabets.state.characters,
    );
    expect(VenezuelaAlphabets.stateName.render('K'), 'LARA');
  });

  test('categories', () {
    expect(VenezuelaValidator.categoryOf('AB174S')?.name, 'Private car');
    expect(VenezuelaValidator.categoryOf('AH7A23')?.name, 'Motorcycle');
    expect(VenezuelaValidator.categoryOf('7A1B2C')?.name, 'Taxi');
    expect(VenezuelaValidator.categoryOf('123456'), isNull);
  });

  test('validator', () {
    expect(judge('AB174SK').isValid, isTrue);
    expect(judge('AE328KG').isValid, isTrue);
    expect(judge('AB174SQ').isValid, isFalse, reason: 'Q names no state');
    expect(judge('A1B2CDD').isValid, isFalse, reason: 'LDLDLL is no category');
    expect(
      judge('AB174S').isValid,
      isTrue,
      reason: 'quiet until the state letter',
    );
  });
}
