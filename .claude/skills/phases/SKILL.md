---
name: phases
description: "Index of the 14-phase plate monorepo refactor roadmap. Invoke when the user runs /phases, asks which phase to run next, or asks what the refactor plan is. Each phase is its own skill: p0, p1, p2, p3, p3b, p4, p5, p6, p7, p8, p9, p10, p11, p12."
---

# `/phases` — plate monorepo refactor roadmap

Fourteen phases, each self-contained, each leaving `flutter analyze` clean and every app running.
**Run one per session with `/clear` between them.** Evidence for every finding is in
`claude/AUDIT_DIAGNOSIS.md`; the narrative overview is `claude/REFACTOR_ROADMAP.md`.

Philosophy: **data structures first, behaviour second, surface last.** P0–P1 buy the safety net.
P2, P3, P3B fix the *types*. P4–P8 propagate them through behaviour. P9–P12 clean the surface.

| # | skill | what it does | Δ lines | model · level · thinking | requires |
|---|---|---|---|---|---|
| 0 | `/p0` | pub workspace; fix the `core_plate: ^0.1.0` constraints that would break every published consumer; capture the analyze/test baseline | ±0 Dart, −180 yaml | **Sonnet 5 · low · off** | — |
| 1 | `/p1` | the test suite `core_plate` has never had — 3,070 lines, zero tests today | **+530** | **Opus 5 · high · ON** | p0 |
| 2 | `/p2` | `PlateTheme.monochrome`; collapse 15 near-identical theme literals | −95 | **Sonnet 5 · medium · off** | p1 |
| 3 | `/p3` | `PlateCanvas.country` — make the country block a render-time input, like the theme already is | +75 | **Opus 5 · high · ON** | p1 |
| 3B | `/p3b` | register geometry primitives; fixes 3 arithmetic drifts nothing could catch | **−315** | **Opus 5 · high · ON** | p1 |
| 4 | `/p4` | collapse Yemen's 55 specs to 11 — 44 vary only in `id` and `country` | **−700** | **Opus 5 · high · ON** | p3 (p3b first if you can) |
| 5 | `/p5` | remove Palestine's 2 colour-clone specs | −70 | **Sonnet 5 · medium · off** | p3 |
| 6 | `/p6` | `isDigits` + `GatedPlateValidator`; 6 validators stop repeating one shape | −60 | **Sonnet 5 · medium · ON** | p1 |
| 7 | `/p7` | `PlateSpec.indicesOfGroup`; make Palestine's serial generator spec-driven | +10 | **Sonnet 5 · low · ON** | p1 |
| 8 | `/p8` | one text renderer, one no-op chooser; `ShowPlate` gains `theme:`/`country:` | −45 | **Sonnet 5 · low · off** | p1 |
| 9 | `/p9` | 3 dead deprecated symbols, ~2.8 MB of stale docs, every dangling doc reference | −140, −2.8 MB | **Sonnet 5 · low · off** | p2 p4 p5 p6 p7 p8 |
| 10 | `/p10` | one `plate_gallery/` app replaces four showcase apps | **−1,230** | **Opus 5 · high · ON** | p4 p5 p9 |
| 11 | `/p11` | goldens per country, the bloc binding test, shared lint base, publish rehearsal | +260 | **Sonnet 5 · medium · off** | all |
| 12 | `/p12` | the animation lag: 10 candidates + a measure-fix-remeasure loop | +130 | **Opus 5 · medium · ON** | p1 |

**Net ≈ −1,650 Dart lines** (12,449 → ~10,800), with test coverage rising 542 → ~1,515.

## Ordering

```
p0 ─► p1 ─┬─► p2 ────────────────────────┐
          ├─► p3b ─┐                     │
          ├─► p3 ──┼─► p4 ─┐             │
          │        └─► p5 ─┤             │
          ├─► p6 ───────────┤             ├─► p9 ─► p10 ─► p11
          ├─► p7 ───────────┤             │        │
          └─► p8 ───────────┘             │        └─► p12
```

`p2`, `p3`, `p3b`, `p6`, `p7`, `p8` are mutually independent once `p1` lands — run them in any order, or
in parallel worktrees. `p4` and `p5` are independent of each other; both need `p3`.

**`/p12` (animation lag) depends only on `/p1`.** It sits late in the diagram only because profiling one
gallery app beats profiling four demos — if the lag is reproducible today, pull it forward and measure it
today.

## Standing rules for every phase

1. **`plate_number_holder/` is out of scope for the entire roadmap.** Never read it, never build it,
   never add it to the workspace.
2. **Never hand-edit `pubspec.lock` or anything under `.dart_tool/`, `build/` or `*.iml`.** A phase may
   cause `flutter pub get` to regenerate a lockfile; that is fine.
3. **`plate_canvas.dart`'s subscription architecture is frozen** through p8. The per-slot
   `ValueListenableBuilder` bindings, the resolved-once `behaviors` list, `_PlateFaceClipper`'s
   `_overlap = 0.75` seam fix and the post-frame active-index announcement are load-bearing. A phase may
   *add* a parameter to `PlateCanvas`; none may restructure its build. (`/p12` may make builds cheaper —
   it still may not change *what* rebuilds.)
4. **Every phase ends green:**
   ```bash
   for p in core_plate core_plate_bloc plate_keypad iran_plate germany_plate palestine_plate yemen_plate; do
     (cd "$p" && flutter analyze --no-fatal-infos) || echo "FAIL: $p"
   done
   (cd core_plate && flutter test); (cd palestine_plate && flutter test)
   ```
5. **No behaviour change without a test that pins it.** After p1, any phase changing engine semantics
   adds or updates a test in the same commit.
6. **Do not consult prior plans.** `core_plate/docs/`, `REFACTOR_MANIFEST.md`, `PLATE_CONTROLLER_PLAN.md`
   and the root `PROMPT_*.md` files describe work that may or may not have happened; `/p9` deletes them.
   Until then, treat them as noise. The one exception is `/p12`, which is told to reconcile against
   `claude/ANIMATION_PERF.md` explicitly.
7. **One phase, one session.** `/clear` between phases.

## Before the first phase

The Palestine golden test may already be failing — `palestine_plate/test/failures/` holds four diff
images newer than `test/goldens/wb_modern_car_green.png`. `/p0` captures the true baseline and forces a
decision about it. **Do not start anywhere else.**

## If you are rationing Opus

Five phases want Opus: `p1`, `p3`, `p3b`, `p4`, `p10`. Of those, **`/p3b` and `/p4` repay it most** —
both are irreversible and both touch geometry that no test currently guards.
