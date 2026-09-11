import 'package:flutter/material.dart';

import '../sources/sources.dart';

/// What this app is, and which package draws which plates.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// The versions this app is built against. Written out rather than read from
  /// a generated file: an app that wants its own dependency versions at runtime
  /// needs a build step, and this is a showcase.
  static const List<(String, String)> _packages = <(String, String)>[
    ('core_plate', '0.5.0'),
    ('core_plate_bloc', '0.1.0'),
    ('plate_keypad', '0.1.0'),
    ('iran_plate', '0.1.0'),
    ('germany_plate', '0.1.0'),
    ('palestine_plate', '0.2.0'),
    ('yemen_plate', '0.3.0'),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Text('plate_gallery', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'One app for every country package in this repo. Each package ships '
          'a ~30-line example that draws one plate; the catalogue and the '
          'playground live here instead, so no publishable package carries a '
          'showcase.\n\n'
          'A plate is three independent render-time inputs: a PlateSpec for '
          'geometry, a PlateTheme for colour and a PlateCountry for the panel '
          'block. Nothing in this app depends on a country package knowing '
          'about any other, and no country package depends on this app.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 28),
        Text('Countries', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final GallerySource source in gallerySources)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${source.countryName} · ${source.packageName}'),
            subtitle: Text(source.note),
            trailing: Text(
              '${source.specIds.length} specs',
              style: theme.textTheme.labelSmall,
            ),
          ),
        const SizedBox(height: 20),
        Text('Built against', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final (String name, String version) in _packages)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '$name $version',
              style: theme.textTheme.bodySmall?.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }
}
