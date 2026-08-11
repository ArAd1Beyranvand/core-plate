import 'package:flutter/material.dart';
import 'package:plate_number/model/plate_number.dart';

import '../device_preview/device_frame.dart';
import '../widgets/plate_display.dart';

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
            children: DevicePreset.values.map((preset) {
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
          if (_settings.device == DevicePreset.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Width',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: _settings.customWidth?.toStringAsFixed(0) ?? '360',
                    ),
                    onChanged: (v) {
                      final w = double.tryParse(v);
                      if (w != null) {
                        _update((s) => s.copyWith(customWidth: w));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Height',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                      text: _settings.customHeight?.toStringAsFixed(0) ?? '640',
                    ),
                    onChanged: (v) {
                      final h = double.tryParse(v);
                      if (h != null) {
                        _update((s) => s.copyWith(customHeight: h));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          _sectionHeader('Scale'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('0.5'),
              Expanded(
                child: Slider(
                  value: _settings.scale,
                  min: 0.5,
                  max: 1.5,
                  divisions: 20,
                  label: _settings.scale.toStringAsFixed(2),
                  onChanged: (v) {
                    _update((s) => s.copyWith(scale: v));
                  },
                ),
              ),
              const Text('1.5'),
            ],
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
  final DevicePreset device;
  final double? customWidth;
  final double? customHeight;
  final double scale;
  final double spacingScale;
  final ShowcaseMode mode;
  final bool isDark;
  final Color activeColor;

  const ShowcaseSettings({
    required this.plateType,
    required this.device,
    this.customWidth,
    this.customHeight,
    required this.scale,
    required this.spacingScale,
    required this.mode,
    required this.isDark,
    required this.activeColor,
  });

  static const defaults = ShowcaseSettings(
    plateType: PlateType.irCar,
    device: DevicePreset.largePhone,
    scale: 1.0,
    spacingScale: 6,
    mode: ShowcaseMode.input,
    isDark: false,
    activeColor: Colors.blueAccent,
  );

  ShowcaseSettings copyWith({
    PlateType? plateType,
    DevicePreset? device,
    double? customWidth,
    double? customHeight,
    double? scale,
    double? spacingScale,
    ShowcaseMode? mode,
    bool? isDark,
    Color? activeColor,
  }) {
    return ShowcaseSettings(
      plateType: plateType ?? this.plateType,
      device: device ?? this.device,
      customWidth: customWidth ?? this.customWidth,
      customHeight: customHeight ?? this.customHeight,
      scale: scale ?? this.scale,
      spacingScale: spacingScale ?? this.spacingScale,
      mode: mode ?? this.mode,
      isDark: isDark ?? this.isDark,
      activeColor: activeColor ?? this.activeColor,
    );
  }
}
