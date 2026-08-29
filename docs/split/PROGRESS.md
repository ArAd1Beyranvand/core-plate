# Split progress

Phases are runnable prompts in `.claude/skills/`. Invoke one with `/p1-slot-identity` (or ask
for "run P1"). Plan and rationale: `PLAN.md` beside this file.

| | phase | skill | est. net lines | status | commit | actual |
|---|---|---|---|---|---|---|
| P0 | example → `plate_number_holder` | — | — | **done** | | |
| P0.5 | repo hygiene (README, dead assets) | `p0.5-repo-hygiene` | −9.6MB assets | todo | | |
| P0.75 | package template correction (android/linux/windows/web scaffolding) | `p0.75-package-template` | repo size only | todo | | |
| P1 | slot identity | `p1-slot-identity` | −70 | todo | | |
| P2 | plate geometry | `p2-plate-geometry` | −80 | todo | | |
| P3 | input model | `p3-input-model` | −60 | todo | | |
| P4 | input machine — **fixes a confirmed live bug, see PLAN.md §1** | `p4-input-machine` | ±0 | todo | | |
| P5 | value semantics | `p5-value-semantics` | −85 | todo | | |
| P6 | plate text | `p6-plate-text` | −35 | todo | | |
| P7 | validation as data | `p7-validation-as-data` | −60 (+−35 holder) | todo | | |
| P7.5 | district data (decision) | `p7.5-district-data` | varies | todo | | |
| P8 | country decoupling | `p8-country-decoupling` | −35 | todo | | |
| P9 | keypad compaction | `p9-keypad-compaction` | −90 | todo | | |
| P10 | core package | `p10-core-package` | ±0 | todo | | |
| P11 | country packages | `p11-country-packages` | ±0 | todo | | |
| P12 | keypad package + cutover | `p12-keypad-package-and-cutover` | ±0 | todo | | |

Baseline: `lib/` = 2 588 lines. Target after P9: ~2 075. Target core after P12: ~1 475.
P0.5 is independent of the line budget — it is a repo-hygiene pass, not a code refactor.

Fill in `actual` as you go — the gap between estimate and reality is the useful part.

## Order

Strictly linear P1 → P12, with four exceptions:

- **P0.5** depends on nothing and blocks nothing. Run it whenever — it touches `README.md` and
  `assets/`, not code any other phase edits.
- **P0.75** depends on nothing and blocks nothing. Repo-root platform-folder cleanup, no Dart
  source touched. Safe alongside P0.5.
- **P6** depends only on P2 and can be pulled forward for an early win.
- **P9** touches only `plate_keypad.dart`; it needs P8 (which removes the Persian defaults)
  but nothing else.
- **P7.5** depends on P7 (same file) but is a product decision, not a mechanical step — see
  its `SKILL.md` before running it. Ask the user; do not default to "wire it in."

## Do not skip P4's bug fix

Every other phase in this list is an improvement. P4 is that too, but it is also the fix for a
bug that is live in `plate_number_holder` today — confirmed by grep (zero `Key`s anywhere from
`DeviceFrame` to `PlateCanvas`), not assumed. See `PLAN.md` §1. If phases get reprioritized or
some are dropped, P4 should not be one of them.

## Gates

- P10 must not start until the P8 acceptance grep returns nothing.
- P10 and P12 each ask a question from `PLAN.md` §5 (package naming; publish or not). Settle
  them before starting the phase, not during it.

## Log

Append one line per phase as it lands: date, commit, anything the prompt got wrong. A phase
prompt that turned out to be inaccurate is worth correcting in its `SKILL.md` before the next
phase inherits the same mistake.
