# sk8 — The floating callout cards

**Model: Opus 5 · low thinking on.** The existing callout machinery is good; this
is a restyle plus a content swap, not a rebuild.

---

Repo: `~/StudioProjects/plate/plate_number_holder`, branch `newdesign-nocturne`.
Read `lib/poster/callouts/callout_card.dart`, `callout_data.dart`,
`lib/poster/callout_motion.dart`, and the three floating cards in the Showcase
section of `design_ref/Plate Gallery.dc.html`.

## What the design specifies

Three cards float over the device stage. In the new design they are
`.pg-feat-card`-style panels:

```
border: 1px n800
border-radius: var(--radius-lg)   /* 14 */
padding: 16px 18px
background: linear-gradient(158deg, #1C2233, #0D1017)
```

Each card is: a MartianMono uppercase kicker (+0.12em) in `accent`, then a title in
Archivo w800 (~19–21px, `n100`), then optional body text in Archivo 13/1.5 at
`n400`.

The three cards and their kickers:

| Kicker | Title | Body |
| --- | --- | --- |
| `RULES` | Live validation | Forbidden district and serial combinations flare red as you type: before submit, not after. |
| `FEATURE` | Both plate input and its display | — |
| `SCALE` | Everything is customizable | — |

Take the exact strings from the design file. Positions: read them off the design's
inline styles and express them in the existing callout layout system rather than
absolute pixels, so they still track the device stage when the hero stacks.

The current app's cards are the blue bevelled `SoftPanel` / `BevelPanel` variety
with dashed rules and a coloured chip. All of that goes: **no bevel, no dashed
rule, no coloured number badge, no blue.** One hairline border, one gradient fill,
three text roles.

## Do this

- Retarget `callout_card.dart` at the Nocturne panel above. If `BevelPanel`,
  `SoftPanel`, `DashedRule` and `card_decorations.dart` end up with no callers,
  leave them on disk — sk15 sweeps them.
- Update `callout_data.dart` to the three cards above.
- Keep `callout_motion.dart` as-is unless the new geometry breaks it. The entrance
  motion (the design's `pg-rise`: 10px up, 0.4–0.5s ease, opacity 0→1) is close to
  what we already do; match the duration and offset to the design's keyframe and
  leave the rest.
- Under the 1180 breakpoint, where the hero stacks, the cards must not overlap the
  text column. Read what the mobile panel does with them in the design and follow
  it — if the design drops them into a plain stacked list (`.pg-feat`, a
  `gap: 10px` grid padded `0 18px 8px`), do exactly that.

## Do not

- Do not add a fourth card.
- Do not put a drop shadow on these. The design gives them a border and a gradient;
  the shadow belongs to the device mockup, not the cards.
- Do not touch the device frames.

## Gate

`flutter analyze` clean · `flutter test` passes · `flutter build web` succeeds.

Manual at 1440×900, 1100 and 390: no card overlaps the h1 or the buttons at any
width, and the kicker colour is `accent` not blue.

Commit: `newdesign: sk8 callout cards`.
