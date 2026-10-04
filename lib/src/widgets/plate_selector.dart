import 'package:flutter/widgets.dart';

import '../input/plate_controller.dart';

/// Rebuilds [builder] only when [selector]'s result changes.
class PlateSelector<T> extends StatefulWidget {
  const PlateSelector({
    super.key,
    required this.controller,
    required this.selector,
    required this.builder,
  });

  final PlateController controller;
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
    if (!identical(oldWidget.controller, widget.controller) ||
        !identical(oldWidget.selector, widget.selector)) {
      _value = widget.selector(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    if (!mounted) return;
    final next = widget.selector(widget.controller);
    if (next == _value) return;
    setState(() => _value = next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}
