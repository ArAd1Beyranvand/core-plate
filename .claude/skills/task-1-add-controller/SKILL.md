---
name: task-1-add-controller
description: "PlateController refactor — Stage 1 of 7: add value-owning PlateController extends PlateInputController plus PlateSelector to core_plate, exported but wired to nothing. Invoke when the user runs /task for stage 1, or asks to start the core_plate controller refactor."
---

# Stage 1 — add the controller

**Recommended model: Opus 5, medium reasoning, thinking ON.**
The `adoptSpec` / `byGroupKey` migration algorithm is subtle and must match an existing
reference implementation exactly; get it wrong and every later stage inherits the bug.

Run the prompt below in a fresh session. This is stage 1 of 7 (`task-1-add-controller`
… `task-7-merge-controllers`). Do the acceptance check and commit before stopping.
Next: `task-2-canvas-owns-controller`.

---

Repo: /home/aradbeyranvand/StudioProjects/plate — a Dart/Flutter workspace of sibling
packages. You are working in `core_plate` only.

Read core_plate/CLAUDE.md and follow it, with one exception: it says "don't survey the
repo before editing". Read the files named below in full before editing — they are named
in this task, so that rule is satisfied. Do NOT create or edit anything under any
`test/` directory and do not run `flutter test`; this project has no automated tests.

CONTEXT
core_plate's PlateCanvas keeps the plate's characters in a `PlateCardBloc` that the host
must provide above it in the tree, and its `PlateInputController` explicitly owns no value
state ("The controller keeps no plate state of its own"). We are introducing a
value-owning `PlateController` as the primary host-facing API, over several stages. This
is stage 1 of 7: add the new types and export them. Wire NOTHING. Nothing in the package
may change behaviour, and PlateCanvas must not be touched at all.

FILES YOU MAY TOUCH — and no others
  core_plate/lib/src/input/plate_controller.dart   (new)
  core_plate/lib/src/widgets/plate_selector.dart   (new)
  core_plate/lib/core_plate.dart                   (exports only)

READ FIRST (do not edit)
  core_plate/lib/src/input/plate_input_controller.dart
  core_plate/lib/src/input/plate_input_machine.dart
  core_plate/lib/src/model/plate_spec.dart
  core_plate/lib/src/model/plate_number.dart
  core_plate/lib/src/model/plate_alphabet.dart

WHAT TO BUILD

1. `enum PlateValuePreservation { none, byIndex, byGroupKey }` in plate_controller.dart.

2. `class PlateController extends PlateInputController`. It subclasses the existing
   controller deliberately: every host today passes a `PlateInputController` to
   `PlateCanvas.controller`, and subclassing means those call sites keep compiling while
   new hosts pass the richer type. Do not rename or change PlateInputController.

   Constructors:
     PlateController({required PlateSpec spec, List<String?>? values})
     factory PlateController.fromValues(PlateSpec spec, List<String?> values)
     factory PlateController.fromText(PlateSpec spec, String text)
   `fromText` assigns one character per slot in index order, skipping characters the
   slot's alphabet refuses (`PlateAlphabet.accepts`).

   Surface:
     PlateSpec get spec;
     void adoptSpec(PlateSpec next, {PlateValuePreservation preserve = PlateValuePreservation.byGroupKey});
     List<String?> get values;            // unmodifiable, always spec.slotCount long
     String? valueAt(int index);          // null when out of range
     void setAt(int index, String? value);// '' or null clears; refused chars are a no-op
     void setValues(List<String?> values);// one notification, not one per slot
     void clear();
     String text({String sep = ' '});     // spec.renderGroup over spec.effectiveTextGroups
     String group(String key);            // canonical chars — reuse spec.valueOfGroup
     void setGroup(String key, String value);
     bool get isCompleted;
     bool get isEmpty;
     PlateNumber get plateNumber;
     ValueListenable<String?> slot(int index);
     ValueListenable<bool> completed;
     @override void dispose();

3. Narrowing, which is the point of the whole exercise — implement it exactly like this:
   the controller keeps a private `List<ValueNotifier<String?>> _slots` (one per slot,
   built from `spec.slotCount`) and a private `ValueNotifier<bool> _completed`.
   `setAt` writes `_values[i]`, then `_slots[i].value = v`, then `_completed.value = …`
   (ValueNotifier swallows an equal write, so completion only notifies on a real flip),
   then `notifyListeners()` for whole-controller listeners. `slot(i)` returns
   `_slots[i]`. Out-of-range `slot(i)` must return a const always-null listenable rather
   than throwing. `dispose()` disposes every notifier, then `super.dispose()`.

4. `adoptSpec` semantics. Build the new value list per `preserve`:
   - none      → all null.
   - byIndex   → old[i] → new[i] while both exist; drop any character the incoming slot's
                 alphabet refuses.
   - byGroupKey→ match `PlateTextGroup.key` between `old.effectiveTextGroups` and
                 `next.effectiveTextGroups`. Within a matched pair copy positionally,
                 source characters in group order with unset slots skipped, stopping at
                 the shorter group. A target slot whose alphabet holds exactly ONE
                 character is filled from the alphabet (it is a printed constant, not
                 input). A character the target alphabet refuses is cleared, never forced.
                 If neither spec declares keyed groups, fall back to byIndex.
     `plate_number_holder/lib/showcase/plate_mirror.dart` implements exactly this
     algorithm for the cross-spec case — READ IT and match its rules; do not invent a
     second set. Do not import it (wrong package, and it is app code); reimplement in
     core against PlateSpec/PlateTextGroup/PlateAlphabet only.
   Then re-found `_slots` for the new spec's length, seed each notifier with the migrated
   value, update `_completed`, and `notifyListeners()` ONCE.

5. `PlateSelector<T>` in plate_selector.dart: a StatefulWidget taking
   `{PlateController controller, T Function(PlateController) selector,
   Widget Function(BuildContext, T) builder}`. It listens to the controller, holds the
   last selected value in State, and `setState`s only when the newly selected value is
   `!=` the held one. Handle a swapped controller in `didUpdateWidget` (remove the old
   listener, add the new, re-select). Never run `selector` after dispose. This exists for
   the ONE subscription that is genuinely derived (the validation verdict); per-slot
   subscriptions use `slot(i)` with a plain ValueListenableBuilder and need no diffing.

6. In core_plate.dart, export both new files under the existing "Input" section, with a
   doc comment saying PlateController is the value-owning primary API and that
   PlateInputController remains for focus-only hosts. Do not change any other export.

CONSTRAINTS
- No country name may appear anywhere in core_plate — not even in a comment. This is a
  standing invariant of the package; see the doc comment at the top of core_plate.dart.
- Do not add a dependency. Do not touch pubspec.yaml.
- Do not touch plate_canvas.dart, plate_input_machine.dart, plate_input_controller.dart,
  or anything under src/bloc/.

ACCEPTANCE CHECK
- `flutter analyze` clean in core_plate AND in every sibling package: iran_plate,
  germany_plate, palestine_plate, yemen_plate, plate_keypad, plate_number_holder, and
  each package's example/ app.
- `flutter run` still works unchanged for core_plate/example and iran_plate/example.
- `git diff` shows two new files and export lines only.
Finish with analyzer clean + a git commit, per CLAUDE.md.
