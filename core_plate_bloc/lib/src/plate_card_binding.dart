import 'dart:async';

import 'package:core_plate/core_plate.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'plate_card_bloc.dart';

/// Provides a [PlateCardBloc] to [child] and keeps it holding the same
/// characters as [controller], in both directions.
///
/// This is the migration seam for hosts built on the bloc. A [PlateCanvas] no
/// longer needs one: it owns its characters in a [PlateController], and a host
/// that wants them reads that controller. But a host with bloc-shaped code
/// around the plate — a `BlocBuilder` over the value, a `ShowPlate`, its own
/// `ValueIsChanged` dispatches — can keep every line of it by wrapping the
/// subtree in this widget instead of a `BlocProvider`.
///
/// Pass [bloc] to mirror onto a bloc the host already holds; leave it null and
/// this widget creates one for [controller]'s spec and disposes it with itself.
class PlateCardBinding extends StatefulWidget {
  const PlateCardBinding({
    super.key,
    required this.controller,
    this.bloc,
    required this.child,
  });

  /// The value-owning side. Never disposed here — the host owns it.
  final PlateController controller;

  /// The bloc to mirror onto, or null to create (and own) one.
  final PlateCardBloc? bloc;

  final Widget child;

  @override
  State<PlateCardBinding> createState() => _PlateCardBindingState();
}

class _PlateCardBindingState extends State<PlateCardBinding> {
  late PlateCardBloc _bloc;

  /// Whether [_bloc] is ours to close. False when the host passed one in.
  bool _ownsBloc = false;

  late PlateBlocBridge _bridge;

  @override
  void initState() {
    super.initState();
    _adoptBloc();
    _foundBridge(seed: true);
  }

  @override
  void didUpdateWidget(PlateCardBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(widget.controller, oldWidget.controller) &&
        identical(widget.bloc, oldWidget.bloc)) {
      return;
    }
    // Down before the swap, up after: the bridge holds a listener on the
    // controller being stood down, and a subscription to the bloc being closed.
    _bridge.dispose();
    if (!identical(widget.bloc, oldWidget.bloc)) {
      final stoodDown = _ownsBloc ? _bloc : null;
      _adoptBloc();
      stoodDown?.close();
    }
    _foundBridge(seed: true);
  }

  @override
  void dispose() {
    _bridge.dispose();
    if (_ownsBloc) _bloc.close();
    super.dispose();
  }

  void _adoptBloc() {
    final host = widget.bloc;
    if (host != null) {
      _bloc = host;
      _ownsBloc = false;
      return;
    }
    _bloc = PlateCardBloc(widget.controller.spec);
    _ownsBloc = true;
  }

  void _foundBridge({bool seed = false}) {
    _bridge = PlateBlocBridge(controller: widget.controller, bloc: _bloc);
    if (seed) _bridge.seed();
  }

  @override
  Widget build(BuildContext context) =>
      BlocProvider<PlateCardBloc>.value(value: _bloc, child: widget.child);
}

/// Keeps one [PlateController] and one [PlateCardBloc] holding the same
/// characters, in both directions.
///
/// Neither side can be the only writer. The controller is the plate's writer of
/// record, but bloc-shaped hosts write straight to the bloc — a `ValueIsChanged`
/// dispatched by hand, a second plate driven off `bloc.stream` — so every write
/// has to reach both stores, whichever one it lands on first.
///
/// **The echo, and why it settles.** A write is reflected onto the other side,
/// which notifies, which would reflect it back. Two things stop that:
///
/// - [_syncing] drops the *synchronous* return trip. `setValues` notifies its
///   listeners during the call, so the controller's change fires while we are
///   still inside the bloc handler that caused it. This is not a mere
///   optimisation: the controller sanitises (a character its slot's alphabet
///   refuses is stored as null) and the bloc does not, so without the flag a
///   value the bloc holds and the controller declines would be echoed back as
///   an instruction to clear it — the bridge overwriting the host.
/// - The value comparisons drop the *asynchronous* return trip. `bloc.add` is
///   queued, so the emission it causes arrives a microtask later, long after
///   the flag is down; by then both sides already agree and there is nothing
///   to copy.
///
/// One write therefore settles in a single pass, and cannot oscillate.
///
/// Not exported: [PlateCardBinding] is the only way in. The canvas has no bloc
/// path of its own any more — it owns a [PlateController] and knows nothing
/// about this package.
class PlateBlocBridge {
  PlateBlocBridge({required this.controller, required this.bloc}) {
    controller.addListener(_onControllerChanged);
    _emissions = bloc.stream.listen(_onBlocState);
  }

  final PlateController controller;
  final PlateCardBloc bloc;

  late final StreamSubscription<PlateCardState> _emissions;

  /// True while this bridge is itself applying a write, so the change it is
  /// about to cause on the far side is not read back as a fresh one.
  bool _syncing = false;

  /// Brings the two sides into agreement at install time.
  ///
  /// The bloc wins, because mounting a canvas over a pre-populated bloc is the
  /// documented way to open an existing plate for editing and it must still
  /// render. The one exception is a controller holding a value against an empty
  /// bloc, where deferring to the bloc would silently blank the host's plate;
  /// there the controller wins and the bloc is caught up.
  void seed() {
    if (bloc.state.plateNumber.isEmpty && !controller.isEmpty) {
      _onControllerChanged();
      return;
    }
    _onBlocState(bloc.state);
  }

  /// Pushes the controller's value onto the bloc. Used after a spec swap, where
  /// the controller has migrated to the new spec and the bloc has not caught up:
  /// the controller is the side to trust.
  void adoptControllerValue() => _onControllerChanged();

  void _onControllerChanged() {
    if (_syncing) return;
    final values = controller.values;
    final current = bloc.state.plateNumber.values;
    _syncing = true;
    try {
      for (var i = 0; i < values.length && i < current.length; i++) {
        if ((current[i] ?? '') == (values[i] ?? '')) continue;
        bloc.add(ValueIsChanged(index: i, value: values[i]));
      }
    } finally {
      _syncing = false;
    }
  }

  void _onBlocState(PlateCardState state) {
    if (_syncing) return;
    final values = state.plateNumber.values;
    if (_agree(values, controller.values)) return;
    _syncing = true;
    try {
      controller.setValues(values);
    } finally {
      _syncing = false;
    }
  }

  /// Whether the two value lists describe the same plate. An unset slot is
  /// null on one side and '' on the other depending on which store cleared it,
  /// so they compare as the same character.
  static bool _agree(List<String?> a, List<String?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ((a[i] ?? '') != (b[i] ?? '')) return false;
    }
    return true;
  }

  void dispose() {
    controller.removeListener(_onControllerChanged);
    _emissions.cancel();
  }
}
