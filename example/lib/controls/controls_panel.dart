import 'package:flutter/material.dart';
import 'package:plate_number/model/plate_number.dart';

import '../device_preview/device_config.dart';
import '../widgets/plate_display.dart';

extension on DeviceType {
  String get label => switch (this) {
        DeviceType.mobile => 'Mobile',
        DeviceType.tablet => 'Tablet',
        DeviceType.desktop => 'Laptop',
      };
}

class ShowcaseControls extends StatefulWidget {
  const ShowcaseControls({
    super.key,
    required this.onChanged,
    required this.settings,
  });

  final ValueChanged<ShowcaseSettings> onChanged;
  final ShowcaseSettings settings;

  @override
  State<ShowcaseControls> createState() => _ShowcaseControlsState();
}

class _ShowcaseControlsState extends State<ShowcaseControls> {
  late ShowcaseSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _update(ShowcaseSettings Function(ShowcaseSettings) transform) {
    setState(() {
      _settings = transform(_settings);
    });
    widget.onChanged(_settings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Plate Type'),
          const SizedBox(height: 8),
          SegmentedButton<PlateType>(
            segments: const [
              ButtonSegment(value: PlateType.irCar, label: Text('Car')),
              ButtonSegment(
                value: PlateType.irBicycle,
                label: Text('Motorcycle'),
              ),
            ],
            selected: {_settings.plateType},
            onSelectionChanged: (selection) {
              _update((s) => s.copyWith(plateType: selection.first));
            },
          ),
          const SizedBox(height: 20),
          _sectionHeader('Device'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DeviceType.values.map((preset) {
              final isSelected = _settings.device == preset;
              return ChoiceChip(
                label: Text(preset.label),
                selected: isSelected,
                onSelected: (_) {
                  _update((s) => s.copyWith(device: preset));
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionHeader('Spacing Scale'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('2'),
              Expanded(
                child: Slider(
                  value: _settings.spacingScale,
                  min: 2,
                  max: 16,
                  divisions: 14,
                  label: _settings.spacingScale.toStringAsFixed(0),
                  onChanged: (v) {
                    _update((s) => s.copyWith(spacingScale: v));
                  },
                ),
              ),
              const Text('16'),
            ],
          ),
          const SizedBox(height: 20),
          _sectionHeader('Mode'),
          const SizedBox(height: 8),
          SegmentedButton<ShowcaseMode>(
            segments: const [
              ButtonSegment(
                value: ShowcaseMode.input,
                label: Text('Input'),
                icon: Icon(Icons.edit),
              ),
              ButtonSegment(
                value: ShowcaseMode.display,
                label: Text('Display'),
                icon: Icon(Icons.visibility),
              ),
            ],
            selected: {_settings.mode},
            onSelectionChanged: (selection) {
              _update((s) => s.copyWith(mode: selection.first));
            },
          ),
          const SizedBox(height: 20),
          _sectionHeader('Theme'),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark Mode'),
            value: isDark,
            onChanged: (v) {
              _update((s) => s.copyWith(isDark: v));
            },
          ),
          const SizedBox(height: 20),
          _sectionHeader('Active Color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Colors.blueAccent,
              Colors.pinkAccent,
              Colors.teal,
              Colors.orange,
              Colors.purple,
              Colors.green,
            ].map((color) {
              final isSelected = _settings.activeColor == color;
              return GestureDetector(
                onTap: () => _update((s) => s.copyWith(activeColor: color)),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.onSurface, width: 3)
                        : null,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class ShowcaseSettings {
  final PlateType plateType;
  final DeviceType device;
  final double spacingScale;
  final ShowcaseMode mode;
  final bool isDark;
  final Color activeColor;

  const ShowcaseSettings({
    required this.plateType,
    required this.device,
    required this.spacingScale,
    required this.mode,
    required this.isDark,
    required this.activeColor,
  });

  static const defaults = ShowcaseSettings(
    plateType: PlateType.irCar,
    device: DeviceType.mobile,
    spacingScale: 6,
    mode: ShowcaseMode.input,
    isDark: true,
    activeColor: Colors.blueAccent,
  );

  ShowcaseSettings copyWith({
    PlateType? plateType,
    DeviceType? device,
    double? spacingScale,
    ShowcaseMode? mode,
    bool? isDark,
    Color? activeColor,
  }) {
    return ShowcaseSettings(
      plateType: plateType ?? this.plateType,
      device: device ?? this.device,
      spacingScale: spacingScale ?? this.spacingScale,
      mode: mode ?? this.mode,
      isDark: isDark ?? this.isDark,
      activeColor: activeColor ?? this.activeColor,
    );
  }
}
