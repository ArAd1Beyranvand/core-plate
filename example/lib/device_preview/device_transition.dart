// STABLE — presentation subsystem. Do not refactor for consistency with other
// layers; change only for rendering bugs.

import 'package:flutter/foundation.dart';

/// The three phases of a device change.
enum DeviceTransitionPhase { idle, contentFadeOut, frameTransform, contentFadeIn }

/// Durations for each phase. Fades default to 1500ms.
///
/// The fades are kept equal on purpose: with a symmetric swap the frame morph
/// sits at the centre of the transition timeline, off only by the half of
/// [blankHold] that trails it.
@immutable
class DeviceTransitionDurations {
  const DeviceTransitionDurations({
    this.contentFadeOut = const Duration(milliseconds: 1500),
    this.frameTransform = const Duration(milliseconds: 1100),
    this.contentFadeIn = const Duration(milliseconds: 1500),
    this.blankHold = const Duration(milliseconds: 120),
  });

  final Duration contentFadeOut;

  /// Body, bezel, camera, speaker, buttons and the laptop deck all morph here.
  final Duration frameTransform;
  final Duration contentFadeIn;

  /// A beat of pure black after the morph, before the content fades back in, so
  /// the screen reads as switched off rather than mid-fade. The morph itself
  /// starts the instant the outgoing content hits zero opacity — no leading
  /// hold — so the shell begins reshaping exactly on the swap.
  final Duration blankHold;

  Duration get total =>
      contentFadeOut + frameTransform + blankHold + contentFadeIn;
}
