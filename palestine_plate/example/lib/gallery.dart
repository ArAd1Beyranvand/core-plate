/// Every plate `palestine_plate` ships, on one scrollable page, each one
/// editable.
///
/// The other example in this directory (`main.dart`) is the shape a real host
/// takes: one plate, a scheme picker, a usage picker and a keypad. This one is
/// the opposite and is meant to be — it is a catalogue. Nothing is generated
/// and nothing is auto-filled; each plate starts empty and the user types into
/// it.
///
/// The three properties that make a page of live plates work:
///
/// - **One `PlateCardBloc` per plate.** The bloc holds the values, so a shared
///   one would make every plate on the page the same plate. Each [_PlateCard]
///   provides its own, scoped to itself.
/// - **No `PlateController` and no `inputSource`.** The single-plate
///   example routes input through `plate_keypad`, which means one keypad and
///   one controller for one focused plate. A catalogue has no single focus, so
///   these plates take the platform keyboard instead — `PlateCanvas` falls back
///   to `defaultInputSource()` — and tapping any slot on any plate types into
///   that slot.
/// - **The governorate slot still opens a picker.** It is a `chosen` alphabet,
///   so core asks for a character rather than accepting typing, whatever the
///   input source is. `PlateCharacterPicker.show` answers, which is the only
///   reason this example depends on `plate_keypad` at all.
///
/// Colour is derived, never chosen. A West Bank card passes the usage its spec
/// is *for* through `PSThemes.forUsage`; a Gaza card reads the usage off the
/// plate's own last two digits, so its colour changes as the user types.
library;

import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:palestine_plate/palestine_plate.dart';
import 'package:plate_keypad/plate_keypad.dart';

void main() => runApp(const GalleryApp());

// ---------------------------------------------------------------------------
// The catalogue.
//
// A `PlateSpec` carries geometry and nothing else, so the two things that go
// with one — which validator judges it and where its colour comes from — are
// named here, alongside the spec, exactly as a host would name them.
// ---------------------------------------------------------------------------

/// Which grammar a spec speaks, and therefore which validator reads it.
///
/// Never sniffed from the value: a modern West Bank plate ends in a
/// governorate letter and a legacy one ends in two usage digits, and they are
/// different specs, so the scheme is a property of the catalogue entry.
enum _Kind { westBankModern, westBankLegacy, gaza }

class _Entry {
  const _Entry({
    required this.label,
    required this.spec,
    required this.kind,
    this.usage,
  });

  final String label;
  final PlateSpec spec;
  final _Kind kind;

  /// The usage this card's colour comes from, for the West Bank schemes.
  ///
  /// Null for Gaza, whose usage is on the plate — see [_themeFor]. It is not a
  /// picker: each legacy ink variant is a *different spec* (the `ف / P` block
  /// carries its own colour on the [PlateCountry], which no theme can
  /// recolour), so the usage that goes with each one is fixed here.
  final PSUsage? usage;
}

/// The West Bank's nine specs, each with the usage its ink was cut for.
const List<_Entry> _westBank = <_Entry>[
  _Entry(
    label: 'Modern car — since July 2018',
    spec: PSWestBankPlates.modernCar,
    kind: _Kind.westBankModern,
    usage: PSUsage.private,
  ),
  _Entry(
    label: 'Modern car, two-line',
    spec: PSWestBankPlates.modernCarTwoLine,
    kind: _Kind.westBankModern,
    usage: PSUsage.private,
  ),
  _Entry(
    label: 'Modern motorcycle',
    spec: PSWestBankPlates.modernMoto,
    kind: _Kind.westBankModern,
    usage: PSUsage.private,
  ),
  _Entry(
    label: 'Modern motorcycle, two-line',
    spec: PSWestBankPlates.modernMotoTwoLine,
    kind: _Kind.westBankModern,
    usage: PSUsage.private,
  ),
  _Entry(
    label: 'Modern trade / test — white on blue',
    spec: PSWestBankPlates.modernTrade,
    kind: _Kind.westBankModern,
    usage: PSUsage.tradePlate,
  ),
  _Entry(
    label: 'Legacy car — green on white',
    spec: PSWestBankPlates.legacyCar,
    kind: _Kind.westBankLegacy,
    usage: PSUsage.private,
  ),
  _Entry(
    label: 'Legacy car, two-line',
    spec: PSWestBankPlates.legacyCarTwoLine,
    kind: _Kind.westBankLegacy,
    usage: PSUsage.private,
  ),
  _Entry(
    // The inverted plate: usage code 30. A whole second spec for one colour,
    // because the `ف / P` block's ink lives on the country.
    label: 'Legacy public transport — white on green',
    spec: PSWestBankPlates.legacyCarPublicTransport,
    kind: _Kind.westBankLegacy,
    usage: PSUsage.publicTransport,
  ),
  _Entry(
    // Government (99) and duty-exempt (31) share this one.
    label: 'Legacy government / exempt — red on white',
    spec: PSWestBankPlates.legacyCarGovernment,
    kind: _Kind.westBankLegacy,
    usage: PSUsage.government,
  ),
];

/// Gaza's specs. No usage on any of them: the plate says what it is.
const List<_Entry> _gaza = <_Entry>[
  _Entry(label: 'Gaza 2012', spec: PSGazaPlates.car2012, kind: _Kind.gaza),
  _Entry(label: 'Gaza 2012, two-line', spec: PSGazaPlates.car2012TwoLine, kind: _Kind.gaza),
  _Entry(label: 'Gaza 2021, two-line', spec: PSGazaPlates.car2021TwoLine, kind: _Kind.gaza),
  _Entry(label: 'Gaza motorcycle', spec: PSGazaPlates.moto, kind: _Kind.gaza),
];

/// The theme to paint [entry] in, given what is currently typed into it.
///
/// **Never chosen — always derived.** The West Bank asks `forUsage`, because
/// the modern scheme encodes no usage on the plate and the host is the only
/// thing that knows it. Gaza reads its own last two digits instead, which is
/// why a Gaza card recolours itself as the user types and a West Bank card does
/// not.
PlateTheme _themeFor(_Entry entry, List<String?> values) {
  final PSUsage? usage = entry.usage;
  if (usage != null) return PSThemes.forUsage(usage);
  // Null for an unallocated Gaza code (30-39, 60-99), and for a plate whose
  // usage digits are not typed yet. Both are "not a valid plate" rather than
  // "unknown usage"; falling back to black is this page's decision, made
  // knowing it is a guess.
  return PSThemes.forGazaUsageCode(entry.spec.valueOfGroup('usage', values)) ??
      PSThemes.gazaBlack;
}

/// The `PlateValidator` the canvas paints its red state from.
PlateValidator _validatorFor(_Kind kind) => switch (kind) {
  _Kind.westBankModern => const PSWestBankModernValidator(),
  _Kind.westBankLegacy => const PSWestBankLegacyValidator(),
  _Kind.gaza => const PSGazaValidator(),
};

// ---------------------------------------------------------------------------

class GalleryApp extends StatelessWidget {
  const GalleryApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'palestine_plate — every plate',
    theme: ThemeData(useMaterial3: true),
    home: const _GalleryPage(),
  );
}

class _GalleryPage extends StatelessWidget {
  const _GalleryPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('palestine_plate'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(28),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_westBank.length + _gaza.length} plates, all empty — tap a '
              'slot and type.',
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
          const _SectionHeader(
            title: 'West Bank',
            note:
                'Colour comes from usage, and the last slot is a governorate '
                'letter chosen from the thirteen legal ones — tap it and the '
                'picker opens. The legacy scheme ends in two usage digits '
                'instead, and each of its ink variants is a separate spec.',
          ),
          const SizedBox(height: 12),
          const _PlateGrid(entries: _westBank),
          const SizedBox(height: 32),
          const _SectionHeader(
            title: 'Gaza',
            note:
                'A different design, not a recoloured West Bank plate: the '
                'field is always white and only the glyphs, the border and the '
                'rules change. Usage is the last two digits, so these cards '
                'recolour themselves as you type — 00-09 black, and see '
                'PSThemes.forGazaUsageCode for the rest.',
          ),
          const SizedBox(height: 12),
          const _PlateGrid(entries: _gaza),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.note});

  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: text.titleMedium),
        const SizedBox(height: 4),
        Text(note, style: text.bodySmall),
      ],
    );
  }
}

/// The plates of one section, wrapped so a wide window gets a grid and a narrow
/// one gets a column.
///
/// [Wrap] rather than [GridView] on purpose: a one-line plate is 520 x 110 and
/// a two-line one is 300 x 150, so a fixed aspect ratio would letterbox one or
/// crop the other. Each card sizes itself from its own spec instead.
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
class _PlateCard extends StatefulWidget {
  const _PlateCard({required this.entry});

  final _Entry entry;

  @override
  State<_PlateCard> createState() => _PlateCardState();
}

class _PlateCardState extends State<_PlateCard> {
  /// Scoped to this card. One controller shared across the page would make
  /// every plate on it show the same value.
  late final PlateController _plate = PlateController(spec: widget.entry.spec);

  /// Every card is drawn to the same height and takes its width from the
  /// spec's own aspect ratio, so a one-line and a two-line plate sit on one row
  /// without either being distorted.
  static const double _height = 96;

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _Entry entry = widget.entry;
    final PlateSpec spec = entry.spec;
    final double width = _height * spec.canvasWidth / spec.canvasHeight;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: _height,
          width: width,
          // Gaza's colour is a function of its own values, so the canvas is
          // rebuilt on them. The West Bank cards do not need this, but they
          // are cheap and it keeps one card widget instead of two.
          child: ListenableBuilder(
            listenable: _plate,
            builder: (BuildContext context, Widget? _) => PlateCanvas(
              spec: spec,
              // Colour is derived and passed in. PlateSpec has no theme field.
              theme: _themeFor(entry, _plate.values),
              // No `inputSource`: each plate takes the platform default, so
              // tapping a slot on any card types into that card. See the
              // library comment.
              controller: _plate,
              validator: _validatorFor(entry.kind),
              // Paints the underlines red on an invalid plate; never blocks a
              // keystroke, never throws. Each validator stays quiet until the
              // user reaches its last group, so an empty plate does not read
              // as wrong.
              autoValidate: true,
              // The governorate slot is a `chosen` alphabet, so core asks for
              // a character instead of accepting typing. plate_keypad's modal
              // wheel offers exactly the thirteen legal letters — no I, no O.
              onChooseCharacter: (PlateAlphabet alphabet) =>
                  PlateCharacterPicker.show(context, alphabet),
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: width,
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
