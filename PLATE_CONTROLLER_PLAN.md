# core_plate — value-owning `PlateController`

Survey + refactor plan. No code written, nothing committed.

Workspace: `/home/aradbeyranvand/StudioProjects/plate`
Packages: `core_plate`, `iran_plate`, `germany_plate`, `palestine_plate`, `yemen_plate`, `plate_keypad`, `plate_number_holder` (app), plus six example apps.

---

## 1. Findings

### 1.1 The four claims

**Claim 1 — PlateCanvas hard-requires a `BlocProvider<PlateCardBloc>`. CONFIRMED.**

`plate_canvas.dart:21-26` says it in the doc comment, and five separate sites make it true at runtime:

| line | call |
|---|---|
| 96 | `context.read<PlateCardBloc>().add(SpecIsChanged(...))` in `didUpdateWidget` |
| 125-127 | `context.read<PlateCardBloc>()` inside the `readValues` / `commit` closures |
| 166 | `context.read<PlateCardBloc>()` in `_probeValidation` |
| 190 | `context.read<PlateCardBloc>()` in `_openPicker` |
| 402, 480, 516, 526, 561 | `BlocSelector` / `context.select` / `context.read` in the four bindings |

`flutter_bloc: ^9.1.1` and `bloc: ^9.2.1` are hard `dependencies` in `core_plate/pubspec.yaml:13-14`. The cost is visible in consumers: `palestine_plate/pubspec.yaml:22-25` carries `flutter_bloc` as a **dev-dependency with an apology comment** solely so its golden tests can wrap `ShowPlate` in a provider. That package's own `lib/` needs no bloc at all.

**Claim 2 — two controller-ish objects, neither owns value state. CONFIRMED, and it is actually three.**

- `PlateInputController` (`plate_input_controller.dart:26`) — doc comment line 24: *"The controller keeps no plate state of its own."* Public surface is `activeIndex`, `activeSlotIn(spec)`, `isAttached`, `validation`, `submit`, `backspace`, `focusFirstEmpty`, `focusSlot`, plus four `attach`/`detach`/`installValidation`/`reportValidation` methods explicitly documented "Do not call from app code". No `.text`, no `.values`, no `.setGroup`.
- `PlateInputMachine` (`plate_input_machine.dart:139`) — owns focus nodes and `TextEditingController`s, reads/writes values only through injected closures.
- `PlateCardBloc` — owns the values.

So a host holds a bloc **and** a `PlateInputController` and keeps them consistent by hand. `plate_number_holder/lib/showcase/device_stage.dart` is the proof: it holds `_bloc` (line 65), `_secondaryBloc` (71), a `StreamSubscription<PlateCardState> _mirror` (75) and `_plateInput` (126), and manually re-creates and re-wires all four on every device swap (`_onContentSwap`, line 197-203). `PlateTypist.run` takes `bloc:` *and* `controller:` as separate required parameters (`plate_typist.dart:157-159`) and uses the bloc for character commits and the controller for backspace/focus — a single object would collapse that signature.

**Claim 3 — the decoupling seam already exists. CONFIRMED, and it is clean.**

`PlateInputMachine` imports no bloc (`plate_input_machine.dart:118-125`), and its doc comment (131-134) states the intent outright: *"swapping `PlateCardBloc` for something else later would not touch this file."* All value access is `readValues()` / `commit(i, v)`. Nothing in the machine needs to change in this refactor except its constructor arguments' provenance.

**Claim 4a — spec swap wipes the plate. CONFIRMED.**

`plate_card_bloc.dart:26-28`: `on<SpecIsChanged>` emits `PlateCardState.empty(event.spec)` unconditionally. `plate_canvas.dart:90-100` dispatches it whenever `spec.id` changes. Four consumer docs already carry the warning as a documented limitation:

- `yemen_plate/lib/src/northern_plates.dart:1108-1109` — "Pick the two lengths before entry begins. Swapping `spec:` on a live `PlateCanvas` resets the bloc"
- `yemen_plate/lib/src/unified_plates.dart:29-30`, `:864`
- `palestine_plate/lib/src/west_bank_plates.dart:217`, `:251-252`
- `palestine_plate/example/lib/main.dart:180-193` — a 14-line comment block, then a **post-frame re-seed workaround** (`_switchTo`, lines 195-221) that replays the old values positionally one `ValueIsChanged` at a time, after the frame in which core empties them.

**Claim 4b — `_installMachine` captures `BuildContext` in long-lived closures. CONFIRMED.**

`plate_canvas.dart:125-128`. Both closures outlive the build that created them and are invoked from focus callbacks and host keypad taps. It has not bitten yet because the element stays mounted for the machine's life, but it is a use-after-dispose waiting for the first host that keeps a `PlateInputController` alive across a canvas teardown.

### 1.2 What the brief got wrong

**The `PlateMirror` workstream is not concurrent — it has already landed in the working tree.** `plate_spec.dart` (mtime the most recent in the package) declares `PlateMirror` at line 31 and `PlateSpec.mirrors` at line 168; `debugValidateSpec` walks mirrors at lines 274-290 and folds their alphabets into the content-key check at 303-307. `plate_canvas.dart` renders them at lines 306-315 and defines `_MirrorBinding` at line 546 — already `context.select`-narrowed to one value, with the canvas's big NOTE comment (lines 235-249) rewritten to mention mirrors. So there is no collision risk to manage: `_MirrorBinding` is an existing call site in the inventory below, and it gets the same selector treatment as `_SlotBinding` in the same stage. **Re-verify this before executing stage 3** — if the workstream is still mid-flight on another branch, the only impact is that stage 3's file list gains a fourth binding, which it already accounts for.

### 1.3 Blast radius the brief did not name

- **`ShowPlate` and `PlateText`** (`show_plate.dart`) are two more *public, bloc-only* widgets. Both are `BlocBuilder<PlateCardBloc, PlateCardState>` with no controller path at all, and both read `state.spec` — so the bloc is the source of truth for the spec too, not just the values. Any "core_plate has zero bloc dependency" endgame must relocate or re-found both. `palestine_plate`'s golden tests render through `ShowPlate`; `yemen_plate/lib/yemen_plate.dart:27` and `palestine_plate` docs point users at it.
- **`PlateText` has a latent range bug**: `show_plate.dart` indexes `values[i]` for every group index with no bounds check, while `renderGroup` (`plate_spec.dart:216`) does guard. A spec whose group indices outrun the bloc's current value list — exactly the mid-swap window — throws. Worth fixing in the same stage that fixes spec swap.
- **`_SlotBinding.build` mutates during build**: line 524 calls `machine.syncController(index, value)`, which writes `TextEditingController.value` from inside `build`. It is correct today only because it runs before that slot's own `TextField` builds in the same frame (the comment at 521-523 says so). This survives the refactor unchanged, but it is a constraint on where the new selector widget may sit — the sync must stay *above* the `PlateSlotItem`, not inside a nested builder.
- **`mirrorByGroup` already exists**, in `plate_number_holder/lib/showcase/plate_mirror.dart:71`. It rewrites one spec's values into another's **by group key**, handles one-character alphabets as constants, drops characters the target alphabet refuses, and truncates at the shorter group. That is precisely the `adoptSpec(preserve:)` algorithm the brief asks for, already written, already exercised on two real spec pairs. Core should absorb the identity-pairing case of it rather than invent a second one.
- **`PlateCardBloc.spec`** (line 11) is a dead field after construction — only `PlateCardState.spec` is read downstream. Free deletion once the bloc becomes an adapter.

### 1.4 Verdict on the proposed direction

The direction is right and the code agrees with it, with two amendments:

1. **Do not introduce a second `controller:` parameter.** Make `PlateController extends PlateInputController`. Every existing `controller:` call site keeps compiling and keeps working; new hosts pass the richer subtype and the canvas feature-detects. This removes the entire "hosts must hold two objects" problem in stage 1 with zero breakage, and defers the merge to a rename in a later major.
2. **Do not build a generic `select`-alike as the primary narrowing tool.** Per-slot narrowing does not need diffing — it needs one listenable per slot. `PlateController` exposes `ValueListenable<String?>` per slot, and the bindings become plain `ValueListenableBuilder`s: a Flutter primitive, exactly one rebuild for exactly one slot, no equality scan over the value list on every notification. Keep a small generic selector only for the one genuinely derived subscription (the validation verdict).

---

## 2. Call-site inventory

`flutter_bloc`/`PlateCardBloc`/`PlateInputController` references across the workspace. `core_plate/lib/src/**` is listed first (the thing being changed), then consumers.

### core_plate — internals

| file | what it uses | how it changes |
|---|---|---|
| `lib/src/widgets/plate_canvas.dart:96` | `context.read<PlateCardBloc>().add(SpecIsChanged)` | → `_controller.adoptSpec(widget.spec, preserve: widget.onSpecChange)` (S4) |
| `…:125-128` | `readValues`/`commit` closures capturing `context` | → `readValues: () => _controller.values`, `commit: _controller.setAt` (S2, fixes 4b) |
| `…:166` | `context.read` in `_probeValidation` | → `_controller.values` (S2) |
| `…:190,193` | `context.read` + `ValueIsChanged` in `_openPicker` | → `_controller.setAt(index, chosen)` (S2) |
| `…:402` `_ValidationBinding` | `BlocSelector<…, PlateValidation>` | → `PlateSelector<PlateValidation>` over the controller (S3) |
| `…:480` `_FrameBinding` | `context.select<PlateCardBloc,bool>` | → `ValueListenableBuilder<bool>` on `controller.completed` (S3) |
| `…:516,526,534` `_SlotBinding` | `context.select` String?, `context.read`, `ValueIsChanged` | → `ValueListenableBuilder<String?>` on `controller.slot(i)`; `onChanged: (v)=>controller.setAt(i,v)` (S3) |
| `…:561` `_MirrorBinding` | `context.select` String? | → `ValueListenableBuilder<String?>` on `controller.slot(mirror.source)` (S3) — **same treatment, same stage** |
| `lib/src/input/plate_input_controller.dart` | the class itself | gains `PlateController` subclass in a new file (S1); merged + deprecated (S7) |
| `lib/src/input/plate_input_machine.dart` | nothing bloc-shaped | **unchanged in every stage** — the seam holds |
| `lib/src/bloc/*.dart` | the bloc | unchanged through S5; moved to `core_plate_bloc` in S6 |
| `lib/src/widgets/show_plate.dart` | `BlocBuilder` ×2 (`ShowPlate`, `PlateText`) | controller-based `PlateView`/`PlateTextView` added in core (S5); bloc versions move to `core_plate_bloc` (S6). Bounds-check fix in S4 |
| `lib/src/widgets/plate_slot_item.dart` | none — takes `value` as a param | **unchanged** (doc comment at :17-18 already promises this) |
| `lib/core_plate.dart:95` | `export 'src/bloc/plate_card_bloc.dart'` | export of `PlateController` added (S1); bloc export becomes a deprecated re-export (S6) then removed |
| `pubspec.yaml:13-14` | `flutter_bloc`, `bloc` | dropped entirely in S6 |

### Consumers

| file | what it uses | how it changes |
|---|---|---|
| `core_plate/example/lib/main.dart:2,13,21-22` + `example/pubspec.yaml:13` | `BlocProvider(create: PlateCardBloc(spec))` | rewritten to zero-config `PlateCanvas(spec: …)`; `flutter_bloc` dep deleted (S5) |
| `iran_plate/example/lib/main.dart:2,19-20` + `pubspec.yaml:13` | same | same (S5) |
| `germany_plate/example/lib/main.dart:2,19-20` + `pubspec.yaml:13` | same | same (S5) |
| `yemen_plate/example/lib/main.dart:5,28-37` | `BlocProvider<PlateCardBloc>` + a comment about the spec-swap reset | provider deleted; comment deleted once S4 lands (S5) |
| `yemen_plate/example/lib/main.dart:203-209` (`_ShowPlateLike`) | `BlocProvider` + seeded `ValueIsChanged` loop | → `PlateController.fromValues(spec, values)` + `PlateCanvas(mode: display)` (S5) |
| `yemen_plate/example/lib/gallery.dart:23,251-254` | one `BlocProvider` per gallery tile | → one `PlateController` per tile, or none at all (canvas self-owns) (S5) |
| `palestine_plate/example/lib/gallery.dart:33,302-308` | `BlocProvider` + `BlocBuilder` per tile | same (S5) |
| `palestine_plate/example/lib/main.dart:5,141-142,196,218,225` | provider, `context.read`, `ValueIsChanged` re-seed loop, `BlocBuilder` | the whole `_switchTo` post-frame workaround (lines 180-221) **deletes**; becomes `controller.adoptSpec(newSpec, preserve: PlateValuePreservation.byGroupKey)` (S4/S5) |
| `palestine_plate/example/lib/main.dart:502-510` | `BlocProvider` + seed loop + `ShowPlate` | → `PlateView(controller:)` (S5) |
| `palestine_plate/test/golden_test.dart:3,22-49` | `PlateCardBloc`, `ValueIsChanged`, `BlocProvider.value`, `ShowPlate` | → seeded `PlateController` + `PlateView`; **must keep passing**, it is the only golden coverage in the workspace (S5) |
| `palestine_plate/pubspec.yaml:22-25` | `flutter_bloc` dev-dep + its apology comment | deleted (S5) |
| `palestine_plate/lib/src/west_bank_plates.dart:217,251-252` | doc warnings about the reset | rewritten once S4 lands (S4) |
| `yemen_plate/lib/src/northern_plates.dart:1108-1109`, `unified_plates.dart:29-30,864` | same doc warnings | same (S4) |
| `plate_number_holder/lib/minimal/main.dart:3,19-20` | `BlocProvider(create: PlateCardBloc(IranPlates.car))` | provider deleted (S5) |
| `plate_number_holder/lib/widgets/plate_display.dart:2,55,107,132-135,180,260,325-328` | `bloc:` and `secondaryBloc:` params, two `BlocProvider`s, `BlocProvider.value` in `_SecondaryPlate` | `bloc:`→`controller:`, `secondaryBloc:`→`secondaryController:`; both providers delete (S5) |
| `plate_number_holder/lib/showcase/device_stage.dart:65,71,75,98-121,126,197-203` | `_bloc`, `_secondaryBloc`, `StreamSubscription<PlateCardState> _mirror`, `_plateInput` | four fields collapse to two `PlateController`s; the stream subscription becomes `controller.addListener` (or stays, via `core_plate_bloc`) (S5) |
| `plate_number_holder/lib/showcase/plate_typist.dart:157,159,204,206,260,279,290,326` | `bloc:` + `controller:` on `run`/`_runStep`/`_pickLetter`; `bloc.add(ValueIsChanged…)` ×3 | `bloc:` parameter **deletes**; commits go through `controller.setAt` (S5). Signature shrinks by one required param at 4 sites |
| `plate_number_holder/lib/showcase/plate_mirror.dart:57` | doc reference to writing into a `PlateCardBloc` | doc update; the function itself is spec→spec and unchanged (S4 informs it) |
| `plate_number_holder/lib/showcase/demo_config.dart:51` | doc reference to `PlateInputController` | doc update only (S7) |
| `plate_number_holder/pubspec.yaml:58-59` | `flutter_bloc` dep + comment | deleted (S5) |
| `plate_keypad/**` | **nothing** | untouched in every stage — it already depends on `PlateAlphabet` only |
| `iran_plate/lib/**`, `germany_plate/lib/**`, `yemen_plate/lib/**`, `palestine_plate/lib/**` | no bloc references in `lib/` at all | untouched except doc comments |

**Totals:** 8 `BlocProvider`/`BlocProvider.value` sites, 3 `BlocBuilder`, 1 `BlocSelector`, 3 `context.select`, 4 `context.read`, 11 `ValueIsChanged` dispatch sites, 1 `SpecIsChanged`, 0 `RemovePlateCard` (dead event — nothing in the workspace dispatches it), 6 `pubspec.yaml` entries for `flutter_bloc`, and 2 public bloc-only widgets. Six example apps must keep running; `palestine_plate` has 4 test files that must keep compiling.

---

## 3. The target API

New file `core_plate/lib/src/input/plate_controller.dart`.

```dart
/// How a controller carries its values across a spec change.
enum PlateValuePreservation {
  /// Clear everything. Today's behaviour.
  none,

  /// Copy slot i to slot i while both specs have one, dropping characters
  /// the incoming slot's alphabet refuses. Truncates on a shorter spec.
  byIndex,

  /// Copy group-by-group, matching PlateTextGroup.key. A spec with no keyed
  /// groups falls back to [byIndex]. Within a matched pair the copy is
  /// positional and stops at the shorter group; a slot whose alphabet holds
  /// exactly one character is filled from the alphabet, not from the source.
  byGroupKey,
}

/// The plate's state, owned. Spec, values, focus and navigation in one object,
/// held by a host the way a TextEditingController is.
///
/// A [PlateCanvas] given no controller creates and owns one; a host that wants
/// to read or write the value passes its own and disposes it.
class PlateController extends PlateInputController {
  PlateController({required PlateSpec spec, List<String?>? values});

  /// A controller pre-seeded with [values], for rendering a known plate.
  factory PlateController.fromValues(PlateSpec spec, List<String?> values);

  /// A controller seeded from a plain text string, one character per slot in
  /// index order, skipping characters the slot's alphabet refuses.
  factory PlateController.fromText(PlateSpec spec, String text);

  // --- spec ---------------------------------------------------------------

  PlateSpec get spec;

  /// Replaces [spec], carrying the current values across per [preserve].
  /// Notifies once. Slot listenables are re-founded: a listener on slot i of
  /// the old spec is moved to slot i of the new one where it exists, and
  /// receives null where it does not.
  void adoptSpec(PlateSpec next, {
    PlateValuePreservation preserve = PlateValuePreservation.byGroupKey,
  });

  // --- values -------------------------------------------------------------

  /// Current characters in slot order. Unmodifiable, always [spec.slotCount]
  /// long.
  List<String?> get values;

  /// The character at [index], or null. Out of range returns null.
  String? valueAt(int index);

  /// Writes [value] to [index]; '' or null clears. No-op when [index] is out
  /// of range, when the value is unchanged, or when the slot's alphabet
  /// refuses [value].
  void setAt(int index, String? value);

  /// Replaces every value at once. Shorter lists clear the tail; longer ones
  /// are truncated. One notification, not one per slot.
  void setValues(List<String?> values);

  /// Clears every slot.
  void clear();

  // --- text and groups ----------------------------------------------------

  /// The plate as printed text: every [PlateTextGroup] rendered through its
  /// slots' alphabets, in [spec.textDirection] reading order, joined by [sep].
  String text({String sep = ' '});

  /// The canonical (storage-form, un-rendered) characters of the group keyed
  /// [key], concatenated. '' when no group carries that key.
  String group(String key);

  /// Writes [value] across the slots of the group keyed [key], one character
  /// per slot in group order, clearing any tail the string does not reach.
  /// Characters the target slot's alphabet refuses are dropped, not forced.
  /// No-op when no group carries [key]. One notification.
  void setGroup(String key, String value);

  // --- derived ------------------------------------------------------------

  bool get isCompleted;
  bool get isEmpty;

  /// The plate as an immutable value, for hosts that persist or compare one.
  PlateNumber get plateNumber;

  // --- narrowed subscriptions --------------------------------------------

  /// This slot's character alone. Rebuilding on this instead of on the
  /// controller is what keeps a keystroke local to one slot. Valid for the
  /// life of the current [spec]; re-founded by [adoptSpec].
  ValueListenable<String?> slot(int index);

  /// Whether every slot is filled. Flips at most twice per plate, so the
  /// frame is untouched by an ordinary keystroke.
  ValueListenable<bool> completed;

  @override
  void dispose();
}
```

Narrowing primitive, same file or `src/widgets/plate_selector.dart`:

```dart
/// Rebuilds [builder] only when [selector] over [controller] produces a value
/// unequal to the last one. The `context.select` replacement for the one
/// subscription that is genuinely derived rather than per-slot (the validation
/// verdict). Per-slot and completed subscriptions use [PlateController.slot]
/// and [PlateController.completed] with a plain ValueListenableBuilder — no
/// diffing needed, because the notifier already is the narrow thing.
class PlateSelector<T> extends StatefulWidget {
  const PlateSelector({
    super.key,
    required this.controller,
    required this.selector,
    required this.builder,
  });

  final PlateController controller;
  final T Function(PlateController controller) selector;
  final Widget Function(BuildContext context, T value) builder;
}
```

`PlateCanvas` changes:

```dart
class PlateCanvas extends StatefulWidget {
  const PlateCanvas({
    super.key,
    required this.spec,
    this.mode = PlateMode.input,
    this.theme,
    this.inputSource,
    required this.onChooseCharacter,
    this.onActiveIndexChanged,
    this.controller,                 // type widens: PlateInputController?
    this.validator,
    this.autoValidate = false,
    this.onSpecChange = PlateValuePreservation.none,   // S4; default flips in S6
  });

  /// The host's handle on this plate. Pass a [PlateController] to own the
  /// value as well as the focus; a plain [PlateInputController] keeps the
  /// pre-0.3 focus-only behaviour and the canvas owns the value itself.
  /// Null creates and owns a [PlateController], exactly as a [TextField]
  /// creates its own [TextEditingController].
  final PlateInputController? controller;

  /// What happens to the typed value when [spec] changes on a live canvas.
  final PlateValuePreservation onSpecChange;
}
```

The bloc adapter — `core_plate_bloc/lib/src/plate_card_binding.dart` (S6; ships inside `core_plate` first in S5):

```dart
/// Two-way bridge between a [PlateController] and a [PlateCardBloc], for
/// hosts whose app state lives in bloc. Mirrors controller writes out as
/// [ValueIsChanged] and bloc emissions back into the controller, with an echo
/// guard so a round trip settles in one pass.
///
/// Provides the bloc to the subtree, so `ShowPlate`, `PlateText` and any
/// host BlocBuilder below keep working unchanged.
class PlateCardBinding extends StatefulWidget {
  const PlateCardBinding({
    super.key,
    required this.controller,
    this.bloc,                       // null creates and owns one
    required this.child,
  });

  final PlateController controller;
  final PlateCardBloc? bloc;
  final Widget child;
}
```

And the controller-based replacements for the two bloc-only widgets, in core:

```dart
/// Read-only graphical plate, driven by a controller. The `ShowPlate` a host
/// reaches for once core no longer ships a bloc.
class PlateView extends StatelessWidget {
  const PlateView({super.key, required this.controller, this.theme, this.emptyPlate});
}

/// Plain-text rendering of the plate string. Bounds-checked (today's
/// `PlateText` is not — see §1.3).
class PlateTextView extends StatelessWidget {
  const PlateTextView({super.key, required this.controller, this.textStyle, this.emptyPlate});
}
```

### Per-slot rebuild narrowing — concretely

Today's property: one keystroke rebuilds one `_SlotBinding` (+ any `_MirrorBinding` pointed at that slot), and nothing else. That is what the NOTE at `plate_canvas.dart:235-249` defends.

The replacement is **not** a `select`-alike. `PlateController` keeps a private `List<ValueNotifier<String?>> _slots`, one per slot, re-founded by `adoptSpec`, plus a single `ValueNotifier<bool> _completed`. `setAt(i, v)`:

1. writes `_values[i]`,
2. sets `_slots[i].value` — notifies **only** that slot's listeners,
3. recomputes completion and sets `_completed.value` — a `ValueNotifier` swallows an equal write, so this notifies only on a genuine flip,
4. calls `notifyListeners()` on the controller itself, for hosts and the verdict selector.

The four bindings then become:

| binding | today | after |
|---|---|---|
| `_SlotBinding` | `context.select<PlateCardBloc, String?>` | `ValueListenableBuilder<String?>(valueListenable: controller.slot(index), …)` — `syncController` stays in that builder, above `PlateSlotItem`, preserving the build-order constraint in §1.3 |
| `_MirrorBinding` | `context.select<PlateCardBloc, String?>` | `ValueListenableBuilder<String?>(valueListenable: controller.slot(mirror.source), …)` — identical shape, no focus node, no sync |
| `_FrameBinding` | `context.select<PlateCardBloc, bool>` | `ValueListenableBuilder<bool>(valueListenable: controller.completed, …)` |
| `_ValidationBinding` | `BlocSelector<…, PlateValidation>` | `PlateSelector<PlateValidation>(controller: c, selector: (c) => validator.validate(entry(c.values)), …)` — `PlateValidation`'s existing `operator ==` over `reason` (`plate_validator.dart:20`) gives the same flip-not-keystroke property. `_VerdictListener` is unchanged |

This is strictly better than `context.select` on two counts: no `InheritedWidget` dependency bookkeeping, and no selector re-evaluation on every emission for slots that did not change — a keystroke wakes exactly one notifier instead of running N+2 selector closures. Both examples in the workspace with the most slots (Yemen's 8-slot northern plates, Palestine's West Bank specs) benefit proportionally.

`PlateSelector` needs `didUpdateWidget` handling for a swapped controller, and must not call `selector` during `dispose`. It holds the last value in `State`, compares with `==`, and `setState`s only on inequality.

---

## 4. Staged sequence

Every stage leaves the whole workspace compiling and `flutter analyze`-clean. Breaking stages are marked.

| # | stage | version | breaking? |
|---|---|---|---|
| **S1** | Add `PlateController extends PlateInputController` + `PlateSelector`. Not wired to anything. Export both. | 0.3.0-dev | no |
| **S2** | `PlateCanvas` internally always holds a `PlateController` — the host's if it passed one, otherwise a self-created one. A private two-way `_BlocBridge` keeps the ancestor `PlateCardBloc` (still required) in sync in both directions, so hosts that write to the bloc directly (`plate_typist`, `device_stage`) keep working. `readValues`/`commit`/`_probeValidation`/`_openPicker` stop touching `context` — **fixes claim 4b**. Bindings still read the bloc. | 0.3.0-dev | no |
| **S3** | Swap the four bindings to controller listenables. `context.select`/`BlocSelector` leave the widget layer entirely; only `_BlocBridge` still talks to bloc. Verify per-slot narrowing survives. | 0.3.0 | no |
| **S4** | `adoptSpec` + `PlateValuePreservation` + `PlateCanvas.onSpecChange` (default `none` = today's behaviour). Fix `PlateText`'s bounds bug. Update the five doc warnings in `yemen_plate`/`palestine_plate`. Delete the `_switchTo` workaround in `palestine_plate/example`. **Fixes claim 4a.** | 0.3.0 | no |
| **S5** | Make the ancestor bloc optional: `PlateCanvas` adopts one if present (deprecated, warns), otherwise runs controller-only. Ship `PlateCardBinding`, `PlateView`, `PlateTextView` inside `core_plate`. Migrate every consumer and all six examples off `BlocProvider`. Drop `flutter_bloc` from five consumer pubspecs. | 0.3.0 | no |
| **S6** | Extract `core_plate_bloc`: `PlateCardBloc`/`State`/events, `PlateCardBinding`, `ShowPlate`, `PlateText` move out. `core_plate` drops `flutter_bloc` + `bloc` deps and the auto-adoption path. `onSpecChange` default flips to `byGroupKey`. | 0.4.0 | **YES** |
| **S7** | Fold `PlateInputController`'s members into `PlateController`; `@Deprecated typedef PlateInputController = PlateController;`. | 0.5.0 | **YES** (deprecation only) |

Why this order: S2 is the risky one and it ships alone, behaviour-identical, with the bloc still authoritative — so if per-slot narrowing or the echo guard regresses, exactly one stage is suspect. S3 is a mechanical swap once S2 has proven the controller carries the same values. S4 is the user-visible payoff and lands before any breakage. Everything breaking is confined to S6/S7, after the ecosystem has already stopped depending on the bloc.

**Deprecation path for bloc hosts, in one sentence per release:** 0.3.0 — nothing breaks, `BlocProvider` still works, but the canvas prints a deprecation notice in debug when it adopts an ancestor bloc instead of being handed a `PlateController`. 0.4.0 — bloc types move to `core_plate_bloc`; a host adds one dependency line and wraps its canvas in `PlateCardBinding(controller: …)`, and every `ValueIsChanged`/`BlocBuilder` it already wrote keeps working. 0.5.0 — `PlateInputController` becomes a deprecated alias; the rename is mechanical.

---

## 5. Stage prompts

Copy one at a time, in order. Each is written for a fresh session.

---

### S1 — add the controller

````text
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
````

---

### S2 — canvas owns a controller; bloc becomes a mirror

````text
Repo: /home/aradbeyranvand/StudioProjects/plate. Working in `core_plate`.
Read core_plate/CLAUDE.md and follow it. Read the files named below in full first (this
task names them, so the "don't survey" rule is satisfied). Never create or edit files
under any `test/` directory; do not run `flutter test`.

CONTEXT
Stage 2 of 7 of moving core_plate off a mandatory bloc. Stage 1 added
`PlateController extends PlateInputController` (lib/src/input/plate_controller.dart) — a
value-owning controller with per-slot `ValueListenable`s — plus `PlateSelector`. Nothing
is wired to it yet.

This stage makes `_PlateCanvasState` hold a `PlateController` internally and become the
writer of record, while the ancestor `PlateCardBloc` stays required and stays in sync in
BOTH directions. Behaviour must be pixel- and rebuild-identical afterwards. The widget
bindings still read the bloc — do not touch them; that is stage 3.

FILES YOU MAY TOUCH
  core_plate/lib/src/widgets/plate_canvas.dart
  core_plate/lib/src/input/plate_controller.dart   (only if a genuine gap appears)

READ FIRST (do not edit)
  core_plate/lib/src/input/plate_input_machine.dart
  core_plate/lib/src/input/plate_input_controller.dart
  core_plate/lib/src/bloc/plate_card_bloc.dart (and its two `part` files)

WHAT TO DO

1. `_PlateCanvasState` gains `PlateController _controller` and a `bool _ownsController`.
   In initState: if `widget.controller is PlateController`, adopt it and set
   `_ownsController = false`; otherwise construct `PlateController(spec: widget.spec)`
   and set `_ownsController = true`. Dispose it in `dispose()` only when owned. Handle a
   changed `widget.controller` in `didUpdateWidget` (dispose an owned one you are
   replacing; never dispose the host's).

2. Seed the controller from the bloc's current values on first build, so an existing host
   that provided a pre-populated bloc still renders its plate.

3. Replace the two closures in `_installMachine` (currently
   `readValues: () => context.read<PlateCardBloc>()...` and
   `commit: (i,v) => context.read<PlateCardBloc>().add(...)`) with
   `readValues: () => _controller.values` and `commit: _controller.setAt`.
   This is the point of the stage: those closures outlive the build that created them and
   currently capture BuildContext. After this change nothing long-lived holds a context.
   Do the same for `_probeValidation` (read `_controller.values`) and `_openPicker`
   (write `_controller.setAt(index, chosen)` instead of `bloc.add(ValueIsChanged(...))`).

4. Add a private two-way bridge so the bloc stays authoritative for hosts that write to it
   directly. Two real consumers do exactly that and must keep working unchanged:
   `plate_number_holder/lib/showcase/plate_typist.dart` dispatches
   `bloc.add(ValueIsChanged(...))` at three sites, and
   `plate_number_holder/lib/showcase/device_stage.dart` drives a second plate from
   `_bloc.stream`. Read both before writing the bridge.
   The bridge: controller listener → dispatch `ValueIsChanged` for each changed slot;
   bloc subscription → `_controller.setValues(state.plateNumber.values)`. Guard the echo
   with a re-entrancy flag so one write settles in a single pass and never loops. Put it
   in a private class in plate_canvas.dart; it is not public API this stage.

5. `didUpdateWidget`'s spec-change branch keeps dispatching `SpecIsChanged` for now AND
   additionally re-founds the controller for the new spec. Do not change what a spec swap
   does to the value — it still clears. That is stage 4.

CONSTRAINTS
- The bindings `_FrameBinding`, `_SlotBinding`, `_MirrorBinding` and `_ValidationBinding`
  keep reading the bloc via `context.select` / `BlocSelector`. Untouched this stage.
- `plate_input_machine.dart` must not change. Its independence from bloc is the seam this
  whole refactor rests on.
- No public API change. `PlateCanvas`'s constructor and parameter types are unchanged.
- No country name anywhere in core_plate.
- Note: `_SlotBinding.build` calls `machine.syncController(index, value)` from inside
  build, and that is load-bearing ordering — leave it exactly where it is.

ACCEPTANCE CHECK
- `flutter analyze` clean across core_plate and every sibling package and example app.
- These apps must still run and behave identically — typing, focus advance, backspace,
  the character picker, and the completed-plate border shift:
    core_plate/example, iran_plate/example, yemen_plate/example,
    palestine_plate/example, plate_number_holder (the showcase, whose auto-typist writes
    straight to the bloc — verify the plate still fills in and the second stacked plate
    still mirrors).
- `grep -n 'context\.read\|context\.select' core_plate/lib/src/widgets/plate_canvas.dart`
  must show NO hits inside `_installMachine`, `_probeValidation` or `_openPicker`.
Finish with analyzer clean + a git commit.
````

---

### S3 — bindings read the controller

````text
Repo: /home/aradbeyranvand/StudioProjects/plate. Working in `core_plate`.
Read core_plate/CLAUDE.md and follow it. Read the named files in full first. Never create
or edit files under any `test/` directory; do not run `flutter test`.

CONTEXT
Stage 3 of 7. Stage 1 added `PlateController` with per-slot `ValueListenable<String?>
slot(int)`, a `ValueListenable<bool> completed`, and a `PlateSelector<T>` widget. Stage 2
made `_PlateCanvasState` own a `PlateController` and made it the writer of record, with a
private two-way bridge keeping the ancestor `PlateCardBloc` in sync. The widget bindings
still read the bloc.

This stage moves the four bindings onto the controller. After it, the only thing in the
widget layer that talks to bloc is the bridge from stage 2.

FILES YOU MAY TOUCH
  core_plate/lib/src/widgets/plate_canvas.dart

READ FIRST (do not edit)
  core_plate/lib/src/input/plate_controller.dart
  core_plate/lib/src/widgets/plate_selector.dart
  core_plate/lib/src/validators/plate_validator.dart
  core_plate/lib/src/input/plate_input_machine.dart

WHAT TO DO — the rebuild-narrowing property is the whole point; preserve it exactly.
The long NOTE comment in `PlateCanvas.build` (it begins "this build deliberately does NOT
watch the plate value") states the invariant: one keystroke rebuilds one slot plus any
mirrors pointed at it, and nothing else. Read it, keep it true, and update its wording to
describe listenables instead of `context.select`.

1. `_SlotBinding`: replace `context.select<PlateCardBloc, String?>` with
   `ValueListenableBuilder<String?>(valueListenable: controller.slot(index), …)`.
   Pass the controller in as a field. `machine.syncController(index, value)` must stay
   INSIDE that builder and ABOVE `PlateSlotItem` — it mutates a TextEditingController
   during build and only works because it runs before that slot's TextField builds in the
   same frame. `onChanged` becomes `(v) => controller.setAt(index, v)`; drop the
   `context.read<PlateCardBloc>()`.

2. `_MirrorBinding`: identical treatment —
   `ValueListenableBuilder<String?>(valueListenable: controller.slot(mirror.source), …)`.
   It owns no focus node and no text controller, so there is no sync call. If
   `_MirrorBinding` is not present in your checkout, a concurrent workstream is adding it
   (a read-only projection of one slot's value, subscribed like `_SlotBinding`) — in that
   case skip this step and say so in the commit message, and DO NOT restructure
   `_SlotBinding` in a way that would make the same treatment awkward for it later.

3. `_FrameBinding`: replace `context.select<PlateCardBloc, bool>` with
   `ValueListenableBuilder<bool>(valueListenable: controller.completed, …)`.

4. `_ValidationBinding`: replace the `BlocSelector<PlateCardBloc, PlateCardState,
   PlateValidation>` with `PlateSelector<PlateValidation>` over the controller, selecting
   `validate(controller.values)`. `PlateValidation` compares by `reason`, so the builder
   must still run only on a valid⇄invalid flip, not per keystroke. `_VerdictListener` is
   unchanged — keep publishing the verdict from its lifecycle callbacks, never from build.

5. Delete any `flutter_bloc` import from the binding classes if nothing else in the file
   needs it. The bridge from stage 2 still does, so the file-level import probably stays.

CONSTRAINTS
- Public API unchanged. No pubspec change. `plate_input_machine.dart` unchanged.
- No country name anywhere in core_plate.
- Do not "simplify" by having the canvas rebuild on the whole controller — that is
  precisely the regression the NOTE comment exists to prevent.

ACCEPTANCE CHECK
- `flutter analyze` clean across core_plate and every sibling package and example app.
- Run plate_number_holder's showcase and yemen_plate/example and type into a plate: the
  plate fills in normally, the frame only shifts when the last slot lands, and a plate
  with mirrors keeps its echoes in step.
- Verify narrowing empirically before committing: temporarily add a debugPrint in
  `_SlotBinding.build` and confirm one keystroke prints once, not once per slot. REMOVE
  the debugPrint before committing.
Finish with analyzer clean + a git commit.
````

---

### S4 — spec swap keeps the value

````text
Repo: /home/aradbeyranvand/StudioProjects/plate. Working in `core_plate`, plus doc-only
edits in `yemen_plate` and `palestine_plate` and one real edit in
`palestine_plate/example`.
Read core_plate/CLAUDE.md and follow it for core_plate. Read the named files in full
first. Never create or edit files under any `test/` directory; do not run `flutter test`.

CONTEXT
Stage 4 of 7. `PlateController` (lib/src/input/plate_controller.dart) already owns the
plate's values and already implements `adoptSpec(next, {preserve})` with a
`PlateValuePreservation` enum (none / byIndex / byGroupKey). `PlateCanvas` already holds a
controller and its bindings already read it.

THE BUG THIS FIXES. Swapping `spec:` on a live `PlateCanvas` wipes the plate.
`PlateCanvas.didUpdateWidget` dispatches `SpecIsChanged` when `spec.id` changes, and
`PlateCardBloc`'s handler emits `PlateCardState.empty(event.spec)` unconditionally. Five
consumer doc comments warn users about this, and one example app carries a post-frame
re-seed workaround to paper over it:
  yemen_plate/lib/src/northern_plates.dart  (~line 1108)
  yemen_plate/lib/src/unified_plates.dart   (~lines 29, 864)
  palestine_plate/lib/src/west_bank_plates.dart (~lines 217, 251)
  palestine_plate/example/lib/main.dart     (the comment block and `_switchTo`, ~180-221)

FILES YOU MAY TOUCH
  core_plate/lib/src/widgets/plate_canvas.dart
  core_plate/lib/src/widgets/show_plate.dart
  core_plate/lib/src/input/plate_controller.dart   (only if adoptSpec has a real gap)
  yemen_plate/lib/src/northern_plates.dart         (doc comments only)
  yemen_plate/lib/src/unified_plates.dart          (doc comments only)
  palestine_plate/lib/src/west_bank_plates.dart    (doc comments only)
  palestine_plate/example/lib/main.dart

WHAT TO DO

1. Add to `PlateCanvas`:
     final PlateValuePreservation onSpecChange;
   defaulting to `PlateValuePreservation.none` — today's behaviour, so this stage breaks
   nobody. Document that the default will change to `byGroupKey` in 0.4.0.

2. In `didUpdateWidget`'s `spec.id` branch, call
   `_controller.adoptSpec(widget.spec, preserve: widget.onSpecChange)` instead of
   dispatching `SpecIsChanged` from the canvas. The bloc bridge from stage 2 mirrors the
   resulting values out, so a bloc-holding host sees the migrated plate. Keep disposing
   and rebuilding the `PlateInputMachine` exactly as it does now — a machine belongs to
   one spec and its focus nodes cannot be reindexed.

3. Fix the latent range bug in `PlateText` (show_plate.dart): it indexes `values[i]`
   directly for every group index while `PlateSpec.renderGroup` bounds-checks. During a
   spec change the value list can be shorter than the new spec's group indices and this
   throws. Guard it the same way `renderGroup` does.

4. Rewrite the five doc warnings listed above. They currently tell users to pick the spec
   before entry begins because a swap resets the bloc. The new text: a swap carries the
   value across per `PlateCanvas.onSpecChange`, and `byGroupKey` is what lets e.g. a
   change of serial length keep the serial and truncate only what no longer fits. Do not
   name the mechanism as "the bloc" — it is the controller now.

5. In palestine_plate/example/lib/main.dart, DELETE the `_switchTo` post-frame re-seed
   workaround (the `WidgetsBinding.instance.addPostFrameCallback` block that replays old
   values as `ValueIsChanged`) and the 14-line comment above it explaining why it exists,
   and pass `onSpecChange: PlateValuePreservation.byGroupKey` to the canvas instead. The
   app must behave BETTER than before: switching scheme or usage mid-entry now keeps the
   serial rather than re-seeding it positionally.

CONSTRAINTS
- `SpecIsChanged` and its handler stay in place; nothing else dispatches it, but removing
  a public event is a breaking change reserved for stage 6.
- No country name anywhere in core_plate — the doc edits in yemen_plate/palestine_plate
  are in those packages, which is fine.
- No pubspec changes.

ACCEPTANCE CHECK
- `flutter analyze` clean across core_plate and every sibling package and example app.
- palestine_plate/example: type a plate, switch region/scheme/usage/form-factor — the
  serial survives, and a character the new alphabet refuses is dropped rather than forced.
- yemen_plate/example: switch between the unified and northern plates mid-entry and
  confirm the governorate and serial land in the right registers, not positionally.
- palestine_plate's existing tests under test/ must still COMPILE and pass unchanged; do
  not edit them.
- core_plate/example and iran_plate/example still run.
Finish with analyzer clean + a git commit.
````

---

### S5 — the bloc becomes optional

````text
Repo: /home/aradbeyranvand/StudioProjects/plate. This stage spans the whole workspace.
Read core_plate/CLAUDE.md and follow it for core_plate edits. Read the named files in
full first. Do not create or edit files under core_plate/test (there is none and there
must not be); palestine_plate's existing tests you WILL edit — see below.

CONTEXT
Stage 5 of 7. `PlateController` owns the plate's values; `PlateCanvas` holds one and its
bindings read it; a private bridge inside plate_canvas.dart mirrors an ancestor
`PlateCardBloc` in both directions. The bloc is still REQUIRED: without a
`BlocProvider<PlateCardBloc>` above it the canvas throws on first build.

This stage makes it optional and migrates every consumer. Nothing breaks: a canvas with a
bloc above it still works.

FILES YOU MAY TOUCH
  core_plate/lib/src/widgets/plate_canvas.dart
  core_plate/lib/src/widgets/plate_card_binding.dart   (new)
  core_plate/lib/src/widgets/plate_view.dart           (new)
  core_plate/lib/core_plate.dart
  core_plate/example/lib/main.dart, core_plate/example/pubspec.yaml
  iran_plate/example/lib/main.dart, iran_plate/example/pubspec.yaml
  germany_plate/example/lib/main.dart, germany_plate/example/pubspec.yaml
  yemen_plate/example/lib/main.dart, yemen_plate/example/lib/gallery.dart,
    yemen_plate/example/pubspec.yaml
  palestine_plate/example/lib/main.dart, palestine_plate/example/lib/gallery.dart,
    palestine_plate/example/pubspec.yaml
  palestine_plate/pubspec.yaml, palestine_plate/test/golden_test.dart
  plate_number_holder/lib/minimal/main.dart
  plate_number_holder/lib/widgets/plate_display.dart
  plate_number_holder/lib/showcase/device_stage.dart
  plate_number_holder/lib/showcase/plate_typist.dart
  plate_number_holder/pubspec.yaml

WHAT TO DO

1. In `PlateCanvas`, make the ancestor bloc optional. Look it up defensively (a failed
   lookup is not an error); when one is present, install the existing bridge and emit a
   `debugPrint` deprecation notice once per canvas saying the host should hand the canvas
   a `PlateController` and, if it needs bloc, wrap it in `PlateCardBinding`. When none is
   present, run controller-only.

2. Ship `PlateCardBinding` (new file): a StatefulWidget taking
   `{required PlateController controller, PlateCardBloc? bloc, required Widget child}`.
   It creates and owns a bloc when given none, provides it to the subtree with
   `BlocProvider.value`, and runs the same two-way mirror with the same echo guard. Move
   the bridge logic out of plate_canvas.dart into it and have the canvas's
   deprecated auto-adoption path reuse it. This is the public migration seam for
   bloc-based hosts and it is what moves to its own package in stage 6.

3. Ship `PlateView` and `PlateTextView` (new file plate_view.dart): controller-driven
   equivalents of `ShowPlate` and `PlateText`. `PlateView` takes
   `{required PlateController controller, PlateTheme? theme, Widget? emptyPlate}` and
   renders `PlateCanvas(mode: PlateMode.display)` — note it takes a theme, which
   `ShowPlate` does not; two consumers have local reimplementations solely for that
   reason (yemen_plate/example/lib/main.dart `_ShowPlateLike` and
   plate_number_holder's `_SecondaryPlate`), and both should collapse onto `PlateView`.
   `PlateTextView` mirrors `PlateText`, bounds-checked. Leave `ShowPlate`/`PlateText`
   in place and untouched; they move out in stage 6. Export the new widgets.

4. Migrate every consumer off `BlocProvider`. In each case the replacement is either a
   `PlateController` the host holds, or nothing at all where the canvas can own its own:
   - core_plate/example, iran_plate/example, germany_plate/example, minimal/main.dart:
     delete the provider entirely, leaving a bare `PlateCanvas(spec: …)`. Delete
     `flutter_bloc` from those pubspecs. These four are the "developer-friendliness bar" —
     after this stage the minimal example is a widget and a spec, nothing else.
   - yemen_plate/example and palestine_plate/example galleries: one `PlateController` per
     tile, or none where the tile only displays.
   - yemen_plate/example `_ShowPlateLike` and the seeded `ValueIsChanged` loop:
     `PlateController.fromValues(spec, values)` + `PlateView`.
   - palestine_plate/example/lib/main.dart: the top-level provider and the `BlocBuilder`
     become a host-held `PlateController` + `ListenableBuilder`; line ~502's provider +
     seed loop + `ShowPlate` becomes `PlateController.fromValues` + `PlateView`.
   - palestine_plate/test/golden_test.dart: seed a `PlateController` and render
     `PlateView` instead of bloc + `BlocProvider.value` + `ShowPlate`. Then delete the
     `flutter_bloc` dev-dependency and its explanatory comment from
     palestine_plate/pubspec.yaml — that dep exists ONLY for this test.
   - plate_number_holder/lib/widgets/plate_display.dart: rename `bloc:` → `controller:`
     (`PlateController?`) and `secondaryBloc:` → `secondaryController:`; delete both
     `BlocProvider`s and the `BlocProvider.value` in `_SecondaryPlate`; collapse
     `_SecondaryPlate` onto `PlateView`.
   - plate_number_holder/lib/showcase/device_stage.dart: `_bloc` and `_secondaryBloc`
     become `PlateController`s; the `StreamSubscription<PlateCardState> _mirror` becomes
     a controller listener that calls `mirrorByGroup` and writes with `setValues`. The
     existing comment explaining why the mirror is a subscription rather than a
     BlocListener still applies — keep its substance.
   - plate_number_holder/lib/showcase/plate_typist.dart: DELETE the `bloc:` parameter from
     `run`, `_runStep` and `_pickLetter` (four signatures) and replace the three
     `bloc.add(ValueIsChanged(index:…, value:…))` calls with `controller.setAt(…)`. This
     is the visible payoff of the merge: the typist now takes one object where it took
     two.
   - Delete `flutter_bloc` from plate_number_holder/pubspec.yaml and its comment.

CONSTRAINTS
- `core_plate`'s pubspec still lists flutter_bloc this stage — `PlateCardBinding`,
  `ShowPlate` and `PlateText` still live in core. Removing it is stage 6.
- No country name anywhere in core_plate.
- Do not change `PlateInputMachine`.
- Do not change what any app LOOKS like. This is a state-plumbing change.

ACCEPTANCE CHECK
- `flutter analyze` clean across all seven packages and all six example apps.
- `grep -rn "BlocProvider" --include=*.dart .` returns hits ONLY inside
  core_plate/lib/src/widgets/plate_card_binding.dart and
  core_plate/lib/src/widgets/show_plate.dart.
- These must run with behaviour unchanged: core_plate/example, iran_plate/example,
  germany_plate/example, yemen_plate/example (including the gallery),
  palestine_plate/example (including the gallery and the mid-entry scheme switch),
  plate_number_holder (the full showcase — device cycling, the auto-typist, the stacked
  second plate, the tablet keypad and the laptop deck keys).
- palestine_plate's four test files still pass.
Finish with analyzer clean + a git commit.
````

---

### S6 — extract `core_plate_bloc` (BREAKING, 0.4.0)

````text
Repo: /home/aradbeyranvand/StudioProjects/plate. This stage spans the workspace and is
BREAKING — it is the 0.4.0 release.
Read core_plate/CLAUDE.md and follow it for core_plate edits. Read the named files in
full first. Do not create tests in core_plate or core_plate_bloc.

CONTEXT
Stage 6 of 7. After stage 5, `PlateController` is the primary API, `PlateCanvas` works
with no bloc anywhere in the tree, `PlateCardBinding` is the seam for bloc-based hosts,
and NO consumer in this workspace uses `BlocProvider` any more. `core_plate` still
declares `flutter_bloc` and `bloc` as dependencies purely to host the bloc types,
`PlateCardBinding`, `ShowPlate` and `PlateText`.

This stage moves all of that into a new sibling package so `core_plate` has a zero-bloc
dependency, and flips the spec-change default.

FILES YOU MAY TOUCH
  core_plate_bloc/**                                   (new package)
  core_plate/lib/src/bloc/**                           (moved out, then deleted)
  core_plate/lib/src/widgets/show_plate.dart           (moved out, then deleted)
  core_plate/lib/src/widgets/plate_card_binding.dart   (moved out, then deleted)
  core_plate/lib/src/widgets/plate_canvas.dart
  core_plate/lib/core_plate.dart
  core_plate/pubspec.yaml, core_plate/CHANGELOG.md
  palestine_plate/pubspec.yaml + test/golden_test.dart  (only if they still reference any
    moved symbol — they should not after stage 5)
  plate_number_holder/**  (only if it still references a moved symbol)

WHAT TO DO

1. Create `core_plate_bloc` as a sibling package (same layout and conventions as
   `plate_keypad`, which is the workspace's existing example of a package split off from
   core — read its pubspec.yaml and its lib/plate_keypad.dart library doc comment and
   match that style). It depends on `core_plate`, `flutter_bloc` and `bloc`. Move into it,
   unchanged in behaviour:
     PlateCardBloc, PlateCardEvent, ValueIsChanged, RemovePlateCard, SpecIsChanged,
     PlateCardState, PlateCardBinding, ShowPlate, PlateText.
   Note `RemovePlateCard` has no dispatcher anywhere in the workspace — move it anyway,
   and mark it deprecated in the new package rather than deleting it silently.
   `PlateCardBloc.spec` is a dead field after construction (only `PlateCardState.spec` is
   read); delete it as part of the move.

2. Delete the moved files from core_plate, remove `flutter_bloc` and `bloc` from
   core_plate/pubspec.yaml, and remove their exports from core_plate.dart. Update
   core_plate.dart's "State — the bloc a canvas keeps its values in" section: it becomes
   the controller, and the library doc comment's list of things the package deliberately
   does not do gains "it does not choose your state management".

3. Delete `PlateCanvas`'s deprecated auto-adoption of an ancestor bloc (the defensive
   lookup, the bridge install and the debugPrint from stage 5). A host that wants bloc
   wraps the canvas in `PlateCardBinding` from the new package.

4. Flip `PlateCanvas.onSpecChange`'s default from `PlateValuePreservation.none` to
   `PlateValuePreservation.byGroupKey`. Update its doc comment. This changes behaviour for
   anyone who swapped `spec:` and relied on the wipe — it belongs in this release and
   nowhere else.

5. Write core_plate/CHANGELOG.md for 0.4.0: what moved, the one-line migration for a bloc
   host (add `core_plate_bloc`, wrap in `PlateCardBinding(controller: …)`, everything else
   unchanged), the `ShowPlate`→`PlateView` / `PlateText`→`PlateTextView` mapping, and the
   `onSpecChange` default flip. Be specific enough that a consumer can migrate from the
   changelog alone.

CONSTRAINTS
- No country name anywhere in core_plate or core_plate_bloc.
- `PlateInputMachine` still must not change. It has not changed in any stage; that is the
  point.
- Do not use this stage to redesign the bloc. It moves verbatim (minus the dead field).

ACCEPTANCE CHECK
- `core_plate/pubspec.yaml` has no `bloc` or `flutter_bloc` entry, and
  `grep -rn "bloc" core_plate/lib/` returns only prose in changelog-style comments.
- `flutter analyze` clean across all eight packages and all six example apps.
- All six examples still run: core_plate, iran_plate, germany_plate, yemen_plate,
  palestine_plate, plate_keypad — plus the plate_number_holder showcase end to end.
- palestine_plate's tests still pass.
- Add a minimal `core_plate_bloc/example` proving the bloc path still works: a
  `PlateController` + `PlateCardBinding` + `PlateCanvas` with a `BlocBuilder` reading the
  value out. It must run.
Finish with analyzer clean + a git commit.
````

---

### S7 — merge the two controllers (0.5.0)

````text
Repo: /home/aradbeyranvand/StudioProjects/plate. Working mostly in `core_plate`.
Read core_plate/CLAUDE.md and follow it. Read the named files in full first. Do not
create tests.

CONTEXT
Stage 7 of 7, the 0.5.0 release. `PlateController` has been the primary API since 0.3.0
and currently `extends PlateInputController` — a compatibility shape chosen so that every
existing `PlateCanvas(controller: …)` call site kept compiling through the migration.
That job is done: no consumer in this workspace passes a bare `PlateInputController` any
more. Two objects where hosts think of one is now just a wart.

FILES YOU MAY TOUCH
  core_plate/lib/src/input/plate_controller.dart
  core_plate/lib/src/input/plate_input_controller.dart
  core_plate/lib/src/widgets/plate_canvas.dart
  core_plate/lib/core_plate.dart
  core_plate/CHANGELOG.md
  plate_number_holder/lib/showcase/demo_config.dart   (doc comment only)
  plate_number_holder/lib/showcase/plate_typist.dart  (doc comment only)
  any consumer file whose type annotations need widening

WHAT TO DO

1. Fold `PlateInputController`'s members into `PlateController`: the `PlateInputTarget`
   plumbing (`attach`, `detach`, `installValidation`, `reportValidation`,
   `notifyActiveSlotChanged`), the host-facing focus API (`activeIndex`, `activeSlotIn`,
   `isAttached`, `validation`, `submit`, `backspace`, `focusFirstEmpty`, `focusSlot`) and
   their doc comments, which are good and should survive intact.

2. Keep `PlateInputTarget` exactly as it is. It is the interface `PlateInputMachine`
   implements and it is what keeps the machine independent of everything else. The machine
   file must not change in this stage either.

3. Replace the old class with
   `@Deprecated('Renamed to PlateController in 0.5.0; will be removed in 0.6.0.')
    typedef PlateInputController = PlateController;`
   so existing annotations still compile with a warning.

4. `PlateController.activeSlotIn(PlateSpec spec)` is now redundant — the controller knows
   its own spec. Add `PlateSlot? get activeSlot` and deprecate `activeSlotIn`, pointing at
   it. Do the same for any other member the merge made spec-redundant.

5. Widen `PlateCanvas.controller` to `PlateController?` and simplify the
   `is PlateController` feature-detection that stage 2 introduced — there is one type now,
   so the canvas either got a controller or it makes one. Keep the
   `TextField`/`TextEditingController` ownership semantics exactly: owned when created,
   never disposed when the host's.

6. Update the doc comments in plate_number_holder that reference `PlateInputController`
   by name.

7. CHANGELOG.md for 0.5.0: the rename, the deprecated typedef, the `activeSlotIn` →
   `activeSlot` mapping, and the 0.6.0 removal date.

CONSTRAINTS
- No country name anywhere in core_plate.
- `plate_input_machine.dart` unchanged.
- Do not change any behaviour. This is a rename and a merge.

ACCEPTANCE CHECK
- `flutter analyze` clean across all eight packages and all six example apps, with no
  deprecation warnings in this workspace's own code (the typedef exists for external
  consumers; nothing here should still use the old name).
- All six examples run, plus plate_number_holder's showcase end to end: device cycling,
  the auto-typist, the stacked mirror plate, the tablet keypad, the laptop deck keys.
- palestine_plate's tests still pass.
Finish with analyzer clean + a git commit.
````
