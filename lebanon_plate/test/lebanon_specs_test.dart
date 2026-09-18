import 'package:core_plate/core_plate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebanon_plate/lebanon_plate.dart';

/// Every spec this package ships, so a `debugValidateSpec` failure names the
/// plate it came from.
Iterable<PlateSpec> _allSpecs() sync* {
  yield* LebanonPlates.oneLineGeometries.values;
  yield* LebanonPlates.twoLineGeometries.values;
}

void main() {
  group('spec consistency', () {
    for (final PlateSpec spec in _allSpecs()) {
      test('${spec.id} passes debugValidateSpec', () {
        expect(() => debugValidateSpec(spec), returnsNormally);
      });
    }

    test('every spec id is unique', () {
      final List<String> ids = _allSpecs().map((PlateSpec s) => s.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('the standard geometries are the six-digit ones, by identity', () {
      // Identity, not equality: a `PlateCanvas` handed a different instance
      // with a different id treats it as a spec change and migrates the value.
      expect(LebanonPlates.oneLineOf(digits: 6), same(LebanonPlates.oneLine));
      expect(LebanonPlates.twoLineOf(digits: 6), same(LebanonPlates.twoLine));
      expect(LebanonPlates.oneLineOf(digits: 7), isNull);
      expect(LebanonPlates.oneLineOf(digits: 0), isNull);
    });

    test('every spec is a letter slot followed by digit slots', () {
      for (final PlateSpec spec in _allSpecs()) {
        expect(spec.slots.first.alphabet, same(LebanonAlphabets.letters), reason: spec.id);
        for (final PlateSlot slot in spec.slots.skip(1)) {
          expect(slot.alphabet, same(LebanonAlphabets.digits), reason: spec.id);
        }
      }
    });

    test('the letter and serial groups cover every slot exactly once', () {
      for (final PlateSpec spec in _allSpecs()) {
        final List<int> letter = spec.indicesOfGroup('letter');
        final List<int> serial = spec.indicesOfGroup('serial');
        expect(letter, <int>[0], reason: spec.id);
        expect(<int>[...letter, ...serial], List<int>.generate(spec.slots.length, (int i) => i), reason: spec.id);
      }
    });

    test('the band is the same blue on every plate', () {
      // Lebanon colour-codes the field, not the band. A panel colour that
      // varied by usage would be inventing a system.
      for (final PlateSpec spec in _allSpecs()) {
        expect(spec.country.panelColor, LebanonColors.band, reason: spec.id);
      }
      for (final LebanonUsage usage in LebanonUsage.values) {
        expect(LebanonCountry.forUsage(usage).panelColor, LebanonColors.band);
      }
    });

    test('no spec ships a flag, and no panel reserves room for one', () {
      for (final PlateSpec spec in _allSpecs()) {
        expect(spec.country.flag, isNull, reason: spec.id);
        expect(spec.panel.flagScale, 0, reason: spec.id);
      }
    });
  });

  group('alphabets', () {
    test('the letter alphabet is exactly the enum, in order', () {
      expect(LebanonAlphabets.letters.characters, LebanonLetter.values.map((LebanonLetter l) => l.character).toList());
    });

    test('the letter alphabet is chosen, because MP is two glyphs', () {
      expect(LebanonAlphabets.letters.input, AlphabetInput.chosen);
      expect(LebanonAlphabets.letters.characters, contains('MP'));
    });
  });

  group('letters', () {
    test('fromCharacter is case-insensitive and round-trips every letter', () {
      for (final LebanonLetter letter in LebanonLetter.values) {
        expect(LebanonLetter.fromCharacter(letter.character), letter);
        expect(LebanonLetter.fromCharacter(letter.character.toLowerCase()), letter);
      }
      expect(LebanonLetter.fromCharacter('Q'), isNull);
      expect(LebanonLetter.fromCharacter(''), isNull);
    });

    test('K is the only letter documented as out of service', () {
      expect(LebanonLetter.values.where((LebanonLetter l) => !l.inUse), <LebanonLetter>[LebanonLetter.k]);
    });

    test('a town code carries a governorate, and a class letter carries neither', () {
      for (final LebanonLetter letter in LebanonLetter.values) {
        expect(letter.governorate != null, letter.isTownCode, reason: letter.character);
      }
      expect(LebanonLetter.townCodes, isNot(contains(LebanonLetter.mp)));
      expect(LebanonLetter.townCodes, contains(LebanonLetter.b));
    });
  });

  group('themes', () {
    test('every usage resolves to a theme, and private is the only white one', () {
      for (final LebanonUsage usage in LebanonUsage.values) {
        expect(LebanonThemes.forUsage(usage).plateBackground, isNotNull);
      }
      expect(LebanonThemes.forUsage(LebanonUsage.private).plateBackground, LebanonColors.white);
      for (final LebanonUsage usage in LebanonUsage.coloured) {
        expect(LebanonThemes.forUsage(usage).plateBackground, isNot(LebanonColors.white), reason: usage.name);
      }
    });

    test('the frame is black on every field, including the dark ones', () {
      for (final LebanonUsage usage in LebanonUsage.values) {
        expect(LebanonThemes.forUsage(usage).plateBorder, LebanonColors.frame, reason: usage.name);
      }
    });

    test('a dark field takes light ink and a light field takes dark ink', () {
      const Set<LebanonUsage> lightInk = <LebanonUsage>{
        LebanonUsage.consular,
        LebanonUsage.publicInstitution,
        LebanonUsage.publicTransport,
        LebanonUsage.transit,
        LebanonUsage.temporary,
      };
      for (final LebanonUsage usage in LebanonUsage.values) {
        expect(
          LebanonThemes.forUsage(usage).ink,
          lightInk.contains(usage) ? LebanonColors.lightInk : LebanonColors.darkInk,
          reason: usage.name,
        );
      }
    });

    test('the theme ratios match the ones baked into the specs', () {
      for (final PlateSpec spec in _allSpecs()) {
        expect(spec.borderWidthRatioOverride, LebanonThemes.private.borderWidthRatio, reason: spec.id);
      }
    });
  });

  group('usage', () {
    test('private is the only white class', () {
      expect(LebanonUsage.values.where((LebanonUsage u) => u.isWhite), <LebanonUsage>[LebanonUsage.private]);
      expect(LebanonUsage.coloured, LebanonUsage.values.toSet().difference(<LebanonUsage>{LebanonUsage.private}));
    });

    test('every letter a usage fixes is a letter the alphabet accepts', () {
      for (final LebanonUsage usage in LebanonUsage.values) {
        if (usage.letter == null) continue;
        expect(LebanonLetter.fromCharacter(usage.letter!), isNotNull, reason: usage.name);
      }
    });

    test('M is shared by two usages, which is why colour is the other axis', () {
      final List<LebanonUsage> m = LebanonUsage.values.where((LebanonUsage u) => u.letter == 'M').toList();
      expect(m, <LebanonUsage>[LebanonUsage.publicInstitution, LebanonUsage.drivingSchool]);
      expect(LebanonThemes.forUsage(m.first).plateBackground, isNot(LebanonThemes.forUsage(m.last).plateBackground));
    });
  });
}
