import 'package:core_plate/core_plate.dart';
import 'package:core_plate/src/input/plate_input_machine.dart';
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

/// Characters that are not on a normal keyboard, so they are picked rather
/// than typed — the slots that have no [TextEditingController].
const _chosen = PlateAlphabet(
  id: 'zz.chosen',
  characters: ['ا', 'ب', 'ج'],
  input: AlphabetInput.chosen,
  isNumeric: false,
);

PlateSpec _spec({
  String id = 'zz.test',
  List<PlateAlphabet> alphabets = const [_digits, _digits, _digits],
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
);

/// A machine plus the host state it reads and writes, so a test can assert on
/// what was committed rather than on a controller's internals.
class _Harness {
  _Harness({
    required PlateSpec spec,
    List<String?>? values,
    PlateInputSource inputSource = PlateInputSource.host,
  }) : values = values ?? List<String?>.filled(spec.slotCount, null) {
    machine = PlateInputMachine(
      spec: spec,
      readValues: () => this.values,
      commit: (index, value) {
        commits.add((index, value));
        this.values[index] = value.isEmpty ? null : value;
      },
      inputSource: inputSource,
      onActiveIndexChanged: activeChanges.add,
    );
  }

  final List<String?> values;
  final List<(int, String)> commits = [];
  final List<int?> activeChanges = [];
  final List<int> sheetRequests = [];

  late final PlateInputMachine machine;

  /// Puts every slot's focus node in the tree, which is what makes
  /// `requestFocus` and `unfocus` mean anything.
  Future<void> mount(WidgetTester tester) async {
    machine.onSheetRequested = sheetRequests.add;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            for (var i = 0; i < machine.spec.slotCount; i++)
              Focus(
                focusNode: machine.focusNodeAt(i),
                child: const SizedBox(width: 10, height: 10),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> focus(WidgetTester tester, int index) async {
    machine.focusSlot(index);
    await tester.pump();
  }

  /// Takes the plate out of the tree before disposing, so the framework never
  /// touches a disposed [FocusNode] on the way down.
  Future<void> retire(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    machine.dispose();
  }
}

void main() {
  group('construction', () {
    testWidgets('seeds activeIndex to 0 and does not announce it', (
      tester,
    ) async {
      final h = _Harness(spec: _spec());
      expect(h.machine.activeIndex, 0);
      expect(
        h.activeChanges,
        isEmpty,
        reason: 'the seed is reported by the canvas post-frame, not from here',
      );
      h.machine.dispose();
    });

    testWidgets('seeds activeIndex to null for an empty spec', (tester) async {
      final h = _Harness(spec: _spec(alphabets: const []));
      expect(h.machine.activeIndex, isNull);
      expect(h.activeChanges, isEmpty);
      h.machine.dispose();
    });

    testWidgets('controllerAt is a field for typed slots and null for chosen', (
      tester,
    ) async {
      final h = _Harness(
        spec: _spec(alphabets: const [_digits, _chosen, _digits]),
      );
      expect(h.machine.controllerAt(0), isA<TextEditingController>());
      expect(h.machine.controllerAt(1), isNull);
      expect(h.machine.controllerAt(2), isA<TextEditingController>());
      h.machine.dispose();
    });

    testWidgets('focusNodeAt is never null, and one node per slot', (
      tester,
    ) async {
      final h = _Harness(
        spec: _spec(alphabets: const [_digits, _chosen, _digits]),
      );
      final nodes = {for (var i = 0; i < 3; i++) h.machine.focusNodeAt(i)};
      expect(nodes, hasLength(3));
      h.machine.dispose();
    });
  });

  group('submitCharacter', () {
    testWidgets('commits to the active slot and advances', (tester) async {
      final h = _Harness(spec: _spec());
      await h.mount(tester);

      h.machine.submitCharacter('7');
      await tester.pump();

      expect(h.commits, [(0, '7')]);
      expect(h.values, ['7', null, null]);
      expect(h.machine.activeIndex, 1);
      expect(h.activeChanges, [1]);

      await h.retire(tester);
    });

    testWidgets('a character the active slot refuses is a no-op', (
      tester,
    ) async {
      final h = _Harness(spec: _spec());
      await h.mount(tester);

      h.machine.submitCharacter('A');
      await tester.pump();

      expect(h.commits, isEmpty);
      expect(h.machine.activeIndex, 0, reason: 'no advance either');
      expect(h.activeChanges, isEmpty);

      await h.retire(tester);
    });

    testWidgets('is a no-op with no active slot', (tester) async {
      final h = _Harness(spec: _spec(alphabets: const []));
      h.machine.submitCharacter('7');
      expect(h.commits, isEmpty);
      h.machine.dispose();
    });
  });

  group('backspaceCharacter', () {
    testWidgets('clears a non-empty active slot in place', (tester) async {
      final h = _Harness(spec: _spec(), values: ['1', '2', '3']);
      await h.mount(tester);
      await h.focus(tester, 1);

      h.machine.backspaceCharacter();
      await tester.pump();

      expect(h.commits, [(1, '')]);
      expect(h.values, ['1', null, '3']);
      expect(h.machine.activeIndex, 1, reason: 'focus stays on the slot');

      await h.retire(tester);
    });

    testWidgets('steps back and clears the previous slot when already empty', (
      tester,
    ) async {
      final h = _Harness(spec: _spec(), values: ['1', null, null]);
      await h.mount(tester);
      await h.focus(tester, 1);

      h.machine.backspaceCharacter();
      await tester.pump();

      expect(h.commits, [(0, '')]);
      expect(h.values, [null, null, null]);
      expect(h.machine.activeIndex, 0);

      await h.retire(tester);
    });

    testWidgets('is a no-op at index 0 with an empty slot', (tester) async {
      final h = _Harness(spec: _spec());
      await h.mount(tester);
      await h.focus(tester, 0);
      h.activeChanges.clear();

      h.machine.backspaceCharacter();
      await tester.pump();

      expect(h.commits, isEmpty);
      expect(h.machine.activeIndex, 0);
      expect(h.activeChanges, isEmpty);

      await h.retire(tester);
    });
  });

  group('advanceFrom', () {
    testWidgets('moves focus to the next slot', (tester) async {
      final h = _Harness(spec: _spec());
      await h.mount(tester);
      await h.focus(tester, 0);

      h.machine.advanceFrom(0);
      await tester.pump();

      expect(h.machine.activeIndex, 1);
      expect(h.machine.focusNodeAt(1).hasFocus, isTrue);

      await h.retire(tester);
    });

    testWidgets('unfocuses at the last slot rather than wrapping', (
      tester,
    ) async {
      final h = _Harness(spec: _spec());
      await h.mount(tester);
      await h.focus(tester, 2);

      h.machine.advanceFrom(2);
      await tester.pump();

      expect(h.machine.activeIndex, isNull);
      expect(h.machine.focusNodeAt(0).hasFocus, isFalse);
      expect(h.activeChanges.last, isNull);

      await h.retire(tester);
    });

    testWidgets('requests the sheet for a chosen slot and does not focus it', (
      tester,
    ) async {
      // chosen + system is the one combination that resolves to a sheet.
      final h = _Harness(
        spec: _spec(alphabets: const [_digits, _chosen, _digits]),
        inputSource: PlateInputSource.system,
      );
      await h.mount(tester);
      await h.focus(tester, 0);

      h.machine.advanceFrom(0);
      await tester.pump();

      expect(h.sheetRequests, [1]);
      expect(h.machine.focusNodeAt(1).hasFocus, isFalse);
      expect(h.machine.activeIndex, 0);

      await h.retire(tester);
    });

    testWidgets('focuses a chosen slot when the host supplies characters', (
      tester,
    ) async {
      // Under host/packageKeypad the same slot is an externalField, not a
      // sheet: it takes focus and waits to be fed.
      final h = _Harness(
        spec: _spec(alphabets: const [_digits, _chosen, _digits]),
      );
      await h.mount(tester);
      await h.focus(tester, 0);

      h.machine.advanceFrom(0);
      await tester.pump();

      expect(h.sheetRequests, isEmpty);
      expect(h.machine.activeIndex, 1);

      await h.retire(tester);
    });
  });

  group('focusFirstEmptySlot', () {
    testWidgets('focuses the first slot with no character', (tester) async {
      final h = _Harness(spec: _spec(), values: ['1', null, '3']);
      await h.mount(tester);

      h.machine.focusFirstEmptySlot();
      await tester.pump();

      expect(h.machine.activeIndex, 1);
      await h.retire(tester);
    });

    testWidgets('falls back to the first slot on a full plate', (tester) async {
      final h = _Harness(spec: _spec(), values: ['1', '2', '3']);
      await h.mount(tester);
      await h.focus(tester, 2);

      h.machine.focusFirstEmptySlot();
      await tester.pump();

      expect(h.machine.activeIndex, 0);
      await h.retire(tester);
    });
  });

  group('focusSlot', () {
    testWidgets('focuses the slot at index, and ignores out of range', (
      tester,
    ) async {
      final h = _Harness(spec: _spec());
      await h.mount(tester);

      await h.focus(tester, 2);
      expect(h.machine.activeIndex, 2);

      h.machine.focusSlot(-1);
      h.machine.focusSlot(3);
      await tester.pump();
      expect(h.machine.activeIndex, 2, reason: 'out of range is a no-op');

      await h.retire(tester);
    });
  });

  group('syncController', () {
    testWidgets('is a no-op when the text already matches', (tester) async {
      final h = _Harness(spec: _spec());
      final field = h.machine.controllerAt(0)!;
      field.value = const TextEditingValue(
        text: '5',
        selection: TextSelection(baseOffset: 0, extentOffset: 1),
      );

      h.machine.syncController(0, '5');

      expect(field.text, '5');
      expect(
        field.selection,
        const TextSelection(baseOffset: 0, extentOffset: 1),
        reason: 'an untouched field keeps its selection',
      );
      h.machine.dispose();
    });

    testWidgets('sets a collapsed selection at the end otherwise', (
      tester,
    ) async {
      final h = _Harness(spec: _spec());
      final field = h.machine.controllerAt(0)!;

      h.machine.syncController(0, '4');
      expect(field.text, '4');
      expect(field.selection, const TextSelection.collapsed(offset: 1));

      h.machine.syncController(0, null);
      expect(field.text, '');
      expect(field.selection, const TextSelection.collapsed(offset: 0));

      h.machine.dispose();
    });

    testWidgets('is a no-op for a chosen slot, which has no field', (
      tester,
    ) async {
      final h = _Harness(
        spec: _spec(alphabets: const [_digits, _chosen, _digits]),
      );
      expect(() => h.machine.syncController(1, 'ا'), returnsNormally);
      h.machine.dispose();
    });
  });

  group('dispose', () {
    testWidgets('drops the focus listener before disposing the nodes', (
      tester,
    ) async {
      final h = _Harness(spec: _spec());
      await h.mount(tester);
      await h.focus(tester, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      final announced = h.activeChanges.length;

      expect(h.machine.dispose, returnsNormally);
      expect(
        h.activeChanges.length,
        announced,
        reason: 'a listener surviving into dispose would announce again',
      );
    });
  });
}
