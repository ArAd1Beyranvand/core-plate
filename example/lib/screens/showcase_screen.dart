import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../device_preview/device_config.dart';
import '../device_preview/device_transition.dart';
import '../poster/backdrop/ground_shadow.dart';
import '../poster/backdrop/poster_backdrop.dart';
import '../poster/backdrop/sweep_light.dart';
import '../poster/callout_motion.dart' as motion;
import '../poster/callouts/callout_card.dart';
import '../poster/callouts/callout_data.dart' as callouts;
import '../poster/chrome/inspection_stamp.dart';
import '../poster/chrome/poster_chrome.dart';
import '../poster/chrome/poster_links.dart';
import '../poster/chrome/poster_masthead.dart';
import '../poster/chrome/poster_meta.dart';
import '../poster/chrome/poster_wordmark.dart';
import '../poster/poster_scale.dart';
import '../poster/poster_tokens.dart';
import '../showcase/device_stage.dart';

class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  DeviceType _device = DeviceType.desktop;

  /// The device the layout slot is sized for. It lags [_device] until the frame
  /// actually starts morphing: the hop fires at the top of the content fade-out,
  /// and resizing the slot there squeezed the still-full-size laptop down to
  /// phone width before the shell had reshaped, so it pinched tiny and then grew
  /// back. Holding the outgoing bounds keeps the slot and the shell in step.
  DeviceType _slotDevice = DeviceType.desktop;
  DeviceTransitionPhase _phase = DeviceTransitionPhase.idle;

  void _onFrameDeviceChanged(DeviceType device) {
    if (!mounted) return;
    setState(() => _device = device);
  }

  void _onPhaseChanged(DeviceTransitionPhase phase) {
    if (!mounted) return;
    setState(() {
      _phase = phase;
      if (phase == DeviceTransitionPhase.frameTransform ||
          phase == DeviceTransitionPhase.idle) {
        _slotDevice = _device;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PosterColors.pageBlack,
      body: PosterMetricsScope(
        child: _PosterAssembly(
          device: _device,
          slotDevice: _slotDevice,
          phase: _phase,
          onFrameDeviceChanged: _onFrameDeviceChanged,
          onPhaseChanged: _onPhaseChanged,
        ),
      ),
    );
  }
}

class _PosterAssembly extends StatelessWidget {
  const _PosterAssembly({
    required this.device,
    required this.slotDevice,
    required this.phase,
    required this.onFrameDeviceChanged,
    required this.onPhaseChanged,
  });

  final DeviceType device;

  /// Sizes the device slot; lags [device] until the shell starts morphing.
  final DeviceType slotDevice;
  final DeviceTransitionPhase phase;
  final ValueChanged<DeviceType> onFrameDeviceChanged;
  final ValueChanged<DeviceTransitionPhase> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    final metrics = PosterMetrics.of(context);
    switch (metrics.tier) {
      case PosterTier.wide:
        return _WidePoster(
          device: device,
          slotDevice: slotDevice,
          phase: phase,
          onFrameDeviceChanged: onFrameDeviceChanged,
          onPhaseChanged: onPhaseChanged,
        );
      case PosterTier.medium:
        return _MediumPoster(
          device: device,
          slotDevice: slotDevice,
          phase: phase,
          onFrameDeviceChanged: onFrameDeviceChanged,
          onPhaseChanged: onPhaseChanged,
        );
      case PosterTier.compact:
        return _CompactPoster(
          device: device,
          phase: phase,
          onFrameDeviceChanged: onFrameDeviceChanged,
          onPhaseChanged: onPhaseChanged,
        );
    }
  }
}

class _WidePoster extends StatelessWidget {
  const _WidePoster({
    required this.device,
    required this.slotDevice,
    required this.phase,
    required this.onFrameDeviceChanged,
    required this.onPhaseChanged,
  });

  final DeviceType device;
  final DeviceType slotDevice;
  final DeviceTransitionPhase phase;
  final ValueChanged<DeviceType> onFrameDeviceChanged;
  final ValueChanged<DeviceTransitionPhase> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    final metrics = PosterMetrics.of(context);
    final bounds = _wideDeviceBounds(metrics.size, slotDevice);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        PosterBackdrop(
          // Fires on the rising edge of frameTransform, which is the exact
          // frame the device's content opacity reaches zero.
          sweep: SweepLight(
            isHopping: phase == DeviceTransitionPhase.frameTransform,
          ),
        ),
        GroundShadowLayer(device: device),
        _AnimatedDeviceSlot(
          bounds: bounds,
          device: device,
          onFrameDeviceChanged: onFrameDeviceChanged,
          onPhaseChanged: onPhaseChanged,
        ),
        Positioned.fill(
          child: _CalloutLayer(device: device, layout: _CalloutLayout.wide),
        ),
        Positioned.fill(child: _WideChrome(device: device)),
      ],
    );
  }
}

class _MediumPoster extends StatelessWidget {
  const _MediumPoster({
    required this.device,
    required this.slotDevice,
    required this.phase,
    required this.onFrameDeviceChanged,
    required this.onPhaseChanged,
  });

  final DeviceType device;
  final DeviceType slotDevice;
  final DeviceTransitionPhase phase;
  final ValueChanged<DeviceType> onFrameDeviceChanged;
  final ValueChanged<DeviceTransitionPhase> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    final metrics = PosterMetrics.of(context);
    final topBand = math.min(168.0, metrics.size.height * 0.24);
    final bottomBar = math.min(112.0, metrics.size.height * 0.18);
    final areaTop = topBand;
    final areaHeight = math.max(1.0, metrics.size.height - topBand - bottomBar);
    final railWidth = math.max(220.0, metrics.size.width * 0.29);
    final railGap = 16.0;
    final centerWidth = math.max(
      1.0,
      metrics.size.width - railWidth * 2 - railGap * 2,
    );
    final stageArea = Rect.fromLTWH(
      railWidth + railGap,
      areaTop,
      centerWidth,
      areaHeight,
    );
    final bounds = _mediumDeviceBounds(stageArea, slotDevice);

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        PosterBackdrop(
          // Fires on the rising edge of frameTransform, which is the exact
          // frame the device's content opacity reaches zero.
          sweep: SweepLight(
            isHopping: phase == DeviceTransitionPhase.frameTransform,
          ),
        ),
        GroundShadowLayer(device: device),
        _AnimatedDeviceSlot(
          bounds: bounds,
          device: device,
          onFrameDeviceChanged: onFrameDeviceChanged,
          onPhaseChanged: onPhaseChanged,
        ),
        Positioned(
          left: 0,
          top: areaTop,
          width: railWidth,
          height: areaHeight,
          child: _CalloutLayer(
            device: device,
            layout: _CalloutLayout.medium,
            side: callouts.CalloutSide.left,
          ),
        ),
        Positioned(
          right: 0,
          top: areaTop,
          width: railWidth,
          height: areaHeight,
          child: _CalloutLayer(
            device: device,
            layout: _CalloutLayout.medium,
            side: callouts.CalloutSide.right,
          ),
        ),
        Positioned.fill(
          child: _MediumChrome(
            device: device,
            topBand: topBand,
            bottomBar: bottomBar,
          ),
        ),
      ],
    );
  }
}

class _CompactPoster extends StatelessWidget {
  const _CompactPoster({
    required this.device,
    required this.phase,
    required this.onFrameDeviceChanged,
    required this.onPhaseChanged,
  });

  final DeviceType device;
  final DeviceTransitionPhase phase;
  final ValueChanged<DeviceType> onFrameDeviceChanged;
  final ValueChanged<DeviceTransitionPhase> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PosterColors.stageBlack,
        gradient: RadialGradient(
          center: Alignment(0.55, -0.15),
          radius: 1.2,
          colors: <Color>[
            PosterColors.groundRadialCore,
            PosterColors.stageBlack,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const PosterMasthead(),
            const SizedBox(height: 18),
            const _CompactWordmark(),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 832 / 486,
              child: RepaintBoundary(
                child: DeviceStage(
                  onFrameDeviceChanged: onFrameDeviceChanged,
                  onPhaseChanged: onPhaseChanged,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _CompactCallouts(device: device),
            const SizedBox(height: 28),
            const _CompactLinks(),
            const SizedBox(height: 16),
            const _CompactMeta(),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDeviceSlot extends StatelessWidget {
  const _AnimatedDeviceSlot({
    required this.bounds,
    required this.device,
    required this.onFrameDeviceChanged,
    required this.onPhaseChanged,
  });

  final Rect bounds;
  final DeviceType device;
  final ValueChanged<DeviceType> onFrameDeviceChanged;
  final ValueChanged<DeviceTransitionPhase> onPhaseChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const DeviceTransitionDurations().frameTransform,
      curve: Curves.easeInOutCubic,
      left: bounds.left,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
      child: DeviceStage(
        onFrameDeviceChanged: onFrameDeviceChanged,
        onPhaseChanged: onPhaseChanged,
      ),
    );
  }
}

class _WideChrome extends StatelessWidget {
  const _WideChrome({required this.device});

  final DeviceType device;

  @override
  Widget build(BuildContext context) {
    return PosterChrome(device: device);
  }
}

class _MediumChrome extends StatelessWidget {
  const _MediumChrome({
    required this.device,
    required this.topBand,
    required this.bottomBar,
  });

  final DeviceType device;
  final double topBand;
  final double bottomBar;

  @override
  Widget build(BuildContext context) {
    final metrics = PosterMetrics.of(context);
    final double wordmarkWidth = math.min(
      metrics.size.width * 0.48,
      metrics.px(760),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(left: 20, top: 16, child: const PosterMasthead()),
        Positioned(
          left: 20,
          top: 54,
          width: wordmarkWidth,
          height: math.max(1.0, topBand - 58),
          child: const FittedBox(
            alignment: Alignment.topLeft,
            fit: BoxFit.contain,
            child: PosterWordmark(),
          ),
        ),
        Positioned(
          left: 16,
          bottom: bottomBar - 2,
          child: const _ScaledLinks(),
        ),
        Positioned(left: 16, bottom: 10, child: const _ScaledMeta()),
        Positioned(
          right: 66,
          bottom: 8,
          child: const InspectionStamp(),
        ),
      ],
    );
  }
}

class _CompactWordmark extends StatelessWidget {
  const _CompactWordmark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: FittedBox(
        alignment: Alignment.topLeft,
        fit: BoxFit.scaleDown,
        child: PosterWordmark(),
      ),
    );
  }
}

class _CompactLinks extends StatelessWidget {
  const _CompactLinks();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: PosterLinks(),
      ),
    );
  }
}

class _CompactMeta extends StatelessWidget {
  const _CompactMeta();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: PosterMeta(),
      ),
    );
  }
}

class _ScaledLinks extends StatelessWidget {
  const _ScaledLinks();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 260,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: PosterLinks(),
      ),
    );
  }
}

class _ScaledMeta extends StatelessWidget {
  const _ScaledMeta();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 230,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: PosterMeta(),
      ),
    );
  }
}

enum _CalloutLayout { wide, medium }

class _CalloutLayer extends StatelessWidget {
  const _CalloutLayer({required this.device, required this.layout, this.side});

  final DeviceType device;
  final _CalloutLayout layout;
  final callouts.CalloutSide? side;

  @override
  Widget build(BuildContext context) {
    if (layout == _CalloutLayout.wide) {
      return Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          _CalloutSideLayer(
            device: device,
            layout: layout,
            side: callouts.CalloutSide.left,
          ),
          _CalloutSideLayer(
            device: device,
            layout: layout,
            side: callouts.CalloutSide.right,
          ),
        ],
      );
    }
    return _CalloutSideLayer(
      device: device,
      layout: layout,
      side: side ?? callouts.CalloutSide.left,
    );
  }
}

class _CalloutSideLayer extends StatefulWidget {
  const _CalloutSideLayer({
    required this.device,
    required this.layout,
    required this.side,
  });

  final DeviceType device;
  final _CalloutLayout layout;
  final callouts.CalloutSide side;

  @override
  State<_CalloutSideLayer> createState() => _CalloutSideLayerState();
}

class _CalloutSideLayerState extends State<_CalloutSideLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _exit;
  late final Animation<double> _entry;
  DeviceType? _outgoing;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // The rails read as prose, not chrome: they run the full length of the
      // device hop, not the frame morph, which is far too quick to read a
      // sentence out of.
      duration: _kCalloutSwap,
    );
    _exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4),
    );
    _entry = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1),
    );
  }

  @override
  void didUpdateWidget(covariant _CalloutSideLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final settled =
            _outgoing == null ||
            _controller.status == AnimationStatus.completed;
        if (settled) {
          return _buildCalloutSet(context, widget.device);
        }

        final bool showingOutgoing = _controller.value < 0.5;
        final DeviceType shownDevice = showingOutgoing
            ? _outgoing!
            : widget.device;
        final Animation<double> transition = showingOutgoing ? _exit : _entry;
        final motion.CalloutMotif motif = _motifFor(shownDevice);

        return motion.CalloutTransition(
          motif: motif,
          animation: transition,
          entering: !showingOutgoing,
          side: _motionSide(widget.side),
          child: _buildCalloutSet(
            context,
            shownDevice,
          ),
        );
      },
    );
  }

  Widget _buildCalloutSet(
    BuildContext context,
    DeviceType device,
  ) {
    final set = callouts.calloutSets[_calloutDevice(device)]!;
    final specs = set.where(
      (spec) =>
          _visibleIndexes(widget.layout).contains(spec.index) &&
          spec.side == widget.side,
    );
    if (widget.layout == _CalloutLayout.wide) {
      return Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (final spec in specs)
            _WideCalloutItem(spec: spec),
        ],
      );
    }
    return _MediumCalloutSet(
      specs: specs.toList(growable: false),
    );
  }

  List<int> _visibleIndexes(_CalloutLayout layout) {
    if (layout == _CalloutLayout.wide) {
      return const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    }
    return switch (widget.side) {
      callouts.CalloutSide.left => const <int>[1, 3, 5, 9],
      callouts.CalloutSide.right => const <int>[6, 10],
    };
  }
}

class _WideCalloutItem extends StatelessWidget {
  const _WideCalloutItem({required this.spec});

  final callouts.CalloutSpec spec;

  @override
  Widget build(BuildContext context) {
    final metrics = PosterMetrics.of(context);
    final cardWidth = metrics.px(spec.widthFx * 1920);
    final left = _wideCalloutLeft(metrics.size, spec, cardWidth);

    return Positioned(
      left: left,
      top: spec.anchorFy * metrics.size.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          CalloutCard(spec: spec),
        ],
      ),
    );
  }
}

class _MediumCalloutSet extends StatelessWidget {
  const _MediumCalloutSet({required this.specs});

  final List<callouts.CalloutSpec> specs;

  @override
  Widget build(BuildContext context) {
    if (specs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final spec in specs)
          Expanded(
            child: Align(
              alignment: spec.side == callouts.CalloutSide.left
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: FittedBox(
                alignment: spec.side == callouts.CalloutSide.left
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: _MediumCalloutItem(
                  spec: spec,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MediumCalloutItem extends StatelessWidget {
  const _MediumCalloutItem({required this.spec});

  final callouts.CalloutSpec spec;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        CalloutCard(spec: spec),
      ],
    );
  }
}

/// How long a callout set takes to leave and be replaced when the device
/// changes — the full device-hop timeline (fade out, blank, morph, blank, fade
/// in), so the text drifts out and back at exactly the pace of everything else
/// on screen. Both callout layers — the wide side rails and the compact set —
/// share it.
final Duration _kCalloutSwap = const DeviceTransitionDurations().total;

class _CompactCallouts extends StatelessWidget {
  const _CompactCallouts({required this.device});

  final DeviceType device;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      // Deliberately not the frame morph's duration: the callouts are prose and
      // need to stay readable on the way out, so they cross-fade on their own,
      // slower clock while the shell reshapes underneath them.
      duration: _kCalloutSwap,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            return Opacity(
              opacity: animation.value,
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - animation.value)),
                child: child,
              ),
            );
          },
        );
      },
      child: _CompactCalloutSet(
        key: ValueKey<DeviceType>(device),
        device: device,
      ),
    );
  }
}

class _CompactCalloutSet extends StatelessWidget {
  const _CompactCalloutSet({super.key, required this.device});

  final DeviceType device;

  @override
  Widget build(BuildContext context) {
    final metrics = PosterMetrics.of(context);
    final specs = callouts.calloutSets[_calloutDevice(device)]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int index = 0; index < specs.length; index++) ...<Widget>[
          if (index > 0) const SizedBox(height: 18),
          _CompactCalloutRow(spec: specs[index], metrics: metrics),
        ],
      ],
    );
  }
}

class _CompactCalloutRow extends StatelessWidget {
  const _CompactCalloutRow({required this.spec, required this.metrics});

  final callouts.CalloutSpec spec;
  final PosterMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CalloutCard(
                spec: spec,
                widthDesignPx: constraints.maxWidth / metrics.f,
              );
            },
          ),
        ),
      ],
    );
  }
}

Rect _wideDeviceBounds(Size size, DeviceType device) {
  final geometry = _geometryFor(device);
  return Rect.fromLTWH(
    geometry.left * size.width,
    geometry.top * size.height,
    geometry.width * size.width,
    geometry.height * size.height,
  );
}

Rect _mediumDeviceBounds(Rect stageArea, DeviceType device) {
  final (widthFactor, heightFactor) = switch (device) {
    DeviceType.desktop => (0.92, 0.72),
    DeviceType.mobile => (0.48, 0.90),
    DeviceType.tablet => (0.92, 0.80),
  };
  final width = stageArea.width * widthFactor;
  final height = stageArea.height * heightFactor;
  return Rect.fromLTWH(
    stageArea.left + (stageArea.width - width) / 2,
    stageArea.top + (stageArea.height - height) / 2,
    width,
    height,
  );
}

double _wideCalloutLeft(
  Size size,
  callouts.CalloutSpec spec,
  double cardWidth,
) {
  final desired = spec.anchorFx * size.width;
  final chipOverflow = size.width / 1920 * 28;
  final minimum = chipOverflow;
  final maximum = math.max(minimum, size.width - cardWidth - chipOverflow);
  return desired.clamp(minimum, maximum).toDouble();
}

_DeviceGeometry _geometryFor(DeviceType device) {
  return switch (device) {
    DeviceType.desktop => const _DeviceGeometry(0.527, 0.243, 0.433, 0.450),
    DeviceType.mobile => const _DeviceGeometry(0.677, 0.191, 0.190, 0.646),
    DeviceType.tablet => const _DeviceGeometry(0.523, 0.231, 0.454, 0.556),
  };
}

motion.CalloutSide _motionSide(callouts.CalloutSide side) {
  return side == callouts.CalloutSide.left
      ? motion.CalloutSide.left
      : motion.CalloutSide.right;
}

motion.CalloutMotif _motifFor(DeviceType device) {
  return switch (device) {
    DeviceType.desktop => motion.CalloutMotif.sweep,
    DeviceType.mobile => motion.CalloutMotif.trapdoor,
    DeviceType.tablet => motion.CalloutMotif.siphon,
  };
}

callouts.DeviceType _calloutDevice(DeviceType device) {
  return switch (device) {
    DeviceType.desktop => callouts.DeviceType.desktop,
    DeviceType.mobile => callouts.DeviceType.mobile,
    DeviceType.tablet => callouts.DeviceType.tablet,
  };
}

class _DeviceGeometry {
  const _DeviceGeometry(this.left, this.top, this.width, this.height);

  final double left;
  final double top;
  final double width;
  final double height;
}
