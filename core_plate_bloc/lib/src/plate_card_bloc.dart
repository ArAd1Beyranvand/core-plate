import 'package:bloc/bloc.dart';
import 'package:plate_core/plate_core.dart';

part 'plate_card_event.dart';

part 'plate_card_state.dart';

class PlateCardBloc extends Bloc<PlateCardEvent, PlateCardState> {
  PlateCardBloc(PlateSpec spec) : super(PlateCardState.empty(spec)) {
    on<ValueIsChanged>((ValueIsChanged event, Emitter<PlateCardState> emit) {
      if ((state.plateNumber.values[event.index] ?? '') ==
          (event.value ?? '')) {
        return;
      }
      final values = List<String?>.of(state.plateNumber.values)
        ..[event.index] = event.value;
      emit(state.copyWith(plateNumber: PlateNumber(values: values)));
    });
    on<SpecIsChanged>((SpecIsChanged event, Emitter<PlateCardState> emit) {
      emit(PlateCardState.empty(event.spec));
    });
  }
}
