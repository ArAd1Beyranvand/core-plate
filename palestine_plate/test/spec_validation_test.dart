import 'package:core_plate/core_plate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palestine_plate/palestine_plate.dart';

void main() {
  group('debugValidateSpec', () {
    for (final spec in PSWestBankPlates.all) {
      test(spec.id, () {
        // debugValidateSpec is assert-only and always returns true; the
        // assertion itself is what fails a spec with a slot outside its
        // canvas or an alphabet id reused for two character lists.
        var ok = false;
        assert(ok = debugValidateSpec(spec));
        expect(
          ok,
          isTrue,
          reason: 'assertions must be enabled to run this test',
        );
      });
    }

    for (final spec in PSGazaPlates.all) {
      test(spec.id, () {
        var ok = false;
        assert(ok = debugValidateSpec(spec));
        expect(
          ok,
          isTrue,
          reason: 'assertions must be enabled to run this test',
        );
      });
    }
  });

  test('every spec id is unique', () {
    final ids = [
      for (final s in PSWestBankPlates.all) s.id,
      for (final s in PSGazaPlates.all) s.id,
    ];
    expect(ids.toSet().length, ids.length);
  });

  test('West Bank specs declare the keyed groups their validators read', () {
    for (final spec in PSWestBankPlates.all) {
      final keys = spec.effectiveTextGroups.map((g) => g.key).toSet();
      final isModern = spec.slots.length == 6;
      if (isModern) {
        expect(
          keys,
          containsAll(<String>{'region', 'serial', 'governorate'}),
          reason: spec.id,
        );
      } else {
        expect(
          keys,
          containsAll(<String>{'district', 'serial', 'usage'}),
          reason: spec.id,
        );
      }
    }
  });

  test('Gaza specs declare prefix/serial/usage groups', () {
    for (final spec in PSGazaPlates.all) {
      final keys = spec.effectiveTextGroups.map((g) => g.key).toSet();
      expect(
        keys,
        containsAll(<String>{'prefix', 'serial', 'usage'}),
        reason: spec.id,
      );
    }
  });
}
