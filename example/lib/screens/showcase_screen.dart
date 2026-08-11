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
      data: _settings.isDark ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Plate Number Showcase'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'About',
              onPressed: () => _showAboutDialog(context),
            ),
          ],
        ),
        body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
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
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(16),
      child: DeviceFrame(
        device: _settings.device,
        customWidth: _settings.customWidth,
        customHeight: _settings.customHeight,
        scale: _settings.scale,
        child: PlateDisplay(
          plateType: _settings.plateType,
          mode: _settings.mode,
          activeColor: _settings.activeColor,
          spacingScale: _settings.spacingScale,
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plate Number Package'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A Flutter package for capturing and displaying '
              'Iranian vehicle plate numbers.',
            ),
            SizedBox(height: 12),
            Text(
              'Supports car and motorcycle plates with '
              'customizable styling and interactive input.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
