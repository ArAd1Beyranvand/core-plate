import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number/bloc/plate_card_bloc.dart';
import 'package:plate_number/input/plate_input_controller.dart';
import 'package:plate_number/model/plate_input_source.dart';
import 'package:plate_number/model/plate_spec.dart';
import 'package:plate_number/widgets/plate_canvas.dart';

void main() {
  final spec = PlateSpecs.deCar;

  Future<PlateCardBloc> pumpCanvas(
    WidgetTester tester,
    PlateInputController controller,
  ) async {
    final bloc = PlateCardBloc(spec);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<PlateCardBloc>.value(
          value: bloc,
          child: Scaffold(
            body: PlateCanvas(
              spec: spec,
              inputSource: PlateInputSource.host,
              controller: controller,
            ),
          ),
        ),
      ),
    );
    // Let the post-frame callback that seeds the active slot run.
    await tester.pump();
    return bloc;
  }

  group('PlateCanvas (host input source)', () {
    testWidgets('reports slot 0 as active after the first frame', (
      tester,
    ) async {
      final c = PlateInputController();
      addTearDown(c.dispose);
      await pumpCanvas(tester, c);

      expect(c.activeSlot, isNotNull);
      expect(c.activeSlot!.index, 0);
    });

    testWidgets('submit writes the value and advances focus', (tester) async {
      final c = PlateInputController();
      addTearDown(c.dispose);
      final bloc = await pumpCanvas(tester, c);

      c.submit('D');
      await tester.pump();

      expect(bloc.state.plateNumber.values[0], 'D');
      expect(c.activeSlot, isNotNull);
      expect(c.activeSlot!.index, 1);
    });

    testWidgets('submitting a character the alphabet rejects is a no-op', (
      tester,
    ) async {
      final c = PlateInputController();
      addTearDown(c.dispose);
      final bloc = await pumpCanvas(tester, c);

      c.submit('!');
      await tester.pump();

      expect(bloc.state.plateNumber.values[0], anyOf(isNull, isEmpty));
      expect(c.activeSlot!.index, 0);
    });

    testWidgets('backspace on an empty slot steps back and clears previous', (
      tester,
    ) async {
      final c = PlateInputController();
      addTearDown(c.dispose);
      final bloc = await pumpCanvas(tester, c);

      // Fill slot 0, landing focus on the (empty) slot 1.
      c.submit('D');
      await tester.pump();
      expect(c.activeSlot!.index, 1);

      c.backspace();
      await tester.pump();

      // Focus stepped back to slot 0 and its value was cleared.
      expect(c.activeSlot!.index, 0);
      expect(bloc.state.plateNumber.values[0], anyOf(isNull, isEmpty));
    });

    testWidgets('focusFirstEmpty lands on the first empty slot', (tester) async {
      final c = PlateInputController();
      addTearDown(c.dispose);
      final bloc = await pumpCanvas(tester, c);

      c.submit('D');
      await tester.pump();
      c.submit('A');
      await tester.pump();

      expect(bloc.state.plateNumber.values[0], 'D');
      expect(bloc.state.plateNumber.values[1], 'A');

      c.focusFirstEmpty();
      await tester.pump();

      expect(c.activeSlot!.index, 2);
    });
  });
}
