import 'dart:math';

import 'package:plate_core/plate_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebanon_plate/lebanon_plate.dart';

void main() {
  group('LebanonSerialGenerator', () {
    test(
      'fills every slot of every geometry with something the validator accepts',
      () {
        final Random rnd = Random(7);
        for (final PlateSpec spec in <PlateSpec>[
          ...LebanonPlates.oneLineGeometries.values,
          ...LebanonPlates.twoLineGeometries.values,
        ]) {
          for (final List<String?> values
              in LebanonSerialGenerator.generateMany(spec, 40, random: rnd)) {
            expect(values, hasLength(spec.slots.length), reason: spec.id);
            expect(
              values.any((String? v) => v == null),
              isFalse,
              reason: spec.id,
            );
            expect(
              const LebanonValidator()
                  .validate(PlateEntry(spec: spec, values: values))
                  .isValid,
              isTrue,
              reason: '${spec.id} $values',
            );
          }
        }
      },
    );

    test('is repeatable for a given seed', () {
      final List<String?> a = LebanonSerialGenerator.generate(
        LebanonPlates.oneLine,
        random: Random(11),
      );
      final List<String?> b = LebanonSerialGenerator.generate(
        LebanonPlates.oneLine,
        random: Random(11),
      );
      expect(a, b);
    });

    test('never draws the letter that is out of service', () {
      final Random rnd = Random(3);
      for (final List<String?> values in LebanonSerialGenerator.generateMany(
        LebanonPlates.oneLine,
        200,
        random: rnd,
      )) {
        expect(values.first, isNot('K'));
      }
    });

    test('honours a fixed letter', () {
      final List<String?> values = LebanonSerialGenerator.generate(
        LebanonPlates.twoLine,
        random: Random(1),
        letter: LebanonLetter.z,
      );
      expect(values.first, 'Z');
    });

    test('takes the letter from a usage that fixes one', () {
      final List<String?> values = LebanonSerialGenerator.generate(
        LebanonPlates.oneLine,
        random: Random(1),
        usage: LebanonUsage.diplomatic,
      );
      expect(values.first, 'D');
    });

    test('a usage that fixes no letter leaves the draw alone', () {
      final List<String?> values = LebanonSerialGenerator.generate(
        LebanonPlates.oneLine,
        random: Random(1),
        usage: LebanonUsage.private,
      );
      expect(LebanonLetter.fromCharacter(values.first!), isNotNull);
    });

    test('refuses a letter and a letter-fixing usage at once', () {
      expect(
        () => LebanonSerialGenerator.generate(
          LebanonPlates.oneLine,
          letter: LebanonLetter.b,
          usage: LebanonUsage.consular,
        ),
        throwsArgumentError,
      );
    });

    test('keeps a parliament number inside 1..128', () {
      final Random rnd = Random(5);
      for (final List<String?> values in LebanonSerialGenerator.generateMany(
        LebanonPlates.oneLine,
        100,
        random: rnd,
        letter: LebanonLetter.mp,
      )) {
        final String serial = LebanonPlates.oneLine
            .indicesOfGroup('serial')
            .map((int i) => values[i] ?? '')
            .join();
        expect(
          int.parse(serial),
          inInclusiveRange(1, LebanonValidator.maxParliamentNumber),
        );
      }
    });

    test('throws on a spec that is not one of ours', () {
      const PlateSpec foreign = PlateSpec(
        id: 'xx.none',
        country: LebanonCountry.band,
        canvasWidth: 100,
        canvasHeight: 50,
        panel: PlatePanel(box: PlateBox(0, 0, 10, 50)),
        slots: <PlateSlot>[
          PlateSlot(
            alphabet: LebanonAlphabets.digits,
            box: PlateBox(20, 5, 20, 40),
          ),
        ],
      );
      expect(
        () => LebanonSerialGenerator.generate(foreign),
        throwsArgumentError,
      );
    });
  });
}
