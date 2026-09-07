import 'dart:math';

import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:yemen_plate/yemen_plate.dart';

void main() => runApp(const ExampleApp());

/// Which of Yemen's two current systems the screen is showing.
///
/// This lives in the example, not in `yemen_plate`. The package deliberately
/// ships no `YemenSystem` enum: a host normally knows which system it is
/// registering vehicles under and reaches for one namespace, and only a demo
/// that wants to show both needs a switch. Note it is a *display* choice here
/// and nothing more — the two systems are not two versions of one thing, and
/// flipping this replaces the spec, the theme and the validator together.
enum ExampleSystem { unified, northern }

extension on ExampleSystem {
  String get label =>
      this == ExampleSystem.unified ? '2026 unified' : '1993 northern';
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'yemen_plate',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFFB02A30),
      brightness: Brightness.light,
    ),
    darkTheme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFFB02A30),
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
        headerSliverBuilder: (BuildContext context, _) => <Widget>[
          SliverAppBar.large(
            title: const Text('yemen_plate'),
            bottom: const TabBar(
              tabs: <Widget>[
                Tab(icon: Icon(Icons.edit_outlined), text: 'Enter a plate'),
                Tab(icon: Icon(Icons.grid_view_outlined), text: 'Every type'),
              ],
            ),
          ),
        ],
        body: const TabBarView(
          children: <Widget>[_PlateEntry(), _CatalogueTab()],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tab 1: one plate, and the pickers that choose which.
// ---------------------------------------------------------------------------

class _PlateEntry extends StatefulWidget {
  const _PlateEntry();

  @override
  State<_PlateEntry> createState() => _PlateEntryState();
}

class _PlateEntryState extends State<_PlateEntry> {
  ExampleSystem _system = ExampleSystem.unified;
  YemenUsage _usage = YemenUsage.private;
  YemenMilitaryStyle _militaryStyle = YemenMilitaryStyle.classic;
  bool _motorcycle = false;

  /// System A: how many digits the vehicle number has.
  int _numberLength = 5;

  /// System B: how many digits the governorate code and the serial have.
  (int, int) _northernDigits = (2, 5);

  // --- What the pickers currently resolve to. -------------------------------

  bool get _isUnified => _system == ExampleSystem.unified;

  /// The usages the current system issues, in declaration order.
  List<YemenUsage> get _usageOptions => YemenUsage.values
      .where(_isUnified ? YemenUsage.unified.contains : YemenUsage.northern.contains)
      .toList(growable: false);

  PlateSpec get _spec {
    if (_isUnified) {
      final Map<int, PlateSpec> byLength = YemenUnifiedPlates.byNumberLength(
        _usage,
        motorcycle: _motorcycle,
      );
      return byLength[_numberLength] ?? byLength.values.first;
    }
    final Map<(int, int), PlateSpec> byDigits = YemenNorthernPlates.byDigits(
      _usage,
      motorcycle: _motorcycle,
    );
    // The motorcycle map holds one layout, so a (2, 4) selection carried over
    // from the car form falls back rather than blanking the screen.
    return byDigits[_northernDigits] ?? byDigits.values.first;
  }

  PlateTheme get _theme => _isUnified
      ? YemenThemes.forUnifiedUsage(_usage)
      : YemenThemes.forNorthernUsage(_usage, style: _militaryStyle);

  PlateValidator get _validator => _isUnified
      ? const YemenUnifiedValidator()
      : const YemenNorthernValidator();

  // --- Picker handlers. -----------------------------------------------------

  void _setSystem(ExampleSystem system) => setState(() {
    _system = system;
    // `police` exists only on System A and `military` only on System B, so a
    // usage can stop being issuable when the system flips. The package's
    // lookups fall back rather than throwing — see `YemenCountry.unifiedFor` —
    // but a picker that keeps showing a usage the system does not issue is
    // lying, so reset instead.
    final Set<YemenUsage> issued = _isUnified
        ? YemenUsage.unified
        : YemenUsage.northern;
    if (!issued.contains(_usage)) _usage = YemenUsage.private;
  });

  @override
  Widget build(BuildContext context) {
    final PlateSpec spec = _spec;
    final PlateTheme theme = _theme;
    final bool unified = _isUnified;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _PlateStage(
          spec: spec,
          child: PlateCanvas(
            spec: spec,
            theme: theme,
            // Real text fields: each slot opens the platform keyboard.
            inputSource: PlateInputSource.system,
            validator: _validator,
            // Paints the plate's underlines red on an invalid value; never
            // blocks a keystroke. Both Yemeni validators stay quiet until the
            // last register has something in it, so this does not flash red at
            // the first digit.
            autoValidate: true,
            // Every control on this screen changes the spec, so the value is
            // carried across register by register rather than cleared — the
            // serial stays the serial even when the layout around it changes.
            onSpecChange: PlateValuePreservation.byGroupKey,
            // Every alphabet on both systems is `typed`, so no slot ever opens
            // a picker.
            onChooseCharacter: (PlateAlphabet alphabet) async => null,
          ),
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'Scheme',
          child: Column(
            children: <Widget>[
              _PickerRow(
                label: 'System',
                children: <Widget>[
                  for (final ExampleSystem s in ExampleSystem.values)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: _system == s,
                      onSelected: (_) => _setSystem(s),
                    ),
                ],
              ),
              _PickerRow(
                label: 'Usage',
                children: <Widget>[
                  for (final YemenUsage u in _usageOptions)
                    ChoiceChip(
                      // The Arabic the plate itself prints, where the plate
                      // prints one. A northern government or military plate
                      // carries no usage word that any source names — see the
                      // TODOs on `YemenUsage` — so those fall back to the
                      // enum's own name.
                      label: Text(
                        (unified ? u.unifiedArabic : u.northernArabic) ?? u.name,
                      ),
                      selected: _usage == u,
                      onSelected: (_) => setState(() => _usage = u),
                    ),
                ],
              ),
              if (!unified && _usage == YemenUsage.military)
                _PickerRow(
                  label: 'Printing',
                  children: <Widget>[
                    for (final YemenMilitaryStyle s in YemenMilitaryStyle.values)
                      ChoiceChip(
                        label: Text(s.name),
                        selected: _militaryStyle == s,
                        onSelected: (_) => setState(() => _militaryStyle = s),
                      ),
                  ],
                ),
              _PickerRow(
                label: 'Form',
                note: _motorcycle
                    ? 'Every motorcycle spec in this package is unverified '
                          'geometry.'
                    : null,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('Car'),
                    selected: !_motorcycle,
                    onSelected: (_) => setState(() => _motorcycle = false),
                  ),
                  ChoiceChip(
                    label: const Text('Motorcycle'),
                    selected: _motorcycle,
                    onSelected: (_) => setState(() => _motorcycle = true),
                  ),
                ],
              ),
              if (unified)
                _PickerRow(
                  label: 'Number',
                  children: <Widget>[
                    for (final int n in YemenUnifiedPlates.numberLengths)
                      ChoiceChip(
                        label: Text('$n digits'),
                        selected: _numberLength == n,
                        onSelected: (_) => setState(() => _numberLength = n),
                      ),
                  ],
                )
              else
                _PickerRow(
                  label: 'Registers',
                  note: 'governorate digits + serial digits',
                  children: <Widget>[
                    for (final (int, int) d in _northernOptions)
                      ChoiceChip(
                        label: Text('${d.$1} + ${d.$2}'),
                        selected: _northernDigits == d,
                        onSelected: (_) => setState(() => _northernDigits = d),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  static const List<(int, int)> _northernOptions = <(int, int)>[
    (2, 5),
    (1, 5),
    (2, 4),
    (2, 6),
  ];
}

// ---------------------------------------------------------------------------
// Tab 2: the catalogue — one generated plate per distinct plate type.
//
// Walked out of the package's own lookup maps rather than named by hand, so a
// spec added to `YemenUnifiedPlates.car` or `YemenNorthernPlates.moto` shows up
// here without this file changing. Each card is a *different* spec: this page
// shows the range of plates the package draws, not repeated samples of one.
// ---------------------------------------------------------------------------

class _Sample {
  const _Sample({
    required this.label,
    required this.spec,
    required this.theme,
    required this.values,
  });

  final String label;
  final PlateSpec spec;
  final PlateTheme theme;
  final List<String?> values;
}

/// The catalogue, grouped into a section per system and form factor.
///
/// Seeded, so the page looks the same on every run and every hot reload — a
/// catalogue that reshuffles itself is hard to compare against.
Map<String, List<_Sample>> _buildCatalogue() {
  final Random rng = Random(1970);
  final Map<String, List<_Sample>> out = <String, List<_Sample>>{};

  for (final bool moto in <bool>[false, true]) {
    final String form = moto ? 'motorcycle' : 'car';

    // System A. One card per (usage, number length): the number length is a
    // real layout difference, so all three earn a card.
    final List<_Sample> unified = <_Sample>[
      for (final YemenUsage usage in YemenUsage.values)
        for (final MapEntry<int, PlateSpec> e
            in YemenUnifiedPlates.byNumberLength(usage, motorcycle: moto)
                .entries)
          _Sample(
            label:
                '${usage.unifiedArabic ?? usage.name} · ${e.key} digits',
            spec: e.value,
            theme: YemenThemes.forUnifiedUsage(usage),
            values: YemenUnifiedSerialGenerator.generate(e.value, random: rng),
          ),
    ];
    if (unified.isNotEmpty) out['2026 unified · $form'] = unified;

    // System B. Same walk, keyed by (governorate digits, serial digits).
    // Military is drawn twice, once per printing style: the two are the same
    // spec in different ink, and on System B the ink *is* the class.
    final List<_Sample> northern = <_Sample>[
      for (final YemenUsage usage in YemenUsage.values)
        for (final MapEntry<(int, int), PlateSpec> e
            in YemenNorthernPlates.byDigits(usage, motorcycle: moto).entries)
          for (final YemenMilitaryStyle style in usage == YemenUsage.military
              ? YemenMilitaryStyle.values
              : const <YemenMilitaryStyle>[YemenMilitaryStyle.classic])
            _Sample(
              label: <String>[
                usage.northernArabic ?? usage.name,
                '${e.key.$1} + ${e.key.$2}',
                if (usage == YemenUsage.military) style.name,
              ].join(' · '),
              spec: e.value,
              theme: YemenThemes.forNorthernUsage(usage, style: style),
              values: YemenNorthernSerialGenerator.generate(
                e.value,
                random: rng,
              ),
            ),
    ];
    if (northern.isNotEmpty) out['1993 northern · $form'] = northern;
  }
  return out;
}

final Map<String, List<_Sample>> _catalogue = _buildCatalogue();

class _CatalogueTab extends StatelessWidget {
  const _CatalogueTab();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int total = _catalogue.values.fold(
      0,
      (int n, List<_Sample> s) => n + s.length,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        Text(
          'All $total plates the package can draw, one of each — walked out of '
          'the package’s own lookup maps, not named here by hand.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        for (final MapEntry<String, List<_Sample>> section
            in _catalogue.entries) ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  section.key.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Text(
                '${section.value.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // As many columns as fit at a comfortable card width.
              final int columns = (constraints.maxWidth / 280).floor().clamp(
                1,
                4,
              );
              const double gap = 12;
              final double width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: <Widget>[
                  for (final _Sample s in section.value)
                    SizedBox(width: width, child: _SampleCard(sample: s)),
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
///
/// [PlateView] rather than `ShowPlate` because it takes a [PlateTheme]:
/// `ShowPlate` always paints the standard black-on-white plate, which is fine
/// for Iran and wrong for Yemen — a northern plate's colour *is* its usage
/// class, so a green government plate rendered white is a different plate.
class _SampleCard extends StatefulWidget {
  const _SampleCard({required this.sample});

  final _Sample sample;

  @override
  State<_SampleCard> createState() => _SampleCardState();
}

class _SampleCardState extends State<_SampleCard> {
  /// A controller of its own, scoped to this one plate, so no card on the page
  /// shares a value with any other.
  late final PlateController _controller = PlateController.fromValues(
    widget.sample.spec,
    widget.sample.values,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final PlateSpec spec = widget.sample.spec;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: SizedBox(
                // A fixed height, width derived from the spec: a tall
                // motorcycle plate then sits at its true proportions next to a
                // long car plate instead of being stretched to match it.
                height: 74,
                width: 74 * spec.canvasWidth / spec.canvasHeight,
                child: PlateView(
                  controller: _controller,
                  theme: widget.sample.theme,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.sample.label,
              style: theme.textTheme.titleSmall,
            ),
            Text(
              spec.id,
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

// ---------------------------------------------------------------------------
// Chrome, shared by both tabs.
// ---------------------------------------------------------------------------

/// The hero slot the editable plate sits in: a soft, recessed panel that keeps
/// the plate at its own aspect ratio however wide the window gets.
class _PlateStage extends StatelessWidget {
  const _PlateStage({required this.spec, required this.child});

  final PlateSpec spec;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: ConstrainedBox(
          // A motorcycle plate is nearly square; without a ceiling it would
          // grow to fill a desktop window and dwarf everything under it.
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: children),
          if (note != null) ...<Widget>[
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
