part of 'plate_card_bloc.dart';

class PlateCardState {
  final PlateNumber plateNumber;
  final PlateType plateType;

  PlateCardState({
    required this.plateNumber,
    required this.plateType,
  });

  PlateCardState copyWith({
    final PlateType? plateType,
    final PlateNumber? plateNumber,
  }) {
    return PlateCardState(
      plateNumber: plateNumber ?? this.plateNumber,
      plateType: plateType ?? this.plateType,
    );
  }

  static PlateCardState emptyPlateCardState(PlateType plateType) {
    if (plateType == PlateType.irCar) {
      return PlateCardState(
        plateNumber: PlateNumber(
          values: const [null, null, null, null, null, null, null, null],
          valueTypes: const [
            SelectableInt,
            SelectableInt,
            SelectableString,
            SelectableInt,
            SelectableInt,
            SelectableInt,
            SelectableInt,
            SelectableInt
          ],
        ),
        plateType: PlateType.irCar,
      );
    }
    if (plateType == PlateType.irBicycle) {
      return PlateCardState(
        plateNumber: PlateNumber(
          values: const [null, null, null, null, null, null, null, null],
          valueTypes: const [SelectableInt, SelectableInt, SelectableInt, SelectableInt, SelectableInt, SelectableInt, SelectableInt, SelectableInt],
        ),
        plateType: PlateType.irBicycle,
      );
    }
    throw Error();
  }
}