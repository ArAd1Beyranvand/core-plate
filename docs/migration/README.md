FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================


# Poster migration — task pack

Nine tasks, in order, split out of `docs/PROMPTS.md`. Each is self-contained:
Claude Code starts cold every session, so every task re-states the freeze rules
and points at `DESIGN_SPEC.md`.

**Scope:** the road, the theme, the text containers and the page chrome. The device
and everything on its screen — shells, plate, keypads, typist, scripts — do not change.

## Running

```
/task 1
```

That reads `docs/migration/P1.md`, does the work, verifies, commits, and ticks
`PROGRESS.md`. Repeat with 2 … 9. Commit between every task.

| # | File | Task | Run with | Budget option |
|---|------|------|----------|---------------|
| P1 | [P1.md](P1.md) | Bootstrap & demolition | **Sonnet 5 · medium** | Sonnet 5 · low |
| P2 | [P2.md](P2.md) | Theme tokens & responsive metrics | **Sonnet 5 · medium** | Sonnet 5 · low |
| P3 | [P3.md](P3.md) | Bevel-panel primitives | **Opus 5 · high** | Sonnet 5 · high |
| P4 | [P4.md](P4.md) | The road backdrop | **Opus 5 · high** | Sonnet 5 · high |
| P5 | [P5.md](P5.md) | Sweep light & ground shadow | **Sonnet 5 · high** | Sonnet 5 · medium |
| P6 | [P6.md](P6.md) | Wordmark & page chrome | **Opus 5 · medium** | Sonnet 5 · medium |
| P7 | [P7.md](P7.md) | Callout content & cards | **Sonnet 5 · medium** | Sonnet 5 · low |
| P8 | [P8.md](P8.md) | Callout motion | **Opus 5 · high** | Sonnet 5 · high |
| P9 | [P9.md](P9.md) | Responsive assembly & verification | **Opus 5 · xhigh** | Opus 5 · high |

## The one rule that matters

**The device is not part of this migration.** The design draws its own laptop, phone,
tablet, plates and keyboards — that is reference art, not a spec. Ignore its plate slot
counts, its German layout, its Persian digit strings, its keypad grids and its status
chip. `lib/`, `device_preview/`, the typist scripts, the keypad and `plate_display` all
stay exactly as they are.

What actually changes: the background becomes a lit road, the callouts become bevelled
panels with new copy, a display wordmark and page chrome arrive, and the device moves
from centre-stage to right-of-centre.

## Notes on running the pack

- **Commit between every task.** P8 and P9 are the most likely to need a second pass.
- **P3 and P4 are load-bearing.** If the bevel recipe or the beam wedge come out wrong,
  everything downstream inherits the error. Spend the extra turn there.
- **P9 is the hard one** — the tier architecture plus the freeze audit. It is also the
  only task that can catch a device-side regression, so don't skip its verification.
- If Claude ever proposes changing a plate spec, a typist script, a keypad layout
  or a device preset, that is the wrong answer — none of that is in scope.
