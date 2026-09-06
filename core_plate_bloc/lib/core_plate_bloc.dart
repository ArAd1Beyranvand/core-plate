/// The optional bloc layer for the `core_plate` library.
///
/// A [PlateCanvas] holds its characters in a `PlateController` and needs
/// nothing above it. This package is for hosts whose surrounding code is
/// bloc-shaped: [PlateCardBinding] provides a [PlateCardBloc] to the subtree
/// and keeps it holding the same characters as the controller, in both
/// directions, so a `BlocBuilder` over the value, a hand-dispatched
/// [ValueIsChanged] and a [ShowPlate] all keep working unchanged.
///
/// Nothing in `core_plate` imports this package, and nothing here is required
/// to draw a plate. Depend on it if you have bloc code to keep; skip it and use
/// `PlateController` with `PlateView` / `PlateTextView` if you do not.
///
/// Everything reachable from this file is API this package supports. Anything
/// under `src/` that this file does not export is an implementation detail:
/// `PlateBlocBridge` — the two-way mirror [PlateCardBinding] installs — is this
/// package's own business, not a consumer's.
library;

/// The bloc, its events and its state: the store a bloc-shaped host reads and
/// writes.
export 'src/plate_card_bloc.dart';

/// Provides a [PlateCardBloc] mirrored onto a `PlateController`. The seam a
/// bloc host wraps its plate subtree in, in place of a `BlocProvider`.
export 'src/plate_card_binding.dart' show PlateCardBinding;

/// The bloc-reading read-only pair. `core_plate`'s `PlateView` /
/// `PlateTextView` render a controller and need no provider above them; these
/// two read the bloc, and exist for hosts that already have one.
export 'src/show_plate.dart';
