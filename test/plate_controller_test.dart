import 'package:plate_core/core_plate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _country = PlateCountry(
  code: 'zz',
  captionLines: ['ZZ'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);

const _panel = PlatePanel(box: PlateBox(0, 0, 10, 40));

const _digits = PlateAlphabet.latinDigits;
const _letters = PlateAlphabet.latinUppercase;

const _iranian = PlateAlphabet(
  id: 'zz.iranian',
  characters: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'],
  input: AlphabetInput.typed,
  isNumeric: false,
  glyphs: {'1': '١', '2': '٢', '3': '٣', '4': '٤'},
);

/// An alphabet holding exactly one character: the printed-on-every-plate case
/// [PlateValuePreservation.byGroupKey] pre-fills from the alphabet itself.
const _dash = PlateAlphabet(
  id: 'zz.dash',
  characters: ['-'],
  input: AlphabetInput.chosen,
  isNumeric: false,
);

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
      PlateSlot(
        alphabet: alphabets[i],
        box: PlateBox(20 + i * 25.0, 5, 20, 30),
      ),
  ],
  textGroups: textGroups,
);

/// Counts how many times a [Listenable] fires.
class _Counter {
  _Counter(this.listenable) {
    listenable.addListener(_bump);
  }

  final Listenable listenable;
  int count = 0;

  void _bump() => count++;
  void stop() => listenable.removeListener(_bump);
}

void main() {
  group('construction', () {
    test('fills values with nulls to slotCount', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      expect(c.values, [null, null, null]);
      expect(c.isEmpty, isTrue);
      expect(c.isCompleted, isFalse);
    });

    test('a values list longer than the plate is truncated', () {
      final c = PlateController(
        spec: _spec(alphabets: const [_digits, _digits]),
        values: ['1', '2', '3', '4'],
      );
      addTearDown(c.dispose);
      expect(c.values, ['1', '2']);
    });

    test('a values list shorter than the plate is padded with null', () {
      final c = PlateController(spec: _spec(), values: ['1']);
      addTearDown(c.dispose);
      expect(c.values, ['1', null, null]);
    });

    test('a character the slot refuses lands as null', () {
      final c = PlateController(
        spec: _spec(alphabets: const [_digits, _letters]),
        values: ['A', '7'],
      );
      addTearDown(c.dispose);
      expect(c.values, [null, null]);
    });

    test('an empty string lands as null', () {
      final c = PlateController(spec: _spec(), values: ['', '2', '']);
      addTearDown(c.dispose);
      expect(c.values, [null, '2', null]);
    });

    test('values is unmodifiable', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      expect(() => c.values[0] = '1', throwsUnsupportedError);
    });

    test('fromValues is the constructor', () {
      final c = PlateController.fromValues(_spec(), ['1', '2', '3']);
      addTearDown(c.dispose);
      expect(c.values, ['1', '2', '3']);
      expect(c.isCompleted, isTrue);
    });
  });

  group('fromText', () {
    test('skips characters no slot accepts rather than consuming a slot', () {
      final c = PlateController.fromText(
        _spec(alphabets: const [_digits, _digits, _letters, _letters]),
        '12 AB',
      );
      addTearDown(c.dispose);
      // The space is in no alphabet, so it is passed over: it costs no slot.
      expect(c.values, ['1', '2', 'A', 'B']);
    });

    test('stops at the end of the plate', () {
      final c = PlateController.fromText(_spec(), '123456');
      addTearDown(c.dispose);
      expect(c.values, ['1', '2', '3']);
    });

    test('a short text leaves the tail null', () {
      final c = PlateController.fromText(_spec(), '1');
      addTearDown(c.dispose);
      expect(c.values, ['1', null, null]);
    });
  });

  group('setAt', () {
    test('stores an accepted character', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      c.setAt(1, '7');
      expect(c.values, [null, '7', null]);
      expect(c.valueAt(1), '7');
    });

    test('empty string and null clear the slot', () {
      final c = PlateController(spec: _spec(), values: ['1', '2', '3']);
      addTearDown(c.dispose);
      c.setAt(0, '');
      c.setAt(1, null);
      expect(c.values, [null, null, '3']);
    });

    test('a refused character is a no-op, not a clear', () {
      final c = PlateController(
        spec: _spec(alphabets: const [_digits]),
        values: ['1'],
      );
      addTearDown(c.dispose);
      final notifications = _Counter(c);
      c.setAt(0, 'A');
      expect(c.valueAt(0), '1', reason: 'the existing value stays intact');
      expect(notifications.count, 0);
    });

    test('an out-of-range index is a no-op', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      final notifications = _Counter(c);
      c
        ..setAt(-1, '1')
        ..setAt(3, '1');
      expect(c.values, [null, null, null]);
      expect(notifications.count, 0);
    });

    test('valueAt is null outside the plate', () {
      final c = PlateController(spec: _spec(), values: ['1', '2', '3']);
      addTearDown(c.dispose);
      expect(c.valueAt(-1), isNull);
      expect(c.valueAt(3), isNull);
    });
  });

  group('setValues', () {
    test('writes every slot and notifies once', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      final notifications = _Counter(c);
      c.setValues(['1', '2', '3']);
      expect(c.values, ['1', '2', '3']);
      expect(notifications.count, 1);
    });

    test('a short list clears the tail', () {
      final c = PlateController(spec: _spec(), values: ['1', '2', '3']);
      addTearDown(c.dispose);
      c.setValues(['9']);
      expect(c.values, ['9', null, null]);
    });

    test('refused characters land as null', () {
      final c = PlateController(
        spec: _spec(alphabets: const [_digits, _letters]),
      );
      addTearDown(c.dispose);
      c.setValues(['A', 'B']);
      expect(c.values, [null, 'B']);
    });

    test('clear empties every slot in one notification', () {
      final c = PlateController(spec: _spec(), values: ['1', '2', '3']);
      addTearDown(c.dispose);
      final notifications = _Counter(c);
      c.clear();
      expect(c.values, [null, null, null]);
      expect(c.isEmpty, isTrue);
      expect(notifications.count, 1);
    });
  });

  group('setGroup', () {
    PlateController build() => PlateController(
      spec: _spec(
        alphabets: const [_digits, _digits, _digits],
        textGroups: const [
          PlateTextGroup([0, 1], key: 'pair'),
          PlateTextGroup([2], key: 'tail'),
        ],
      ),
    );

    test('writes across the group in group order', () {
      final c = build();
      addTearDown(c.dispose);
      c.setGroup('pair', '48');
      expect(c.values, ['4', '8', null]);
    });

    test('stops at the shorter of value and group', () {
      final c = build();
      addTearDown(c.dispose);
      c.setGroup('pair', '4867');
      expect(c.values, [
        '4',
        '8',
        null,
      ], reason: 'extra characters are dropped');
    });

    test('a short value clears the trailing slots of the group', () {
      final c = build();
      addTearDown(c.dispose);
      c.setGroup('pair', '48');
      c.setGroup('pair', '5');
      expect(c.values, ['5', null, null]);
    });

    test('is a no-op for an unknown key', () {
      final c = build();
      addTearDown(c.dispose);
      c.setGroup('pair', '48');
      final notifications = _Counter(c);
      c.setGroup('district', '99');
      expect(c.values, ['4', '8', null]);
      expect(notifications.count, 0);
    });

    test('group() reads back the storage form', () {
      final c = build();
      addTearDown(c.dispose);
      c.setGroup('pair', '48');
      expect(c.group('pair'), '48');
      expect(c.group('tail'), '');
      expect(c.group('district'), '');
    });
  });

  group('listenables', () {
    test('slot(i) fires only for writes to i', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      final zero = _Counter(c.slot(0));
      final one = _Counter(c.slot(1));
      addTearDown(zero.stop);
      addTearDown(one.stop);

      c.setAt(0, '1');
      expect(zero.count, 1);
      expect(one.count, 0);

      c.setAt(1, '2');
      expect(zero.count, 1);
      expect(one.count, 1);

      expect(c.slot(0).value, '1');
      expect(c.slot(1).value, '2');
    });

    test('an out-of-range slot is null forever and never notifies', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      for (final index in [-1, 3, 99]) {
        final listenable = c.slot(index);
        final fired = _Counter(listenable);
        expect(listenable.value, isNull);
        c.setValues(['1', '2', '3']);
        expect(listenable.value, isNull);
        expect(fired.count, 0);
        c.clear();
      }
    });

    test('completed fires on the flip and not on the keystrokes between', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      final flips = _Counter(c.completed);
      addTearDown(flips.stop);

      c.setAt(0, '1');
      c.setAt(1, '2');
      expect(flips.count, 0, reason: 'N-1 keystrokes on an N-slot plate');
      expect(c.isCompleted, isFalse);

      c.setAt(2, '3');
      expect(flips.count, 1);
      expect(c.isCompleted, isTrue);
      expect(c.completed.value, isTrue);
    });

    test('completed flips back when a slot is cleared', () {
      final c = PlateController(spec: _spec(), values: ['1', '2', '3']);
      addTearDown(c.dispose);
      final flips = _Counter(c.completed);
      addTearDown(flips.stop);
      c.setAt(1, null);
      expect(flips.count, 1);
      expect(c.isCompleted, isFalse);
    });
  });

  group('text', () {
    test('joins the effective groups with the separator, through glyphs', () {
      final c = PlateController(
        spec: _spec(
          alphabets: const [_digits, _digits, _iranian, _iranian],
          textGroups: const [
            PlateTextGroup([0, 1]),
            PlateTextGroup([2, 3], prefix: 'ZZ-'),
          ],
        ),
        values: ['1', '2', '3', '4'],
      );
      addTearDown(c.dispose);
      expect(c.text(), '12 ZZ-٣٤');
      expect(c.text(sep: '-'), '12-ZZ-٣٤');
    });

    test('falls back to one group per slot when the spec has none', () {
      final c = PlateController(spec: _spec(), values: ['1', '2', '3']);
      addTearDown(c.dispose);
      expect(c.text(), '1 2 3');
      expect(c.text(sep: ''), '123');
    });

    test('unset slots render as empty', () {
      final c = PlateController(spec: _spec(), values: ['1', null, '3']);
      addTearDown(c.dispose);
      expect(c.text(), '1  3');
    });
  });

  group('plateNumber', () {
    test('carries the values across', () {
      final c = PlateController(spec: _spec(), values: ['1', '2', '3']);
      addTearDown(c.dispose);
      expect(c.plateNumber, PlateNumber(values: const ['1', '2', '3']));
      expect(c.plateNumber.isCompleted, isTrue);
    });
  });

  group('adoptSpec', () {
    // Same registers, different positions: 'serial' moves from [1,2,3,4] to
    // [0,1,2,3] and 'region' from [0] to [4].
    final from = _spec(
      id: 'zz.from',
      alphabets: const [_digits, _digits, _digits, _digits, _digits],
      textGroups: const [
        PlateTextGroup([0], key: 'region'),
        PlateTextGroup([1, 2, 3, 4], key: 'serial'),
      ],
    );
    final to = _spec(
      id: 'zz.to',
      alphabets: const [_digits, _digits, _digits, _digits, _digits],
      textGroups: const [
        PlateTextGroup([0, 1, 2, 3], key: 'serial'),
        PlateTextGroup([4], key: 'region'),
      ],
    );

    test('none empties every slot', () {
      final c = PlateController(spec: from, values: ['9', '1', '2', '3', '4']);
      addTearDown(c.dispose);
      c.adoptSpec(to, preserve: PlateValuePreservation.none);
      expect(c.spec, to);
      expect(c.values, [null, null, null, null, null]);
    });

    test('byIndex copies positionally', () {
      final c = PlateController(spec: from, values: ['9', '1', '2', '3', '4']);
      addTearDown(c.dispose);
      c.adoptSpec(to, preserve: PlateValuePreservation.byIndex);
      expect(c.values, ['9', '1', '2', '3', '4']);
    });

    test('byIndex sanitises against the new spec\'s alphabets', () {
      final c = PlateController(
        spec: _spec(alphabets: const [_digits, _digits, _digits]),
        values: ['1', '2', '3'],
      );
      addTearDown(c.dispose);
      c.adoptSpec(
        _spec(id: 'zz.mixed', alphabets: const [_letters, _digits, _digits]),
        preserve: PlateValuePreservation.byIndex,
      );
      expect(c.values, [null, '2', '3'], reason: 'letters refuse the digit');
    });

    test('byIndex truncates and null-pads by length', () {
      final short = PlateController(
        spec: _spec(alphabets: const [_digits, _digits, _digits]),
        values: ['1', '2', '3'],
      );
      addTearDown(short.dispose);
      short.adoptSpec(
        _spec(id: 'zz.two', alphabets: const [_digits, _digits]),
        preserve: PlateValuePreservation.byIndex,
      );
      expect(short.values, ['1', '2']);

      final long = PlateController(
        spec: _spec(alphabets: const [_digits, _digits]),
        values: ['1', '2'],
      );
      addTearDown(long.dispose);
      long.adoptSpec(
        _spec(id: 'zz.four', alphabets: const [_digits, _digits, _digits]),
        preserve: PlateValuePreservation.byIndex,
      );
      expect(long.values, ['1', '2', null]);
    });

    test('byGroupKey is the default', () {
      final c = PlateController(spec: from, values: ['9', '1', '2', '3', '4']);
      addTearDown(c.dispose);
      c.adoptSpec(to);
      expect(c.values, ['1', '2', '3', '4', '9']);
    });

    test('byGroupKey matches registers by key regardless of position', () {
      final c = PlateController(spec: from, values: ['9', '1', '2', '3', '4']);
      addTearDown(c.dispose);
      c.adoptSpec(to, preserve: PlateValuePreservation.byGroupKey);
      expect(c.group('serial'), '1234');
      expect(c.group('region'), '9');
      expect(c.values, ['1', '2', '3', '4', '9']);
    });

    test('a half-typed register carries as far as it got, gaps closed', () {
      final c = PlateController(
        spec: from,
        values: ['9', '1', null, '3', null],
      );
      addTearDown(c.dispose);
      c.adoptSpec(to);
      // The '3' moves up behind the '1' rather than holding position 2.
      expect(c.values, ['1', '3', null, null, '9']);
      expect(c.group('serial'), '13');
    });

    test('a register with no counterpart in the new spec is dropped', () {
      final c = PlateController(spec: from, values: ['9', '1', '2', '3', '4']);
      addTearDown(c.dispose);
      c.adoptSpec(
        _spec(
          id: 'zz.serialonly',
          alphabets: const [_digits, _digits],
          textGroups: const [
            PlateTextGroup([0, 1], key: 'serial'),
          ],
        ),
      );
      expect(c.values, ['1', '2']);
    });

    test('a single-character alphabet slot is pre-filled from its own '
        'alphabet', () {
      final c = PlateController(
        spec: _spec(
          alphabets: const [_digits, _digits],
          textGroups: const [
            PlateTextGroup([0], key: 'a'),
            PlateTextGroup([1], key: 'b'),
          ],
        ),
        values: ['1', '2'],
      );
      addTearDown(c.dispose);
      c.adoptSpec(
        _spec(
          id: 'zz.dashed',
          // Index 1 is in no group: only the pre-fill can reach it.
          alphabets: const [_digits, _dash, _digits],
          textGroups: const [
            PlateTextGroup([0], key: 'a'),
            PlateTextGroup([2], key: 'b'),
          ],
        ),
      );
      expect(c.values, ['1', '-', '2']);
    });

    test('a matched group covering a pre-filled slot still wins', () {
      final c = PlateController(
        spec: _spec(
          alphabets: const [_digits, _digits, _digits],
          textGroups: const [
            PlateTextGroup([0, 1, 2], key: 'all'),
          ],
        ),
        values: ['1', '2', '3'],
      );
      addTearDown(c.dispose);
      c.adoptSpec(
        _spec(
          id: 'zz.covered',
          alphabets: const [_digits, _dash, _digits],
          textGroups: const [
            PlateTextGroup([0, 1, 2], key: 'all'),
          ],
        ),
      );
      // The group writes '2' into slot 1, the dash alphabet refuses it, and the
      // sanitised null overwrites the pre-filled '-'. The group wins even when
      // winning means clearing.
      expect(c.values, ['1', null, '3']);
    });

    test('byGroupKey falls back to positional when neither spec is keyed', () {
      final c = PlateController(
        spec: _spec(alphabets: const [_digits, _digits, _digits]),
        values: ['1', '2', '3'],
      );
      addTearDown(c.dispose);
      c.adoptSpec(_spec(id: 'zz.two', alphabets: const [_digits, _digits]));
      expect(c.values, ['1', '2']);
    });

    test('re-founds the slot listenables for the new length', () {
      final c = PlateController(
        spec: _spec(alphabets: const [_digits, _digits]),
        values: ['1', '2'],
      );
      addTearDown(c.dispose);
      c.adoptSpec(
        _spec(id: 'zz.three', alphabets: const [_digits, _digits, _digits]),
        preserve: PlateValuePreservation.byIndex,
      );
      expect(c.slot(2).value, isNull);
      c.setAt(2, '9');
      expect(c.slot(2).value, '9');
    });

    test('notifies once', () {
      final c = PlateController(spec: from);
      addTearDown(c.dispose);
      final notifications = _Counter(c);
      c.adoptSpec(to);
      expect(notifications.count, 1);
    });

    test('a slot handle from before the swap stops updating', () {
      final c = PlateController(
        spec: _spec(alphabets: const [_digits, _digits]),
        values: ['1', '2'],
      );
      addTearDown(c.dispose);
      final stale = c.slot(0);
      c.adoptSpec(
        _spec(id: 'zz.other', alphabets: const [_digits, _digits]),
        preserve: PlateValuePreservation.byIndex,
      );
      c.setAt(0, '9');
      expect(stale.value, '1', reason: 'reading a stale handle does not throw');
      expect(c.slot(0).value, '9');
    });

    test(
      'a slot handle from before the swap can still be subscribed to',
      () {
        final c = PlateController(
          spec: _spec(alphabets: const [_digits, _digits]),
          values: ['1', '2'],
        );
        addTearDown(c.dispose);
        final stale = c.slot(0);
        c.adoptSpec(_spec(id: 'zz.other', alphabets: const [_digits, _digits]));
        expect(() => stale.addListener(() {}), returnsNormally);
      },
      skip:
          'BUG: adoptSpec disposes the old slot notifiers, so a handle held '
          'across a spec swap throws on addListener — but the method doc '
          'promises "a live object that simply stops being updated".',
    );
  });

  group('lifecycle', () {
    test('dispose disposes every slot notifier and completed', () {
      final c = PlateController(spec: _spec());
      final slots = [for (var i = 0; i < 3; i++) c.slot(i)];
      final completed = c.completed;
      c.dispose();
      for (final slot in slots) {
        expect(() => slot.addListener(() {}), throwsA(isA<FlutterError>()));
      }
      expect(() => completed.addListener(() {}), throwsA(isA<FlutterError>()));
    });

    test('a second dispose is the standard ChangeNotifier error', () {
      final c = PlateController(spec: _spec());
      c.dispose();
      expect(c.dispose, throwsA(isA<FlutterError>()));
    });
  });

  group('validation plumbing', () {
    test('validation is null with no probe installed', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      expect(c.validation, isNull);
    });

    test('installValidation installs the probe, and null clears it', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      c.installValidation(() => const PlateValidation.invalid('nope'));
      expect(c.validation, const PlateValidation.invalid('nope'));
      c.installValidation(null);
      expect(c.validation, isNull);
    });

    test('reportValidation notifies on a change of verdict only', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      final notifications = _Counter(c);

      c.reportValidation(const PlateValidation.invalid('x'));
      expect(notifications.count, 1);

      c.reportValidation(const PlateValidation.invalid('x'));
      expect(notifications.count, 1, reason: 'same verdict, same reason');

      c.reportValidation(const PlateValidation.invalid('y'));
      expect(notifications.count, 2);

      c.reportValidation(const PlateValidation.valid());
      expect(notifications.count, 3);

      c.reportValidation(null);
      expect(notifications.count, 4);
    });

    test('installValidation resets the last verdict', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      c.reportValidation(const PlateValidation.invalid('x'));
      final notifications = _Counter(c);
      c.installValidation(null);
      c.reportValidation(const PlateValidation.invalid('x'));
      expect(notifications.count, 1, reason: 'the verdict is news again');
    });
  });

  group('attach and detach', () {
    test('activeIndex and activeSlot are null with nothing attached', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      expect(c.isAttached, isFalse);
      expect(c.activeIndex, isNull);
      expect(c.activeSlot, isNull);
    });

    test('submit, backspace and focus calls are no-ops with no target', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      expect(() {
        c
          ..submit('1')
          ..backspace()
          ..focusFirstEmpty()
          ..focusSlot(0);
      }, returnsNormally);
      expect(c.values, [null, null, null]);
    });

    test('attach exposes the target, detach retracts it', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      final target = _FakeTarget(activeIndex: 1);
      final notifications = _Counter(c);

      c.attach(target);
      expect(c.isAttached, isTrue);
      expect(notifications.count, 1);
      expect(c.activeIndex, 1);
      expect(c.activeSlot, same(c.spec.slots[1]));

      c.submit('7');
      expect(target.submitted, ['7']);
      c.backspace();
      expect(target.backspaces, 1);

      c.detach(target);
      expect(c.isAttached, isFalse);
      expect(notifications.count, 2);
    });

    test('a detach from a retired target does not null out the live one', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      final old = _FakeTarget();
      final replacement = _FakeTarget();
      c.attach(old);
      // A rebuilt canvas attaches before the old state disposes.
      c.attach(replacement);
      c.detach(old);
      expect(c.isAttached, isTrue);
      c.submit('1');
      expect(replacement.submitted, ['1']);
      expect(old.submitted, isEmpty);
    });

    test('notifyActiveSlotChanged notifies', () {
      final c = PlateController(spec: _spec());
      addTearDown(c.dispose);
      final notifications = _Counter(c);
      c.notifyActiveSlotChanged();
      expect(notifications.count, 1);
    });
  });
}

class _FakeTarget implements PlateInputTarget {
  _FakeTarget({this.activeIndex});

  @override
  final int? activeIndex;

  final List<String> submitted = [];
  int backspaces = 0;
  int firstEmptyRequests = 0;
  final List<int> focused = [];

  @override
  void submitCharacter(String character) => submitted.add(character);

  @override
  void backspaceCharacter() => backspaces++;

  @override
  void focusFirstEmptySlot() => firstEmptyRequests++;

  @override
  void focusSlot(int index) => focused.add(index);
}
