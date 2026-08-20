import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plate_number/plate_number.dart';

import 'virtual_keypad.dart' show kBackspaceKey, kLetterPadSlide;

/// One step in a typing script: either a keystroke into a slot, or a
/// backspace. `pauseAfter: true` marks a natural break (a burst just
/// finished, or a letter was just entered) — the typist waits the slower
/// [PlateTypist.gap] there. Everywhere else it waits the quicker
/// [PlateTypist.burstGap], so a run reads as bursts of digits rather than
/// one evenly-spaced drip. [holdAfter], when set, overrides that gap/burstGap
/// choice with an exact duration — for a deliberate beat (e.g. lingering on
/// an invalid state) rather than the run's usual rhythm.
sealed class TypistStep {
  const TypistStep({this.pauseAfter = false, this.holdAfter});

  final bool pauseAfter;
  final Duration? holdAfter;
}

/// Types [char] into the slot at [index].
class KeyStep extends TypistStep {
  const KeyStep(this.index, this.char, {super.pauseAfter, super.holdAfter});

  final int index;
  final String char;
}

/// Deletes a character via [PlateInputController.backspace] — the active
/// slot if it holds a value, otherwise the previous slot.
class BackspaceStep extends TypistStep {
  const BackspaceStep({super.pauseAfter, super.holdAfter});
}

/// The keystrokes for the car plate ("91-ه-886-40"): '9' and '1' typed as a
/// quick burst, a pause, the letter, another pause, then '886' and '40' as
/// two more quick bursts.
const List<TypistStep> carScript = [
  KeyStep(0, '9'),
  KeyStep(1, '1', pauseAfter: true),
  KeyStep(2, 'ه', pauseAfter: true),
  KeyStep(3, '8'),
  KeyStep(4, '8'),
  KeyStep(5, '6', pauseAfter: true),
  KeyStep(6, '4'),
  KeyStep(7, '0'),
];

/// The keystrokes for the German car plate demo: types the district ("DA")
/// and identifier letter ("X", slot 2 — deCar only has a single identifier-
/// letter slot, so a 2-letter entry like "SS" can never actually be typed
/// here; [GermanPlateValidator]'s forbidden *letter* pairs are unreachable
/// through this spec). It then types "88" into the serial digits, which
/// *is* reachable — the digits field spans four slots (3-6) — and lands on
/// one of the validator's forbidden numbers. It holds on the resulting
/// invalid (red) state long enough to read it, backs the two offending
/// digits out, then types the valid remainder so the plate finishes as
/// "DA X1953".
const List<TypistStep> germanCarScript = [
  KeyStep(0, 'D'),
  KeyStep(1, 'A', pauseAfter: true),
  KeyStep(2, 'X', pauseAfter: true),
  // Serial digits (slots 3-6): "88" reproduces a forbidden number.
  KeyStep(3, '8'),
  KeyStep(4, '8', holdAfter: Duration(milliseconds: 1200)),
  BackspaceStep(),
  BackspaceStep(pauseAfter: true),
  KeyStep(3, '1'),
  KeyStep(4, '9'),
  KeyStep(5, '5', pauseAfter: true),
  KeyStep(6, '3'),
];

/// The keystrokes for the bicycle plate: eight straight digits, no letter,
/// evenly spaced.
const List<TypistStep> bicycleScript = [
  KeyStep(0, '9', pauseAfter: true),
  KeyStep(1, '1', pauseAfter: true),
  KeyStep(2, '8', pauseAfter: true),
  KeyStep(3, '8', pauseAfter: true),
  KeyStep(4, '6', pauseAfter: true),
  KeyStep(5, '4', pauseAfter: true),
  KeyStep(6, '0', pauseAfter: true),
  KeyStep(7, '4', pauseAfter: true),
];

/// Tracks which slot the letters pad is currently showing across a [PlateTypist.run],
/// so the pad only rises or falls when the kind of slot actually changes.
/// Null means the digit pad is up.
class _LetterPadState {
  int? shown;
}

/// Auto-types a plate one slot at a time, flashing each key as it goes.
///
/// [activeKey] is the label of the key currently held down (for the laptop deck
/// or the on-screen keypad to highlight); it is null between keystrokes. Drive a
/// run with [run] and stop it early with [cancel]; every `await` inside a run is
/// guarded so a cancel (or a dispose) unwinds the walk immediately.
class PlateTypist extends ChangeNotifier {
  /// Label currently being "pressed", or null between keystrokes.
  String? activeKey;

  bool _running = false;
  bool _cancelled = true;
  bool _disposed = false;

  bool get isRunning => _running;

  /// Walks [steps] in order against [bloc], flashing each key for [flash].
  /// [spec] resolves each [KeyStep.index] to its [PlateSlot] so a letter slot
  /// (non-numeric alphabet) is detected the same way the keypad decides
  /// whether to show its letters pad, rather than by a hardcoded index/char.
  /// [controller] drives [BackspaceStep]s the same way the on-screen keypad's
  /// backspace key does.
  Future<void> run({
    required PlateCardBloc bloc,
    required PlateSpec spec,
    required PlateInputController controller,
    required List<TypistStep> steps,
    required bool useLetterPicker,
    required BuildContext context,
    Duration gap = const Duration(milliseconds: 320),
    Duration burstGap = const Duration(milliseconds: 90),
    Duration flash = const Duration(milliseconds: 140),
    ValueChanged<int?>? onSlotChanged,
  }) async {
    _cancelled = false;
    _running = true;
    // Which slot is currently reported through onSlotChanged (i.e. which
    // pad is up): null means the digit pad, a slot index means the letters
    // pad is showing that slot's alphabet. Tracked at run level so the pad
    // only rises/falls when the kind actually changes, instead of once per
    // step.
    final padState = _LetterPadState();
    for (final step in steps) {
      if (_cancelled) break;
      final keepGoing = await _runStep(
        step,
        bloc: bloc,
        spec: spec,
        controller: controller,
        useLetterPicker: useLetterPicker,
        context: context,
        gap: gap,
        burstGap: burstGap,
        flash: flash,
        onSlotChanged: onSlotChanged,
        padState: padState,
      );
      if (!keepGoing) break;
    }

    _running = false;
    activeKey = null;
    onSlotChanged?.call(null);
    _notify();
  }

  /// Runs one [step]; returns false when the run should stop (cancelled or
  /// disposed mid-step).
  Future<bool> _runStep(
    TypistStep step, {
    required PlateCardBloc bloc,
    required PlateSpec spec,
    required PlateInputController controller,
    required bool useLetterPicker,
    required BuildContext context,
    required Duration gap,
    required Duration burstGap,
    required Duration flash,
    required ValueChanged<int?>? onSlotChanged,
    required _LetterPadState padState,
  }) async {
    if (step is BackspaceStep) {
      activeKey = kBackspaceKey;
      _notify();
      if (!await _sleep(flash)) return false;

      // Keystrokes land straight on the bloc (see below), bypassing the real
      // focus chain PlateCanvas tracks its active slot through — so unless
      // something has already focused a slot, seed it before backspacing,
      // the same way re-entering the plate programmatically would.
      if (controller.activeSlot == null) controller.focusFirstEmpty();
      controller.backspace();

      activeKey = null;
      _notify();
      return _sleep(step.holdAfter ?? (step.pauseAfter ? gap : burstGap));
    }

    final keyStep = step as KeyStep;
    final slot = spec.slotAt(keyStep.index);
    final isLetterSlot =
        slot != null && !slot.alphabet.isNumeric;

    if (isLetterSlot) {
      if (useLetterPicker) {
        await _pickLetter(bloc: bloc, context: context, step: keyStep);
        if (_cancelled) return false;
        return _sleep(keyStep.holdAfter ?? gap);
      }
      if (onSlotChanged != null) {
        if (padState.shown != keyStep.index) {
          final padAlreadyUp = padState.shown != null;
          onSlotChanged(keyStep.index);
          padState.shown = keyStep.index;
          if (!padAlreadyUp) {
            if (!await _sleep(
              kLetterPadSlide + const Duration(milliseconds: 80),
            )) {
              return false;
            }
          }
        }
        controller.focusSlot(keyStep.index);
        activeKey = keyStep.char;
        _notify();
        if (!await _sleep(flash)) return false;
        bloc.add(ValueIsChanged(index: keyStep.index, value: keyStep.char));
        activeKey = null;
        _notify();
        return _sleep(keyStep.holdAfter ?? gap);
      }
    } else if (onSlotChanged != null && padState.shown != null) {
      onSlotChanged(null);
      padState.shown = null;
      if (!await _sleep(kLetterPadSlide + const Duration(milliseconds: 80))) {
        return false;
      }
    }

    // Press the key.
    controller.focusSlot(keyStep.index);
    activeKey = keyStep.char;
    _notify();
    if (!await _sleep(flash)) return false;

    bloc.add(ValueIsChanged(index: keyStep.index, value: keyStep.char));

    // Release it.
    activeKey = null;
    _notify();
    return _sleep(keyStep.holdAfter ?? (keyStep.pauseAfter ? gap : burstGap));
  }

  /// Opens the letter-picker sheet and scrolls it to the fifth entry
  /// (`PlateAlphabet.persianPlateLetters.characters[4] == 'ص'`) before committing the value.
  Future<void> _pickLetter({
    required PlateCardBloc bloc,
    required BuildContext context,
    required KeyStep step,
  }) async {
    if (!context.mounted) return;

    final scroll = FixedExtentScrollController(initialItem: 0);
    final navigator = Navigator.of(context);
    var sheetOpen = false;

    try {
      // Fire-and-forget: the sheet stays up until we pop it below.
      unawaited(
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => SafeArea(
            child: SizedBox(
              height: 216,
              child: CupertinoPicker(
                scrollController: scroll,
                itemExtent: 44,
                onSelectedItemChanged: (_) {},
                children: [
                  for (final letter in PlateAlphabet.persianPlateLetters.characters)
                    Center(
                      child: Text(letter, style: const TextStyle(fontSize: 22)),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      sheetOpen = true;

      // Let the picker mount so the controller is attached before we scroll.
      if (!await _sleep(const Duration(milliseconds: 220))) return;
      if (scroll.hasClients) {
        await scroll.animateToItem(
          4,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      if (_cancelled) return;
      if (!await _sleep(const Duration(milliseconds: 400))) return;

      if (sheetOpen && navigator.canPop()) {
        navigator.pop();
        sheetOpen = false;
      }
      bloc.add(ValueIsChanged(index: step.index, value: step.char));
    } finally {
      if (sheetOpen && navigator.canPop()) navigator.pop();
      scroll.dispose();
    }
  }

  /// Awaits [d], returning false if the run was cancelled or disposed meanwhile.
  Future<bool> _sleep(Duration d) async {
    await Future<void>.delayed(d);
    return !_cancelled && !_disposed;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Aborts an in-flight [run]; the walk unwinds at its next guarded await.
  void cancel() {
    _cancelled = true;
    _running = false;
    activeKey = null;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelled = true;
    super.dispose();
  }
}
