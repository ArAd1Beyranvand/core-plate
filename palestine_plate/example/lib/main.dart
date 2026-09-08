import 'dart:math';

import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:palestine_plate/palestine_plate.dart';
import 'package:plate_keypad/plate_keypad.dart' show PlateCharacterPicker;

void main() => runApp(const ExampleApp());

// ---------------------------------------------------------------------------
// The schemes this app can draw.
//
// A `PlateSpec` carries geometry and nothing else, so the two things a host
// needs alongside one — which validator judges the plate, and where its colour
// comes from — live here rather than on the spec. That is the whole shape of
// this package: data in, decisions in the host.
// ---------------------------------------------------------------------------

/// Which grammar a spec speaks, and therefore which validator reads it.
///
/// Modern and legacy West Bank plates are *different specs* with different last
/// groups — a governorate letter versus two usage digits — so the scheme is
/// picked here and never sniffed from the value.
enum _Kind { westBankModern, westBankLegacy, gaza }

extension on _Kind {
  String get label => switch (this) {
    _Kind.westBankModern => 'West Bank · modern',
    _Kind.westBankLegacy => 'West Bank · legacy',
    _Kind.gaza => 'Gaza',
  };
}

class _Scheme {
  const _Scheme(
    this.label,
    this.base,
    this.kind, {
    this.isTwoLine = false,
    this.isMotorcycle = false,
  });

  final String label;
  final PlateSpec base;
  final _Kind kind;
  final bool isTwoLine;
  final bool isMotorcycle;
}

final List<_Scheme> _westBankModernSchemes = [
  _Scheme('Standard', PSWestBankPlates.modernCar, _Kind.westBankModern),
  _Scheme('Trade / test', PSWestBankPlates.modernTrade, _Kind.westBankModern),
  _Scheme(
    'Two-line',
    PSWestBankPlates.modernCarTwoLine,
    _Kind.westBankModern,
    isTwoLine: true,
  ),
];

final List<_Scheme> _westBankLegacySchemes = [
  _Scheme('Standard', PSWestBankPlates.legacyCar, _Kind.westBankLegacy),
  _Scheme(
    'Two-line',
    PSWestBankPlates.legacyCarTwoLine,
    _Kind.westBankLegacy,
    isTwoLine: true,
  ),
];

final List<_Scheme> _gazaSchemes = [
  _Scheme('2012', PSGazaPlates.car2012, _Kind.gaza),
  _Scheme(
    '2012, two-line',
    PSGazaPlates.car2012TwoLine,
    _Kind.gaza,
    isTwoLine: true,
  ),
  _Scheme(
    '2021, two-line',
    PSGazaPlates.car2021TwoLine,
    _Kind.gaza,
    isTwoLine: true,
  ),
];

final List<_Scheme> _westBankModernMotorcycleSchemes = [
  _Scheme(
    'Standard',
    PSWestBankPlates.modernMoto,
    _Kind.westBankModern,
    isMotorcycle: true,
  ),
  _Scheme(
    'Two-line',
    PSWestBankPlates.modernMotoTwoLine,
    _Kind.westBankModern,
    isTwoLine: true,
    isMotorcycle: true,
  ),
];

final List<_Scheme> _gazaMotorcycleSchemes = [
  _Scheme('Standard', PSGazaPlates.moto, _Kind.gaza, isMotorcycle: true),
];

/// The spec to draw for [scheme]. Geometry only — the ink comes from
/// [_countryFor], handed to `PlateCanvas.country` at render time.
PlateSpec _specFor(_Scheme scheme, PSUsage usage) => scheme.base;

/// The `ف / P` block ink for [scheme] at [usage]. Only the legacy West Bank
/// plate varies — an inverted (white-on-green) or red plate is the same
/// geometry with a different [PlateCountry].
PlateCountry? _countryFor(_Scheme scheme, PSUsage usage) {
  if (scheme.base != PSWestBankPlates.legacyCar) return null;
  return PSWestBankPlates.legacyCountryForUsage(usage);
}

/// The theme to paint [spec] in. **Never chosen — always derived.**
///
/// The West Bank asks `forUsage`, because the modern scheme encodes no usage on
/// the plate and the host is the only thing that knows it. Gaza reads its own
/// last two digits instead, which is why the usage picker is disabled there:
/// the plate already says what it is.
PlateTheme _themeFor(
  _Scheme scheme,
  PSUsage usage,
  PlateSpec spec,
  List<String?> values,
) {
  if (scheme.kind != _Kind.gaza) return PSThemes.forUsage(usage);
  // Null for an unallocated Gaza code (30-39, 60-99), which is an invalid
  // plate rather than an unknown usage. Falling back to black to have
  // something to draw is a decision this app makes knowing it is guessing.
  return PSThemes.forGazaUsageCode(spec.valueOfGroup('usage', values)) ??
      PSThemes.gazaBlack;
}

/// The `PlateValidator` the canvas paints its red state from.
PlateValidator _validatorFor(_Kind kind) => switch (kind) {
  _Kind.westBankModern => const PSWestBankModernValidator(),
  _Kind.westBankLegacy => const PSWestBankLegacyValidator(),
  _Kind.gaza => const PSGazaValidator(),
};

/// The verdict the **submit button** is gated on.
///
/// This goes through each validator's static, spec-free `validateFields` rather
/// than through `PlateValidator.validate`. The difference matters: `validate`
/// stays deliberately quiet until the user has reached the last group, so an
/// empty plate reads as valid and gating a button on it would let a blank
/// plate through. `validateFields` judges the groups as given, so a
/// half-entered serial is invalid — which is what a submit button wants to
/// know. `PlateNumber.isCompleted` is not asked at all.
PlateValidation _verdictFor(
  _Scheme scheme,
  PlateSpec spec,
  List<String?> values,
) {
  final entry = PlateEntry(spec: spec, values: values);
  return switch (scheme.kind) {
    _Kind.westBankModern => PSWestBankModernValidator.validateFields(
      region: entry.group('region'),
      serial: entry.group('serial'),
      governorate: entry.group('governorate'),
    ),
    _Kind.westBankLegacy => PSWestBankLegacyValidator.validateFields(
      district: entry.group('district'),
      serial: entry.group('serial'),
      usage: entry.group('usage'),
    ),
    _Kind.gaza => PSGazaValidator.validateFields(
      prefix: entry.group('prefix'),
      serial: entry.group('serial'),
      usage: entry.group('usage'),
    ),
  };
}

// ---------------------------------------------------------------------------

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'palestine_plate',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF0F7A3D),
      brightness: Brightness.light,
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF0F7A3D),
      brightness: Brightness.dark,
    ),
    home: const _HomePage(),
  );
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar.large(
            title: const Text('palestine_plate'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.edit_outlined), text: 'Enter a plate'),
                Tab(icon: Icon(Icons.grid_view_outlined), text: 'Every type'),
              ],
            ),
          ),
        ],
        body: const TabBarView(children: [_Demo(), _CatalogueTab()]),
      ),
    ),
  );
}

class _Demo extends StatefulWidget {
  const _Demo();

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  _Kind _region = _Kind.westBankModern;
  _Scheme _scheme = _westBankModernSchemes.first;
  PSUsage _usage = PSUsage.private;
  bool _motorcycle = false;

  /// The plate's characters. Held here rather than provided above the tree,
  /// because this screen reads the value on every build — the theme, the
  /// verdict and the Submit button all derive from it — and writes none of it.
  /// The canvas is the only writer.
  late final PlateController _plate = PlateController(
    spec: _westBankModernSchemes.first.base,
  );

  @override
  void initState() {
    super.initState();
    // Subscribed here rather than through a `ListenableBuilder` around the
    // canvas. The canvas is the controller's *writer*, and attaching to a
    // controller notifies its listeners synchronously from `initState` — so a
    // builder that both listens to `_plate` and builds the canvas would be
    // marked dirty in the middle of its own build. Rebuilding this whole
    // screen from a plain listener sidesteps that: the notification lands
    // outside anyone's build.
    _plate.addListener(_onPlateChanged);
  }

  void _onPlateChanged() {
    if (!mounted) return;
    // `PlateController.attach` notifies synchronously from the canvas's own
    // `initState`, which runs while this widget is building its subtree — so a
    // straight `setState` here would be a build-during-build. Everything the
    // notification affects on this screen (the verdict line, the Submit
    // button, and Gaza's value-derived livery) is chrome around the plate
    // rather than the plate itself, so settling it on the next frame costs
    // nothing visible.
    final SchedulerPhase phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _plate.removeListener(_onPlateChanged);
    _plate.dispose();
    super.dispose();
  }

  List<_Scheme> get _currentSchemes {
    if (_motorcycle) {
      return switch (_region) {
        _Kind.westBankModern => _westBankModernMotorcycleSchemes,
        _Kind.gaza => _gazaMotorcycleSchemes,
        _Kind.westBankLegacy => [],
      };
    }
    return switch (_region) {
      _Kind.westBankModern => _westBankModernSchemes,
      _Kind.westBankLegacy => _westBankLegacySchemes,
      _Kind.gaza => _gazaSchemes,
    };
  }

  // Switching scheme, region, usage or form factor. `PlateCanvas` is passed
  // `onSpecChange: PlateValuePreservation.byGroupKey`, so a swapped `spec.id`
  // carries the value across register by register — the serial stays the
  // serial even when it moves position, and a character the new alphabet
  // refuses is dropped rather than forced.
  void _switchTo({
    _Kind? region,
    _Scheme? scheme,
    PSUsage? usage,
    bool? motorcycle,
  }) {
    setState(() {
      if (region != null) _region = region;
      if (motorcycle != null) _motorcycle = motorcycle;
      if (scheme != null) _scheme = scheme;
      if (usage != null) _usage = usage;
      // Region and form factor both re-key the variant list, so a variant
      // carried over from the previous list would not be in the new one and
      // the picker would show nothing selected.
      if (region != null || motorcycle != null) {
        final options = _currentSchemes;
        if (options.isNotEmpty && !options.contains(_scheme)) {
          _scheme = options.first;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final spec = _specFor(_scheme, _usage);
    final values = _plate.values;
    // Gaza's livery is read off the plate's own digits, so this changes as the
    // user types; every other scheme derives it from the chosen usage.
    final theme = _themeFor(_scheme, _usage, spec, values);
    final verdict = _verdictFor(_scheme, spec, values);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // The plate first and big: it is the subject of the screen, and the
        // pickers below it only describe which one is on show.
        _PlateStage(
          spec: spec,
          child: PlateCanvas(
            spec: spec,
            theme: theme,
            country: _countryFor(_scheme, _usage),
            // Real text fields: each slot opens the platform keyboard.
            inputSource: PlateInputSource.system,
            validator: _validatorFor(_scheme.kind),
            autoValidate: true,
            onSpecChange: PlateValuePreservation.byGroupKey,
            controller: _plate,
            onChooseCharacter: (alphabet) =>
                PlateCharacterPicker.show(context, alphabet),
          ),
        ),
        const SizedBox(height: 20),

        _VerdictBar(verdict: verdict),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: verdict.isValid ? () => _onSubmit(spec, values) : null,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Submit'),
          ),
        ),

        const SizedBox(height: 24),
        _Section(
          title: 'Scheme',
          child: Column(
            children: [
              _PickerRow(
                label: 'Region',
                children: [
                  for (final r in _Kind.values)
                    ChoiceChip(
                      label: Text(r.label),
                      selected: _region == r,
                      onSelected: (_) => _switchTo(region: r),
                    ),
                ],
              ),
              _PickerRow(
                label: 'Form',
                children: [
                  ChoiceChip(
                    label: const Text('Car'),
                    selected: !_motorcycle,
                    onSelected: (_) => _switchTo(motorcycle: false),
                  ),
                  ChoiceChip(
                    label: const Text('Motorcycle'),
                    selected: _motorcycle,
                    onSelected:
                        _region == _Kind.westBankModern || _region == _Kind.gaza
                        ? (_) => _switchTo(motorcycle: true)
                        : null,
                  ),
                ],
              ),
              _PickerRow(
                label: 'Variant',
                children: [
                  for (final s in _currentSchemes)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: _scheme == s,
                      onSelected: (_) => _switchTo(scheme: s),
                    ),
                ],
              ),
              _PickerRow(
                label: 'Usage',
                // Gaza reads its usage off the plate's own last two digits,
                // so there is nothing for a picker to decide.
                note: _scheme.kind == _Kind.gaza
                    ? 'Gaza encodes usage in the plate itself.'
                    : null,
                children: [
                  for (final u in PSUsage.values)
                    ChoiceChip(
                      label: Text(u.name),
                      selected: _usage == u,
                      onSelected: _scheme.kind != _Kind.gaza
                          ? (_) => _switchTo(usage: u)
                          : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onSubmit(PlateSpec spec, List<String?> values) {
    final plate = [
      for (final group in spec.effectiveTextGroups)
        spec.renderGroup(group, values),
    ].join('·');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(plate)),
    );
  }
}

// ---------------------------------------------------------------------------
// Chrome.
// ---------------------------------------------------------------------------

/// The hero slot the editable plate sits in: a soft, recessed panel that keeps
/// the plate at its own aspect ratio however wide the window gets.
class _PlateStage extends StatelessWidget {
  const _PlateStage({required this.spec, required this.child});

  final PlateSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: ConstrainedBox(
          // A two-line plate is nearly square; without a ceiling it would grow
          // to fill a desktop window and dwarf everything under it.
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 260),
          child: AspectRatio(
            aspectRatio: spec.canvasWidth / spec.canvasHeight,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// The live verdict, as a quiet line rather than a red wall of text.
class _VerdictBar extends StatelessWidget {
  const _VerdictBar({required this.verdict});

  final PlateValidation verdict;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ok = verdict.isValid;
    final color = ok ? colors.primary : colors.error;
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle_outline : Icons.info_outline,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ok ? 'Valid plate' : verdict.reason!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.label, required this.children, this.note});

  final String label;
  final String? note;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: children),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The catalogue: one generated plate per distinct plate type.
//
// The point of this tab is coverage, not sampling — every entry below is a
// *different spec or a different livery*, so scrolling it shows the whole of
// what `palestine_plate` can draw rather than four rolls of one die.
// ---------------------------------------------------------------------------

class _Sample {
  const _Sample({
    required this.label,
    required this.spec,
    required this.theme,
    required this.kind,
    this.country,
    this.note,
  });

  final String label;
  final String? note;
  final PlateSpec spec;
  final PlateTheme theme;
  final _Kind kind;

  /// The `ف / P` block ink, for the legacy West Bank liveries. Null keeps the
  /// spec's own country.
  final PlateCountry? country;
}

/// The catalogue, grouped by region.
Map<String, List<_Sample>> _buildCatalogue() {
  // Every West Bank livery is a usage the host chooses, so the usages that
  // print differently are what deserve a row. `leased` paints as `private` and
  // `exempt` as `government`, so listing all five would repeat two plates.
  const wbLiveries = <(String, PSUsage)>[
    ('Private', PSUsage.private),
    ('Public transport', PSUsage.publicTransport),
    ('Government', PSUsage.government),
    ('Police', PSUsage.police),
  ];

  return {
    'West Bank · modern': [
      for (final (name, usage) in wbLiveries)
        _Sample(
          label: name,
          spec: PSWestBankPlates.modernCar,
          theme: PSThemes.forUsage(usage),
          kind: _Kind.westBankModern,
        ),
      _Sample(
        label: 'Trade / test',
        spec: PSWestBankPlates.modernTrade,
        theme: PSThemes.forUsage(PSUsage.private),
        kind: _Kind.westBankModern,
      ),
      _Sample(
        label: 'Two-line',
        spec: PSWestBankPlates.modernCarTwoLine,
        theme: PSThemes.forUsage(PSUsage.private),
        kind: _Kind.westBankModern,
      ),
      _Sample(
        label: 'Motorcycle',
        spec: PSWestBankPlates.modernMoto,
        theme: PSThemes.forUsage(PSUsage.private),
        kind: _Kind.westBankModern,
      ),
      _Sample(
        label: 'Motorcycle, two-line',
        spec: PSWestBankPlates.modernMotoTwoLine,
        theme: PSThemes.forUsage(PSUsage.private),
        kind: _Kind.westBankModern,
      ),
    ],
    'West Bank · legacy': [
      _Sample(
        label: 'Private',
        spec: PSWestBankPlates.legacyCar,
        theme: PSThemes.forUsage(PSUsage.private),
        kind: _Kind.westBankLegacy,
      ),
      _Sample(
        label: 'Public transport',
        // The legacy `ف / P` block is printed in the plate's own ink, so an
        // inverted plate recolours the block via `country:` — same spec.
        spec: PSWestBankPlates.legacyCar,
        theme: PSThemes.forUsage(PSUsage.publicTransport),
        country: PSWestBankPlates.legacyCountryForUsage(PSUsage.publicTransport),
        kind: _Kind.westBankLegacy,
      ),
      _Sample(
        label: 'Government',
        spec: PSWestBankPlates.legacyCar,
        theme: PSThemes.forUsage(PSUsage.government),
        country: PSWestBankPlates.legacyCountryForUsage(PSUsage.government),
        kind: _Kind.westBankLegacy,
      ),
      _Sample(
        label: 'Two-line',
        spec: PSWestBankPlates.legacyCarTwoLine,
        theme: PSThemes.forUsage(PSUsage.private),
        kind: _Kind.westBankLegacy,
      ),
    ],
    // Gaza's colour is a fact about the value, not a choice: the generator
    // picks a usage code and `forGazaUsageCode` reads the livery back off it.
    // So each Gaza card derives its own theme from the digits it was dealt,
    // and the labels below name the layout rather than the colour.
    'Gaza': [
      _Sample(
        label: '2012',
        spec: PSGazaPlates.car2012,
        theme: PSThemes.gazaBlack,
        kind: _Kind.gaza,
        note: 'colour read from the plate',
      ),
      _Sample(
        label: '2012, two-line',
        spec: PSGazaPlates.car2012TwoLine,
        theme: PSThemes.gazaBlack,
        kind: _Kind.gaza,
      ),
      _Sample(
        label: '2021, two-line',
        spec: PSGazaPlates.car2021TwoLine,
        theme: PSThemes.gazaBlack,
        kind: _Kind.gaza,
      ),
      _Sample(
        label: 'Motorcycle',
        spec: PSGazaPlates.moto,
        theme: PSThemes.gazaBlack,
        kind: _Kind.gaza,
      ),
    ],
  };
}

/// The value dealt to each catalogue entry.
///
/// Filled in one pass in catalogue order, so the seed is consumed the same way
/// on every run and the page is reproducible.
final Map<_Sample, List<String?>> _values = {
  for (final samples in _catalogue.values)
    for (final s in samples)
      s: switch (s.kind) {
        _Kind.westBankModern =>
          PSSerialGenerator.modernWestBank(s.spec, random: _rng),
        _Kind.westBankLegacy =>
          PSSerialGenerator.legacyWestBank(s.spec, random: _rng),
        _Kind.gaza => PSSerialGenerator.gaza(s.spec, random: _rng),
      },
};

final Random _rng = Random(20180701);

final Map<String, List<_Sample>> _catalogue = _buildCatalogue();

class _CatalogueTab extends StatelessWidget {
  const _CatalogueTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          'Every plate the package can draw, one of each — not several rolls '
          'of the same one.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        for (final MapEntry(key: section, value: samples)
            in _catalogue.entries) ...[
          Text(
            section.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Two columns once there is room for them; one on a phone.
              final columns = constraints.maxWidth >= 560 ? 2 : 1;
              const gap = 12.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final s in samples)
                    SizedBox(
                      width: width,
                      child: _SampleCard(sample: s),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
        ],
      ],
    );
  }
}

/// One read-only plate with its label — the unit the catalogue is made of.
class _SampleCard extends StatefulWidget {
  const _SampleCard({required this.sample});

  final _Sample sample;

  @override
  State<_SampleCard> createState() => _SampleCardState();
}

class _SampleCardState extends State<_SampleCard> {
  /// Seeded once with the generated value; nothing types into it.
  late final PlateController _plate = PlateController.fromValues(
    widget.sample.spec,
    _values[widget.sample]!,
  );

  @override
  void dispose() {
    _plate.dispose();
    super.dispose();
  }

  /// Gaza's livery is a fact about the digits, so it is read back off the
  /// value rather than taken from the catalogue entry.
  PlateTheme get _theme {
    final s = widget.sample;
    if (s.kind != _Kind.gaza) return s.theme;
    return PSThemes.forGazaUsageCode(
          s.spec.valueOfGroup('usage', _values[s]!),
        ) ??
        s.theme;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spec = widget.sample.spec;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SizedBox(
                // A fixed height, width derived from the spec: two-line and
                // motorcycle plates then sit at their true proportions next to
                // a long car plate instead of being stretched to match it.
                height: 74,
                width: 74 * spec.canvasWidth / spec.canvasHeight,
                child: PlateThemeScope(
                  theme: _theme,
                  child: PlateView(
                    controller: _plate,
                    theme: _theme,
                    country: widget.sample.country,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(widget.sample.label, style: theme.textTheme.titleSmall),
            Text(
              widget.sample.note ?? spec.id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
