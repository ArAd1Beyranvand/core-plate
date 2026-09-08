import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A throwaway country: [PlateSpec] needs one, and nothing here reads it.
const _country = PlateCountry(
  code: 'zz',
  captionLines: ['ZZ'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);

const _panel = PlatePanel(box: PlateBox(0, 0, 10, 40));

/// Digits that print as their own characters.
const _digits = PlateAlphabet.latinDigits;

/// Digits stored as ASCII but printed as Eastern Arabic numerals — the
/// storage-vs-glyph split [PlateSpec.renderGroup] renders through.
const _easternDigits = PlateAlphabet(
  id: 'zz.eastern',
  characters: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
  input: AlphabetInput.typed,
  isNumeric: false,
  glyphs: {
    '0': '٠',
    '1': '١',
    '2': '٢',
    '3': '٣',
    '4': '٤',
    '5': '٥',
    '6': '٦',
    '7': '٧',
    '8': '٨',
    '9': '٩',
  },
);

PlateSlot _slot(PlateAlphabet alphabet, double left) =>
    PlateSlot(alphabet: alphabet, box: PlateBox(left, 5, 20, 30));

PlateSpec _spec({
  String id = 'zz.test',
  List<PlateAlphabet> alphabets = const [_digits, _digits, _digits],
  List<PlateTextGroup> textGroups = const [],
}) => PlateSpec(
  id: id,
  country: _country,
  canvasWidth: 400,
  canvasHeight: 100,
  panel: _panel,
  slots: [
    for (var i = 0; i < alphabets.length; i++)
      _slot(alphabets[i], 20 + i * 25.0),
  ],
  textGroups: textGroups,
);

void main() {
  group('slot access', () {
    test('slotCount tracks slots.length', () {
      expect(_spec().slotCount, 3);
      expect(_spec(alphabets: const [_digits]).slotCount, 1);
      expect(_spec(alphabets: const []).slotCount, 0);
    });

    test('slotAt returns null out of range at both ends', () {
      final spec = _spec();
      expect(spec.slotAt(-1), isNull);
      expect(spec.slotAt(3), isNull);
      expect(spec.slotAt(0), same(spec.slots.first));
      expect(spec.slotAt(2), same(spec.slots.last));
    });
  });

  group('effectiveTextGroups', () {
    test('returns textGroups when non-empty', () {
      const groups = [
        PlateTextGroup([0, 1], key: 'pair'),
        PlateTextGroup([2]),
      ];
      final spec = _spec(textGroups: groups);
      expect(spec.effectiveTextGroups, same(groups));
    });

    test('falls back to one single-index group per slot, in index order', () {
      final fallback = _spec().effectiveTextGroups;
      expect(fallback.map((g) => g.indices), [
        [0],
        [1],
        [2],
      ]);
      expect(fallback.every((g) => g.key == null), isTrue);
      expect(fallback.every((g) => g.prefix.isEmpty), isTrue);
    });

    test('fallback for an empty spec is empty', () {
      expect(_spec(alphabets: const []).effectiveTextGroups, isEmpty);
    });
  });

  group('groupAt', () {
    test('finds the containing group', () {
      final spec = _spec(
        textGroups: const [
          PlateTextGroup([0, 1], key: 'pair'),
          PlateTextGroup([2], key: 'tail'),
        ],
      );
      expect(spec.groupAt(0)?.key, 'pair');
      expect(spec.groupAt(1)?.key, 'pair');
      expect(spec.groupAt(2)?.key, 'tail');
    });

    test('returns null for an index in no group', () {
      final spec = _spec(
        textGroups: const [
          PlateTextGroup([0, 1], key: 'pair'),
        ],
      );
      expect(spec.groupAt(2), isNull);
      expect(spec.groupAt(-1), isNull);
      expect(spec.groupAt(99), isNull);
    });
  });

  group('renderGroup', () {
    test('applies each slot\'s own alphabet and prepends the prefix', () {
      final spec = _spec(
        alphabets: const [_digits, _easternDigits, _digits],
        textGroups: const [
          PlateTextGroup([0, 1, 2], prefix: 'ZZ-'),
        ],
      );
      expect(
        spec.renderGroup(spec.effectiveTextGroups.single, ['1', '2', '3']),
        'ZZ-1٢3',
      );
    });

    test('unset slots render as the empty string', () {
      final spec = _spec();
      expect(
        spec.renderGroup(const PlateTextGroup([0, 1, 2]), ['1', null, '3']),
        '13',
      );
    });

    test(
      'an index past values.length renders as empty rather than throwing',
      () {
        final spec = _spec();
        expect(spec.renderGroup(const PlateTextGroup([0, 1, 2]), ['1']), '1');
      },
    );

    test(
      'an index outside the plate renders as empty rather than throwing',
      () {
        final spec = _spec();
        expect(
          spec.renderGroup(const PlateTextGroup([0, 9]), ['1', '2', '3']),
          '1',
        );
      },
    );
  });

  group('valueOfGroup', () {
    test('returns storage form, not glyphs', () {
      final spec = _spec(
        alphabets: const [_easternDigits, _easternDigits, _easternDigits],
        textGroups: const [
          PlateTextGroup([0, 1, 2], prefix: 'ZZ-', key: 'serial'),
        ],
      );
      // Storage form: the ASCII the slots hold, without glyphs and without the
      // prefix — a validator reads characters, not a rendering.
      expect(spec.valueOfGroup('serial', ['1', '2', '3']), '123');
    });

    test('unset slots and short value lists contribute nothing', () {
      final spec = _spec(
        textGroups: const [
          PlateTextGroup([0, 1, 2], key: 'serial'),
        ],
      );
      expect(spec.valueOfGroup('serial', ['1', null, '3']), '13');
      expect(spec.valueOfGroup('serial', ['1']), '1');
    });

    test('returns empty for an absent key', () {
      final spec = _spec(
        textGroups: const [
          PlateTextGroup([0, 1, 2], key: 'serial'),
        ],
      );
      expect(spec.valueOfGroup('district', ['1', '2', '3']), '');
      // An unkeyed spec has no keyed groups by definition.
      expect(_spec().valueOfGroup('serial', ['1', '2', '3']), '');
    });
  });

  group('navigation', () {
    test('nextIndex returns null at the end and never wraps', () {
      final spec = _spec();
      expect(spec.nextIndex(0), 1);
      expect(spec.nextIndex(1), 2);
      expect(spec.nextIndex(2), isNull);
      expect(spec.nextIndex(-1), isNull);
      expect(spec.nextIndex(99), isNull);
    });

    test('previousIndex returns null at the start and never wraps', () {
      final spec = _spec();
      expect(spec.previousIndex(2), 1);
      expect(spec.previousIndex(1), 0);
      expect(spec.previousIndex(0), isNull);
      expect(spec.previousIndex(-1), isNull);
      expect(spec.previousIndex(99), isNull);
    });
  });

  group('model value types', () {
    test('PlateBox derives its edges and its rect', () {
      const box = PlateBox(10, 20, 30, 40);
      expect(box.right, 40);
      expect(box.bottom, 60);
      expect(box.rect, const Rect.fromLTWH(10, 20, 30, 40));
    });

    test('PlateAlphabet accepts, renders and compares over id', () {
      expect(_digits.accepts('4'), isTrue);
      expect(_digits.accepts('A'), isFalse);
      expect(_digits.render('4'), '4', reason: 'no glyphs: display == storage');
      expect(_easternDigits.render('4'), '٤');
      expect(_easternDigits.render('x'), 'x', reason: 'falls back to itself');

      // Ids are the identity: same id, different content, still equal — which
      // is exactly why debugValidateSpec polices ids against content.
      const twin = PlateAlphabet(
        id: 'latin.digits',
        characters: ['7'],
        input: AlphabetInput.chosen,
        isNumeric: true,
      );
      expect(_digits, equals(twin));
      expect(_digits.hashCode, twin.hashCode);
      expect(_digits, isNot(equals(_easternDigits)));
      expect(_digits, equals(_digits));
    });

    test('PlateCountry compares over code alone', () {
      const other = PlateCountry(
        code: 'zz',
        captionLines: ['ELSEWHERE'],
        panelColor: Color(0xFF000000),
        panelTextColor: Color(0xFF000000),
      );
      expect(_country, equals(other));
      expect(_country.hashCode, other.hashCode);
      expect(_country, equals(_country));
      expect(
        _country,
        isNot(
          equals(
            const PlateCountry(
              code: 'yy',
              captionLines: ['YY'],
              panelColor: Color(0xFF000000),
              panelTextColor: Color(0xFF000000),
            ),
          ),
        ),
      );
    });

    test('PlateNumber has value equality over its characters', () {
      final a = PlateNumber(values: const ['1', '2']);
      final b = PlateNumber(values: const ['1', '2']);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, equals(a));
      expect(a, isNot(equals(PlateNumber(values: const ['1', '3']))));
      expect(a.isCompleted, isTrue);
      expect(a.isEmpty, isFalse);
      expect(PlateNumber(values: const [null, null]).isEmpty, isTrue);
      expect(PlateNumber(values: const ['1', null]).isCompleted, isFalse);
    });

    test('PlateAsset carries the owning package, not the rendering one', () {
      const svg = SvgPlateAsset('flags/zz.svg', package: 'zz_plate');
      const raster = RasterPlateAsset('badges/zz.png', package: 'zz_plate');
      expect(svg.path, 'flags/zz.svg');
      expect(svg.package, 'zz_plate');
      expect(raster.path, 'badges/zz.png');
      expect(raster.package, 'zz_plate');
      expect(svg, isA<PlateAsset>());
    });

    test('chrome elements are plate-space geometry plus content', () {
      const rule = PlateRule(box: PlateBox(0, 0, 2, 40));
      const label = PlateLabel(
        text: 'ZZ',
        box: PlateBox(5, 5, 20, 10),
        glyphHeight: 10,
      );
      const decal = PlateDecal(
        image: AssetImage('badges/zz.png', package: 'zz_plate'),
        box: PlateBox(5, 20, 10, 10),
      );
      expect(rule.box.width, 2);
      expect(label.text, 'ZZ');
      expect(label.glyphHeight, 10);
      expect(decal.box.left, 5);
    });
  });

  group('equality', () {
    test('is over id alone', () {
      final a = _spec(id: 'zz.car');
      final b = _spec(
        id: 'zz.car',
        alphabets: const [_digits],
        textGroups: const [
          PlateTextGroup([0], key: 'other'),
        ],
      );
      expect(a.slotCount, isNot(b.slotCount));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differing ids are unequal', () {
      expect(_spec(id: 'zz.car'), isNot(equals(_spec(id: 'zz.bike'))));
    });
  });
}
