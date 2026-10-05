# platekit — run it yourself, from the beginning

The offline half of `/plate_creator`: everything up to "decide the design
and write the builders", and everything after it. Why it exists and what
each step saves is in [RESEARCH.md](RESEARCH.md).

Every command runs from the **workspace root** (`StudioProjects/plate`).
Examples use Laos (`la`); swap in any country and its two-letter code.

## 0. Once: install

```sh
python3 -m pip install -r tools/platekit/requirements.txt
alias pk='python3 tools/platekit/pk.py'      # optional, used below

# optional, for step 3 only
ollama pull qwen3.5:4b
ollama serve &                               # if not already running
```

Check: `pk --help` lists the subcommands.

## 1. Fetch — article, tables, photos (≈ 10 s, network)

```sh
pk fetch Laos la
```

Writes `.plateref/la/`: `art.html`, `facts.json` (infobox, size, every
table row with its image names, prose by section, the Israel check) and
`orig_*` — the original photos. Wikimedia rate-limits bursts; the fetcher
backs off by itself, so a pause is normal.

Look at: `facts.json` → `size_mm`, `mentions_israel`, `tables[0].rows`.

## 2. Photos — fit, flatten, measure, colour (≈ 30 s, CPU)

```sh
pk photos .plateref/la
# if the infobox size is wrong and you know the real one:
pk photos .plateref/la --size 340 150
```

Per photo it prints `ok` or `CHECK <reason>`, the fitted aspect, the
white-balanced field and ink colour, and the number of ink rows. It writes:

| file | what |
|---|---|
| `flat_<photo>.png` | the plate, perspective-corrected to plate units |
| `sheet_flat.png` | all flats on one image — **open this one** |
| `corners_<photo>.png` | zoomed corners with pixel grid, only for `CHECK` |
| `photos.json` | all numbers |
| `size_conflict.json` | only when the infobox size disagrees with the photos |

A `CHECK` means: open its `corners_` image, read the four corner pixels
off the grid and re-run that photo by hand (see "fixing a fit" below), or
ignore it if another photo shows the same design.

## 3. Ask — local model layout answers (optional, ≈ 30 s per photo)

```sh
pk ask .plateref/la          # skips photos already answered
pk ask .plateref/la --again  # re-ask all
```

Uses `prompts/layout.md` with ollama's JSON mode. Answers are categories
only (row count, badge side, script, separator, border, rotated text);
anything outside the allowed values is stored as `unknown`. Saved after
every photo, so stopping it half-way keeps what it did. Skip this step if
ollama is not running — nothing later depends on it.

## 4. Brief — the hand-off to the LLM

```sh
pk brief .plateref/la
```

`brief.md` (≈ 4 KB for Laos): infobox, the category table with each row's
photo, the prose, the per-photo numbers, which fits to distrust, and the
list of what is left for the LLM (`prompts/llm_brief.md`). Start the
`/plate_creator` session by telling it to read `brief.md` and
`sheet_flat.png` instead of the article.

## 5. Scaffold — the boilerplate

```sh
pk scaffold Laos la --epithet "resilient" \
   --summary "one sentence for README, pubspec and library doc" \
   --categories cats.json \
   --font /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf \
   --register
```

`cats.json` is `[{"id": "private", "getter": "private", "theme": "private", "value": "ຮ ຍ 8 1 1 8"}, …]`
(one per golden). Writes `laos_plate/` with `pubspec.yaml`, `LICENSE`,
`analysis_options.yaml`, `README.md` (template + alphabetical "Also
available"), `lib/laos_plate.dart` and `test/golden_test.dart`;
`--register` adds the workspace member, the gallery dependency, the
`sources.dart` lines and the gallery render test. Existing files are never
overwritten unless `--force`.

**Not** written: `lib/src/*_plates.dart`, `*_themes.dart`, `*_colors.dart`,
validators, the gallery source. That is the LLM's part.

## 6. While the LLM writes — the checks, reduced

```sh
pk analyze laos_plate        # one line per issue
pk test laos_plate           # only failing tests: expectation, overflow px, file:line
pk test plate_number_holder test/laos_gallery_render_test.dart
pk calibrate 40 270.5 232.5  # glyph that makes a 270.5-wide run 232.5 wide → 34.4
```

## 7. Goldens against the photos

```sh
cd laos_plate && flutter test --update-goldens test/golden_test.dart && cd ..
pk sheet .plateref/la/goldens.png laos_plate/test/goldens/*.png --crop
pk goldens laos_plate targets.json --size 340 150
```

`targets.json` maps golden stem → target rows from step 2, e.g.
`{"la_private": [{"name": "caption", "y": [14, 40], "x": [54, 286.5]}]}`.
It prints only rows that are off (`-v` prints all) and exits 1 if any are.

## 8. Commit order

```sh
pk commits
```

Dirty repositories innermost first (`plate_number_holder`, `plate_alphabet`
before the workspace), `build/` caches left out.

## Or all of 1–4 at once

```sh
pk all Laos la             # fetch → photos → ask → brief
pk all Laos la --no-ask    # without the local model
```

## Inside Claude Code: hooks

`hooks/settings.snippet.json` wires the same steps around the LLM. Merge
it into `.claude/settings.json` (project) to enable:

| hook | when | does |
|---|---|---|
| `before_prompt.py` | you send a prompt with a plates-article URL | runs `pk all`, tells the LLM to read the brief |
| `after_edit.py` | the LLM edits a `.dart` file | `dart format` + analyze that file; issues go straight back to it |
| `after_stop.py` | the LLM says it is done | analyze + test every changed package; failures send it back, success prints the commit plan |

They are not installed by default — try the steps by hand first.

## Fixing a fit by hand

```python
import cv2, sys; sys.path.insert(0, 'tools/platekit')
from platekit import vision
im = cv2.imread('.plateref/la/orig_X.jpg')
f = vision.find(im, seed=(x, y))               # a point inside the plate, or:
corners = [[x0, y0], [x1, y1], [x2, y2], [x3, y3]]   # tl tr br bl from corners_X.png
flat = vision.flatten(im, corners, 340, 340 / 150)
print(vision.measure(flat, 340, 150), vision.colours(flat))
```

## Layout

```
pk.py                 the CLI
platekit/fetch.py     article → facts.json, image download
platekit/vision.py    find, flatten, measure, colours, sheets, compare, calibrate
platekit/scaffold.py  package and registration templates
platekit/brief.py     facts + photos → brief.md
platekit/local_llm.py ollama, JSON-schema answers
platekit/logfilter.py flutter test / analyze → short report
platekit/gitplan.py   nested-repo commit order
prompts/              layout.md, same_design.md (local model), llm_brief.md (LLM)
hooks/                Claude Code hooks + settings snippet
```
