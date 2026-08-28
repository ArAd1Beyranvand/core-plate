import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../device_preview/device_config.dart' show DeviceType;
import '../poster_scale.dart';
import '../poster_tokens.dart';

/// The inspection stamp from DESIGN_SPEC.md §6 "Chrome", anchored at
/// `.843, .874`, width `.130`.
///
/// Rotated `-6deg`, with a double inner ring
/// (`inset 0 0 0 2px rgba(228,214,188,.34), inset 0 0 0 8px rgba(228,214,188,.14)`)
/// and two centred Martian Mono lines:
///
///   made in IRAN
///   {LAPTOP|PHONE|TABLET} — INSPECTED
///
/// The current [device] drives the device label. Per §6 the numbering follows
/// `DeviceCycle.order` — `desktop → LAPTOP`, `mobile → PHONE`,
/// `tablet → TABLET` — which is NOT the declaration order of the
/// [DeviceType] enum, so the mapping is spelled out explicitly below.
class InspectionStamp extends StatelessWidget {
  const InspectionStamp({super.key, required this.device});

  final DeviceType device;

  static const Color _ringOuter = Color(0x57E4D6BC); // rgba(228,214,188,.34)
  static const Color _ringInner = Color(0x24E4D6BC); // rgba(228,214,188,.14)

  /// `(ordinal, label)` for each device, following `DeviceCycle.order`.
  static ({int ordinal, String label}) _spec(DeviceType device) {
    switch (device) {
      case DeviceType.desktop:
        return (ordinal: 1, label: 'LAPTOP');
      case DeviceType.mobile:
        return (ordinal: 2, label: 'PHONE');
      case DeviceType.tablet:
        return (ordinal: 3, label: 'TABLET');
    }
  }

  @override
  Widget build(BuildContext context) {
    final PosterMetrics metrics = PosterMetrics.of(context);
    final spec = _spec(device);

    final TextStyle stampStyle = PosterType.stamp(metrics.f);

    return Transform.rotate(
      angle: -6 * math.pi / 180.0,
      child: SizedBox(
        width: metrics.px(250),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Double inner ring reproduced as two stacked inset borders.
            border: Border.all(color: _ringOuter, width: metrics.px(2)),
          ),
          child: Padding(
            padding: EdgeInsets.all(metrics.px(6)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: _ringInner, width: metrics.px(6)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.px(18),
                  vertical: metrics.px(14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'made in IRAN',
                      textAlign: TextAlign.center,
                      style: stampStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${spec.label} — INSPECTED',
                      textAlign: TextAlign.center,
                      style: stampStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
