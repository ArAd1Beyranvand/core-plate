import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plate_number/car_plate/index.dart';

/// The keystrokes for the car plate: two digits, the letter, then the serial
/// and province digits. `(index, char)` maps a plate slot to the value typed.
const List<(int, String)> carScript = [
  (0, '1'),
  (1, '2'),
  (2, 'ص'),
  (3, '3'),
  (4, '4'),
  (5, '5'),
  (6, '6'),
  (7, '7'),
];

/// The keystrokes for the bicycle plate: eight straight digits, no letter.
const List<(int, String)> bicycleScript = [
  (0, '1'),
  (1, '2'),
  (2, '3'),
  (3, '4'),
  (4, '5'),
  (5, '6'),
  (6, '7'),
  (7, '8'),
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

  /// Walks [steps] in order against [bloc], flashing each key for [flash] and
  /// pausing [gap] between them. When [useLetterPicker] is true the letter slot
  /// (index 2, 'ص') is entered through the modal picker instead of a flash.
  Future<void> run({
    required PlateCardBloc bloc,
    required List<(int index, String char)> steps,
    required bool useLetterPicker,
    required BuildContext context,
    Duration gap = const Duration(milliseconds: 320),
    Duration flash = const Duration(milliseconds: 140),
  }) async {
    _cancelled = false;
    _running = true;
    for (final (index, char) in steps) {
      if (_cancelled) break;

      if (useLetterPicker && index == 2 && char == 'ص') {
        await _pickLetter(bloc: bloc, context: context, char: char);
        if (_cancelled) break;
        if (!await _sleep(gap)) break;
        continue;
      }

      // Press the key.
      activeKey = char;
      _notify();
      if (!await _sleep(flash)) break;

      bloc.add(ValueIsChanged(index: index, value: char));

      // Release it.
      activeKey = null;
      _notify();
      if (!await _sleep(gap)) break;
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
