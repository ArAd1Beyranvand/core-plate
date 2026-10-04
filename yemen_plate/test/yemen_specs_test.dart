import 'dart:math';

import 'package:plate_core/core_plate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yemen_plate/yemen_plate.dart';

/// Every spec this package declares — eleven, one per geometry.
///
/// There is no usage axis to walk any more: a usage is a `PlateCountry` and a
/// `PlateTheme` the host hands to the canvas, so the same spec draws a private
/// plate and a government one. What is left to sweep is the geometry.
Iterable<PlateSpec> get _allSpecs sync* {
  yield* _unifiedSpecs;
  yield* _northernSpecs;
}

Iterable<PlateSpec> get _unifiedSpecs sync* {
  yield* YemenUnifiedPlates.carGeometries.values;
  yield* YemenUnifiedPlates.motoGeometries.values;
}

Iterable<PlateSpec> get _northernSpecs sync* {
  yield* YemenNorthernPlates.carGeometries.values;
  yield* YemenNorthernPlates.motoGeometries.values;
}

/// The slot indices of [spec]'s group named [key].
List<int> _indices(PlateSpec spec, String key) => spec.effectiveTextGroups
    .firstWhere((PlateTextGroup g) => g.key == key)
    .indices;

void main() {
  group('debugValidateSpec', () {
    for (final PlateSpec spec in _allSpecs) {
      test(spec.id, () {
        // debugValidateSpec is assert-only and always returns true; the
        // assertion itself is what fails a spec with a slot outside its
        // canvas, a mirror pointing at no slot, or an unevenly pitched
        // register.
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

  group('the count is the point', () {
    test('eleven specs, five northern and six unified', () {
      expect(_northernSpecs.length, 5);
      expect(_unifiedSpecs.length, 6);
    });
  });

  group('ids', () {
    test('are unique across both systems', () {
      final List<String> ids = <String>[for (final s in _allSpecs) s.id];
      expect(ids.toSet().length, ids.length);
    });

    test('carry no usage segment', () {
      // The whole phase, as an assertion: a spec is a geometry, so its id
      // names one. `ye.northern.car.g2s5`, never `....private`.
      for (final PlateSpec spec in _allSpecs) {
        expect(
          YemenUsage.values.any((YemenUsage u) => spec.id.contains(u.name)),
          isFalse,
          reason: spec.id,
        );
      }
    });

    test('are four segments on System B and three on System A', () {
      for (final PlateSpec spec in _northernSpecs) {
        expect(spec.id.split('.').length, 4, reason: spec.id);
      }
      for (final PlateSpec spec in _unifiedSpecs) {
        expect(spec.id.split('.').length, 3, reason: spec.id);
      }
    });
  });

  group('text groups carry the keys the validators read', () {
    test('System A: number + sideCode', () {
      for (final PlateSpec spec in _unifiedSpecs) {
        final Set<String?> keys = <String?>{
          for (final PlateTextGroup g in spec.effectiveTextGroups) g.key,
        };
        expect(
          keys,
          containsAll(<String>['number', 'sideCode']),
          reason: spec.id,
        );
      }
    });

    test('System B: governorate + serial', () {
      for (final PlateSpec spec in _northernSpecs) {
        final Set<String?> keys = <String?>{
          for (final PlateTextGroup g in spec.effectiveTextGroups) g.key,
        };
        expect(
          keys,
          containsAll(<String>['governorate', 'serial']),
          reason: spec.id,
        );
      }
    });
  });

  group('slot counts match the geometry the name and the key claim', () {
    test('System B cars', () {
      YemenNorthernPlates.carGeometries.forEach((
        (int, int) shape,
        PlateSpec spec,
      ) {
        final (int gov, int serial) = shape;
        expect(spec.slots.length, gov + serial, reason: spec.id);
        expect(_indices(spec, 'governorate').length, gov, reason: spec.id);
        expect(_indices(spec, 'serial').length, serial, reason: spec.id);
        // One echo per digit: the small Latin row prints the whole number.
        expect(spec.mirrors.length, gov + serial, reason: spec.id);
      });
    });

    test('System B motorcycles', () {
      YemenNorthernPlates.motoGeometries.forEach((
        (int, int) shape,
        PlateSpec spec,
      ) {
        expect(spec.slots.length, shape.$1 + shape.$2, reason: spec.id);
      });
    });

    test('System A: the number, plus two side-code cells', () {
      for (final MapEntry<int, PlateSpec> e in <MapEntry<int, PlateSpec>>[
        ...YemenUnifiedPlates.carGeometries.entries,
        ...YemenUnifiedPlates.motoGeometries.entries,
      ]) {
        final PlateSpec spec = e.value;
        expect(spec.slots.length, e.key + 2, reason: spec.id);
        expect(_indices(spec, 'number').length, e.key, reason: spec.id);
        expect(_indices(spec, 'sideCode').length, 2, reason: spec.id);
      }
    });
  });

  group('generator round-trip', () {
    // The strongest available proof that no group key and no slot order moved
    // when the twenty and twenty-four clones went: the generator reads a spec
    // by group key and the validator reads the values back the same way, so a
    // disagreement anywhere between them shows up as an invalid draw.
    const int draws = 1000;

    test('$draws northern draws all validate', () {
      final Random rng = Random(4491);
      const YemenNorthernValidator validator = YemenNorthernValidator();
      for (final PlateSpec spec in _northernSpecs) {
        for (int i = 0; i < draws; i++) {
          final List<String?> values = YemenNorthernSerialGenerator.generate(
            spec,
            random: rng,
          );
          expect(values.length, spec.slots.length, reason: spec.id);
          expect(values, isNot(contains(null)), reason: spec.id);
          final PlateValidation v = validator.validate(
            PlateEntry(spec: spec, values: values),
          );
          expect(v.isValid, isTrue, reason: '${spec.id} $values: ${v.reason}');
        }
      }
    });

    test('$draws unified draws all validate', () {
      final Random rng = Random(4492);
      const YemenUnifiedValidator validator = YemenUnifiedValidator();
      for (final PlateSpec spec in _unifiedSpecs) {
        for (int i = 0; i < draws; i++) {
          final List<String?> values = YemenUnifiedSerialGenerator.generate(
            spec,
            random: rng,
          );
          expect(values.length, spec.slots.length, reason: spec.id);
          expect(values, isNot(contains(null)), reason: spec.id);
          final PlateValidation v = validator.validate(
            PlateEntry(spec: spec, values: values),
          );
          expect(v.isValid, isTrue, reason: '${spec.id} $values: ${v.reason}');
        }
      }
    });
  });

  test('every northern serial register ends flush at the same right edge', () {
    // P3B's thesis, kept: four, five and six digits all fill x [140, 530), so
    // no length can run past its siblings. The four-cell layout used to end at
    // 531.
    for (final PlateSpec spec in YemenNorthernPlates.carGeometries.values) {
      final List<PlateBox> boxes = <PlateBox>[
        for (final int i in _indices(spec, 'serial')) spec.slots[i].box,
      ];
      expect(boxes.first.left, 140, reason: spec.id);
      expect(boxes.last.left + boxes.last.width, 530, reason: spec.id);
    }
  });

  group('the geometry lookups', () {
    test('car() and moto() return the geometry maps', () {
      expect(
        YemenNorthernPlates.car(governorateDigits: 2, serialDigits: 5),
        same(YemenNorthernPlates.carGov2Serial5),
      );
      expect(
        YemenNorthernPlates.car(governorateDigits: 1, serialDigits: 4),
        isNull,
      );
      expect(
        YemenNorthernPlates.moto(governorateDigits: 2, serialDigits: 5),
        isNotNull,
      );
      expect(
        YemenUnifiedPlates.car(numberDigits: 5),
        same(YemenUnifiedPlates.car5),
      );
      expect(YemenUnifiedPlates.car(numberDigits: 7), isNull);
      expect(
        YemenUnifiedPlates.moto(numberDigits: 4),
        same(YemenUnifiedPlates.moto4),
      );
    });
  });

  group('the usage axis is a country block, not a spec', () {
    test('every issued northern usage resolves to a block', () {
      for (final YemenUsage usage in YemenUsage.northern) {
        expect(YemenCountry.northernFor(usage), isNotNull, reason: usage.name);
      }
    });

    test('every issued unified usage resolves to its own caption lines', () {
      final Set<List<String>> captions = <List<String>>{};
      for (final YemenUsage usage in YemenUsage.unified) {
        final PlateCountry country = YemenCountry.unifiedFor(usage);
        expect(country.captionLines, isNotEmpty, reason: usage.name);
        expect(country.captionLines.first, usage.unifiedArabic);
        captions.add(country.captionLines);
      }
      expect(captions.length, YemenUsage.unified.length);
    });

    test('a spec defaults to private, so an un-overridden canvas is sane', () {
      for (final PlateSpec spec in _unifiedSpecs) {
        expect(
          spec.country,
          same(YemenCountry.unifiedPrivate),
          reason: spec.id,
        );
      }
      for (final PlateSpec spec in _northernSpecs) {
        expect(
          spec.country,
          same(YemenCountry.northernPrivate),
          reason: spec.id,
        );
      }
    });
  });
}
