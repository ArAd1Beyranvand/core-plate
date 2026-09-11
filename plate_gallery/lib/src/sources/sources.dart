import '../catalogue.dart';
import 'germany.dart';
import 'iran.dart';
import 'palestine.dart';
import 'yemen.dart';

export '../catalogue.dart';
export 'germany.dart';
export 'iran.dart';
export 'palestine.dart';
export 'yemen.dart';

/// Every country this app can draw, in the order the catalogue lists them.
///
/// Built once. Two of the four adapters deal seeded sample values, so a fresh
/// list per read would reshuffle the catalogue on every frame.
final List<GallerySource> gallerySources = <GallerySource>[
  const IranSource(),
  const GermanySource(),
  PalestineSource(),
  YemenSource(),
];
