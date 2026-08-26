import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../device_preview/device_config.dart' show DeviceType;
import '../poster/backdrop/ground_shadow.dart';
import '../poster/backdrop/poster_backdrop.dart';
import '../poster/backdrop/sweep_light.dart';
import '../poster/chrome/poster_chrome.dart';
import '../poster/poster_scale.dart';
import '../poster/poster_tokens.dart';

/// A throwaway gallery for the DESIGN_SPEC.md §6 road backdrop, its sweep
/// light (§6.10), the ground shadow, and the P6 chrome layer.
///
///   S — fire the sweep once (what a device hop does)
///   D — cycle the device: desktop → mobile → tablet (moves the ground
///       shadow, the stamp and the active pip)
///   C — toggle the chrome layer on/off (to inspect the backdrop alone)
///
/// The tier tab renders the backdrop at a fixed size per `PosterTier` so the
/// wedge, rails and lane dashes can be checked as the stage box changes shape.
/// Run with:
///
///   flutter run -t lib/dev/backdrop_gallery.dart
void main() => runApp(const BackdropGallery());

class BackdropGallery extends StatelessWidget {
  const BackdropGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: PosterColors.pageBlack,
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: <Widget>[
              const Material(
                color: PosterColors.pageBlack,
                child: TabBar(
                  labelColor: PosterColors.inkDisplay1,
                  unselectedLabelColor: PosterColors.inkMetaWeak,
                  indicatorColor: PosterColors.accent,
                  tabs: <Widget>[
                    Tab(text: 'Live window  (S sweep · D device)'),
                    Tab(text: 'Tier previews'),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _LiveStage(),
                    _TierPreviews(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full-window backdrop with the two P5 layers over it, driven by the
/// keyboard instead of by a real device hop.
class _LiveStage extends StatefulWidget {
  const _LiveStage();

  @override
  State<_LiveStage> createState() => _LiveStageState();
}

class _LiveStageState extends State<_LiveStage> {
  static const List<DeviceType> _order = <DeviceType>[
    DeviceType.desktop,
    DeviceType.mobile,
    DeviceType.tablet,
  ];

  final FocusNode _focus = FocusNode();
  int _deviceIndex = 0;
  bool _hopping = false;
  bool _chrome = true;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Mimics `DeviceFrame.onPhaseChanged`: a rising edge, then back to idle.
  /// `SweepLight` fires on the edge, so the hold only has to outlast the
  /// 1.5s sweep.
  Future<void> _hop() async {
    if (_hopping) return;
    setState(() => _hopping = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _hopping = false);
  }

  void _cycleDevice() {
    setState(() => _deviceIndex = (_deviceIndex + 1) % _order.length);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.keyS) {
      _hop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyD) {
      _cycleDevice();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyC) {
      setState(() => _chrome = !_chrome);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final DeviceType device = _order[_deviceIndex];
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: PosterMetricsScope(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const PosterBackdrop(),
            GroundShadowLayer(device: device),
            SweepLight(isHopping: _hopping),
            // The chrome sits in its own layer ABOVE everything (see
            // PosterChrome / §9.1). Here it hangs over the bare backdrop; in
            // the real screen (P9) the callout layer goes between.
            if (_chrome) PosterChrome(device: device),
            Positioned(
              left: 20,
              bottom: 20,
              child: Text(
                'S — sweep${_hopping ? ' (running)' : ''}   ·   '
                'D — ${device.name}   ·   '
                'C — chrome ${_chrome ? 'on' : 'off'}',
                style: const TextStyle(
                  fontFamily: PosterFonts.martianMono,
                  fontSize: 12,
                  color: PosterColors.inkMetaWeak,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierPreviews extends StatelessWidget {
  const _TierPreviews();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          _Preview(
            label: 'wide — 1920 × 1080 (design canvas)',
            width: 1920,
            height: 1080,
          ),
          _Preview(label: 'wide — 1280 × 720', width: 1280, height: 720),
          _Preview(label: 'medium — 900 × 620', width: 900, height: 620),
          _Preview(
            label: 'compact — 420 × 780 (portrait)',
            width: 420,
            height: 780,
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.label,
    required this.width,
    required this.height,
  });

  final String label;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: PosterFonts.martianMono,
                fontSize: 12,
                color: PosterColors.inkMetaWeak,
              ),
            ),
          ),
          // Each preview scales its own box down to fit the gallery column
          // while keeping the stage's real aspect ratio, so PosterMetrics sees
          // the size the tier is meant to be.
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double scale = constraints.maxWidth < width
                  ? constraints.maxWidth / width
                  : 1.0;
              return SizedBox(
                width: width * scale,
                height: height * scale,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: const PosterMetricsScope(child: PosterBackdrop()),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
