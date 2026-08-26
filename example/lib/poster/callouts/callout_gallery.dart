import 'package:flutter/material.dart';

import '../poster_scale.dart';
import '../poster_tokens.dart';
import 'callout_card.dart';
import 'callout_data.dart';

class CalloutGallery extends StatefulWidget {
  const CalloutGallery({super.key});

  @override
  State<CalloutGallery> createState() => _CalloutGalleryState();
}

class _CalloutGalleryState extends State<CalloutGallery> {
  late int _activeDeviceIndex;

  @override
  void initState() {
    super.initState();
    _activeDeviceIndex = 0;
  }

  List<CalloutSpec> get _currentCallouts {
    final types = [DeviceType.desktop, DeviceType.mobile, DeviceType.tablet];
    return calloutSets[types[_activeDeviceIndex]] ?? [];
  }

  String _deviceLabel(int index) {
    switch (index) {
      case 0:
        return 'Desktop (01–04)';
      case 1:
        return 'Mobile (05–08)';
      case 2:
        return 'Tablet (09–12)';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PosterColors.pageBlack,
      appBar: AppBar(
        title: const Text('Callout Cards Gallery'),
        backgroundColor: PosterColors.stageBlack,
      ),
      body: Column(
        children: <Widget>[
          // Device selector
          Container(
            color: PosterColors.stageBlack,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _activeDeviceIndex = i),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _activeDeviceIndex == i
                            ? PosterColors.accent
                            : PosterColors.stageBlack,
                        foregroundColor: _activeDeviceIndex == i
                            ? Colors.white
                            : PosterColors.inkDisplay1,
                      ),
                      child: Text(_deviceLabel(i)),
                    ),
                  ),
              ],
            ),
          ),
          // Cards grid
          Expanded(
            child: PosterMetricsScope(
              child: Builder(
                builder: (context) {
                  return ListView(
                    padding: const EdgeInsets.all(32),
                    children: <Widget>[
                      for (final spec in _currentCallouts)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: CalloutCard(spec: spec),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
