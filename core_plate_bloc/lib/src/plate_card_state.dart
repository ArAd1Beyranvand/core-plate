part of 'plate_card_bloc.dart';

class PlateCardState {
  final PlateNumber plateNumber;
  final PlateSpec spec;

  /// The spec restriction the last refused [ValueIsChanged] would have broken,
  /// or null. A refused value never reaches [plateNumber].
  final PlateRestriction? rejection;

  PlateCardState({
    required this.plateNumber,
    required this.spec,
    this.rejection,
  });

  PlateCardState copyWith({
    final PlateSpec? spec,
    final PlateNumber? plateNumber,
    final PlateRestriction? rejection,
  }) {
    return PlateCardState(
      plateNumber: plateNumber ?? this.plateNumber,
      spec: spec ?? this.spec,
      rejection: rejection,
    );
  }

  static PlateCardState empty(PlateSpec spec) => PlateCardState(
    plateNumber: PlateNumber(
      values: List<String?>.filled(spec.slotCount, null),
    ),
    spec: spec,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlateCardState &&
        other.plateNumber == plateNumber &&
        other.spec == spec &&
        other.rejection == rejection;
  }

  @override
  int get hashCode => Object.hash(plateNumber, spec, rejection);
}
