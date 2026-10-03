# Mobile view migration — plate_number_holder

Port the new **Plate Gallery mobile design** (Claude Design canvas "Plate Gallery", 2 pages) into
`plate_number_holder`. Mobile body only. One skill per Claude Code session, `/clear` between them.
Every session ends with `flutter analyze` clean, the app running, and a commit.

**Before MV0:** export the design from Claude Design and drop it here as
`claude/mobile_view/design/plate_gallery.html`. Every skill treats that file as the source of truth for
layout and tokens. Screenshots are not enough — MV0 stops if the file is missing.

## Frozen for the whole migration

| Zone | Rule |
|---|---|
| `plate_number` / every `lib/` of the plate packages | Not one line. |
| Wide / desktop body (`_WideBody`, `CalloutRail`s, poster) | Unchanged. Mobile only. |
| `device_preview/**`, `plate_typist.dart`, `virtual_keypad.dart`, `device_cycle.dart`, `plate_display.dart`, `plate_backdrop.dart` | Frozen. Consume, never edit. |
| Numbers in the mockup (5 / 7 / 51 / 2) | **Mock data.** Real counts come from the catalogue (today: 11 / 16 / 140 / 2). |

## House rules (inherited from `CLAUDE.md`)

- No widget-returning functions — only real `StatelessWidget` / `StatefulWidget` classes.
- Variation is data: feature cards, package cards and stat cells are `const` lists, never `if` chains.
- **Tree shape is constant across animation frames** (P12C lesson): never swap `SizedBox` ↔ `Opacity` ↔ bare
  child by animation value; keep the wrapper, change its parameters.
- No `TextPainter.layout()` inside a per-frame `build`/`paint` — lay out once, cache.
- New mobile code lives under `example/lib/mobile/` (adjust to the real root MV0 finds).

## Phase index

| ID | Title | Files | Model | Level | Thinking | Depends |
|---|---|---|---|---|---|---|
| **MV0** | Recon & spec freeze | `MOBILE_SPEC.md` (new, no Dart) | Sonnet 5.5 | medium | **on** | — |
| **MV1** | Tokens & primitives | `mobile/mobile_tokens.dart`, `mobile/mono_label.dart`, `mobile/section_header.dart` | Sonnet 5.5 | low | off | MV0 |
| **MV2** | Shell: header + tab bar | `mobile/mobile_header.dart`, `mobile/mobile_tab_bar.dart` | Sonnet 5.5 | medium | off | MV1 |
| **MV3** | Package carousel | `mobile/package_carousel.dart` | Sonnet 5.5 | medium | **on** | MV1 |
| **MV4a** | Feature story deck (standalone) | `mobile/feature_deck.dart`, `mobile/segmented_progress.dart` | Sonnet 5.5 | high | **on** | MV1 |
| **MV4b** | Deck ↔ device frame sync | `mobile/feature_deck.dart`, mobile body only | Opus 5.5 | high | **on** | MV4a |
| **MV5** | Rolling outlined counter (01→09) | `mobile/rolling_numeral.dart` (new), 1 line in `feature_deck.dart` | Opus 5.5 | medium | **on** | MV4a |
| **MV6** | Archive plate strip (stats footer) | `mobile/archive_strip.dart` | Sonnet 5.5 | low | off | MV1 |
| **MV7** | Compose mobile body, delete old | mobile body in `showcase_screen.dart`, old mobile widgets | Sonnet 5.5 | medium | **on** | MV2–MV6 |
| **MV8** | Verify: goldens, perf, a11y | `test/mobile/**` | Sonnet 5.5 | medium | off | MV7 |

**Commit-before markers:** MV4b and MV7 (both touch shared, load-bearing files).

```
MV0 ─► MV1 ─┬─► MV2 ─────────────┐
            ├─► MV3 ─────────────┤
            ├─► MV4a ─┬─► MV4b ──┼─► MV7 ─► MV8
            │         └─► MV5 ───┤
            └─► MV6 ─────────────┘
```

MV2, MV3, MV4a, MV6 are independent once MV1 lands. If MV4b stalls, split it: **MV4b-i** (expose the
device cycle's current device + a `jumpTo` hook, Sonnet 5.5 medium) then **MV4b-ii** (bind deck to it).
