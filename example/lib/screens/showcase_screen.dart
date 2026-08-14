import 'package:flutter/material.dart';

import '../controls/controls_panel.dart';
import '../device_preview/device_frame.dart';
import '../widgets/plate_display.dart';

class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  ShowcaseSettings _settings = ShowcaseSettings.defaults;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 840;

    return Theme(
      data: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _settings.activeColor,
          brightness: _settings.isDark ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      child: Scaffold(
        body: SafeArea(
          child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildPreviewArea(),
        ),
        const VerticalDivider(width: 1),
        SizedBox(
          width: 320,
          child: ShowcaseControls(
            settings: _settings,
            onChanged: (updated) => setState(() => _settings = updated),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _buildPreviewArea(),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: ShowcaseControls(
            settings: _settings,
            onChanged: (updated) => setState(() => _settings = updated),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewArea() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surfaceContainerLowest,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            // Isolate the device + plate in its own layer. It is expensive to
            // raster (perspective transform, nested FittedBoxes, clips and live
            // TextFields), and on Linux an instant window maximise that forces a
            // full re-raster of it can miss the GL embedder's frame deadline and
            // crash the app with "Timed out waiting for OpenGL frame". A
            // RepaintBoundary lets the resize composite the cached layer instead
            // of re-rendering it from scratch.
            child: RepaintBoundary(
              child: DeviceFrame(
                device: _settings.device,
                builder: (context, config) => PlateDisplay(
                  plateType: _settings.plateType,
                  mode: _settings.mode,
                  activeColor: _settings.activeColor,
                  spacingScale: _settings.spacingScale,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'plate_number',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Iranian vehicle plate capture & display for Flutter',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _CapabilityChip('Car & motorcycle plates'),
              _CapabilityChip('Customizable styling'),
              _CapabilityChip('Interactive input'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
    );
  }
}
