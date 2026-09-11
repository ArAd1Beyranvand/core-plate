import 'package:flutter/widgets.dart';

import '../input/plate_controller.dart';

/// Rebuilds [builder] only when [selector]'s result actually changes.
///
/// For the one subscription that is genuinely *derived* from the whole plate —
/// a validation verdict, say, which reads every slot but flips rarely. A
/// listener on the controller itself fires on every keystroke; this one runs
/// [selector] on each of those and rebuilds only when the value it selected is
/// `!=` the one it is already showing.
///
/// Per-slot subscriptions do not need this: [PlateController.slot] is already
/// narrow, so a plain [ValueListenableBuilder] over it rebuilds exactly the
/// slot that changed.
class PlateSelector<T> extends StatefulWidget {
  const PlateSelector({super.key, required this.controller, required this.selector, required this.builder});

  final PlateController controller;

  /// Reads the piece of the controller this widget cares about. Called on
  /// every controller notification, so keep it cheap and free of side effects.
  final T Function(PlateController) selector;

  final Widget Function(BuildContext, T) builder;

  @override
  State<PlateSelector<T>> createState() => _PlateSelectorState<T>();
}

class _PlateSelectorState<T> extends State<PlateSelector<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.selector(widget.controller);
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(PlateSelector<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_handleChange);
      widget.controller.addListener(_handleChange);
    }
    // Re-select on a swapped controller *or* a swapped selector: either can
    // pick out a different value from the same keystrokes.
    if (!identical(oldWidget.controller, widget.controller) || !identical(oldWidget.selector, widget.selector)) {
      _value = widget.selector(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    // A notification can arrive in the same frame the element is retired.
    if (!mounted) return;
    final next = widget.selector(widget.controller);
    if (next == _value) return;
    setState(() => _value = next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
