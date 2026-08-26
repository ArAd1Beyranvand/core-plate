import 'package:flutter/material.dart';

import '../../device_preview/device_config.dart' show DeviceType;
import '../poster_scale.dart';
import '../poster_tokens.dart';

/// The form-factor pips from DESIGN_SPEC.md §6 "Chrome", anchored at
/// `.977, .415`.
///
/// A right-aligned column of three 5 design-px-tall bars, gap 12. The bar for
/// the active [device] is 28px long, `#7C5CFF`, with a
/// `0 0 18px rgba(124,92,255,.95)` glow; the idle bars are 14px long,
/// `rgba(200,212,236,.24)`. The length animates over `.24s linear` on a device
/// change.
///
/// The three pips are ordered `desktop, mobile, tablet` following
/// `DeviceCycle.order`, the same order the stamp numbers by.
class FormFactorPips extends StatelessWidget {
  const FormFactorPips({super.key, required this.device});

  final DeviceType device;

  static const List<DeviceType> _order = <DeviceType>[
    DeviceType.desktop,
    DeviceType.mobile,
    DeviceType.tablet,
  ];

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < _order.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: metrics.px(12)),
          _Pip(active: _order[i] == device),
        ],
      ],
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final double height = metrics.px(5);
    final double activeLen = metrics.px(28);
    final double idleLen = metrics.px(14);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.linear,
      width: active ? activeLen : idleLen,
      height: height,
      decoration: BoxDecoration(
        color: active ? PosterColors.accent : PosterColors.pipIdle,
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: PosterColors.accentPipGlow,
                  blurRadius: metrics.px(18),
                ),
              ]
            : const <BoxShadow>[],
      ),
    );
  }
}
