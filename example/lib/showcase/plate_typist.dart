import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plate_number/plate_number.dart';

import 'virtual_keypad.dart' show kLetterPadSlide;

/// One keystroke: which slot, what char, and whether to pause afterwards.
///
/// `pauseAfter: true` marks a natural break (a burst just finished, or a
/// letter was just entered) — the typist waits the slower [PlateTypist.gap]
/// there. Everywhere else it waits the quick [PlateTypist.burstGap], so a
/// run reads as bursts of digits rather than one evenly-spaced drip.
typedef Keystroke = (int index, String char, bool pauseAfter);

/// The keystrokes for the car plate ("91-ه-886-40"): '9' and '1' typed as a
/// quick burst, a pause, the letter, another pause, then '886' and '40' as
/// two more quick bursts.
const List<Keystroke> carScript = [
  (0, '9', false),
  (1, '1', true),
  (2, 'ه', true),
  (3, '8', false),
  (4, '8', false),
  (5, '6', true),
  (6, '4', false),
  (7, '0', false),
];

/// The keystrokes for the German car plate ("DA X1953"): the two district
/// letters, then the identifier's letter and its four serial digits, evenly
/// spaced.
const List<Keystroke> germanCarScript = [
  (0, 'D', true),
  (1, 'A', true),
  (2, 'X', true),
  (3, '1', true),
  (4, '9', true),
  (5, '5', true),
  (6, '3', true),
];

/// The keystrokes for the bicycle plate: eight straight digits, no letter,
/// evenly spaced.
const List<Keystroke> bicycleScript = [
  (0, '9', true),
  (1, '1', true),
  (2, '8', true),
  (3, '8', true),
  (4, '6', true),
  (5, '4', true),
  (6, '0', true),
  (7, '4', true),
];

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
  /// After a key, pauses [gap] if its step is marked `pauseAfter`, otherwise
  /// the quicker [burstGap] — so consecutive digits within a burst land fast
  /// and only natural breaks (before/after the letter, between groups) wait.
  /// When [useLetterPicker] is true the letter slot (index 2, 'ص') is entered
  /// through the modal picker instead of a flash.
  Future<void> run({
    required PlateCardBloc bloc,
    required List<Keystroke> steps,
    required bool useLetterPicker,
    required BuildContext context,
    Duration gap = const Duration(milliseconds: 320),
    Duration burstGap = const Duration(milliseconds: 90),
    Duration flash = const Duration(milliseconds: 140),
    ValueChanged<int?>? onSlotChanged,
  }) async {
    _cancelled = false;
    _running = true;
    for (final (index, char, pauseAfter) in steps) {
      if (_cancelled) break;

      if (index == 2 && char == 'ص') {
        if (useLetterPicker) {
          await _pickLetter(bloc: bloc, context: context, char: char);
          if (_cancelled) break;
          if (!await _sleep(gap)) break;
          continue;
        }
        if (onSlotChanged != null) {
          onSlotChanged(2);
          if (!await _sleep(kLetterPadSlide + const Duration(milliseconds: 80))) {
            onSlotChanged(null);
            break;
          }
          activeKey = char;
          _notify();
          if (!await _sleep(flash)) {
            onSlotChanged(null);
            break;
          }
          bloc.add(ValueIsChanged(index: index, value: char));
          activeKey = null;
          _notify();
          onSlotChanged(null);
          if (!await _sleep(gap)) break;
          continue;
        }
      }

      // Press the key.
      activeKey = char;
      _notify();
      if (!await _sleep(flash)) break;

      bloc.add(ValueIsChanged(index: index, value: char));

      // Release it.
      activeKey = null;
      _notify();
      if (!await _sleep(pauseAfter ? gap : burstGap)) break;
    }

    _running = false;
    activeKey = null;
    _notify();
  }

  /// Opens the letter-picker sheet and scrolls it to the fifth entry
  /// (`persianCarPlateLetters[4] == 'ص'`) before committing the value.
  Future<void> _pickLetter({
    required PlateCardBloc bloc,
    required BuildContext context,
    required String char,
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
                  for (final letter in persianCarPlateLetters)
                    Center(child: Text(letter, style: const TextStyle(fontSize: 22))),
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
      bloc.add(ValueIsChanged(index: 2, value: char));
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
