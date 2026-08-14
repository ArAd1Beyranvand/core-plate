import 'package:flutter/widgets.dart';

import 'device_config.dart';

/// Built-in presets. Override any of them with [DeviceFrame.configResolver].
class DevicePresets {
  const DevicePresets._();

  static const mobile = DeviceConfig(
    type: DeviceType.mobile,
    label: 'Mobile',
    bodySize: Size(390, 844),
    bezel: EdgeInsets.all(12),
    bodyRadius: 54,
    screenRadius: 42,
    notchSize: Size(126, 32),
    notchRadius: 16,
    cameraEdge: 0.1463,
    cameraRadius: 5,
    speakerEdge: 0.1175,
    speakerSize: Size(44, 5),
    homeIndicatorWidth: 134,
    sideButtons: [
      SideButton(side: -1, start: 0.18, length: 0.035),
      SideButton(side: -1, start: 0.235, length: 0.065),
      SideButton(side: -1, start: 0.315, length: 0.065),
      SideButton(side: 1, start: 0.26, length: 0.10),
    ],
    shadowBlur: 46,
    shadowOffsetY: 20,
  );

  /// Landscape tablet — wider than tall.
  static const tablet = DeviceConfig(
    type: DeviceType.tablet,
    label: 'Tablet',
    bodySize: Size(1194, 834),
    bezel: EdgeInsets.all(16),
    bodyRadius: 38,
    screenRadius: 24,
    cameraEdge: 0.875,
    cameraRadius: 4,
    speakerEdge: 0.625,
    speakerSize: Size(64, 3),
    homeIndicatorWidth: 200,
    sideButtons: [
      SideButton(side: -1, start: 0.10, length: 0.05),
      SideButton(side: -1, start: 0.20, length: 0.07),
      SideButton(side: -1, start: 0.30, length: 0.07),
      SideButton(side: 1, start: 0.06, length: 0.06),
    ],
    shadowBlur: 54,
    shadowOffsetY: 22,
  );

  static const desktop = DeviceConfig(
    type: DeviceType.desktop,
    label: 'Desktop',
    bodySize: Size(1280, 830),
    bezel: EdgeInsets.fromLTRB(11, 22, 11, 12),
    bodyRadius: 16,
    screenRadius: 8,
    notchSize: Size(180, 22),
    notchRadius: 8,
    cameraEdge: 0.125,
    cameraRadius: 3.5,
    deck: DeviceDeck(depth: 660, angleDeg: 45, hingeHeight: 9, opacity: 1),
    shadowBlur: 60,
    shadowOffsetY: 26,
  );

  static DeviceConfig of(DeviceType type) => switch (type) {
        DeviceType.mobile => mobile,
        DeviceType.tablet => tablet,
        DeviceType.desktop => desktop,
      };
}
