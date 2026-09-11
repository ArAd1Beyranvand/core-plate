import 'package:core_plate/core_plate.dart';
import 'package:flutter/foundation.dart';

/// One entry in the gallery: everything needed to draw one plate and say what
/// it is.
///
/// [spec] is geometry, [theme] is colour and [country] is the panel block —
/// three independent inputs to `PlateCanvas` since core_plate 0.6.0. An entry
/// binds one combination of the three and names it. Two entries can therefore
/// share a spec and still be two different plates, which is the whole point of
/// the collapse: a Yemeni government plate and a private one are one geometry
/// in two liveries, not two specs.
@immutable
class GalleryEntry {
  const GalleryEntry({
    required this.id,
    required this.label,
    required this.spec,
    this.theme,
    this.country,
    this.validator,
    this.sampleValues,
    this.themeForValues,
    this.note,
  });

  /// Stable across runs, for goldens and deep links. Never the spec's id
  /// alone: several entries share a spec.
  final String id;

  /// Human-readable, shown on the card.
  final String label;

  final PlateSpec spec;

  /// The livery, or null to inherit the app's [PlateTheme].
  final PlateTheme? theme;

  /// The panel block, or null to keep [PlateSpec.country].
  final PlateCountry? country;

  /// The advisory rule the canvas paints its red state from. Null where the
  /// package ships none.
  final PlateValidator? validator;

  /// What the catalogue draws into the plate. Null leaves it blank.
  final List<String?>? sampleValues;

  /// A livery that is a fact about the *value* rather than a choice.
  ///
  /// Gaza prints its usage class in the plate's own last two digits, so a Gaza
  /// plate recolours itself as the user types and no picker decides its
  /// colour. Every other entry leaves this null and answers from [theme].
  /// Keeping it here rather than in the card widget is what lets the card stay
  /// country-blind.
  final PlateTheme? Function(List<String?> values)? themeForValues;

  /// A line of small print under the label, where the entry needs one.
  final String? note;

  /// The livery to paint this entry in, given what is currently in its slots.
  PlateTheme? themeFor(List<String?> values) => themeForValues?.call(values) ?? theme;
}

/// A run of entries under one heading — a system, a scheme, a form factor.
@immutable
class GallerySection {
  const GallerySection({required this.title, required this.note, required this.entries});

  final String title;
  final String note;
  final List<GalleryEntry> entries;
}

/// Everything one country package offers, normalised.
///
/// This interface lives in the gallery and not in `core_plate` on purpose. A
/// catalogue is a *presentation* concern: putting a `PlateCatalog` type into
/// the engine would make it know about lists of plates, which is one step from
/// knowing about countries. Each country exposes its plates its own way — two
/// bare consts, one const, `.all` lists, geometry maps — and the four adapters
/// under `sources/` are where those four idioms get normalised, once, in an
/// app instead of four times in four apps.
abstract interface class GallerySource {
  /// The country, as the catalogue heads its block.
  String get countryName;

  /// The package that ships it.
  String get packageName;

  /// One line for the About screen, pointing at the package's own README.
  String get note;

  List<GallerySection> get sections;
}

extension GallerySourceEntries on GallerySource {
  /// Every entry, sections flattened — what a picker offers and what a test
  /// counts.
  List<GalleryEntry> get entries => <GalleryEntry>[for (final GallerySection section in sections) ...section.entries];

  /// The distinct geometries the entries cover, by [PlateSpec.id]. The number
  /// a coverage test compares against the package's own catalogue surface.
  Set<String> get specIds => <String>{for (final GalleryEntry entry in entries) entry.spec.id};
}
