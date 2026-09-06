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

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'yemen_plate',
    home: Scaffold(
      // Nothing above the plate: the canvas owns the value itself. Note that
      // every control on this screen changes the spec, and this canvas leaves
      // `onSpecChange` at its default — so **every control clears the plate**.
      // A real host either passes `PlateValuePreservation.byGroupKey` or
      // presents its system, usage and length pickers before entry begins
      // rather than beside it.
      body: const SafeArea(child: _PlateEntry()),
    ),
  );
}

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

  /// Seeded, so the generated row is the same on every run — a demo that
  /// reshuffles itself on hot reload is hard to look at.
  final Random _random = Random(1970);

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

  List<String?> _generate(PlateSpec spec) => _isUnified
      ? YemenUnifiedSerialGenerator.generate(spec, random: _random)
      : YemenNorthernSerialGenerator.generate(spec, random: _random);

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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        PlateCanvas(
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
          // Every alphabet on both systems is `typed`, so no slot ever opens a
          // picker.
          onChooseCharacter: (PlateAlphabet alphabet) async => null,
        ),
        const SizedBox(height: 16),
        _Controls(
          system: _system,
          onSystem: _setSystem,
          usage: _usage,
          usageOptions: _usageOptions,
          onUsage: (YemenUsage u) => setState(() => _usage = u),
          militaryStyle: _militaryStyle,
          onMilitaryStyle: (YemenMilitaryStyle s) =>
              setState(() => _militaryStyle = s),
          motorcycle: _motorcycle,
          onMotorcycle: (bool m) => setState(() => _motorcycle = m),
          numberLength: _numberLength,
          onNumberLength: (int n) => setState(() => _numberLength = n),
          northernDigits: _northernDigits,
          onNorthernDigits: ((int, int) d) =>
              setState(() => _northernDigits = d),
        ),
        const Divider(height: 32),
        Text('Generated', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => _GeneratedPlate(
              spec: spec,
              theme: theme,
              values: _generate(spec),
            ),
          ),
        ),
      ],
    );
  }
}

/// One read-only plate showing a generated value.
///
/// [PlateView] rather than `ShowPlate` because it takes a [PlateTheme]:
/// `ShowPlate` always paints the standard black-on-white plate, which is fine
/// for Iran and wrong for Yemen — a northern plate's colour *is* its usage
/// class, so a green government plate rendered white is a different plate.
class _GeneratedPlate extends StatefulWidget {
  const _GeneratedPlate({
    required this.spec,
    required this.theme,
    required this.values,
  });

  final PlateSpec spec;
  final PlateTheme theme;
  final List<String?> values;

  @override
  State<_GeneratedPlate> createState() => _GeneratedPlateState();
}

class _GeneratedPlateState extends State<_GeneratedPlate> {
  /// A controller of its own, scoped to this one plate, so the generated row
  /// does not touch the value being typed above it.
  late final PlateController _controller = PlateController.fromValues(
    widget.spec,
    widget.values,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 90,
    width: 90 * widget.spec.canvasWidth / widget.spec.canvasHeight,
    child: PlateView(controller: _controller, theme: widget.theme),
  );
}

/// The pickers. Every one of them changes the spec, and changing the spec
/// clears the plate — see the note in [ExampleApp].
class _Controls extends StatelessWidget {
  const _Controls({
    required this.system,
    required this.onSystem,
    required this.usage,
    required this.usageOptions,
    required this.onUsage,
    required this.militaryStyle,
    required this.onMilitaryStyle,
    required this.motorcycle,
    required this.onMotorcycle,
    required this.numberLength,
    required this.onNumberLength,
    required this.northernDigits,
    required this.onNorthernDigits,
  });

  final ExampleSystem system;
  final ValueChanged<ExampleSystem> onSystem;
  final YemenUsage usage;
  final List<YemenUsage> usageOptions;
  final ValueChanged<YemenUsage> onUsage;
  final YemenMilitaryStyle militaryStyle;
  final ValueChanged<YemenMilitaryStyle> onMilitaryStyle;
  final bool motorcycle;
  final ValueChanged<bool> onMotorcycle;
  final int numberLength;
  final ValueChanged<int> onNumberLength;
  final (int, int) northernDigits;
  final ValueChanged<(int, int)> onNorthernDigits;

  static const List<(int, int)> _northernOptions = <(int, int)>[
    (2, 5),
    (1, 5),
    (2, 4),
    (2, 6),
  ];

  @override
  Widget build(BuildContext context) {
    final bool unified = system == ExampleSystem.unified;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Row(
          label: 'System',
          children: <Widget>[
            for (final ExampleSystem s in ExampleSystem.values)
              ChoiceChip(
                label: Text(
                  s == ExampleSystem.unified ? '2026 unified' : '1993 northern',
                ),
                selected: system == s,
                onSelected: (_) => onSystem(s),
              ),
          ],
        ),
        _Row(
          label: 'Usage',
          children: <Widget>[
            for (final YemenUsage u in usageOptions)
              ChoiceChip(
                // The Arabic the plate itself prints, where the plate prints
                // one. A northern government or military plate carries no
                // usage word that any source names — see the TODOs on
                // `YemenUsage` — so those fall back to the enum's own name.
                label: Text(
                  (unified ? u.unifiedArabic : u.northernArabic) ?? u.name,
                ),
                selected: usage == u,
                onSelected: (_) => onUsage(u),
              ),
          ],
        ),
        if (!unified && usage == YemenUsage.military)
          _Row(
            label: 'Printing',
            children: <Widget>[
              for (final YemenMilitaryStyle s in YemenMilitaryStyle.values)
                ChoiceChip(
                  label: Text(s.name),
                  selected: militaryStyle == s,
                  onSelected: (_) => onMilitaryStyle(s),
                ),
            ],
          ),
        _Row(
          label: 'Form',
          children: <Widget>[
            ChoiceChip(
              label: const Text('car'),
              selected: !motorcycle,
              onSelected: (_) => onMotorcycle(false),
            ),
            ChoiceChip(
              // Every motorcycle spec in this package is unverified geometry;
              // the northern ones are `@Deprecated` to say so out loud.
              label: const Text('motorcycle (unverified)'),
              selected: motorcycle,
              onSelected: (_) => onMotorcycle(true),
            ),
          ],
        ),
        if (unified)
          _Row(
            label: 'Number',
            children: <Widget>[
              for (final int n in YemenUnifiedPlates.numberLengths)
                ChoiceChip(
                  label: Text('$n digits'),
                  selected: numberLength == n,
                  onSelected: (_) => onNumberLength(n),
                ),
            ],
          )
        else
          _Row(
            label: 'Registers',
            children: <Widget>[
              for (final (int, int) d in _northernOptions)
                ChoiceChip(
                  label: Text('${d.$1} + ${d.$2}'),
                  selected: northernDigits == d,
                  onSelected: (_) => onNorthernDigits(d),
                ),
            ],
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 78,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(child: Wrap(spacing: 8, runSpacing: 4, children: children)),
      ],
    ),
  );
}
