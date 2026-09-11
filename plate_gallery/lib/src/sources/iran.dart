import 'package:iran_plate/iran_plate.dart';

import '../catalogue.dart';

/// `iran_plate` exposes no catalogue at all — two bare consts, `IranPlates.car`
/// and `.bicycle`. Naming them here is the adapter; there is nothing to walk.
///
/// The sample values are written out rather than generated: the package ships
/// no serial generator, and adding one to it so that a showcase could fill a
/// plate would be the gallery driving library API.
class IranSource implements GallerySource {
  const IranSource();

  @override
  String get countryName => 'Iran';

  @override
  String get packageName => 'iran_plate';

  @override
  String get note =>
      'Two specs, one country block, Persian digits and the chosen-letter '
      'slot. See iran_plate/README.md.';

  /// Built once, and returned by identity: the pickers select a section by
  /// equality, and a fresh list per read would make the selected one never
  /// equal the one in the list.
  @override
  List<GallerySection> get sections => _sections;

  static final List<GallerySection> _sections = <GallerySection>[
    GallerySection(
      title: 'Iran',
      note:
          'Right-to-left, with the province pair past the divider. The letter '
          'slot is a `chosen` alphabet, so it opens a picker rather than '
          'accepting typing.',
      entries: <GalleryEntry>[
        GalleryEntry(
          id: 'ir.car',
          label: 'Car',
          spec: IranPlates.car,
          sampleValues: const <String?>['1', '2', 'ب', '3', '4', '5', '1', '1'],
        ),
        GalleryEntry(
          id: 'ir.bicycle',
          label: 'Bicycle',
          spec: IranPlates.bicycle,
          sampleValues: const <String?>[
            '1', '2', '3', //
            '4', '5', '6', '7', '8',
          ],
        ),
      ],
    ),
  ];
}
