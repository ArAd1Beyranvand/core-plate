import 'dart:math';

import 'package:core_plate/core_plate.dart';
import 'package:yemen_plate/yemen_plate.dart';

import '../catalogue.dart';

/// `yemen_plate` exposes geometry maps — `carGeometries` / `motoGeometries` on
/// each of the two systems, eleven specs in all — plus `car(...)` / `moto(...)`
/// lookups over them. This adapter walks the maps rather than naming consts, so
/// a geometry added to the package shows up here without this file changing.
///
/// **A usage is not a spec.** It selects a country block (the panel caption on
/// System A, the usage word on System B) and, on System B, the field colour.
/// Both are render-time inputs, so the walk below is geometries × usages: two
/// entries can share a spec and still be two different plates. That is the
/// whole of P4, seen from the outside.
class YemenSource implements GallerySource {
  YemenSource();

  /// Seeded, so the page reads the same on every run and hot reload.
  final Random _rng = Random(1970);

  @override
  String get countryName => 'Yemen';

  @override
  String get packageName => 'yemen_plate';

  @override
  String get note =>
      'Two current systems, not one current and one legacy: the 2026 unified '
      'white plate and the 1993 northern format. See yemen_plate/README.md.';

  /// The word the plate itself prints for [usage] on this system, falling back
  /// to the enum's name where no source names one — a northern government or
  /// military plate carries no usage word that any source attests.
  String _word(YemenUsage usage, {required bool unified}) =>
      (unified ? usage.unifiedArabic : usage.northernArabic) ?? usage.name;

  List<GalleryEntry> _unified({required bool motorcycle}) {
    final String form = motorcycle ? 'moto' : 'car';
    return <GalleryEntry>[
      for (final YemenUsage usage in YemenUsage.values)
        if (usage.onUnified)
          for (final MapEntry<int, PlateSpec> geometry
              in (motorcycle ? YemenUnifiedPlates.motoGeometries : YemenUnifiedPlates.carGeometries).entries)
            GalleryEntry(
              id: 'ye.unified.$form.${usage.name}.${geometry.key}',
              label: '${_word(usage, unified: true)} · ${geometry.key} digits',
              spec: geometry.value,
              country: YemenCountry.unifiedFor(usage),
              theme: YemenThemes.forUnifiedUsage(usage),
              validator: const YemenUnifiedValidator(),
              sampleValues: YemenUnifiedSerialGenerator.generate(geometry.value, random: _rng),
            ),
    ];
  }

  List<GalleryEntry> _northern({required bool motorcycle}) {
    final String form = motorcycle ? 'moto' : 'car';
    return <GalleryEntry>[
      for (final YemenUsage usage in YemenUsage.values)
        if (usage.onNorthern)
          for (final MapEntry<(int, int), PlateSpec> geometry
              in (motorcycle ? YemenNorthernPlates.motoGeometries : YemenNorthernPlates.carGeometries).entries)
            // Military is drawn twice, once per printing: the two are the same
            // spec in different ink, and on System B the ink *is* the class.
            for (final YemenMilitaryStyle style
                in usage == YemenUsage.military
                    ? YemenMilitaryStyle.values
                    : const <YemenMilitaryStyle>[YemenMilitaryStyle.classic])
              GalleryEntry(
                id: <String>[
                  'ye.northern.$form',
                  usage.name,
                  if (usage == YemenUsage.military) style.name,
                  '${geometry.key.$1}+${geometry.key.$2}',
                ].join('.'),
                label: <String>[
                  _word(usage, unified: false),
                  '${geometry.key.$1} + ${geometry.key.$2}',
                  if (usage == YemenUsage.military) style.name,
                ].join(' · '),
                spec: geometry.value,
                country: YemenCountry.northernFor(usage),
                theme: YemenThemes.forNorthernUsage(usage, style: style),
                validator: const YemenNorthernValidator(),
                sampleValues: YemenNorthernSerialGenerator.generate(geometry.value, random: _rng),
              ),
    ];
  }

  @override
  List<GallerySection> get sections => _sections ??= <GallerySection>[
    GallerySection(
      title: 'System A — 2026 unified, car',
      note:
          'The white plate the internationally recognised government began '
          'issuing in mid-2026. The field is white for every usage; the usage '
          'is the word in the blue side panel, and the two-digit code is '
          'stacked beside it.',
      entries: _unified(motorcycle: false),
    ),
    GallerySection(
      title: 'System A — 2026 unified, motorcycle',
      note: 'The same content in the square form factor.',
      entries: _unified(motorcycle: true),
    ),
    GallerySection(
      title: 'System B — 1993 northern, car',
      note:
          'Still in force across the Houthi-controlled north, and still the '
          'larger share of the fleet — not a legacy format. Governorate code '
          'above the rule, serial below, and the field colour is the usage '
          'class: blue private, yellow for hire, red transport, green '
          'government, black military.',
      entries: _northern(motorcycle: false),
    ),
    GallerySection(
      title: 'System B — 1993 northern, motorcycle',
      note:
          'Unverified geometry. No official northern motorcycle design has '
          'been published, so this spec is the car content rendered into the '
          'motorcycle form factor — a guess, and marked as one in the package.',
      entries: _northern(motorcycle: true),
    ),
  ];

  List<GallerySection>? _sections;
}
