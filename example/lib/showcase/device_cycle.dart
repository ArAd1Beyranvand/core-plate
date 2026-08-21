import 'package:flutter/widgets.dart';
import 'package:plate_number/model/plate_spec.dart';

import '../device_preview/device_config.dart';
import 'demo_config.dart';

/// Drives a [DeviceCycle] forward one device at a time.
///
/// Call [advance] to move the cycle to the next device; each call notifies
/// listeners exactly once.
class DeviceCycleController extends ChangeNotifier {
  /// Advances the cycle to the next device.
  void advance() => notifyListeners();
}

/// The [PlateSpec] a given [device] should show: mobile demos the Iranian
/// bicycle plate, the tablet demos the German car plate, and the laptop demos
/// the Iranian car plate.
PlateSpec specFor(DeviceType device) => demoConfigs[device]!.spec;

/// Cycles through a sequence of [DeviceType]s on demand, rebuilding [builder]
/// each time the active device changes.
///
/// Each hop lets [DeviceFrame] morph between form factors. Advancing is driven
/// by [controller]: a device stays put until its plate has been fully typed in
/// and something calls [DeviceCycleController.advance].
class DeviceCycle extends StatefulWidget {
  const DeviceCycle({
    super.key,
    required this.builder,
    required this.controller,
    this.order = const [
      DeviceType.desktop,
      DeviceType.mobile,
      DeviceType.tablet,
    ],
    this.onDeviceChanged,
  });

  /// Builds the content for the currently active [DeviceType].
  final Widget Function(BuildContext context, DeviceType device) builder;

  /// Drives the cycle forward one device per [DeviceCycleController.advance].
  final DeviceCycleController controller;

  /// The sequence of devices to cycle through, wrapping back to the first.
  final List<DeviceType> order;

  /// Called whenever the active device advances to a new form factor.
  final ValueChanged<DeviceType>? onDeviceChanged;

  @override
  State<DeviceCycle> createState() => _DeviceCycleState();
}

class _DeviceCycleState extends State<DeviceCycle> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_advance);
  }

  void _advance() {
    if (!mounted) return;
    setState(() {
      _index = (_index + 1) % widget.order.length;
    });
    widget.onDeviceChanged?.call(widget.order[_index]);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_advance);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.order[_index]);
  }
}
