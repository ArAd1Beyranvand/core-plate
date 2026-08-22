import 'package:flutter/material.dart';

import '../device_preview/device_config.dart'; // DeviceType
import 'annotation_callout.dart'; // AnnotationCallout, CalloutSide,
// CalloutWithConnector
import 'callout_content.dart'; // CalloutSet, calloutSets
import 'callout_motion.dart'; // CalloutMotif, CalloutTransition

/// Owns one side's two callouts and animates them out and in as the device
/// changes: the outgoing set leaves over the first half of the run, then the
/// incoming set arrives over the second, so only ever one set is on screen.
class CalloutRail extends StatefulWidget {
  const CalloutRail({
    super.key,
    required this.device,
    required this.side,
    required this.exitMotif, // how the OUTGOING set leaves
    required this.entryMotif, // how the INCOMING set arrives
    this.duration = const Duration(milliseconds: 1500),
    this.compact = false,
  });

  final DeviceType device;
  final CalloutSide side;
  final CalloutMotif exitMotif;
  final CalloutMotif entryMotif;
  final Duration duration;

  /// Shrinks callout type and tightens rail spacing for narrow viewports
  /// (e.g. mobile landscape).
  final bool compact;

  @override
  State<CalloutRail> createState() => _CalloutRailState();
}

class _CalloutRailState extends State<CalloutRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Exit occupies the first 45%; entry the last 45%. The 0.45-0.55 gap holds
  /// nothing on screen. Both are built once here, never allocated in build.
  late final Animation<double> _exit;
  late final Animation<double> _entry;

  /// The device the outgoing set belongs to, captured when a hop fires. Null
  /// until the first hop, so the rail starts by simply showing its own set.
  DeviceType? _outgoing;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45),
    );
    _entry = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1.0),
    );
  }

  @override
  void didUpdateWidget(covariant CalloutRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only a device change drives the animation; nothing else does.
    if (oldWidget.device != widget.device) {
      _outgoing = oldWidget.device;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The two callouts for [device] on this rail's side, top then bottom.
  List<AnnotationCallout> _calloutsFor(DeviceType device) {
    final set = calloutSets[device]!;
    return widget.side == CalloutSide.left ? set.left : set.right;
  }

  @override
  Widget build(BuildContext context) {
    // ClipRect cuts a departing callout off at the rail's own 360px bounds so
    // it never paints over the poster header or footer.
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final status = _controller.status;
          final settled = status == AnimationStatus.dismissed ||
              status == AnimationStatus.completed;

          // No hop pending, or the run has settled at either end: show the
          // current device's set plainly, with no transition wrapper.
          if (_outgoing == null || settled) {
            return _RailColumn(
              callouts: _calloutsFor(widget.device),
              side: widget.side,
              compact: widget.compact,
            );
          }

          // First half: the outgoing set leaves. Second half: the incoming set
          // arrives. Exactly one is ever built.
          if (_controller.value < 0.5) {
            return CalloutTransition(
              motif: widget.exitMotif,
              entering: false,
              side: widget.side,
              animation: _exit,
              child: _RailColumn(
                callouts: _calloutsFor(_outgoing!),
                side: widget.side,
                connectorAnimation: _exit,
                connectorEntering: false,
                compact: widget.compact,
              ),
            );
          }
          return CalloutTransition(
            motif: widget.entryMotif,
            entering: true,
            side: widget.side,
            animation: _entry,
            child: _RailColumn(
              callouts: _calloutsFor(widget.device),
              side: widget.side,
              connectorAnimation: _entry,
              connectorEntering: true,
              compact: widget.compact,
            ),
          );
        },
      ),
    );
  }
}

/// One side's two-callout column, reproducing the poster's flanking layout so
/// the whole block animates together rather than callout by callout.
class _RailColumn extends StatelessWidget {
  const _RailColumn({
    required this.callouts,
    required this.side,
    this.connectorAnimation,
    this.connectorEntering = true,
    this.compact = false,
  });

  final List<AnnotationCallout> callouts; // exactly two, top then bottom
  final CalloutSide side;
  final Animation<double>? connectorAnimation;
  final bool connectorEntering;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double connectorLength = compact ? 60 : 150;
    final AnnotationCallout top = callouts[0].withCompact(compact);
    final AnnotationCallout bottom = callouts[1].withCompact(compact);
    final CrossAxisAlignment cross =
        side == CalloutSide.left ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final Alignment fitAlign =
        side == CalloutSide.left ? Alignment.centerRight : Alignment.centerLeft;

    final Widget topCallout = CalloutWithConnector(
      callout: top,
      connectorLength: connectorLength,
      connectorAnimation: connectorAnimation,
      connectorEntering: connectorEntering,
    );
    final Widget bottomCallout = CalloutWithConnector(
      callout: bottom,
      connectorLength: connectorLength,
      connectorAnimation: connectorAnimation,
      connectorEntering: connectorEntering,
    );

    if (compact) {
      // Short viewports (mobile landscape) can't guarantee both callouts
      // fit at compact type either, so each is scaled down to whatever
      // room its half of the rail actually has rather than overflowing.
      return Column(
        crossAxisAlignment: cross,
        children: [
          Expanded(
            child: Align(
              alignment: fitAlign,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: fitAlign,
                child: topCallout,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: fitAlign,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: fitAlign,
                child: bottomCallout,
              ),
            ),
          ),
        ],
      );
    }

    if (side == CalloutSide.left) {
      return Column(
        crossAxisAlignment: cross,
        children: [
          Padding(padding: const EdgeInsets.only(top: 40), child: topCallout),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: bottomCallout,
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: cross,
      children: [
        const SizedBox(height: 150),
        topCallout,
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 96),
          child: bottomCallout,
        ),
      ],
    );
  }
}
