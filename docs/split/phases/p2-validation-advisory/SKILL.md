---
name: p2-validation-advisory
description: "Phase P2 of the plate split (second edition) — validation stops blocking input. Introduces PlateValidator/PlateValidation and an opt-in autoValidate red alert in core, and deletes the entire barred-key path (barredNextDigits, barredNextLetters, PlateKeypad.unavailableKeys, the holder's _unavailableKeysFor). Use when the user asks to run P2 or work on validation."
---

# P2 — Validation advises, it does not police

Follow `CLAUDE.md` working style. **Requires P1 committed** (it builds on
`PlateSpec.effectiveTextGroups` / `groupAt`). This project does not use automated tests: do not
write or update anything under `test/`, and do not run `flutter test`. Finish analyzer-clean in
both repos, committed; report diffstat and hashes only.

**Read `docs/split/PLAN.md` §1 before starting.** This phase inverts a design the codebase
currently commits to in three files. If you find yourself preserving the barred-key machinery
"just in case", you have misread the phase.

## The decision this phase implements

The user's words: *"we have a system for validation but we don't want it to ban the user. Only
an alert level (going red like it does now), and only if the developer turned auto validation
on. Not preventing the user from entering some keys — remove that feature."*

So:

| today | after this phase |
|---|---|
| the keypad greys out and refuses keys that would complete a forbidden value | every key in the active alphabet is tappable, always |
| the host computes a barred set per keystroke and feeds it in | the host computes nothing |
| the plate goes red because the holder subscribes to the bloc and validates by hand | the canvas goes red itself, when `autoValidate` is on |
| validation is a thing every consumer reimplements | validation is a thing core offers and a developer opts into |

**Nothing rejects a keystroke.** Not the keypad, not the canvas, not the input machine, not
the bloc. A plate can hold an invalid value; that is the point of an alert.

## What gets deleted (do this first, and let the compiler lead)

Delete these before writing the new interface. Working from a red analyzer is the reliable way
to find every call site, and the list below is what you should expect it to name — if it names
something not on this list, that is worth a line in the report.

1. `lib/validators/german_plate_validator.dart` — `barredNextDigits` (line ~136) and
   `barredNextLetters` (line ~152), including their doc comments, which explicitly describe
   the behaviour being removed ("Lets an on-screen keypad grey out or block the keys…").
2. `lib/widgets/plate_keypad.dart` — the `unavailableKeys` constructor parameter (~line 81),
   the field and its doc comment (~121-124), and the `&& !widget.unavailableKeys.contains(key)`
   clause in `_keyEnabled` (~237).
3. `plate_number_holder/lib/showcase/device_stage.dart` — `_unavailableKeysFor` in full
   (~114-148) and the `unavailableKeys:` argument at its `PlateKeypad` call site (~350).

### What must NOT be deleted along with it

- **`_keyEnabled`'s other clause.** `(widget.activeAlphabet ?? ownAlphabet).accepts(key)`
  stays. A key outside the active alphabet is disabled because `submit()` would reject it
  anyway — that is a fact about the alphabet, not a validation policy. `_Key.enabled`,
  `PlateKeypadTheme.disabledInk` and the 180 ms enabled↔disabled fade all survive on that
  path.
- **The layout invariant comment** in `_buildLettersLayer` (~266-270): "columns/rowCount are
  derived from `letterAlphabet.characters.length` only… or the pad would reflow when a
  validation rule fires." Half of it (`unavailableKeys`) no longer exists; the reasoning about
  `activeAlphabet` still does. Rewrite it, do not drop it — P4 rebuilds this grid and needs
  the invariant stated.
- **`_Key.enabled`'s doc comment** currently says "Barred by a validation rule (or outside the
  active alphabet)". After this phase only the parenthetical is true. Reword it.

## Do

### `lib/validators/plate_validator.dart` (new, core)

```dart
/// The verdict on a plate. [reason] is developer- or user-facing text
/// explaining an invalid plate; null when valid.
@immutable
class PlateValidation {
  const PlateValidation.valid() : reason = null;
  const PlateValidation.invalid(String this.reason);
  final String? reason;
  bool get isValid => reason == null;
}

/// Everything a validator needs about a plate as it stands.
@immutable
class PlateEntry {
  const PlateEntry({required this.spec, required this.values, this.activeIndex});
  final PlateSpec spec;
  final List<String?> values;

  /// The slot the user is on, when a host tracks one. A validator MUST NOT
  /// use this to decide what may be typed next — it exists so a verdict can
  /// name the offending group, and so a validator can stay quiet about a
  /// group the user has not reached yet.
  final int? activeIndex;

  /// Canonical value of the group with [key], or '' if no group has it.
  String group(String key);

  /// The group containing [activeIndex], or null.
  PlateTextGroup? get activeGroup;
}

/// A rule about whether a plate's value is acceptable.
///
/// A validator NEVER prevents input. It is asked a question and answers it;
/// what a host does with the answer — paint the frame red, enable a submit
/// button, do nothing — is the host's decision. There is deliberately no
/// "which keys are barred" method: see docs/split/PLAN.md §1.
abstract class PlateValidator {
  const PlateValidator();
  PlateValidation validate(PlateEntry entry);
}
```

1. Build `group` and `activeGroup` on P1's `PlateSpec.valueOfGroup` and `groupAt`. They should
   be two or three lines each — if either is growing a walk of its own, P1 left something in
   the widget.
2. **There is no `barredNext`, no `completionsOf` and no `ForbiddenByGroup` mixin.** The first
   edition's P7 specified all three. They existed only to serve per-keystroke barring. Do not
   port them, and do not add an "advisory" version — the user asked for the feature removed,
   not renamed.
3. `PlateEntry` has no `activePrefix`. That getter existed solely to feed the barred-key walk.

### `lib/validators/german_plate_validator.dart`

4. `GermanPlateValidator extends PlateValidator`, `const`-constructible, with a
   `const GermanPlateValidator()` public constructor replacing the private `._()`.
5. `validate(PlateEntry entry)` is the override. It keeps every current check — the three
   regexes, the 8-character cap, the forbidden letter pairs, the forbidden numbers — reading
   groups via `entry.group('district' | 'letters' | 'serial')`.
6. **Keep the "empty letters group is valid" early return** (`validateValues`, line 65). An
   in-progress plate must not be flagged before it is filled in. That rule matters more now,
   not less: with nothing barring input, the red state is the *only* feedback, and a plate that
   flashes red on its first character is worse than no validation.
7. Keep the standalone
   `static validate({required district, required identifierLetters, required identifierDigits})`
   — it is genuinely useful without a spec. The instance `validate(PlateEntry)` delegates to it.
   Rename one of the two if the overload reads badly; say which in the report.
8. `GermanPlateValidationResult` collapses into `PlateValidation`. Keep
   `typedef GermanPlateValidationResult = PlateValidation;` for one release and note it in
   `CHANGELOG.md`. Note there too that `barredNextDigits`/`barredNextLetters` are **removed**,
   with one sentence on why — a consumer who used them deserves to know it was deliberate.
9. **Resolve the `docs/forbidden.json` duplication in this same commit.** That file holds this
   exact data — same letter pairs, same numbers, same FZV §8 rationale in its `_comment` — and
   nothing in `lib/` reads it. Two places to update, one of which is a lie waiting to happen.
   Either transcribe the Dart consts from the JSON and say in their doc comment that the JSON
   is the source of truth, or `git rm docs/forbidden.json` and say in the commit message that
   the Dart consts always were. Pick one, state it, do not leave both.

   The keep-this caveat in the library doc comment — "NOT an exhaustive reproduction of every
   municipality's local ban list… treat a `true` result as *not obviously forbidden*, not as an
   official registration guarantee" — is the most important text in the file. It survives
   whatever you do to the data.

### Wire it through core

10. `PlateCanvas` gains two parameters:

```dart
/// The rule this plate is judged against. Never prevents input; see
/// [autoValidate] for when it is consulted.
final PlateValidator? validator;

/// When true, the canvas validates after every committed value and paints
/// the invalid state itself. When false (the default), [validator] is
/// consulted only when the host asks — read
/// [PlateInputController.validation] and decide your own timing.
final bool autoValidate;
```

    Default `autoValidate: false`. A canvas with a validator and `autoValidate: false` must
    never call `validate` on its own — a developer who wants to validate on submit only should
    not pay for a validation per keystroke, and should not see red before they asked for it.

11. **The alert.** With `autoValidate: true` and an invalid entry, the canvas paints the same
    red it paints today under the holder's control — the frame/underline colour, nothing more.
    No dialog, no snackbar, no shake, no exception, no rejected value. Find how the holder
    currently colours it (`device_stage.dart` ~314 passes the invalid state down) and move that
    styling decision into the canvas, reading the colour from `PlateTheme` rather than a
    literal. If `PlateTheme` has no slot for it, add one — an alert colour is theme data.

12. `PlateInputController` exposes `PlateValidation? get validation`, derived from the attached
    machine's entry and notifying on change. Null when no validator is set.

    **Notify on a change of verdict, not on every value change.** The performance pass
    deliberately narrowed the holder so `setState` fires only when `isValid` flips; whatever
    replaces it must keep that property, and putting the debounce in the controller is how it
    stays true for every consumer instead of just this one. `PlateValidation` has no `==`
    today — either give it one (over `reason`) or compare `isValid` explicitly and say which.

13. **Do not add a validator dependency to the bloc or the input machine.** The machine takes a
    read callback and a commit callback and has no opinion about validity; keeping it that way
    is what makes the bloc decision in `PLAN.md` §6.5 a one-file decision later.

### `plate_number_holder`

14. Delete `_unavailableKeysFor` (see above) and drop the `unavailableKeys:` argument.
15. `_germanValidation`, `_validateGermanPlate`, `_blocSub` and `_subscribeToBloc` collapse
    into reading `_plateInput.validation`. `PlateInputController` is a `ChangeNotifier`, so the
    `StreamSubscription<PlateCardState>` and its re-subscribe-on-device-swap dance go with
    them. Keep `DemoConfig.showsValidation` gating — it now maps onto `autoValidate`.
16. Add `final PlateValidator? validator;` to `DemoConfig` and pass
    `validator: const GermanPlateValidator(), autoValidate: config.showsValidation` from there.
    Variation as data (`claude.md` §2), not a `device == tablet` branch.
17. **Keep the scoped rebuilds.** The full keypad sits under a
    `BlocBuilder<PlateCardBloc, PlateCardState>` scoped to itself. With `unavailableKeys` gone,
    check whether that `BlocBuilder` still has a reason to exist — it was there because the
    barred set tracked the typed value. If nothing inside it depends on state any more, remove
    it; if something does, leave it exactly where it is. **What you may not do is hoist a
    rebuild up to the stage.** Say in the report which way it went and why.

## The auto-typist tension is now resolved, not preserved

`device_stage.dart` carries a comment explaining a deliberate contradiction: the scripted
typist commits `88` while the interactive keypad greys the second `8` out. That contradiction
existed because barring was a keypad-level policy the typist bypassed. **It is gone.** Delete
the comment rather than updating it, and replace it with one line noting that the demo now
types a forbidden value and the plate goes red — which is the behaviour being demonstrated.

## Widgets, not widget functions

Per `PLAN.md` §5, in the files this phase already edits — here that is the holder's
`device_stage.dart`, whose `_buildDevice` is a ~40-line widget function this phase reaches
into. Convert it to a `_DeviceBody` class **if** it comes out at a similar length; it closes
over a lot of stage state, so if hoisting those into constructor fields balloons the file,
leave it and say so. Do not let this hold up the validation work, which is the phase.

## Verify

```
cd plate-core            && flutter analyze
cd ../plate_number_holder && flutter analyze
```

(Do not run `flutter test`.)

Then run the tablet demo and check the new behaviour explicitly — this is the phase where
"looks the same" is the wrong result:

1. The auto-typist's German sequence `DA` → `X` → `88` still turns the plate **red**.
2. Type the second `8` **by hand on the keypad**. It must be tappable and it must land. Before
   this phase it was greyed out and inert. This is the acceptance test for the whole phase.
3. Backspace clears the red.
4. `1953` finishes clean.
5. On the phone and the bicycle devices (`showsValidation: false`), nothing ever goes red and
   no validator is constructed.
6. Grep both repos: `grep -rn "unavailableKeys\|barredNext" .` must return nothing outside
   `CHANGELOG.md` and `docs/`.

Expected: ~45 lines out of `lib/`, ~45 out of the holder, one keystroke that used to be
impossible now possible, and validation reduced to a question with an answer.
