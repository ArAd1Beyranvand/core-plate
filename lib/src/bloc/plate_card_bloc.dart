import 'package:bloc/bloc.dart';

import '../model/plate_number.dart';
import '../model/plate_spec.dart';

part 'plate_card_event.dart';

part 'plate_card_state.dart';

class PlateCardBloc extends Bloc<PlateCardEvent, PlateCardState> {
  final PlateSpec spec;

  PlateCardBloc(this.spec) : super(PlateCardState.empty(spec)) {
    on<ValueIsChanged>((ValueIsChanged event, Emitter<PlateCardState> emit) {
      if ((state.plateNumber.values[event.index] ?? '') == (event.value ?? ''))
        return;
      final values = List<String?>.of(state.plateNumber.values)
        ..[event.index] = event.value;
      emit(state.copyWith(plateNumber: PlateNumber(values: values)));
    });
    on<RemovePlateCard>((RemovePlateCard event, Emitter<PlateCardState> emit) {
      emit(PlateCardState.empty(state.spec));
    });
    on<SpecIsChanged>((SpecIsChanged event, Emitter<PlateCardState> emit) {
      emit(PlateCardState.empty(event.spec));
    });
  }
}
