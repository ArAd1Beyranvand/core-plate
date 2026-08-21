import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number/bloc/plate_card_bloc.dart';
import 'package:plate_number/model/plate_spec.dart';

void main() {
  group('PlateCardBloc', () {
    blocTest<PlateCardBloc, PlateCardState>(
      'ValueIsChanged sets the value at the given index',
      build: () => PlateCardBloc(PlateSpecs.deCar),
      act: (bloc) => bloc.add(ValueIsChanged(index: 0, value: 'D')),
      expect: () => [
        isA<PlateCardState>().having(
          (s) => s.plateNumber.values[0],
          'values[0]',
          'D',
        ),
      ],
    );

    blocTest<PlateCardBloc, PlateCardState>(
      'ValueIsChanged with the same value is a no-op and emits nothing',
      build: () => PlateCardBloc(PlateSpecs.deCar),
      seed: () => PlateCardState(
        plateNumber: PlateCardState.empty(PlateSpecs.deCar).plateNumber.copyWith(
              values: List<String?>.filled(PlateSpecs.deCar.slotCount, null)..[0] = 'D',
            ),
        spec: PlateSpecs.deCar,
      ),
      act: (bloc) => bloc.add(ValueIsChanged(index: 0, value: 'D')),
      expect: () => [],
    );

    blocTest<PlateCardBloc, PlateCardState>(
      'SpecIsChanged resets to an empty state for the new spec',
      build: () => PlateCardBloc(PlateSpecs.deCar),
      act: (bloc) {
        bloc.add(ValueIsChanged(index: 0, value: 'D'));
        bloc.add(SpecIsChanged(PlateSpecs.irCar));
      },
      expect: () => [
        isA<PlateCardState>().having((s) => s.plateNumber.values[0], 'values[0]', 'D'),
        isA<PlateCardState>()
            .having((s) => s.spec.id, 'spec.id', PlateSpecs.irCar.id)
            .having((s) => s.plateNumber.isEmpty(), 'isEmpty', isTrue),
      ],
    );
  });
}
