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

  /// The plate's characters. Held here because three things on this screen are
  /// derived from the value — the livery, the verdict line and Submit's enabled
  /// state — and none of them is written here. The canvas is the only writer,
  /// and it adopts a new spec itself when a picker swaps one in.
  late final PlateController _plate = PlateController(spec: widget.entry.spec);

  @override
  void dispose() {
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
                // The livery can be a fact about the value — Gaza reads its
                // usage off its own last two digits — so the canvas is rebuilt
                // when, and only when, the theme that value resolves to
                // actually changes. `PlateTheme` compares by value, so typing
                // within one livery rebuilds nothing here: the canvas's own
                // per-slot bindings handle the keystroke.
                child: _PlateBinding<PlateTheme?>(
                  controller: _plate,
                  select: (PlateController c) => entry.themeFor(c.values),
                  builder: (BuildContext context, PlateTheme? theme) =>
                      PlateCanvas(
                        spec: entry.spec,
                        theme: theme,
                        country: entry.country,
                        inputSource: _inputSource,
                        validator: entry.validator,
                        // Paints the underlines red; never bars a keystroke.
                        autoValidate: true,
                        // Every picker here can change the spec, so the value
                        // carries across register by register rather than
                        // being cleared.
                        onSpecChange: PlateValuePreservation.byGroupKey,
                        controller: _plate,
                        // A `chosen` slot — Iran's letter, the West Bank's
                        // governorate — asks the host for a character. This is
                        // what the dependency on plate_keypad is for.
                        onChooseCharacter: (PlateAlphabet alphabet) =>
                            PlateCharacterPicker.show(context, alphabet),
                      ),
                ),
              ),
              const SizedBox(height: 20),
              // The verdict line and Submit are the two things here that read
              // the value directly, and they flip together: one binding on the
              // pair `(verdict, isCompleted)` rebuilds both, and neither the
              // canvas above nor the pickers below.
              _PlateBinding<(PlateValidation?, bool)>(
                controller: _plate,
                select: (PlateController c) => (c.validation, c.isCompleted),
                builder:
                    (BuildContext context, (PlateValidation?, bool) state) {
                      final (PlateValidation? verdict, bool completed) = state;
                      return Column(
                        children: <Widget>[
                          _VerdictBar(verdict: verdict, completed: completed),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              // Gated on *full* as well as valid: a validator
                              // stays quiet until the last register, so an
                              // empty plate reads as valid and the verdict
                              // alone would let a blank one through.
                              onPressed:
                                  completed && (verdict?.isValid ?? true)
                                  ? _onSubmit
                                  : null,
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Submit'),
                            ),
                          ),
                        ],
                      );
                    },
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
        // The pad depends on the value only through the focused slot, which
        // moves far less often than a character changes. Binding it to the
        // active slot alone keeps a keystroke that stays in one slot from
        // rebuilding 42 keys.
        if (_inputSource == PlateInputSource.packageKeypad)
          _PlateBinding<PlateSlot?>(
            controller: _plate,
            select: (PlateController c) => c.activeSlot,
            builder: (BuildContext context, PlateSlot? active) => PlateKeypad(
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

/// Rebuilds [builder] when, and only when, [select]'s result changes.
///
/// This is core's `PlateSelector` with one addition it cannot make: the
/// notification is allowed to arrive mid-build. `PlateCanvas` notifies this
/// controller synchronously from `initState` (when it attaches its input
/// machine) and from `didUpdateWidget` (when a picker swaps the spec and the
/// controller migrates its values), and both of those run while this screen is
/// building — where `setState` on an already-built sibling is an error. The
/// screen used to dodge that by deferring one screen-wide `setState` to the
/// next frame, which rebuilt the canvas, the pad and all four pickers on every
/// keystroke. Deferring the same way per binding keeps the safety and drops
/// everything else.
class _PlateBinding<T> extends StatefulWidget {
  const _PlateBinding({
    required this.controller,
    required this.select,
    required this.builder,
  });

  final PlateController controller;

  /// Called on every notification, so keep it cheap and free of side effects.
  final T Function(PlateController) select;

  final Widget Function(BuildContext, T) builder;

  @override
  State<_PlateBinding<T>> createState() => _PlateBindingState<T>();
}

class _PlateBindingState<T> extends State<_PlateBinding<T>> {
  late T _value = widget.select(widget.controller);

  /// True between noticing a change mid-build and settling it after the frame,
  /// so a burst of notifications in one frame schedules one rebuild.
  bool _settling = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(_PlateBinding<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_handleChange);
      widget.controller.addListener(_handleChange);
    }
    // Re-select on a swapped controller *or* a swapped selector: either can
    // pick a different value out of the same keystrokes. The selector here
    // closes over the current entry, so a picker swapping the plate lands in
    // this branch.
    _value = widget.select(widget.controller);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    // A notification can arrive in the same frame the element is retired.
    if (!mounted || _settling) return;
    final T next = widget.select(widget.controller);
    if (next == _value) return;

    final SchedulerPhase phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      _settling = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _settling = false;
        // Re-selected rather than reusing `next`: more notifications may have
        // landed between then and now.
        if (mounted) setState(() => _value = widget.select(widget.controller));
      });
      return;
    }
    setState(() => _value = next);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}

/// The live verdict, as a quiet line rather than a red wall of text.
class _VerdictBar extends StatelessWidget {
  const _VerdictBar({required this.verdict, required this.completed});

  /// Null when the entry's package ships no validator for this plate.
  final PlateValidation? verdict;

  /// Whether every slot is filled. Passed in rather than read off the
  /// controller so this widget rebuilds only with the binding that selected it.
  final bool completed;

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
      _ when !completed => (
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
