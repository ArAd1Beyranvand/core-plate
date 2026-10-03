---
name: mv4a-feature-deck
description: MV4a — the "What it does" story deck as a self-contained widget: grouped segmented progress, 4 s auto-advance, tap zones, segment jump. No device sync yet.
model: Sonnet 5.5, high reasoning with thinking
---

# MV4a — Feature story deck (standalone)

Read `MOBILE_SPEC.md`, tokens, primitives, and the callout copy data file. Nothing else.

## Data
`const List<FeatureGroup>` — each group: `device` (mobile/tablet/desktop) + `List<FeatureCard>`
(`label`, `title`). Source the copy from the existing callout data (English side). Count comes from
data — **never hardcode 9**. Total index `i` runs `0..n-1` across groups.

## In
- `mobile/segmented_progress.dart` — `SegmentedProgress(groups, index, progress)`: one thin segment per
  card, larger gap between groups. Past = full accent, current = filled to `progress`, future = dim.
  Each segment is tappable (hit area ≥ 24 px tall even though it draws 2 px).
- `mobile/feature_deck.dart` — `FeatureDeck` (`StatefulWidget`):
  - one `AnimationController(duration: 4 s)`; on complete → next (wraps n-1 → 0).
  - `GestureDetector` over the card: tap x > width/2 → next, else previous. Tap a segment → jump.
    Any manual move restarts the dwell.
  - Long-press pauses (story convention); release resumes.
  - Card: accent mark top-left (short bar + soft glow via `BoxShadow`, inside its own padding so the
    snapshot/shadow clipping issue from P12C cannot bite), `MonoLabel(label)`, title, and the big
    numeral slot bottom-right. **For now the numeral is a plain outlined `Text`** (stroke paint,
    `'${i+1}'.padLeft(2,'0')`) — MV5 replaces it. Keep it isolated in one private class `_DeckNumeral`.
  - Card content change: `AnimatedSwitcher` on label+title keyed by index, fade+slight slide.
  - Footer row: `NN / NN` and `TAP TO ADVANCE`.
  - Exposes `ValueNotifier<int> index` / `onIndexChanged` and a `jumpTo(int)` via a small
    `FeatureDeckController` — MV4b binds to it.
- Pause the controller when not visible (`TickerMode` / app lifecycle) — no ticking off-screen.

## Out
Device frame, chips, body composition.

## Verify
`flutter analyze`. Scratch route: auto-advance, tap zones, segment jump, wrap-around, long-press pause.
Remove scratch route. Commit.

(SEE IF NEW BRANCH NEEDED OR NOT, IN BOTH SITUATIONS COMMIT YOUR WORK!)
