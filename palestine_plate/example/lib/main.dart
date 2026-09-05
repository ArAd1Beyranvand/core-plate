import 'dart:math';

import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _Scheme {
  const _Scheme(this.label, this.base, this.kind, {this.isTwoLine = false, this.isMotorcycle = false});

  final String label;
  final PlateSpec base;
  final _Kind kind;
  final bool isTwoLine;
  final bool isMotorcycle;
}

const List<_Scheme> _westBankModernSchemes = [
  _Scheme('Standard', PSWestBankPlates.modernCar, _Kind.westBankModern),
  _Scheme('Trade / test', PSWestBankPlates.modernTrade, _Kind.westBankModern),
  _Scheme('Two-line', PSWestBankPlates.modernCarTwoLine, _Kind.westBankModern, isTwoLine: true),
];

const List<_Scheme> _westBankLegacySchemes = [
  _Scheme('Standard', PSWestBankPlates.legacyCar, _Kind.westBankLegacy),
  _Scheme('Two-line', PSWestBankPlates.legacyCarTwoLine, _Kind.westBankLegacy, isTwoLine: true),
];

const List<_Scheme> _gazaSchemes = [
  _Scheme('2012', PSGazaPlates.car2012, _Kind.gaza),
  _Scheme('2012, two-line', PSGazaPlates.car2012TwoLine, _Kind.gaza, isTwoLine: true),
  _Scheme('2021, two-line', PSGazaPlates.car2021TwoLine, _Kind.gaza, isTwoLine: true),
];

const List<_Scheme> _westBankModernMotorcycleSchemes = [
  _Scheme('Standard', PSWestBankPlates.modernMoto, _Kind.westBankModern, isMotorcycle: true),
  _Scheme('Two-line', PSWestBankPlates.modernMotoTwoLine, _Kind.westBankModern, isTwoLine: true, isMotorcycle: true),
];

const List<_Scheme> _gazaMotorcycleSchemes = [
  _Scheme('Standard', PSGazaPlates.moto, _Kind.gaza, isMotorcycle: true),
];

/// The spec to draw for [scheme] at [usage].
///
/// Only the legacy West Bank plate varies: its `ف / P` block is printed in the
/// plate's ink, so an inverted (white-on-green) or a red plate needs the const
/// whose [PlateCountry] carries that ink. Same geometry, different country.
PlateSpec _specFor(_Scheme scheme, PSUsage usage) {
  if (scheme.base != PSWestBankPlates.legacyCar) return scheme.base;
  return switch (usage) {
    PSUsage.publicTransport => PSWestBankPlates.legacyCarPublicTransport,
    PSUsage.government || PSUsage.exempt => PSWestBankPlates.legacyCarGovernment,
    _ => PSWestBankPlates.legacyCar,
  };
}

/// The theme to paint [spec] in. **Never chosen — always derived.**
///
/// The West Bank asks `forUsage`, because the modern scheme encodes no usage on
/// the plate and the host is the only thing that knows it. Gaza reads its own
/// last two digits instead, which is why the usage picker is disabled there:
/// the plate already says what it is.
PlateTheme _themeFor(_Scheme scheme, PSUsage usage, PlateSpec spec, List<String?> values) {
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
PlateValidation _verdictFor(_Scheme scheme, PlateSpec spec, List<String?> values) {
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
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      appBar: AppBar(title: const Text('palestine_plate')),
      body: SafeArea(
        child: BlocProvider(
          create: (_) => PlateCardBloc(_westBankModernSchemes.first.base),
          child: const _Demo(),
        ),
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

  // -------------------------------------------------------------------------
  // Switching spec.
  //
  // `PlateCanvas` reacts to a changed `spec.id` by dispatching
  // `SpecIsChanged`, which EMPTIES THE PLATE. It has to: the bloc still holds
  // the previous plate's values, of a different length, and every
  // `values[index]` downstream would be against the wrong list.
  //
  // So changing scheme or form factor mid-entry wipes what the user typed.
  // That is core_plate's behaviour and this app does not pretend otherwise —
  // it re-seeds the new spec from the old values instead, positionally, which
  // works because every scheme here is (region | district | prefix) + a
  // four-digit serial + a tail. A character the new alphabet does not accept —
  // a digit landing in the governorate slot, say — is dropped rather than
  // forced.
  // -------------------------------------------------------------------------

  void _switchTo({_Kind? region, _Scheme? scheme, PSUsage? usage, bool? motorcycle}) {
    final bloc = context.read<PlateCardBloc>();
    final before = List<String?>.of(bloc.state.plateNumber.values);
    final oldSpec = _specFor(_scheme, _usage);

    setState(() {
      if (region != null) _region = region;
      if (motorcycle != null) _motorcycle = motorcycle;
      if (scheme != null) _scheme = scheme;
      if (usage != null) _usage = usage;
    });

    final newSpec = _specFor(_scheme, _usage);
    if (newSpec.id == oldSpec.id) return; // No reset; nothing to re-seed.

    // After the frame in which PlateCanvas.didUpdateWidget dispatches
    // SpecIsChanged, so the re-seeded values are not immediately emptied.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (var i = 0; i < newSpec.slots.length && i < before.length; i++) {
        final value = before[i];
        if (value == null || value.isEmpty) continue;
        if (!newSpec.slots[i].alphabet.accepts(value)) continue;
        bloc.add(ValueIsChanged(index: i, value: value));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlateCardBloc, PlateCardState>(
      builder: (context, state) {
        final spec = _specFor(_scheme, _usage);
        final values = state.plateNumber.values;
        final theme = _themeFor(_scheme, _usage, spec, values);
        final verdict = _verdictFor(_scheme, spec, values);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _RegionPicker(
              region: _region,
              onChanged: (r) => _switchTo(region: r),
            ),
            const SizedBox(height: 8),
            _FormPicker(
              motorcycle: _motorcycle,
              motorcycleAvailable: _region == _Kind.westBankModern || _region == _Kind.gaza,
              onChanged: (m) => _switchTo(motorcycle: m),
            ),
            const SizedBox(height: 8),
            _VariantPicker(
              scheme: _scheme,
              schemeOptions: _currentSchemes,
              onChanged: (s) => _switchTo(scheme: s),
            ),
            const SizedBox(height: 8),
            _UsagePicker(
              usage: _usage,
              enabled: _scheme.kind != _Kind.gaza,
              onChanged: (u) => _switchTo(usage: u),
            ),
            const SizedBox(height: 16),

            PlateCanvas(
              spec: spec,
              theme: theme,
              // Real text fields: each slot opens the platform keyboard.
              inputSource: PlateInputSource.system,
              validator: _validatorFor(_scheme.kind),
              autoValidate: true,
              onChooseCharacter: (alphabet) =>
                  PlateCharacterPicker.show(context, alphabet),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: verdict.isValid ? () => _onSubmit(spec, values) : null,
                child: const Text('Submit'),
              ),
            ),
            if (!verdict.isValid) ...[
              const SizedBox(height: 8),
              Text(
                verdict.reason!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Generated',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const _CategoryShowcase(),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  void _onSubmit(PlateSpec spec, List<String?> values) {
    final plate = [
      for (final group in spec.effectiveTextGroups) spec.renderGroup(group, values),
    ].join('·');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(plate)));
  }
}

// ---------------------------------------------------------------------------
// Pickers.
// ---------------------------------------------------------------------------

class _RegionPicker extends StatelessWidget {
  const _RegionPicker({required this.region, required this.onChanged});

  final _Kind region;
  final ValueChanged<_Kind> onChanged;

  @override
  Widget build(BuildContext context) => _PickerRow(
    label: 'Region',
    children: [
      for (final r in _Kind.values)
        ChoiceChip(
          label: Text(switch (r) {
            _Kind.westBankModern => 'West Bank - modern',
            _Kind.westBankLegacy => 'West Bank - legacy',
            _Kind.gaza => 'Gaza',
          }),
          selected: region == r,
          onSelected: (_) => onChanged(r),
        ),
    ],
  );
}

class _FormPicker extends StatelessWidget {
  const _FormPicker({
    required this.motorcycle,
    required this.motorcycleAvailable,
    required this.onChanged,
  });

  final bool motorcycle;
  final bool motorcycleAvailable;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => _PickerRow(
    label: 'Form',
    children: [
      ChoiceChip(
        label: const Text('car'),
        selected: !motorcycle,
        onSelected: (_) => onChanged(false),
      ),
      ChoiceChip(
        label: const Text('motorcycle'),
        selected: motorcycle,
        onSelected: motorcycleAvailable ? (_) => onChanged(true) : null,
      ),
    ],
  );
}

class _VariantPicker extends StatelessWidget {
  const _VariantPicker({
    required this.scheme,
    required this.schemeOptions,
    required this.onChanged,
  });

  final _Scheme scheme;
  final List<_Scheme> schemeOptions;
  final ValueChanged<_Scheme> onChanged;

  @override
  Widget build(BuildContext context) => _PickerRow(
    label: 'Variant',
    children: [
      for (final s in schemeOptions)
        ChoiceChip(
          label: Text(s.label),
          selected: scheme == s,
          onSelected: (_) => onChanged(s),
        ),
    ],
  );
}

class _UsagePicker extends StatelessWidget {
  const _UsagePicker({
    required this.usage,
    required this.enabled,
    required this.onChanged,
  });

  final PSUsage usage;
  final bool enabled;
  final ValueChanged<PSUsage> onChanged;

  @override
  Widget build(BuildContext context) => _PickerRow(
    label: 'Usage',
    children: [
      for (final u in PSUsage.values)
        ChoiceChip(
          label: Text(u.name),
          selected: usage == u,
          onSelected: enabled ? (_) => onChanged(u) : null,
        ),
    ],
  );
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 78,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        Expanded(child: Wrap(spacing: 8, runSpacing: 4, children: children)),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Category showcase: one plate from each region, always cars.
// ---------------------------------------------------------------------------

class _CategoryShowcase extends StatelessWidget {
  const _CategoryShowcase();

  @override
  Widget build(BuildContext context) {
    final rng = Random(20180701);
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _GeneratedPlate(
            label: 'West Bank - modern',
            spec: PSWestBankPlates.modernCar,
            values: PSSerialGenerator.modernWestBank(rng),
            theme: PSThemes.forUsage(PSUsage.private),
          ),
          _GeneratedPlate(
            label: 'West Bank - legacy',
            spec: PSWestBankPlates.legacyCar,
            values: PSSerialGenerator.legacyWestBank(rng),
            theme: PSThemes.forUsage(PSUsage.private),
          ),
          _GeneratedPlate(
            label: 'Gaza',
            spec: PSGazaPlates.car2012,
            values: PSSerialGenerator.gaza(rng),
            theme: PSThemes.gazaBlack,
          ),
        ],
      ),
    );
  }
}

/// One read-only plate with category label.
class _GeneratedPlate extends StatelessWidget {
  const _GeneratedPlate({
    required this.label,
    required this.spec,
    required this.values,
    required this.theme,
  });

  final String label;
  final PlateSpec spec;
  final List<String?> values;
  final PlateTheme theme;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 70,
          width: 70 * spec.canvasWidth / spec.canvasHeight,
          child: PlateThemeScope(
            theme: theme,
            child: BlocProvider(
              create: (_) {
                final bloc = PlateCardBloc(spec);
                for (var i = 0; i < values.length; i++) {
                  bloc.add(ValueIsChanged(index: i, value: values[i]));
                }
                return bloc;
              },
              child: const ShowPlate(),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
