// STABLE — presentation subsystem. Do not refactor for consistency with other
// layers; change only for rendering bugs.

import 'package:flutter/foundation.dart';

/// The three phases of a device change.
enum DeviceTransitionPhase { idle, contentFadeOut, frameTransform, contentFadeIn }

/// Durations for each phase. Fades default to 1800ms.
@immutable
class DeviceTransitionDurations {
  const DeviceTransitionDurations({
    this.contentFadeOut = const Duration(milliseconds: 1800),
    this.frameTransform = const Duration(milliseconds: 1500),
    this.contentFadeIn = const Duration(milliseconds: 1800),
    this.blankHold = const Duration(milliseconds: 120),
  });

  final Duration contentFadeOut;

  /// Body, bezel, camera, speaker, buttons and the laptop deck all morph here.
  final Duration frameTransform;
  final Duration contentFadeIn;

  /// A beat of pure black either side of the morph, so the screen reads as
  /// switched off rather than mid-fade.
  final Duration blankHold;

  Duration get total =>
      contentFadeOut + blankHold + frameTransform + blankHold + contentFadeIn;
}
