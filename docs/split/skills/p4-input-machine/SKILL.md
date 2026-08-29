---
name: p4-input-machine
description: "Refactor phase P4 of the plate_number split — extract focus-node lifecycle, active-slot tracking and navigation out of _PlateCanvasState into a testable PlateInputMachine, and fix the confirmed live bug where PlateCanvas silently reuses focus/controller state across incompatible specs on every device-cycle transition. Use when the user asks to run P4 or work on the input machine."
---

# P4 — Extract the input machine

Follow `CLAUDE.md` working style. Requires **P3** committed. Finish analyzer-clean, tests
green, committed; report diffstat and hashes only.

**This phase removes almost no lines, and it is the most important phase in the plan anyway.**
It carries a fix for a confirmed live bug — not a theoretical one, a bug the current showcase
app hits on every device-cycle transition it runs. Do not judge this phase by diffstat, and do
not let it slip to "whenever there's time." Read the reproduction steps below before touching
any code, so you know what broken looks like before you fix it.

## Why

`_PlateCanvasState` does five unrelated jobs:

1. `FocusNode` / `TextEditingController` lifecycle, one pair per slot
2. active-index tracking and change notification
3. navigation — `_advance`, `backspaceCharacter`, `focusFirstEmptySlot`, `focusSlot`
4. picker presentation
5. painting the plate

(1)–(3) are a pure state machine with no pixels in it, reachable today only through
`pumpWidget`. There is not one unit test of backspace-steps-back-across-a-slot-boundary,
because there is no way to write one.

It also forces two API apologies that this phase removes:
`PlateInputTarget`'s "Implemented by PlateCanvas's State. Not for app code to implement", and
the identity guard in `PlateInputController.detach` that exists because a rebuilt canvas
attaches its new State before the old one disposes.

### The bug, confirmed

`_focusNodes`/`_controllers` (a `List<FocusNode>` / `List<TextEditingController?>` after P1)
are built exactly once, in `initState`, from `widget.spec.slots`. `didUpdateWidget` reacts only
to `widget.controller` changing — never to `widget.spec` changing. That is only safe if
Flutter gives `PlateCanvas` a fresh `State` whenever its spec changes.

It does not, in `plate_number_holder`. Checked, not assumed:

```bash
grep -rn "key:\|Key(\|ValueKey\|GlobalKey" \
  plate_number_holder/lib/device_preview/device_frame.dart \
  plate_number_holder/lib/widgets/plate_display.dart \
  plate_number_holder/lib/showcase/device_stage.dart
```

Zero matches on any `Key`. `DeviceFrame`'s content cross-fades through a plain `Opacity`
wrapper around `builder: widget.builder` (`device_frame.dart:418-463`) — no
`AnimatedSwitcher`, no `IndexedStack`, nothing that forces the subtree to be discarded and
rebuilt. `PlateCanvas` sits at the same type, same position in the tree, on every device hop.
Flutter's default reconciliation therefore **reuses the same `_PlateCanvasState`** while
`device_stage.dart._onContentSwap` swaps `spec:` underneath it — `irCar` (8 slots) → `deCar`
(7 slots) → `irBicycle` (8 slots) → back to `irCar`, cycling forever, in the app you can run
today.

**Reproduce it before you fix it**, so you can tell the fix worked:

1. Run `plate_number_holder` on the unmodified (pre-P4) tree.
2. Let it cycle desktop (`irCar`) → tablet (`deCar`) at least once — the transition that goes
   from 8 slots to 7.
3. Add a temporary `debugPrint` in `_PlateCanvasState.initState()` and confirm — it will only
   print **once**, on the very first plate shown, never again on subsequent device swaps. That
   single `debugPrint` firing exactly once across a run that shows three different specs is the
   whole bug in one observation: one `State`, three specs.
4. Note whatever symptom you can see with your own eyes at that transition — a focus node that
   doesn't seem to track the right slot, a keypad that shows the wrong pad briefly, or nothing
   visibly wrong at all (this bug can be silently harmless depending on which two specs happen
   to sit adjacent to which — that is not the same as it being safe). Write down what you saw;
   you'll compare against it after the fix.

This is corrected from an earlier version of this plan, which claimed the holder "recreates
the whole subtree on device swap" and therefore never hits this. That claim was checked here
and found to be false — leaving it uncorrected would have left this phase looking optional. It
is not optional.

## Do

### `lib/input/plate_input_machine.dart` (new)

```dart
/// Owns focus and navigation for one plate. Knows the spec and the focus
/// nodes; knows nothing about pixels, and nothing about bloc.
///
/// Values reach it through [readValues] and leave through [commit], so the
/// machine is independent of how the host stores plate state. That is what
/// makes it unit-testable, and it is why swapping [PlateCardBloc] for
/// something else later would not touch this file.
class PlateInputMachine implements PlateInputTarget {
  PlateInputMachine({
    required this.spec,
    required this.readValues,
    required this.commit,
    this.onActiveIndexChanged,
  }) { … }

  final PlateSpec spec;
  final List<String?> Function() readValues;
  final void Function(int index, String value) commit;
  final ValueChanged<int?>? onActiveIndexChanged;

  FocusNode focusNodeAt(int index);
  TextEditingController? controllerAt(int index);   // null for chosen slots

  int? get activeIndex;

  /// Fired when a chosen slot under [SlotBehavior.sheet] is reached by
  /// [advance]. The canvas sets this; the machine never presents UI.
  ValueChanged<int>? onSheetRequested;

  void advanceFrom(int index);
  void syncControllers(List<String?> values);
  void dispose();

  // PlateInputTarget
  @override void submitCharacter(String c);
  @override void backspaceCharacter();
  @override void focusFirstEmptySlot();
  @override void focusSlot(int index);
}
```

Port the bodies from `_PlateCanvasState` verbatim — this is a move, not a rewrite. The two
translations to make:

- Every `context.read<PlateCardBloc>().state.plateNumber.values` becomes `readValues()`.
- Every `bloc.add(ValueIsChanged(index: i, value: v))` becomes `commit(i, v)`.

`_openPicker` stays in the canvas (it needs a `BuildContext` and `showModalBottomSheet`); the
machine signals it through `onSheetRequested`.

`syncControllers` is the loop currently at the top of `PlateCanvas.build` that pushes bloc
values into the `TextEditingController`s. It belongs with the controllers it owns.

### `lib/widgets/plate_canvas.dart`

1. `_PlateCanvasState` keeps: creating and disposing the machine, attaching/detaching
   `widget.controller`, `_openPicker`, and `build`.
2. `initState` constructs the machine with
   `readValues: () => context.read<PlateCardBloc>().state.plateNumber.values` and
   `commit: (i, v) => context.read<PlateCardBloc>().add(ValueIsChanged(index: i, value: v))`.
   Keep the existing post-frame seeding of the first active slot, with its comment — it
   documents a real ordering bug.
3. `didUpdateWidget` must rebuild the machine when `widget.spec` changes identity, not only
   when the controller does — this is the fix for the confirmed bug above. Compare
   `widget.spec.id` against `oldWidget.spec.id` (not `==` on the spec itself — `PlateSpec`
   equality is intentionally `id`-based, so this is the same check either way, but write it as
   `.id` so the intent reads plainly): on change, dispose the old machine's focus nodes and
   controllers and construct a fresh `PlateInputMachine` for the new spec, exactly as
   `initState` does. Also reset `_activeIndex`-adjacent state the same way a fresh mount would
   — a slot index valid in the old spec may not exist, or may mean something different, in the
   new one.
4. `build` reduces to: resolve theme, `machine.syncControllers(values)`, and the widget tree.

### `lib/input/plate_input_controller.dart`

5. `PlateInputTarget`'s "not for app code" caveat can go — a `PlateInputMachine` is a normal
   object a host could legitimately hold.
6. Keep the identity guard in `detach`. It is still correct for spec swaps.

### Tests

7. New `test/plate_input_machine_test.dart`, no `pumpWidget`. At minimum:
   - `submitCharacter` rejects a character the active alphabet does not accept
   - `advanceFrom` on the last slot unfocuses rather than wrapping
   - backspace on a filled slot clears it in place
   - backspace on an empty slot clears the **previous** slot and moves focus there
   - backspace on the first slot when empty is a no-op
   - `focusFirstEmptySlot` on a full plate falls back to slot 0

   The fourth and fifth cases have never been tested. Verify them against the current
   behaviour before you trust your port.

## Verify

```
cd plate-number-upgrade   && flutter analyze && flutter test
cd ../plate_number_holder && flutter analyze && flutter test
```

Then confirm the bug fix specifically, not just that nothing crashed:

1. Re-run the same `debugPrint` in `_PlateCanvasState.initState()` (or wherever the fresh
   machine gets constructed after your change) through a full device cycle. It must now fire
   **once per device swap**, not once total — that is the fix, made visible.
2. Cycle all three devices twice, including the auto-typist's German "88 → backspace → 1953"
   sequence, which exercises backspace-across-boundary and the controller path together.
3. Watch specifically the desktop→tablet transition (8 slots → 7) and the tablet→mobile
   transition (7 slots → 8, but a different alphabet pattern than desktop's 8) — the two
   places a stale focus/controller list would have been most likely to show something wrong.
4. Remove the temporary `debugPrint` before committing.

Expected: ~0 net lines. A new file, a smaller `plate_canvas.dart`, six tests that could not
previously exist, and one bug that was live in the shipped showcase now fixed and verified
fixed — not just refactored around.
