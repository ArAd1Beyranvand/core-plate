import 'package:core_plate/core_plate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yemen_plate/yemen_plate.dart';

/// Every spec this package declares, flattened out of the four lookup maps.
///
/// Yemen exposes its specs by usage and number length rather than as one `all`
/// list, so the list is assembled here. It is the only place in the package
/// that sees all fifty-five at once, which is exactly what a validation sweep
/// wants.
Iterable<PlateSpec> get _allSpecs sync* {
  for (final byLength in YemenUnifiedPlates.car.values) {
    yield* byLength.values;
  }
  for (final byLength in YemenUnifiedPlates.moto.values) {
    yield* byLength.values;
  }
  for (final byDigits in YemenNorthernPlates.car.values) {
    yield* byDigits.values;
  }
  for (final byDigits in YemenNorthernPlates.moto.values) {
    yield* byDigits.values;
  }
}

void main() {
  group('debugValidateSpec', () {
    for (final spec in _allSpecs) {
      test(spec.id, () {
        // debugValidateSpec is assert-only and always returns true; the
        // assertion itself is what fails a spec with a slot outside its
        // canvas, a mirror pointing at no slot, or an unevenly pitched
        // register.
        var ok = false;
        assert(ok = debugValidateSpec(spec));
        expect(ok, isTrue, reason: 'assertions must be enabled to run this test');
      });
    }
  });

  test('every spec id is unique', () {
    final ids = [for (final s in _allSpecs) s.id];
    expect(ids.toSet().length, ids.length);
  });

  test('every northern serial register ends flush at the same right edge', () {
    // The phase's own thesis, as a test: four, five and six digits all fill
    // x [140, 530), so no length can run past its siblings. The four-cell
    // layout used to end at 531.
    for (final byDigits in YemenNorthernPlates.car.values) {
      for (final spec in byDigits.values) {
        final serial = spec.effectiveTextGroups.firstWhere(
          (g) => g.key == 'serial',
        );
        final boxes = [for (final i in serial.indices) spec.slots[i].box];
        expect(boxes.first.left, 140, reason: spec.id);
        expect(boxes.last.left + boxes.last.width, 530, reason: spec.id);
      }
    }
  });
}
