part of 'plate_card_bloc.dart';

class PlateCardEvent {}

class ValueIsChanged extends PlateCardEvent {
  final int index;
  final String? value;

  ValueIsChanged({required this.index, this.value});
}

/// Clears the plate.
///
/// Deprecated, and moved into this package only so nothing disappears in the
/// same release it changes address: nothing in this workspace has ever
/// dispatched it, and `PlateController.clear()` is what a host reaches for now.
/// It will be removed in the next breaking release.
@Deprecated(
  'Nothing dispatches this. Clear the plate through PlateController.clear() '
  'on the controller the PlateCardBinding mirrors. Will be removed in 1.0.0.',
)
class RemovePlateCard extends PlateCardEvent {}

class SpecIsChanged extends PlateCardEvent {
  final PlateSpec spec;

  SpecIsChanged(this.spec);
}
