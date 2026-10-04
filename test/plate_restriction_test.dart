import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_core/plate_core.dart';

const _country = PlateCountry(
  code: 'zz',
  captionLines: ['ZZ'],
  panelColor: Color(0xFF003399),
  panelTextColor: Color(0xFFFFFFFF),
);

const _never = PlateRestriction(
  group: 'code',
  values: ['42'],
  reason: 'NO SUCH CODE',
);

/// Two-digit `code` register, then a one-digit `serial`.
const _spec = PlateSpec(
  id: 'zz.restricted',
  country: _country,
  canvasWidth: 120,
  canvasHeight: 40,
  panel: PlatePanel(box: PlateBox(0, 0, 10, 40)),
  slots: [
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: PlateBox(20, 0, 30, 40),
    ),
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: PlateBox(50, 0, 30, 40),
    ),
    PlateSlot(
      alphabet: PlateAlphabet.latinDigits,
      box: PlateBox(80, 0, 30, 40),
    ),
  ],
  textGroups: [
    PlateTextGroup([0, 1], key: 'code'),
    PlateTextGroup([2], key: 'serial'),
  ],
  restrictions: [_never],
);

class _Serial extends GatedPlateValidator {
  const _Serial();
  @override
  String get gateGroup => 'serial';
  @override
  PlateValidation judge(PlateEntry entry) => const PlateValidation.valid();
}

void main() {
  group('spec', () {
    test('restrictionViolatedBy matches the whole register', () {
      expect(_spec.restrictionViolatedBy(['4', null, null]), isNull);
      expect(_spec.restrictionViolatedBy(['4', '2', null]), _never);
      expect(_spec.restrictionViolatedBy(['4', '2', '7']), _never);
    });

    test('checkRestrictions throws with the reason', () {
      expect(
        () => _spec.checkRestrictions(['4', '2', '1']),
        throwsA(
          isA<PlateRestrictionException>().having(
            (e) => e.toString(),
            'reason',
            'NO SUCH CODE',
          ),
        ),
      );
      _spec.checkRestrictions(['4', '3', '1']);
    });

    test('debugValidateSpec refuses a restriction on a missing group', () {
      const bad = PlateSpec(
        id: 'zz.bad',
        country: _country,
        canvasWidth: 120,
        canvasHeight: 40,
        panel: PlatePanel(box: PlateBox(0, 0, 10, 40)),
        slots: [],
        restrictions: [_never],
      );
      expect(() => debugValidateSpec(bad), throwsAssertionError);
    });
  });

  group('controller', () {
    test('refuses the completing keystroke, either order', () {
      final c = PlateController(spec: _spec);
      expect(c.setAt(0, '4'), isTrue);
      expect(c.setAt(1, '2'), isFalse);
      expect(c.values, ['4', null, null]);
      expect(c.rejection.value, _never);

      final d = PlateController(spec: _spec);
      d.setAt(1, '2');
      expect(d.setAt(0, '4'), isFalse);
      expect(d.values, [null, '2', null]);
    });

    test('a stored write clears the rejection', () {
      final c = PlateController(spec: _spec)..setAt(0, '4');
      c.setAt(1, '2');
      expect(c.rejection.value, isNotNull);
      c.setAt(1, '3');
      expect(c.rejection.value, isNull);
    });

    test('setValues and setGroup refuse whole', () {
      final c = PlateController(spec: _spec);
      expect(c.setValues(['4', '2', '1']), isFalse);
      expect(c.values, [null, null, null]);
      expect(c.setGroup('code', '42'), isFalse);
      expect(c.values, [null, null, null]);
      expect(c.rejection.value, _never);
    });

    test('fromValues and fromText empty the restricted register', () {
      final a = PlateController.fromValues(_spec, ['4', '2', '1']);
      expect(a.values, [null, null, '1']);
      expect(a.rejection.value, _never);
      final b = PlateController.fromText(_spec, '42 1');
      expect(b.values, [null, null, '1']);
    });

    test('adoptSpec empties a register the new spec restricts', () {
      const open = PlateSpec(
        id: 'zz.open',
        country: _country,
        canvasWidth: 120,
        canvasHeight: 40,
        panel: PlatePanel(box: PlateBox(0, 0, 10, 40)),
        slots: [
          PlateSlot(
            alphabet: PlateAlphabet.latinDigits,
            box: PlateBox(20, 0, 30, 40),
          ),
          PlateSlot(
            alphabet: PlateAlphabet.latinDigits,
            box: PlateBox(50, 0, 30, 40),
          ),
          PlateSlot(
            alphabet: PlateAlphabet.latinDigits,
            box: PlateBox(80, 0, 30, 40),
          ),
        ],
        textGroups: [
          PlateTextGroup([0, 1], key: 'code'),
          PlateTextGroup([2], key: 'serial'),
        ],
      );
      final c = PlateController(spec: open, values: ['4', '2', '1']);
      expect(c.values, ['4', '2', '1']);
      c.adoptSpec(_spec);
      expect(c.values, [null, null, '1']);
      expect(c.rejection.value, _never);
    });
  });

  test('a gated validator reports the restriction before its gate', () {
    final entry = PlateEntry(spec: _spec, values: const ['4', '2', null]);
    expect(const _Serial().validate(entry).reason, 'NO SUCH CODE');
  });

  testWidgets('canvas refuses typing, does not advance, shows the reason', (
    tester,
  ) async {
    final c = PlateController(spec: _spec);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 120,
            child: PlateCanvas(
              spec: _spec,
              controller: c,
              inputSource: PlateInputSource.host,
              onChooseCharacter: (_) async => null,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    c.focusSlot(0);
    await tester.pump();
    c.submit('4');
    await tester.pump();
    expect(c.activeIndex, 1);
    expect(find.text('NO SUCH CODE'), findsNothing);

    c.submit('2');
    await tester.pump();
    expect(c.values, ['4', null, null]);
    expect(c.activeIndex, 1);
    expect(find.text('NO SUCH CODE'), findsOneWidget);
    expect(c.validation?.reason, 'NO SUCH CODE');

    c.submit('3');
    await tester.pump();
    expect(find.text('NO SUCH CODE'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    c.dispose();
  });
}
