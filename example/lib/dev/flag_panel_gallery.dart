import 'package:flutter/material.dart';
import 'package:plate_number/model/plate_country.dart';
import 'package:plate_number/theme/plate_theme.dart';
import 'package:plate_number/widgets/country_panel.dart';
import 'package:plate_number/widgets/plate_flag.dart';

/// A tiny widgetbook-style gallery to eyeball [PlateFlag] and [CountryPanel]
/// across sizes. Run with:
///
///   flutter run -t lib/dev/flag_panel_gallery.dart
void main() => runApp(const FlagPanelGallery());

class FlagPanelGallery extends StatelessWidget {
  const FlagPanelGallery({super.key});

  static const _heights = [24.0, 60.0, 200.0];

  @override
  Widget build(BuildContext context) {
    final theme = PlateTheme.standard();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFDDDDDD),
        appBar: AppBar(title: const Text('PlateFlag / CountryPanel')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section(
                'PlateFlag (ir, 7:4)',
                _heights
                    .map((h) => _tile(
                          label: '${h.toInt()}px',
                          height: h,
                          child: SizedBox(
                            height: h,
                            width: h * 7 / 4,
                            child: const PlateFlag(countryCode: 'ir'),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              _section(
                'CountryPanel',
                _heights
                    .map((h) => _tile(
                          label: '${h.toInt()}px',
                          height: h,
                          child: SizedBox(
                            height: h,
                            width: h, // square-ish
                            child: CountryPanel(
                              theme: theme,
                              country: PlateCountry.iran,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 32, runSpacing: 32, crossAxisAlignment: WrapCrossAlignment.end, children: tiles),
      ],
    );
  }

  Widget _tile({required String label, required double height, required Widget child}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
