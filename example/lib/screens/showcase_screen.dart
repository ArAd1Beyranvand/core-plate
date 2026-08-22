import 'package:flutter/material.dart';

import '../device_preview/device_config.dart';
import '../poster/poster_tokens.dart';
import '../poster/annotation_callout.dart';
import '../poster/callout_content.dart';
import '../poster/callout_motion.dart';
import '../poster/callout_rail.dart';
import '../poster/corner_brackets.dart';
import '../poster/grid_backdrop.dart';
import '../poster/poster_footer.dart';
import '../poster/poster_header.dart';
import '../showcase/device_stage.dart';

/// The non-interactive "spec poster" showcase: a device cycling through form
/// factors at the centre, ringed by numbered annotation callouts.
class ShowcaseScreen extends StatelessWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = _isAndroidMobile(context);
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscapePhone =
        mediaQuery.orientation == Orientation.landscape &&
        mediaQuery.size.height < 500;

    return Scaffold(
      backgroundColor: PosterTokens.bg,
      body: Stack(
        children: [
          if (!isMobile) const Positioned.fill(child: GridBackdrop()),
          if (!isMobile) const Positioned.fill(child: CornerBrackets()),
          if (isMobile)
            const Center(child: DeviceStage())
          else
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscapePhone ? 16 : 56,
                  vertical: isLandscapePhone ? 8 : 44,
                ),
                child: Column(
                  children: [
                    if (!isLandscapePhone) const PosterHeader(),
                    const Expanded(child: _PosterBody()),
                    if (!isLandscapePhone) const PosterFooter(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static bool _isAndroidMobile(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 600;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    return isSmallScreen && isPortrait;
  }
}

/// Below this logical width the three-column poster collapses to a stack.
const double _wideBreakpoint = 1080;

/// The motif pairing for each hop, keyed by the device the hop lands on:
/// how the previous set left, and how this set arrives.
///
/// The cycle is desktop -> mobile -> tablet (see DeviceCycle.order), so:
/// the laptop's callouts sweep out sideways and the mobile's sweep in; the
/// mobile's fall through a trapdoor and the tablet's drop in from one above;
/// the tablet's siphon into their connector dots and the laptop's are emitted
/// back out of them.
const Map<DeviceType, ({CalloutMotif exit, CalloutMotif entry})> calloutMotifs =
    {
      DeviceType.desktop: (
        exit: CalloutMotif.siphon,
        entry: CalloutMotif.siphon,
      ),
      DeviceType.mobile: (exit: CalloutMotif.sweep, entry: CalloutMotif.sweep),
      DeviceType.tablet: (
        exit: CalloutMotif.trapdoor,
        entry: CalloutMotif.trapdoor,
      ),
    };

class _PosterBody extends StatefulWidget {
  const _PosterBody();

  @override
  State<_PosterBody> createState() => _PosterBodyState();
}

class _PosterBodyState extends State<_PosterBody> {
  /// The device the callout rails are showing. Tracks the FRAME device, so it
  /// flips at the start of a hop rather than at the content swap. Seeded to
  /// DeviceCycle.order's first entry.
  DeviceType _railDevice = DeviceType.desktop;

  void _onFrameDeviceChanged(DeviceType device) {
    if (!mounted || _railDevice == device) return;
    setState(() => _railDevice = device);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final bool isWide = constraints.maxWidth >= _wideBreakpoint;
      // A short, wide viewport (mobile landscape) still reads better as
      // rails-flanking-the-device than as the stacked grid — it just needs
      // the rails and callout type shrunk to fit.
      final mediaQuery = MediaQuery.of(context);
      final bool isLandscapePhone =
          mediaQuery.orientation == Orientation.landscape &&
          mediaQuery.size.height < 500;

      if (isWide || isLandscapePhone) {
        return _WideBody(
          device: _railDevice,
          onFrameDeviceChanged: _onFrameDeviceChanged,
          compact: !isWide,
        );
      }
      return _StackedBody(
        device: _railDevice,
        onFrameDeviceChanged: _onFrameDeviceChanged,
      );
    },
  );
}

/// Three columns: animated callout rails flanking the device, connectors
/// pointing inward.
class _WideBody extends StatelessWidget {
  const _WideBody({
    required this.device,
    required this.onFrameDeviceChanged,
    this.compact = false,
  });

  final DeviceType device;
  final ValueChanged<DeviceType> onFrameDeviceChanged;

  /// Shrinks the rails for a short, wide viewport (mobile landscape) where
  /// a full 360px rail on each side would crowd out the device.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final motifs = calloutMotifs[device]!;
    final double railWidth = compact ? 150 : 360;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: railWidth,
          child: CalloutRail(
            device: device,
            side: CalloutSide.left,
            exitMotif: motifs.exit,
            entryMotif: motifs.entry,
            compact: compact,
          ),
        ),
        Expanded(
          child: DeviceStage(onFrameDeviceChanged: onFrameDeviceChanged),
        ),
        SizedBox(
          width: railWidth,
          child: CalloutRail(
            device: device,
            side: CalloutSide.right,
            exitMotif: motifs.exit,
            entryMotif: motifs.entry,
            compact: compact,
          ),
        ),
      ],
    );
  }
}

/// Narrow layout: the device on top, callouts as a connector-less 2x2 grid.
/// No animation on this layout — it just rebuilds from the current set.
class _StackedBody extends StatelessWidget {
  const _StackedBody({
    required this.device,
    required this.onFrameDeviceChanged,
  });

  final DeviceType device;
  final ValueChanged<DeviceType> onFrameDeviceChanged;

  @override
  Widget build(BuildContext context) {
    final set = calloutSets[device]!;
    // A short viewport (mobile landscape) can't fit the poster's full-size
    // callout type without the 2x2 grid overflowing or crowding the device
    // stage, so it renders a smaller variant instead.
    final bool compact = MediaQuery.of(context).size.height < 500;
    return Column(
      children: [
        Expanded(
          child: DeviceStage(onFrameDeviceChanged: onFrameDeviceChanged),
        ),
        SizedBox(height: compact ? 12 : 24),
        Wrap(
          spacing: compact ? 24 : 48,
          runSpacing: compact ? 14 : 28,
          children: [
            for (final c in [...set.left, ...set.right])
              SizedBox(
                width: compact ? 180 : 300,
                child: CalloutWithConnector(
                  callout: c.withCompact(compact),
                  showConnector: false,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
