import 'dart:math';

import 'package:core_plate/core_plate.dart';
import 'package:palestine_plate/palestine_plate.dart';

import '../catalogue.dart';

/// `palestine_plate` exposes two `.all` lists — `PSWestBankPlates.all` (7) and
/// `PSGazaPlates.all` (4) — and derives colour from usage rather than shipping
/// it on the spec. Eleven geometries; the adapter says which usages are worth
/// drawing each one in.
///
/// **The legacy family is where the P5 collapse shows.** One spec, `legacyCar`,
/// three liveries: a [PlateCountry] from `legacyCountryForUsage` and a
/// [PlateTheme] from `PSThemes.forUsage`, both handed to the canvas at render
/// time. Public transport inverts the whole plate and is the same geometry.
class PalestineSource implements GallerySource {
  PalestineSource();

  /// Seeded: a catalogue that reshuffles itself on every hot reload cannot be
  /// compared against anything.
  final Random _rng = Random(20180701);

  @override
  String get countryName => 'Palestine';

  @override
  String get packageName => 'palestine_plate';

  @override
  String get note =>
      'Two designs, not one: the West Bank\'s ف / P block and Gaza\'s flag. '
      'Colour is derived from usage, never chosen. See '
      'palestine_plate/README.md.';

  /// The usages that print differently on a West Bank plate. `leased` paints as
  /// `private` and `exempt` as `government`, so all five would repeat two.
  static const List<(String, PSUsage)> _liveries = <(String, PSUsage)>[
    ('Private', PSUsage.private),
    ('Public transport', PSUsage.publicTransport),
    ('Government', PSUsage.government),
  ];

  /// The modern geometries beyond the car, each shown in one livery. `final`,
  /// not `const`: the package's specs are not compile-time constants.
  static final List<(String, String, PlateSpec, PSUsage)> _modernRest = <(String, String, PlateSpec, PSUsage)>[
    ('car2l', 'Two-line', PSWestBankPlates.modernCarTwoLine, PSUsage.private),
    ('moto', 'Motorcycle', PSWestBankPlates.modernMoto, PSUsage.private),
    ('moto2l', 'Motorcycle, two-line', PSWestBankPlates.modernMotoTwoLine, PSUsage.private),
    ('trade', 'Trade / test', PSWestBankPlates.modernTrade, PSUsage.tradePlate),
  ];

  static final List<(String, String, PlateSpec)> _gazaPlates = <(String, String, PlateSpec)>[
    ('car2012', '2012', PSGazaPlates.car2012),
    ('car2012.2l', '2012, two-line', PSGazaPlates.car2012TwoLine),
    ('car2021.2l', '2021, two-line', PSGazaPlates.car2021TwoLine),
    ('moto', 'Motorcycle', PSGazaPlates.moto),
  ];

  GalleryEntry _modern(String id, String label, PlateSpec spec, PSUsage usage) => GalleryEntry(
    id: 'ps.wb.modern.$id',
    label: label,
    spec: spec,
    theme: PSThemes.forUsage(usage),
    validator: const PSWestBankModernValidator(),
    sampleValues: PSSerialGenerator.modernWestBank(spec, random: _rng),
  );

  GalleryEntry _legacy(String id, String label, PlateSpec spec, PSUsage usage, {bool recolourBlock = true}) =>
      GalleryEntry(
        id: 'ps.wb.legacy.$id',
        label: label,
        spec: spec,
        theme: PSThemes.forUsage(usage),
        // The legacy ف / P block is printed in the plate's own ink, so an inverted
        // or red plate recolours the block through `country:` — same spec.
        country: recolourBlock ? PSWestBankPlates.legacyCountryForUsage(usage) : null,
        validator: const PSWestBankLegacyValidator(),
        sampleValues: PSSerialGenerator.legacyWestBank(spec, random: _rng),
      );

  GalleryEntry _gaza(String id, String label, PlateSpec spec) => GalleryEntry(
    id: 'ps.gaza.$id',
    label: label,
    spec: spec,
    // Black is the fallback for an unallocated code (30-39, 60-99) — an invalid
    // plate rather than an unknown usage. Drawing it anyway is a decision this
    // app makes knowing it is guessing.
    theme: PSThemes.gazaBlack,
    themeForValues: (List<String?> values) =>
        PSThemes.forGazaUsageCode(spec.valueOfGroup('usage', values)) ?? PSThemes.gazaBlack,
    validator: const PSGazaValidator(),
    sampleValues: PSSerialGenerator.gaza(spec, random: _rng),
    note: 'colour read from the plate',
  );

  /// Built once: the sample values are drawn from [_rng], so rebuilding on every
  /// read would deal a different plate every frame. The pickers also select by
  /// equality, so the identity has to hold still.
  List<GallerySection>? _sections;

  @override
  List<GallerySection> get sections => _sections ??= <GallerySection>[
    GallerySection(
      title: 'West Bank — modern, since July 2018',
      note:
          'D · DDDD · L. The scheme encodes no usage, so the host supplies it '
          'and the colour follows; the trailing governorate letter is a '
          '`chosen` alphabet and opens a picker.',
      entries: <GalleryEntry>[
        for (final (String name, PSUsage usage) in _liveries)
          _modern('car.${usage.name}', name, PSWestBankPlates.modernCar, usage),
        for (final (String id, String label, PlateSpec spec, PSUsage usage) in _modernRest)
          _modern(id, label, spec, usage),
      ],
    ),
    GallerySection(
      title: 'West Bank — legacy, 1994 to 2018',
      note:
          'D · DDDD · DD, the last two digits being the usage code. One '
          'geometry in three inks: green on white, inverted white on green for '
          'public transport, red on white for government and duty-exempt.',
      entries: <GalleryEntry>[
        for (final (String name, PSUsage usage) in _liveries)
          _legacy('car.${usage.name}', name, PSWestBankPlates.legacyCar, usage),
        _legacy('car2l', 'Two-line', PSWestBankPlates.legacyCarTwoLine, PSUsage.private, recolourBlock: false),
      ],
    ),
    GallerySection(
      title: 'Gaza',
      note:
          'A different design, not a recoloured West Bank plate: the field is '
          'always white and only the glyphs, the border and the rules change. '
          'Usage is the last two digits, so these recolour as you type.',
      entries: <GalleryEntry>[
        for (final (String id, String label, PlateSpec spec) in _gazaPlates) _gaza(id, label, spec),
      ],
    ),
  ];
}
