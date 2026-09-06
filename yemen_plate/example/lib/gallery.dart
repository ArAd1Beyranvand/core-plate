/// Every plate `yemen_plate` ships, on one scrollable page, each one editable.
///
/// The other example in this directory (`main.dart`) is the shape a real host
/// takes: one plate, and pickers that choose which. This one is the opposite
/// and is meant to be — it is a catalogue. Nothing is generated and nothing is
/// auto-filled; each plate starts empty and the user types into it.
///
/// The two properties that make a page of 55 live plates work:
///
/// - **One `PlateCardBloc` per plate.** The bloc holds the values, so a shared
///   one would make every plate on the page the same plate. Each [_PlateCard]
///   provides its own, scoped to itself.
/// - **No `PlateInputController` and no `inputSource`.** The single-plate
///   example routes input through `plate_keypad`, which means one keypad and
///   one controller for one focused plate. A catalogue has no single focus, so
///   these plates take the platform keyboard instead — `PlateCanvas` falls back
///   to `defaultInputSource()` — and tapping any slot on any plate types into
///   that slot.
library;

import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:yemen_plate/yemen_plate.dart';

void main() => runApp(const GalleryApp());

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'yemen_plate — every plate',
    theme: ThemeData(useMaterial3: true),
    home: const _GalleryPage(),
  );
}

// ---------------------------------------------------------------------------
// The catalogue.
//
// Built by walking the package's own lookup maps rather than by naming 55
// consts. A spec added to `YemenUnifiedPlates.car` or `YemenNorthernPlates
// .moto` shows up here without this file changing, and — more to the point —
// this page cannot silently fall behind the package.
// ---------------------------------------------------------------------------

/// One plate in the catalogue: the spec, the colours it is printed in, and the
/// rule it is judged against.
///
/// The theme is not on the spec and never will be — on System B the field
/// colour *is* the usage class, so it is derived from usage through
/// `YemenThemes`, the same way a host would derive it.
class _Entry {
  const _Entry({
    required this.label,
    required this.spec,
    required this.theme,
    required this.validator,
  });

  final String label;
  final PlateSpec spec;
  final PlateTheme theme;
  final PlateValidator validator;
}

/// One section of the page — a system and a form factor.
class _Section {
  const _Section({required this.title, required this.note, required this.entries});

  final String title;
  final String note;
  final List<_Entry> entries;
}

/// System A: the 2026 unified plate. White field for every usage, so the theme
/// varies only in the side panel; the vehicle number is four, five or six
/// digits and the usage is a word in the panel.
List<_Entry> _unified({required bool motorcycle}) => <_Entry>[
  for (final YemenUsage usage in YemenUsage.values)
    if (usage.onUnified)
      for (final MapEntry<int, PlateSpec> byLength
          in YemenUnifiedPlates.byNumberLength(usage, motorcycle: motorcycle).entries)
        _Entry(
          label: '${usage.name} · ${byLength.key} digits',
          spec: byLength.value,
          theme: YemenThemes.forUnifiedUsage(usage),
          validator: const YemenUnifiedValidator(),
        ),
];

/// System B: the 1993 northern plate. The governorate code and the serial each
/// have their own length, and the field colour carries the usage — which is
/// why every card here is a different colour and none of them chose it.
List<_Entry> _northern({required bool motorcycle}) => <_Entry>[
  for (final YemenUsage usage in YemenUsage.values)
    if (usage.onNorthern)
      for (final MapEntry<(int, int), PlateSpec> byDigits
          in YemenNorthernPlates.byDigits(usage, motorcycle: motorcycle).entries)
        _Entry(
          // `(gov digits, serial digits)` — the key the package itself is
          // indexed by, printed as the caption so the two agree.
          label: '${usage.name} · ${byDigits.key.$1}+${byDigits.key.$2}',
          spec: byDigits.value,
          theme: YemenThemes.forNorthernUsage(usage),
          validator: const YemenNorthernValidator(),
        ),
];

final List<_Section> _sections = <_Section>[
  _Section(
    title: 'System A — 2026 unified, car',
    note:
        'The white plate the internationally recognised government began '
        'issuing in mid-2026. The field is white for every usage; the usage is '
        'the word in the blue side panel, and the two-digit code is stacked '
        'beside it.',
    entries: _unified(motorcycle: false),
  ),
  _Section(
    title: 'System A — 2026 unified, motorcycle',
    note: 'The same content in the square form factor.',
    entries: _unified(motorcycle: true),
  ),
  _Section(
    title: 'System B — 1993 northern, car',
    note:
        'Still in force across the Houthi-controlled north, and still the '
        'larger share of the fleet — not a legacy format. Governorate code '
        'above the rule, serial below, and the field colour is the usage '
        'class: blue private, yellow for hire, red transport, green '
        'government, black military.',
    entries: _northern(motorcycle: false),
  ),
  _Section(
    title: 'System B — 1993 northern, motorcycle',
    note:
        'Unverified geometry. No official northern motorcycle design has been '
        'published, so these specs are the car content rendered into the '
        'motorcycle form factor — a guess, and deprecated in the package so '
        'that nothing trusts it silently.',
    entries: _northern(motorcycle: true),
  ),
];

// ---------------------------------------------------------------------------

class _GalleryPage extends StatelessWidget {
  const _GalleryPage();

  @override
  Widget build(BuildContext context) {
    final int total = _sections.fold(0, (int n, _Section s) => n + s.entries.length);
    return Scaffold(
      appBar: AppBar(
        title: const Text('yemen_plate'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$total plates, all empty — tap a slot and type.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            for (final _Section section in _sections) ...<Widget>[
              _SectionHeader(section: section),
              const SizedBox(height: 12),
              _PlateGrid(entries: section.entries),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(section.title, style: text.titleMedium),
        const SizedBox(height: 4),
        Text(section.note, style: text.bodySmall),
      ],
    );
  }
}

/// The plates of one section, wrapped so a wide window gets a grid and a narrow
/// one gets a column.
///
/// [Wrap] rather than [GridView] on purpose: a Yemeni car plate is 3.5 times as
/// wide as it is tall and a motorcycle plate is square, so a fixed aspect ratio
/// would letterbox one or crop the other. Each card sizes itself from its own
/// spec instead.
class _PlateGrid extends StatelessWidget {
  const _PlateGrid({required this.entries});

  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 16,
    children: <Widget>[
      for (final _Entry entry in entries) _PlateCard(entry: entry),
    ],
  );
}

/// One editable plate, with its own bloc.
class _PlateCard extends StatelessWidget {
  const _PlateCard({required this.entry});

  final _Entry entry;

  /// Every card is drawn to the same height and takes its width from the
  /// spec's own aspect ratio, so a car and a motorcycle sit on one row without
  /// either being distorted.
  static const double _height = 96;

  @override
  Widget build(BuildContext context) {
    final PlateSpec spec = entry.spec;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: _height,
          width: _height * spec.canvasWidth / spec.canvasHeight,
          // No provider and no controller: each canvas owns its own value,
          // scoped to this card, so tapping a slot on any card types into that
          // card and nothing else. See the library comment.
          child: PlateCanvas(
            spec: spec,
            theme: entry.theme,
            validator: entry.validator,
            // Paints the underlines red on an invalid value; never blocks a
            // keystroke. Both Yemeni validators stay quiet until the last
            // register has something in it, so an empty plate does not read
            // as wrong.
            autoValidate: true,
            // Every alphabet on both systems is `typed`, so no slot ever
            // opens a picker.
            onChooseCharacter: (PlateAlphabet alphabet) async => null,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: _height * spec.canvasWidth / spec.canvasHeight,
          child: Text(
            entry.label,
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
