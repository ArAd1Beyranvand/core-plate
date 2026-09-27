/// The optional bloc layer for `core_plate`. A [PlateCanvas] needs nothing
/// above it, but this package provides a [PlateCardBloc] for hosts whose
/// surrounding code is bloc-shaped, mirrored onto the controller in both
/// directions.
///
/// Depend on it if you have bloc code; skip it and use `PlateController` with
/// `PlateView` / `PlateTextView` otherwise.
library;

/// The bloc, its events and state.
export 'src/plate_card_bloc.dart';

/// Provides a [PlateCardBloc] mirrored onto a `PlateController`.
export 'src/plate_card_binding.dart' show PlateCardBinding;

/// The bloc-reading read-only pair, for hosts that already have a bloc.
export 'src/show_plate.dart';
