import 'package:flutter/material.dart';

import '../sources/sources.dart';
import '../widgets/plate_card.dart';
import '../widgets/section_header.dart';

/// Every entry from every source, grouped by country and then by section.
///
/// This subsumes the two `gallery.dart` files and the "Every type" tab of the
/// two `main.dart` files — four pages that showed two countries between them.
/// The plates are read-only, filled from each entry's sample value; tap one to
/// open it in the playground.
class CatalogueScreen extends StatelessWidget {
  const CatalogueScreen({super.key, required this.onOpen});

  final ValueChanged<GalleryEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int total = gallerySources.fold(
      0,
      (int n, GallerySource s) => n + s.entries.length,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Text(
          'All $total plates the four country packages can draw. A card is a '
          'geometry, a livery and a country block — so two cards can share a '
          'spec and still be two different plates.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        for (final GallerySource source in gallerySources) ...<Widget>[
          Text(source.countryName, style: theme.textTheme.headlineSmall),
          Text(
            source.packageName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final GallerySection section in source.sections) ...<Widget>[
            SectionHeader(
              title: section.title,
              note: section.note,
              count: section.entries.length,
            ),
            const SizedBox(height: 12),
            PlateCardGrid(entries: section.entries, onTap: onOpen),
            const SizedBox(height: 28),
          ],
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
