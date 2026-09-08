part of 'plate_card_bloc.dart';

class PlateCardEvent {}

class ValueIsChanged extends PlateCardEvent {
  final int index;
  final String? value;

  ValueIsChanged({required this.index, this.value});
}

class SpecIsChanged extends PlateCardEvent {
  final PlateSpec spec;

  SpecIsChanged(this.spec);
}
