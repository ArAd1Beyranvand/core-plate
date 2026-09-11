import 'package:germany_plate/germany_plate.dart';

import '../catalogue.dart';

/// `germany_plate` exposes one const, `GermanPlates.car`, and one validator.
/// The whole adapter is naming both.
class GermanySource implements GallerySource {
  const GermanySource();

  @override
  String get countryName => 'Germany';

  @override
  String get packageName => 'germany_plate';

  @override
  String get note =>
      'One spec, two decals, and the advisory GermanPlateValidator. See '
      'germany_plate/README.md.';

  /// Built once, and returned by identity: the pickers select by equality.
  @override
  List<GallerySection> get sections => _sections;

  static final List<GallerySection> _sections = <GallerySection>[
    GallerySection(
      title: 'Germany',
      note:
          'The standard EU plate. The inspection sticker and the state seal '
          'are decals in the gap between the district code and the '
          'identifier, not slots.',
      entries: <GalleryEntry>[
        GalleryEntry(
          id: 'de.car',
          label: 'Car',
          spec: GermanPlates.car,
          validator: const GermanPlateValidator(),
          sampleValues: const <String?>['D', 'A', 'X', '1', '9', '5', '3'],
        ),
      ],
    ),
  ];
}
