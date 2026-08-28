import 'package:flutter/material.dart';

import 'poster_tokens.dart'; // PosterTokens.accent

/// Which side of the device a callout sits on.
///
/// TODO(P8): annotation_callout.dart, the previous owner of this enum, was
/// removed in the poster demolition; this is a temporary local stand-in
/// until P8 rebuilds the callout content model.
enum CalloutSide { left, right }

/// How a set of callouts leaves and the next set arrives.
enum CalloutMotif {
  /// SWEEP. Exit: slides horizontally off its own side of the screen.
  /// Entry: slides in horizontally from that same side and settles.
  sweep,

  /// TRAPDOOR. Exit: a slot opens beneath the callout and it falls through,
  /// fading. Entry: a slot opens above its resting place and it drops out of it.
  trapdoor,

  /// SIPHON. Exit: the callout collapses along its connector toward the dot,
  /// shrinking to a point on the line. Entry: it is emitted back out of the dot
  /// and expands into place.
  siphon,
}

/// SWEEP — Transform.translate on X, plus independent group opacity.
class SweepTransition extends StatelessWidget {
  const SweepTransition({
    super.key,
    required this.animation,
    required this.entering,
    required this.side,
    required this.child,
  });

  final Animation<double> animation;
  final bool entering;
  final CalloutSide side;
  final Widget child;

  /// Distance to travel off the poster rail.
  static const double _distance = 520;
  static const Curve _enterCurve = Cubic(0.215, 0.61, 0.355, 1);
  static const Curve _exitCurve = Cubic(0.55, 0.055, 0.675, 0.19);

  @override
  Widget build(BuildContext context) {
    final double sign = side == CalloutSide.left ? -1 : 1;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double t = animation.value;
        final double eased = (entering ? _enterCurve : _exitCurve).transform(t);
        final double dx = entering
            ? sign * _distance * (1 - eased)
            : sign * _distance * eased;
        final double opacity = entering ? t : 1 - t;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(opacity: opacity, child: child),
        );
      },
    );
  }
}

/// TRAPDOOR — a slot that opens, and the text falling through it.
class TrapdoorTransition extends StatelessWidget {
  const TrapdoorTransition({
    super.key,
    required this.animation,
    required this.entering,
    required this.side,
    required this.child,
  });

  final Animation<double> animation;
  final bool entering;
  final CalloutSide side;
  final Widget child;

  static const Curve _enterCurve = Cubic(0.25, 0.46, 0.45, 0.94);
  static const Curve _exitCurve = Cubic(0.55, 0.085, 0.68, 0.53);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double t = animation.value;
        final double eased = (entering ? _enterCurve : _exitCurve).transform(t);
        final double slotFactor = entering ? t : 1 - t;
        final double dy = entering ? -90 * (1 - eased) : 90 * eased;
        final double opacity = entering ? t : 1 - t;

        // Entry aligns the slot to the TOP; exit to the BOTTOM.
        final Alignment slotAlign = entering
            ? Alignment.topCenter
            : Alignment.bottomCenter;

        return ClipRect(
          child: Stack(
            children: [
              Align(
                alignment: slotAlign,
                child: _TrapdoorSlot(widthFactor: slotFactor),
              ),
              Transform.translate(
                offset: Offset(0, dy),
                child: Opacity(opacity: opacity, child: child),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The horizontal bar the trapdoor child falls through.
class _TrapdoorSlot extends StatelessWidget {
  const _TrapdoorSlot({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor.clamp(0.0, 1.0),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          color: PosterTokens.accent.withValues(alpha: 0.55),
          boxShadow: const [
            BoxShadow(color: PosterTokens.accent, blurRadius: 12),
          ],
        ),
      ),
    );
  }
}

/// SIPHON — Transform composing scale and translate toward the connector dot.
class SiphonTransition extends StatelessWidget {
  const SiphonTransition({
    super.key,
    required this.animation,
    required this.entering,
    required this.side,
    required this.child,
  });

  final Animation<double> animation;
  final bool entering;
  final CalloutSide side;
  final Widget child;

  static const Curve _enterCurve = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve _exitCurve = Cubic(0.36, 0, 0.66, -0.56);

  @override
  Widget build(BuildContext context) {
    // The dot sits on the device-facing edge: RIGHT for left callouts,
    // LEFT for right callouts.
    final Alignment scaleAlign = side == CalloutSide.left
        ? const Alignment(1, 0.12)
        : const Alignment(-1, 0.12);
    // The X nudge aims toward the dot.
    final double sign = side == CalloutSide.left ? 1 : -1;

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final double t = animation.value;
        final double eased = (entering ? _enterCurve : _exitCurve).transform(t);
        final double scale = entering ? 0.04 + 0.96 * eased : 1 - 0.96 * eased;
        final double opacity = entering ? t : 1 - t;
        final double dx = entering
            ? (-sign * 18) * (1 - eased)
            : (sign * 18) * eased;

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(
            scale: scale,
            alignment: scaleAlign,
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      },
    );
  }
}

/// Dispatcher so callers never switch on [CalloutMotif] themselves.
class CalloutTransition extends StatelessWidget {
  const CalloutTransition({
    super.key,
    required this.motif,
    required this.animation,
    required this.entering,
    required this.side,
    required this.child,
  });

  final CalloutMotif motif;
  final Animation<double> animation;
  final bool entering;
  final CalloutSide side;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return switch (motif) {
      CalloutMotif.sweep => SweepTransition(
        animation: animation,
        entering: entering,
        side: side,
        child: child,
      ),
      CalloutMotif.trapdoor => TrapdoorTransition(
        animation: animation,
        entering: entering,
        side: side,
        child: child,
      ),
      CalloutMotif.siphon => SiphonTransition(
        animation: animation,
        entering: entering,
        side: side,
        child: child,
      ),
    };
  }
}
