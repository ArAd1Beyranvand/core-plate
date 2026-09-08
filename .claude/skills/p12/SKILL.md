---
name: p12
description: "P12 — find and fix the frame drops at the start of and during animations. Ten concrete candidates located in the source, plus a measure-fix-remeasure loop driven by profiling the developer runs in Android Studio. Invoke with /p12 in a fresh session."
---

> **Run this in a fresh session** (`/clear` first).
> **Model:** Opus 5 · **reasoning:** medium · **extended thinking:** ON
> **Requires:** /p1  (/p10 helps, not required)
> Full index: `/phases` · evidence: `claude/AUDIT_DIAGNOSIS.md` · overview: `claude/REFACTOR_ROADMAP.md`

# P12 — Animation frame budget

## Context (assume nothing else)

The reported symptom: **animations lag at the start, and again partway through.** That pairing is
diagnostic — the two halves almost always have different causes.

- **Lag at the start** is usually first-frame work that only happens once: shader compilation, an SVG
  parsed for the first time, an image decoded, or an expensive object built on the first build of a
  subtree.
- **Lag in the middle** is usually per-frame work: something expensive rebuilt on every tick, or a burst
  of rebuilds triggered by an event that happens to land mid-animation.

There are only three animated surfaces in this workspace, and the whole of the animation code is 9
constructs in `plate_keypad/lib/src/plate_keypad.dart`, 2 in `palestine_plate/example/lib/main.dart`
and 2 in `core_plate/lib/src/widgets/plate_canvas.dart`. Everything below was found by reading them.

> **Before you start:** the project holds a doc named `ANIMATION_PERF.md` from earlier work. This phase
> was written from the source alone and deliberately did not read it. Read it now, first thing, and
> reconcile: anything it already fixed, cross off; anything it found that is not below, add. Do not
> assume either document is complete.

---

## The ten candidates, in the order they are worth checking

Severity is *expected frame cost*, not code quality.

### A1 — `ThemeData.light()` is constructed on every canvas build — **H, mid-animation**

`core_plate/lib/src/widgets/plate_canvas.dart:279`:

```dart
final selectionTheme = ThemeData.light().copyWith(
  textSelectionTheme: TextSelectionThemeData(
    selectionColor: theme.activeColor.withValues(alpha: 0.3),
    cursorColor: theme.activeColor,
    selectionHandleColor: theme.activeColor,
  ),
);
```

`ThemeData.light()` builds a complete Material theme — a colour scheme, a full text theme, and roughly
thirty component sub-themes — and it runs on **every** `PlateCanvas.build`. The existing comment says it
is "built once per canvas build … instead of each typed slot constructing its own", so it has already
been hoisted once; it has not been hoisted far enough.

It depends on exactly one value: `theme.activeColor`. Cache it in the `State`, rebuilt only when that
colour changes.

```dart
  ThemeData? _selectionTheme;
  Color? _selectionThemeFor;

  ThemeData _selectionThemeOf(Color active) {
    if (_selectionThemeFor == active) return _selectionTheme!;
    _selectionThemeFor = active;
    return _selectionTheme = ThemeData.light().copyWith(/* … */);
  }
```

Note this interacts with `autoValidate`: when a plate flips invalid, `theme.copyWith(activeColor:
theme.alertColor)` changes `activeColor`, so the cache correctly rebuilds once per verdict flip rather
than once per frame.

### A2 — the Palestine demo rebuilds the whole screen on every keystroke — **H, mid-animation**

`palestine_plate/example/lib/main.dart:266-284`:

```dart
  void _onPlateChanged() {
    if (!mounted) return;
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
```

`PlateCanvas` is built around never doing this. Its per-slot `ValueListenableBuilder` bindings exist
precisely so that a keystroke rebuilds one slot and leaves the frame, the panel, the rules, the labels
and the other slots alone — the file says so at `plate_canvas.dart:287-305`. The host then rebuilds the
entire screen on every controller notification and throws all of it away.

Worse for the symptom: when the notification arrives mid-frame it is deferred to
`addPostFrameCallback`, so the full-screen rebuild lands in the **following** frame. Type while the
keypad is sliding and every character costs one extra fully-rebuilt frame, arriving one frame late.
That is a textbook "lag partway through the animation".

The fix is not to remove the listener — the comment explaining the build-during-build hazard is correct
— but to narrow what it rebuilds. Three things on that screen actually depend on the value: the verdict
line, the Submit button's enabled state, and Gaza's value-derived livery. Wrap each in its own
`PlateSelector` (which core already ships, `plate_selector.dart`, and which rebuilds only when the
selected value changes) and delete `_onPlateChanged` entirely.

Check the Yemen demo for the same shape before assuming it is Palestine-only.

### A3 — the hidden letters grid is built and laid out on every pad build — **H, both**

`plate_keypad/lib/src/plate_keypad.dart:194`:

```dart
          Positioned.fill(child: _buildLettersLayer(innerHeight)),
```

Unconditional. `_buildLettersLayer` (`:212-267`) computes `math.sqrt(...).ceil()`, copies the alphabet
list, pads it with blanks, and builds a `_KeyGrid` of up to 30 keys — **even when `showLetters` is false
and the layer is translated off-screen**. Each key is a `Builder` → `GestureDetector` → `AnimatedScale`
→ `AnimatedContainer` → `Text`, so a Persian or Palestinian alphabet costs roughly 150 widgets built and
laid out for something invisible.

And the pad rebuilds more often than you would think: `activeAlphabet` changes every time focus moves
between a digit slot and a letter slot, which is *during typing*.

Gate it. Keep the layer mounted only while it is or might become visible:

```dart
  if (_controller.isDismissed && !widget.showLetters) {
    // Nothing to draw and nothing sliding: don't build 30 keys off-screen.
  } else
    Positioned.fill(child: _buildLettersLayer(innerHeight)),
```

The pad's fixed `innerHeight` (`:166`) already guarantees the layout does not shift when the layer
appears, so mounting it late is safe — verify that claim holds after the change.

### A4 — an `AnimatedBuilder` rebuilds every frame to flip a bool twice — **M, mid-animation**

`plate_keypad.dart:261-266`:

```dart
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          IgnorePointer(ignoring: _controller.isDismissed, child: child),
      child: slide,
    );
```

`isDismissed` changes exactly twice per slide, at the ends. This rebuilds an `IgnorePointer` on all
~16 frames in between. The `child:` parameter correctly keeps `slide` out of the rebuild, so the cost is
small — but it is per-frame cost during the exact animation being complained about, and it is free to
remove: drive `ignoring` from `AnimationStatus` in a listener, or from `showLetters` plus the status.

### A5 — up to 42 implicit animations can start at once, mid-typing — **M, mid-animation**

`plate_keypad.dart:412-431`: every key wraps an `AnimatedScale` around an `AnimatedContainer`. That is
two implicit `AnimationController`s per key, 84 across a full pad.

`AnimatedContainer` animates a `BoxDecoration`, and decoration lerp is not cheap. Now look at what
triggers it: `enabled` comes from `_keyEnabled` (`:206-210`), which reads `widget.activeAlphabet`. When
focus moves from a digit slot to a letter slot, `activeAlphabet` changes and **every key whose
membership changed starts a simultaneous 180 ms decoration tween**. That fires while the user is typing,
which is when the slide animation is most likely to also be running.

Options, cheapest first:

1. Animate colour only, not the whole decoration — `AnimatedContainer` → a `DecoratedBox` whose border
   colour comes from a `TweenAnimationBuilder<Color>`, or an `AnimatedDefaultTextStyle`-style narrow
   tween. Same look, far less lerp.
2. Drop `AnimatedScale` on the disabled transition and keep it only for the 90 ms press flash, which is
   the one a user actually perceives.
3. Consider whether the grey-out needs to animate at all. The comment at `:405-407` argues it should
   "read as a deliberate fade rather than a snap" — that is a design call, and it is the user's to make.
   **Ask before changing it.**

### A6 — per-build allocations in the pad's hot path — **M, mid-animation**

| Line | Allocation | Frequency |
|---|---|---|
| `:169` | `_rows.expand(...).toList()` — a fresh 12-element list | every pad build |
| `:230-233` | `[...alphabetLetters]` plus a `while` loop padding blanks | every pad build |
| `:408` | `Duration(milliseconds: …)` | every key, every build |
| `:428` | `theme.keyBorder.withValues(alpha: theme.keyBorder.a * 0.5)` | every disabled key, every build |
| `:311` | a `Builder` element per grid cell | 42 extra elements |

None is individually serious. Together, at 42 keys × 60 fps, they are exactly the kind of steady garbage
the file's own comment at `:118-122` says was already removed once from the slide tween. Hoist the two
lists to `late final` fields keyed on the alphabet, make the three `Duration`s `static const`, precompute
the dimmed border colour in `PlateKeypadTheme`, and drop the `Builder` (compute the label inline).

### A7 — the Yemen stipple is 46 widgets rebuilt every canvas build — **M, both**

`yemen_plate/lib/src/unified_plates.dart:159` declares 24 `PlateRule`s and `:276` declares 22 more.
`plate_canvas.dart:345-349` turns each one into a `_Placed` → `Positioned` → `ColoredBox`. So every
build of a unified plate constructs, lays out and paints **46 widgets to draw a dotted line**.

A run of identical rects is a painter, not a widget tree. `PlateFrame` already proves the pattern in this
codebase (`plate_frame.dart:31`, a single `CustomPainter` explicitly chosen over "nested bordered
containers or clippers"). Give `PlateCanvas` one `CustomPaint` for `spec.rules` — they are static
geometry in a fixed colour and never rebuild for any reason other than a theme change.

This is **P3B-adjacent**: P3B changes how the stipple is *declared*, this changes how it is *drawn*. They
do not conflict, and either order works.

### A8 — first-frame asset cost, never precached — **H, start-of-animation**

Nothing in this workspace calls `precacheImage` or warms an SVG.

| Asset | Package | Cost on first paint |
|---|---|---|
| `Flag_of_Iran.svg` | iran_plate | flutter_svg parse + rasterise |
| `Flag_of_Germany.svg` | germany_plate | same |
| `Flag_of_Palestine.svg`, `Flag_of_Palestine_vertical.svg` | palestine_plate | same |
| `de_inspection_sticker.png`, `de_state_seal.png` | germany_plate | image decode |
| `palestine_watermark.png` | palestine_plate | image decode |

`PlateFlag` (`plate_flag.dart:32-43`) builds `SvgPicture.asset` inline, so the first frame that shows a
plate pays the parse. If a plate first appears *as* an animation begins — a card sliding in, a spec
switching — that parse lands inside the animation's first frame. That is a precise match for "lag at the
start".

The fix belongs in the **host**, not in core: a gallery or demo screen precaches the flags and decals for
the countries it is about to show, in `didChangeDependencies`. Core should document the requirement on
`PlateFlag` rather than take a caching responsibility it cannot scope.

### A9 — a `TextEditingController` is mutated during build — **L, correctness-adjacent**

`plate_canvas.dart:596`: `_SlotBinding.build` calls `machine.syncController(index, value)` inside a
`ValueListenableBuilder`'s builder. It is guarded (`if (field.text == text) return`) and the comment
argues the ordering is safe. It is still a `ChangeNotifier` mutation during build, which can mark
something dirty and schedule an extra frame. Low priority, but if the profile shows an unexplained
second build pass per keystroke, this is where to look.

### A10 — `_PlateFaceClipper` allocated per build — **L**

`plate_canvas.dart:331`. `shouldReclip` compares fields so no clip is recomputed, but a `CustomClipper`
is allocated on every build. Hoist alongside A1.

---

## Scope

**In:**
- `core_plate/lib/src/widgets/plate_canvas.dart` — A1, A7, A10.
- `core_plate/lib/src/widgets/plate_flag.dart` — A8, documentation only.
- `plate_keypad/lib/src/plate_keypad.dart` — A3, A4, A5, A6.
- `palestine_plate/example/lib/main.dart` (and `yemen_plate/example/lib/main.dart` if it shares the shape)
  — A2.
- A precache call in whichever host screen is being profiled — A8.
- `core_plate/test/plate_canvas_rebuild_test.dart` — new, see below.

**Out — frozen:**
- **`PlateCanvas`'s subscription architecture.** The per-slot `ValueListenableBuilder` bindings, the
  resolved-once `behaviors` list, the `_MirrorBinding`/`_FrameBinding` narrowing and the post-frame
  active-index announcement are the reason a keystroke is cheap. This phase makes *builds* cheaper; it
  does not change *what rebuilds*. If a fix here would widen a subscription, it is the wrong fix.
- **`_PlateFaceClipper`'s `_overlap = 0.75`.** That constant kills a hairline seam at the border/panel
  boundary under the outer `FittedBox`. It is a rendering correctness value, not a performance knob.
- **`PlateFrame`'s painter.** Already the right shape.
- **Any visible change to timing or easing** — `kPlateKeypadSlide` (260 ms), the 90/160/180 ms key
  durations, `Curves.easeOutCubic`, `Curves.easeOut`. A5 option 3 proposes removing an animation; that is
  a design decision and needs the user's answer before it is made.
- **`plate_number_holder/`.**

---

## The measure–fix–remeasure loop

**This phase cannot be completed from the source alone.** Ten candidates are listed; the profile decides
which two or three actually matter, and whether there is an eleventh nobody has read. The developer runs
Flutter tooling in Android Studio; this phase is written to hand them exact commands and ask for exact
artefacts back.

### Step 1 — establish the baseline. ASK THE USER TO RUN THIS.

> Please run the app in **profile mode** on a real device (not an emulator — emulator raster timings are
> meaningless), reproduce the lag, and send back the two numbers below.

```bash
cd ~/StudioProjects/plate/palestine_plate/example   # or plate_gallery after P10
flutter run --profile -d <your-device-id>
```

Then in Android Studio: **View → Tool Windows → Flutter Performance**, tick *Track widget builds*, open
**Flutter DevTools → Performance**.

Reproduce each symptom separately and record the frame chart for each:

1. **Start-of-animation lag** — open the screen, then trigger the keypad letters slide for the first time.
2. **Mid-animation lag** — trigger the slide again and type two or three characters while it is running.

For each, report:
- the worst **UI thread** frame time and the worst **raster thread** frame time (DevTools shows both);
- whether the tall bars are blue/UI or green/raster.

**That single distinction decides everything that follows.** UI-thread jank means Dart work — A1 through
A6 and A9. Raster-thread jank means painting or shader work — A7, A8 and shader warm-up, and the Dart
fixes will not help.

### Step 2 — attribute it

If **UI thread**: in DevTools, expand the worst frame's *Build* section and read which widgets rebuilt.
Ask for a screenshot or the exported timeline JSON. Then check against A1–A6: a `PlateCanvas` build in
the trace confirms A1; a `_DemoState` build confirms A2; a `_KeyGrid` build while the letters layer is
hidden confirms A3.

Add this temporarily to `main()` to get numbers without the UI:

```dart
SchedulerBinding.instance.addTimingsCallback((timings) {
  for (final t in timings) {
    if (t.totalSpan > const Duration(milliseconds: 17)) {
      debugPrint('JANK build=${t.buildDuration.inMicroseconds}us '
                 'raster=${t.rasterDuration.inMicroseconds}us');
    }
  }
});
```

Remove it before the phase ends.

If **raster thread**, and specifically if the very first run of an animation is bad and every subsequent
run is fine, that is shader compilation. Confirm it and say so explicitly:

```bash
flutter run --profile --trace-skia
```

Whether this is even possible depends on the renderer — Impeller precompiles and does not have this
problem; Skia does. **ASK THE USER:** *does the app run on Impeller or Skia?* (`flutter run -v` prints
the renderer; on Android, Impeller is default on recent Flutter.) If Skia, the fix is SkSL warm-up:

```bash
flutter run --profile --cache-sksl --purge-persistent-cache   # exercise every animation, then:
flutter build apk --bundle-sksl-path flutter_01.sksl.json
```

If Impeller, shader jank is ruled out and the raster cost is real painting — go to A7 and A8.

### Step 3 — fix, one candidate at a time

Apply **one** fix, rebuild in profile mode, and ask the user to re-run the same two reproductions and
report the same two numbers. One at a time is not pedantry here: A1 and A2 both reduce canvas builds, so
fixing both at once tells you nothing about which mattered.

Order: **A1 → A2 → A3 → A8 → A7 → A4 → A6 → A5.** That is expected-payoff order, and the first four are
also the four safest.

### Step 4 — pin it with a test

Frame timings are not testable in CI, but rebuild *counts* are, and every candidate above is ultimately
a rebuild-count problem. Add `core_plate/test/plate_canvas_rebuild_test.dart`:

- Pump a `PlateCanvas` over a controller, count `PlateCanvas` builds with a build-counting wrapper,
  write one character, and assert the canvas itself rebuilt **zero** times (only the one `_SlotBinding`
  did). This is the invariant A2 violates and the one most likely to silently regress.
- Assert that `ThemeData.light()` is not reconstructed when the theme has not changed — expose a
  debug-only build counter, or assert `identical()` on the cached `ThemeData` across two pumps.
- For the keypad: pump with `showLetters: false` and assert `find.byType(_KeyGrid)` matches **one**, not
  two. That is A3, and it is a one-line guard against it coming back.

---

## Verification

```bash
cd ~/StudioProjects/plate

(cd core_plate && flutter test && flutter analyze --no-fatal-infos)
(cd plate_keypad && flutter analyze --no-fatal-infos)
(cd palestine_plate && flutter test)      # golden byte-identical — no visual change

# No animation timing constant moved.
git diff -- '*plate_keypad.dart' | grep -E '^[-+].*(milliseconds|Curves\.|Duration\()'
#   -> only const-hoisting, no changed numbers

# The canvas still narrows the same way.
git diff -- core_plate/lib/src/widgets/plate_canvas.dart | grep -E '^[-+].*ValueListenableBuilder'
#   -> no output
```

**And the measurement, which is the actual acceptance test. ASK THE USER:**

> Re-run both reproductions in profile mode and report the worst UI and raster frame times.

**Success:**
- Worst-frame UI time during the letters slide is under 16 ms on the target device, with no keystroke
  spike.
- The first run of the slide is no worse than the second.
- The Palestine golden is byte-identical and no animation duration or curve changed.
- Every fix applied is one of A1–A10, or is a documented eleventh found in the profile.
- `plate_canvas_rebuild_test.dart` passes and would fail if A2 or A3 returned.

If the profile shows the dominant cost is none of A1–A10, **stop and report that**. Ten candidates
found by reading are a starting hypothesis, not a diagnosis, and shipping fixes for problems the profile
did not confirm is how a performance phase makes a codebase worse.

---

## Dependencies

P1 (engine tests). Benefits from P10 — profiling one gallery app beats profiling four demos — but does
not require it; if the lag is reproducible today, measure it today.

A7 touches the same rules the P3B phase re-declares; run them in either order, they do not conflict.

## Line estimate

`plate_canvas.dart` +25 −10 · `plate_keypad.dart` +30 −25 · `palestine_plate/example` −20 +15 ·
precache +12 · docs +15 · new test +85. **Net ≈ +130, of which 85 is the test.**

This is the one phase in the roadmap that adds lines on purpose. Caching, gating and narrowing all cost
code; they buy frames.
