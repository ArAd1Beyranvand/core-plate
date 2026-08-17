part of 'plate_card_bloc.dart';

class PlateCardState {
  final PlateNumber plateNumber;
  final PlateSpec spec;

  PlateCardState({
    required this.plateNumber,
    required this.spec,
  });

  PlateCardState copyWith({
    final PlateSpec? spec,
    final PlateNumber? plateNumber,
  }) {
    return PlateCardState(
      plateNumber: plateNumber ?? this.plateNumber,
      spec: spec ?? this.spec,
    );
  }

  static PlateCardState empty(PlateSpec spec) => PlateCardState(
        plateNumber: PlateNumber(values: List<String?>.filled(spec.slotCount, null)),
        spec: spec,
      );
}
