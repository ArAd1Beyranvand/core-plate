import 'package:core_plate/core_plate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:plate_keypad/plate_keypad.dart';

import '../sources/sources.dart';
import '../widgets/picker_row.dart';
import '../widgets/plate_stage.dart';
import '../widgets/section_header.dart';

/// One plate at a time, editable, with the pickers that choose which.
///
/// Subsumes the "Enter a plate" tab of both showcase apps. Three pickers walk
/// the catalogue — country, scheme, plate — and the fourth chooses where
/// characters come from, including `plate_keypad`'s pad wired through
/// [PlateController.submit] and [PlateController.backspace].
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({
    super.key,
    required this.entry,
    required this.onEntryChanged,
  });

  final GalleryEntry entry;
  final ValueChanged<GalleryEntry> onEntryChanged;

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  PlateInputSource _inputSource = PlateInputSource.system;

  /// The plate's characters. Held here because this screen *reads* the value on
  /// every build — livery, verdict and Submit all derive from it — and writes
  /// none of it. The canvas is the only writer, and it adopts a new spec itself
  /// when a picker swaps one in.
  late final PlateController _plate = PlateController(spec: widget.entry.spec);

  @override
  void initState() {
    super.initState();
    // A plain listener rather than a `ListenableBuilder` around the canvas:
    // attaching notifies synchronously from the canvas's `initState`, so a
    // builder that both listened and built the canvas would be marked dirty in
    // the middle of its own build.
    _plate.addListener(_onPlateChanged);
  }

  void _onPlateChanged() {
    if (!mounted) return;
    // That same synchronous notification lands mid-build, where `setState` is
    // an error. Everything it affects here is chrome around the plate, so
    // settling it on the next frame costs nothing visible.
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

  GalleryEntry get entry => widget.entry;

  /// Derived rather than stored, so the pickers cannot drift out of step with a
  /// card tapped on the catalogue screen.
  GallerySource get _source => gallerySources.firstWhere(
    (GallerySource s) => s.entries.any((GalleryEntry e) => e.id == entry.id),
  );

  GallerySection get _section => _source.sections.firstWhere(
    (GallerySection s) => s.entries.any((GalleryEntry e) => e.id == entry.id),
  );

  /// The keypad's labels, taken off the plate itself — Persian digits on an
  /// Iranian plate, Latin on a German. A spec with no letter slot falls back to
  /// Latin capitals, which the pad then never slides in.
  PlateAlphabet _alphabet({required bool numeric}) {
    for (final PlateSlot slot in entry.spec.slots) {
      if (slot.alphabet.isNumeric == numeric) return slot.alphabet;
    }
    return numeric ? PlateAlphabet.latinDigits : PlateAlphabet.latinUppercase;
  }

  @override
  Widget build(BuildContext context) {
    final GalleryEntry entry = this.entry;
    final PlateValidation? verdict = _plate.validation;
    final PlateSlot? active = _plate.activeSlot;
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: <Widget>[
              // The plate first and big: it is the subject of the screen, and
              // the pickers below only say which one is on show.
              PlateStage(
                spec: entry.spec,
                child: PlateCanvas(
                  spec: entry.spec,
                  // The three independent render-time inputs. The livery can be
                  // a fact about the value — Gaza reads its usage off its own
                  // last two digits — so it is asked for per build.
                  theme: entry.themeFor(_plate.values),
                  country: entry.country,
                  inputSource: _inputSource,
                  validator: entry.validator,
                  // Paints the underlines red; never bars a keystroke.
                  autoValidate: true,
                  // Every picker here can change the spec, so the value carries
                  // across register by register rather than being cleared.
                  onSpecChange: PlateValuePreservation.byGroupKey,
                  controller: _plate,
                  // A `chosen` slot — Iran's letter, the West Bank's
                  // governorate — asks the host for a character. This is what
                  // the dependency on plate_keypad is for.
                  onChooseCharacter: (PlateAlphabet alphabet) =>
                      PlateCharacterPicker.show(context, alphabet),
                ),
              ),
              const SizedBox(height: 20),
              _VerdictBar(verdict: verdict, plate: _plate),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  // Gated on *full* as well as valid: a validator stays quiet
                  // until the last register, so an empty plate reads as valid
                  // and the verdict alone would let a blank one through.
                  onPressed: _plate.isCompleted && (verdict?.isValid ?? true)
                      ? _onSubmit
                      : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Submit'),
                ),
              ),
              const SizedBox(height: 24),
              SettingsSection(
                title: 'Plate',
                child: Column(
                  children: <Widget>[
                    ChipPicker<GallerySource>(
                      label: 'Country',
                      values: gallerySources,
                      selected: _source,
                      labelOf: (GallerySource s) => s.countryName,
                      onSelected: (GallerySource s) =>
                          widget.onEntryChanged(s.entries.first),
                    ),
                    ChipPicker<GallerySection>(
                      label: 'Scheme',
                      values: _source.sections,
                      selected: _section,
                      labelOf: (GallerySection s) => s.title,
                      onSelected: (GallerySection s) =>
                          widget.onEntryChanged(s.entries.first),
                    ),
                    ChipPicker<GalleryEntry>(
                      label: 'Plate',
                      note: _section.note,
                      values: _section.entries,
                      selected: entry,
                      labelOf: (GalleryEntry e) => e.label,
                      onSelected: widget.onEntryChanged,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SettingsSection(
                title: 'Input',
                child: ChipPicker<PlateInputSource>(
                  label: 'Characters come from',
                  note: _inputSource == PlateInputSource.packageKeypad
                      ? 'The pad below drives PlateController.submit and '
                            '.backspace — nothing else reaches the plate.'
                      : null,
                  values: PlateInputSource.values,
                  selected: _inputSource,
                  labelOf: (PlateInputSource s) => s.name,
                  onSelected: (PlateInputSource s) =>
                      setState(() => _inputSource = s),
                ),
              ),
            ],
          ),
        ),
        if (_inputSource == PlateInputSource.packageKeypad)
          PlateKeypad(
            highlightedKey: null,
            compact: true,
            showLetters: active != null && !active.alphabet.isNumeric,
            digitAlphabet: _alphabet(numeric: true),
            letterAlphabet: _alphabet(numeric: false),
            activeAlphabet: active?.alphabet,
            onKey: (String key) => key == kPlateBackspaceKey
                ? _plate.backspace()
                : _plate.submit(key),
          ),
      ],
    );
  }

  void _onSubmit() => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(_plate.text(sep: ' · ')),
    ),
  );
}

/// The live verdict, as a quiet line rather than a red wall of text.
class _VerdictBar extends StatelessWidget {
  const _VerdictBar({required this.verdict, required this.plate});

  /// Null when the entry's package ships no validator for this plate.
  final PlateValidation? verdict;
  final PlateController plate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final (IconData icon, Color color, String message) = switch (verdict) {
      null => (
        Icons.remove_circle_outline,
        colors.onSurfaceVariant,
        'This package ships no validator for this plate.',
      ),
      final PlateValidation v when !v.isValid => (
        Icons.info_outline,
        colors.error,
        v.reason!,
      ),
      _ when !plate.isCompleted => (
        Icons.more_horiz,
        colors.onSurfaceVariant,
        'Nothing wrong so far — the rule stays quiet until the last register.',
      ),
      _ => (Icons.check_circle_outline, colors.primary, 'Valid plate'),
    };
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
