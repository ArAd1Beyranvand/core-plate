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
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 44,
                ),
                child: Column(
                  children: const [
                    PosterHeader(),
                    Expanded(child: _PosterBody()),
                    PosterFooter(),
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
    return isSmallScreen;
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
    builder: (context, constraints) => constraints.maxWidth >= _wideBreakpoint
        ? _WideBody(
            device: _railDevice,
            onFrameDeviceChanged: _onFrameDeviceChanged,
          )
        : _StackedBody(
            device: _railDevice,
            onFrameDeviceChanged: _onFrameDeviceChanged,
          ),
  );
}

/// Three columns: animated callout rails flanking the device, connectors
/// pointing inward.
class _WideBody extends StatelessWidget {
  const _WideBody({required this.device, required this.onFrameDeviceChanged});

  final DeviceType device;
  final ValueChanged<DeviceType> onFrameDeviceChanged;

  @override
  Widget build(BuildContext context) {
    final motifs = calloutMotifs[device]!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: CalloutRail(
            device: device,
            side: CalloutSide.left,
            exitMotif: motifs.exit,
            entryMotif: motifs.entry,
          ),
        ),
        Expanded(
          child: DeviceStage(onFrameDeviceChanged: onFrameDeviceChanged),
        ),
        SizedBox(
          width: 360,
          child: CalloutRail(
            device: device,
            side: CalloutSide.right,
            exitMotif: motifs.exit,
            entryMotif: motifs.entry,
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
    return Column(
      children: [
        Expanded(
          child: DeviceStage(onFrameDeviceChanged: onFrameDeviceChanged),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 48,
          runSpacing: 28,
          children: [
            for (final c in [...set.left, ...set.right])
              SizedBox(
                width: 300,
                child: CalloutWithConnector(callout: c, showConnector: false),
              ),
          ],
        ),
      ],
    );
  }
}
