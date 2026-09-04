import 'dart:math';

import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:plate_keypad/plate_keypad.dart';
import 'package:plate_palestine/plate_palestine.dart';

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
  const _Scheme(this.label, this.base, this.kind);

  final String label;

  /// The spec before usage is taken into account. For the legacy West Bank
  /// plate the ink colour changes which const is correct — see [_specFor].
  final PlateSpec base;

  final _Kind kind;
}

const List<_Scheme> _schemes = [
  _Scheme('West Bank — modern', PSWestBankPlates.modernCar, _Kind.westBankModern),
  _Scheme('West Bank — legacy', PSWestBankPlates.legacyCar, _Kind.westBankLegacy),
  _Scheme('West Bank — trade / test', PSWestBankPlates.modernTrade, _Kind.westBankModern),
  _Scheme('West Bank — modern, two-line', PSWestBankPlates.modernCarTwoLine, _Kind.westBankModern),
  _Scheme('West Bank — legacy, two-line', PSWestBankPlates.legacyCarTwoLine, _Kind.westBankLegacy),
  _Scheme('West Bank — motorcycle', PSWestBankPlates.modernMoto, _Kind.westBankModern),
  _Scheme('West Bank — motorcycle, two-line', PSWestBankPlates.modernMotoTwoLine, _Kind.westBankModern),
  _Scheme('Gaza — 2012', PSGazaPlates.car2012, _Kind.gaza),
  _Scheme('Gaza — 2021', PSGazaPlates.car2021, _Kind.gaza),
  _Scheme('Gaza — 2012, two-line', PSGazaPlates.car2012TwoLine, _Kind.gaza),
  _Scheme('Gaza — 2021, two-line', PSGazaPlates.car2021TwoLine, _Kind.gaza),
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
    title: 'plate_palestine',
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      appBar: AppBar(title: const Text('plate_palestine')),
      body: SafeArea(
        child: BlocProvider(
          create: (_) => PlateCardBloc(_schemes.first.base),
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
  final PlateInputController _input = PlateInputController();

  _Scheme _scheme = _schemes.first;
  PSUsage _usage = PSUsage.private;

  /// The slot the keypad is typing into, or null when nothing is focused.
  /// Mirrored into state because the keypad greys its keys off it.
  int? _activeIndex;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
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

  void _switchTo({_Scheme? scheme, PSUsage? usage}) {
    final bloc = context.read<PlateCardBloc>();
    final before = List<String?>.of(bloc.state.plateNumber.values);
    final oldSpec = _specFor(_scheme, _usage);

    setState(() {
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

  void _onKey(String key) {
    if (key == kPlateBackspaceKey) {
      _input.backspace();
    } else {
      _input.submit(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlateCardBloc, PlateCardState>(
      builder: (context, state) {
        final spec = _specFor(_scheme, _usage);
        final values = state.plateNumber.values;
        final theme = _themeFor(_scheme, _usage, spec, values);
        final verdict = _verdictFor(_scheme, spec, values);
        final active = _activeIndex;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SchemePicker(
              scheme: _scheme,
              onChanged: (s) => _switchTo(scheme: s),
            ),
            const SizedBox(height: 8),
            _UsagePicker(
              usage: _usage,
              // Gaza reads its usage off the plate's own last two digits, so
              // there is nothing here for a host to choose.
              enabled: _scheme.kind != _Kind.gaza,
              onChanged: (u) => _switchTo(usage: u),
            ),
            const SizedBox(height: 16),

            PlateCanvas(
              spec: spec,
              // Colour is derived and passed in. PlateSpec has no theme field.
              theme: theme,
              // The keypad below is the only way characters get in.
              inputSource: PlateInputSource.packageKeypad,
              controller: _input,
              validator: _validatorFor(_scheme.kind),
              // Paints the underlines red on an invalid plate; never blocks a
              // keystroke, never throws.
              autoValidate: true,
              onActiveIndexChanged: (i) => setState(() => _activeIndex = i),
              // The governorate slot is a `chosen` alphabet, so core asks for a
              // character instead of accepting typing. plate_keypad's modal
              // wheel offers exactly the thirteen legal letters — no I, no O.
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

            const SizedBox(height: 16),
            PlateKeypad(
              highlightedKey: null,
              onKey: _onKey,
              digitAlphabet: PSAlphabets.digits,
              // Never reached from the pad: the only letters on a Palestinian
              // plate are governorate letters, and that slot opens the picker
              // instead. Supplied because the keypad requires it.
              letterAlphabet: PSAlphabets.governorateLetters,
              // Greys out keys the focused slot will not take — the legacy
              // district slot refuses 0 and 2, the Gaza prefix takes only 3.
              activeAlphabet: active == null ? null : spec.slots[active].alphabet,
            ),

            const SizedBox(height: 24),
            const Divider(),
            const Text(
              'Generated, read-only',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const _GeneratedRow(),
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

class _SchemePicker extends StatelessWidget {
  const _SchemePicker({required this.scheme, required this.onChanged});

  final _Scheme scheme;
  final ValueChanged<_Scheme> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<_Scheme>(
    initialValue: scheme,
    decoration: const InputDecoration(
      labelText: 'Scheme',
      helperText: 'Switching resets the plate; entered values are re-seeded.',
      border: OutlineInputBorder(),
    ),
    items: [
      for (final s in _schemes)
        DropdownMenuItem(value: s, child: Text(s.label)),
    ],
    onChanged: (s) => s == null ? null : onChanged(s),
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
  Widget build(BuildContext context) => DropdownButtonFormField<PSUsage>(
    initialValue: usage,
    decoration: InputDecoration(
      labelText: 'Usage',
      helperText: enabled
          ? 'Drives the theme — colour is derived, never passed by hand.'
          : 'Gaza reads usage off the plate’s own last two digits.',
      border: const OutlineInputBorder(),
    ),
    items: [
      for (final u in PSUsage.values)
        DropdownMenuItem(value: u, child: Text(u.name)),
    ],
    onChanged: enabled ? (u) => u == null ? null : onChanged(u) : null,
  );
}

// ---------------------------------------------------------------------------
// A row of generated plates, rendered read-only through ShowPlate.
// ---------------------------------------------------------------------------

class _GeneratedRow extends StatelessWidget {
  const _GeneratedRow();

  @override
  Widget build(BuildContext context) {
    // Seeded, so this row is the same on every run — the whole point of
    // PSSerialGenerator taking a Random rather than making its own.
    final rng = Random(20180701);
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _GeneratedPlate(
            spec: PSWestBankPlates.modernCar,
            values: PSSerialGenerator.modernWestBank(rng),
            theme: PSThemes.forUsage(PSUsage.private),
          ),
          _GeneratedPlate(
            spec: PSWestBankPlates.legacyCarPublicTransport,
            values: PSSerialGenerator.legacyWestBank(rng),
            theme: PSThemes.forUsage(PSUsage.publicTransport),
          ),
          _GeneratedPlate(
            spec: PSGazaPlates.car2021,
            values: PSSerialGenerator.gaza(rng),
            theme: PSThemes.gazaBlack,
          ),
        ],
      ),
    );
  }
}

/// One read-only plate.
///
/// `ShowPlate` renders whatever its nearest `PlateCardBloc` holds, so each
/// plate gets a bloc of its own seeded with the generated values. It passes no
/// `theme:` to the canvas it builds, so the theme has to arrive through a
/// `PlateThemeScope`.
class _GeneratedPlate extends StatelessWidget {
  const _GeneratedPlate({
    required this.spec,
    required this.values,
    required this.theme,
  });

  final PlateSpec spec;
  final List<String?> values;
  final PlateTheme theme;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: SizedBox(
      width: 240,
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
  );
}
