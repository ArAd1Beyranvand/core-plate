# Which parts of `/plate_creator` need an LLM?

A study made while building `laos_plate` (October 2026). For every sub-task
of the skill, the question was: could this be done without the LLM, by
deterministic code, by a structured template, or by a small local model?
The answers below come from doing the Laos plates by hand first, then
rebuilding each step as offline code in `tools/platekit` and running it
on the same article and photos. How to run it is in [README.md](README.md).

## Result in one table

Verdicts: **code** = deterministic, no model; **local** = a small local
model is good enough; **LLM** = needs the big model; **LLM, less** = still
the LLM, but with offline input that replaces most of what it used to read.

| # | Sub-task | Verdict | platekit | Evidence (Laos) |
|---|---|---|---|---|
| 1 | Fetch the article | code | `pk fetch` | 1 request, 122 KB HTML |
| 2 | Find size, format, colours, categories | code | `fetch.parse` | Infobox and the vehicle-type table parse into `facts.json` (6.6 KB) |
| 3 | Match each photo to its category | code | `fetch.parse` | Every image is a `/wiki/File:` link inside its own table row; 7 of 7 rows matched |
| 4 | Israel check | code | `fetch.parse` | First version gave a false "yes" from the navbox link; after removing navboxes: correct "no" |
| 5 | Resolve and download originals | code | `fetch.download` | 8 photos, 21 MB; one batched API call; needs 429 backoff |
| 6 | Province / region names | code | not in `pk` yet (one SPARQL query, done by hand for Laos) | 18 Lao province names in one call |
| 7 | Find the plate in a photo, fit the corners | code + review | `vision.find` | 5 of 8 clean; 2 bad fits flagged correctly; 2 slight cuts passed as ok (see below) |
| 8 | Bad fits | LLM, less | `corners_*.png` | The LLM reads 4 grid crops instead of a 4608 px photo |
| 9 | Perspective flatten to plate units | code | `vision.flatten` | — |
| 10 | Real plate size when the infobox is wrong | code | `cmd_photos` | Infobox 520 × 110 (aspect 4.7); photos median 2.43; plate is 340 × 150 (2.27). Detected automatically |
| 11 | Ink rows, glyph runs, spans | code | `vision.measure` | Provincial 2 rows, temporary 3, diplomatic 1: all match the manual pass |
| 12 | Field and ink colours | code | `vision.colours` | EV field `FFAC00` vs `FFAF00` by hand; the local model said "yellow" |
| 13 | Layout booleans (badge, rows, script, rotated text) | local | `pk ask`, `prompts/layout.md` | qwen3.5:4b: correct booleans in 26 s; wrong colour name; never used for numbers |
| 14 | Group categories into designs | LLM, less | `brief.md` rows column | Same row count and spans means one design; the LLM confirms |
| 15 | Write the spec builders (`_plates.dart`) | LLM | — | Judgement: slot groups, what is fixed and what is typed, edge cases |
| 16 | Validator rules | LLM | — | From the format column and prose; short |
| 17 | Package boilerplate, README, export, golden harness | code | `pk scaffold` | 7 files; the README is a fixed template plus one epithet |
| 18 | Workspace + gallery registration, render test | code | `pk scaffold --register` | 4 edits, all insert-after-pattern |
| 19 | Gallery labels and section notes | LLM | — | Prose |
| 20 | Golden glyph calibration | code | `pk calibrate` | `glyph × target / measured`: caption 40 → 34.4, prefix 48 → 86.6 / 69.3 |
| 21 | Golden vs photo comparison | code | `pk goldens`, `vision.compare` | Digit centres within 0.5 units; caption within 0.5 |
| 22 | Reading `flutter test` / `analyze` output | code | `pk test`, `pk analyze` | A holder overflow report is about 40 KB; the facts are 1 line |
| 23 | Finding the widget that overflows | code | `logfilter.overflow_probe` | Found the tile footer and breadcrumb culprits |
| 24 | Commit order across nested repos | code | `pk commits` | Holder and alphabet first, then the gitlink |
| 25 | Commit messages | LLM | — | Prose |

18 of 25 sub-tasks need no model at all, and one more (13) needs only the
local model. Six still need the LLM: 8 (only when a fit fails), 14, 15, 16,
19 and 25. For 8 and 14 its input is much smaller than before.

## What the LLM reads, before and after

| Material | Skill as written | With platekit |
|---|---|---|
| Article | 122 KB HTML (≈ 30 k tokens) | `brief.md`, 4.4 KB (≈ 1.3 k tokens) |
| Photos | 8 originals, 6 of them 4608 × 3456, opened one by one, often twice (zoom crops) | 1 contact sheet of flats, plus corner sheets for flagged fits |
| Measurements | the LLM wrote throwaway OpenCV scripts and read their output | already in the brief |
| Test output | full logs, tens of KB per failing overflow | one line per failure |
| Boilerplate | written token by token (README alone ≈ 2 KB) | 0, generated |

These figures are sizes, not a measured token bill. The number of
round-trips the LLM needs also drops, but it was not counted in this study.

## Architecture: before, while, after

```
        BEFORE (offline, no tokens)               WHILE (LLM writes)              AFTER (offline)
 ┌───────────────────────────────────┐  ┌──────────────────────────────┐  ┌──────────────────────────┐
 │ fetch   article → facts.json      │  │ reads brief.md + 1 sheet     │  │ analyze + test (reduced) │
 │ photos  fit/flatten/measure/colour│→ │ groups designs, writes       │→ │ goldens vs targets       │
 │ ask     local model, booleans     │  │ _plates.dart, validators,    │  │ commit plan              │
 │ brief   facts + numbers + flags   │  │ labels                       │  │ ↺ back to LLM if failing │
 │ scaffold boilerplate + register   │  │ after each edit: format +    │  └──────────────────────────┘
 └───────────────────────────────────┘  │ analyze that file (hook)     │
                                        └──────────────────────────────┘
```

In Claude Code this runs as three hooks (`hooks/`):

- `UserPromptSubmit` runs the "before" stage when the prompt contains a plates URL.
- `PostToolUse` on Edit/Write handles the "while" stage.
- `Stop` handles the "after" stage. It returns exit code 2 with the reduced report while something fails.

Outside Claude Code the same steps are plain `pk` commands.

## Where the local model fits, and where it does not

Tested with ollama on this machine: `qwen3.5:0.8b`, `qwen3.5:4b` (vision), `qwen3.5-9b`.

- **Good at:** yes/no and pick-one layout questions on a flattened plate. Examples: is there a badge, how many rows, is the top row a caption, is any text rotated. qwen3.5:4b answered all of these correctly on the Laos private plate in 26 s. The answers are constrained by ollama's JSON-schema mode, and any value outside the allowed set becomes `unknown` (`local_llm._validate`).
- **Bad at:**
  - Colours: it said "yellow" for `FFAF00`.
  - Positions, sizes and counts of characters.
  - Reading Lao script.

  Pixels are authoritative for all of these. The prompt forbids them, and the schema has no field for them.
- **Not needed for:** anything in the HTML. The structure is already there, so an LLM (local or not) would only add errors.
- **Resource note:** in the sandbox this study ran in, the vision call was killed (exit 137) on a later run. On a normal desktop session it completes. For that reason the step is optional and saves after each photo.

`tesseract` was also checked. It has no Lao data installed here, and plate fonts are hard for it anyway. Character identity is not needed for the build: the serial values in the goldens come from the article's captions and photos, which the LLM confirms.

## What the offline code got wrong (Laos run)

These are kept here because they show where the review step is still needed.

1. **Infobox size.** It says 520 × 110 mm, but the photographed plates are 340 × 150. The first flatten squashed every plate. *Fixed:* the fitted aspects now override the infobox when they disagree by more than 25 %, and the conflict is written to `size_conflict.json`.
2. **Missed images.** Tables were removed before images were collected, so only 5 images were found, 3 of them icons. *Fixed:* collect from the cleaned body and drop SVGs and maintenance boxes. Now 8 of 8, no icons.
3. **Israel false positive.** It came from the navbox. *Fixed* by removing navboxes before the scan.
4. **Non-repeatable fits.** k-means seeding was random. *Fixed:* seeded.
5. **Two bad fits passed as "ok".** The diplomatic plate's left edge is cut and the government plate's top is slightly cut. The aspect test (±8 % from the median) catches the larger cases only (taxable, police collage). **Open:** a check that the ink rows do not touch the flat's edge would catch both.
6. **Collage photo.** The police/defence image shows two plates on a vehicle. The fit picked one plate and included part of the mount; it was flagged. The LLM still decides which plate is which category.

## Things the skill should change

- Start every country with `pk all <Country> <code>` and read `brief.md` first.
- Never trust the infobox size without the photo aspect (item 1).
- Keep the golden harness and gallery registration generated. Only the builders, validators and labels are hand-written.
- Run tests through `pk test`. Full logs should only be read when the reduced report is not enough.
