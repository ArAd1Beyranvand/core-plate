---
name: mv0-recon-spec
description: MV0 — read the exported design and the current mobile code, write MOBILE_SPEC.md that maps every design block to a file, a data source and a token. No Dart edits.
model: Sonnet 5.5, medium reasoning with thinking
---

# MV0 — Recon & spec freeze

## Context (assume nothing else)

`plate_number_holder` is the Plate Gallery showcase app. On narrow widths it shows a mobile body:
header (`PLATE GALLERY` · `DESKTOP VIEW`), hero (author line, "Plate input for Flutter.", Browse plates /
View on pub.dev), a device frame, stacked callout cards (RULES / CONTROLLER / STATE …), a 2×2 stats grid
(11 PACKAGES / 16 COUNTRIES / 140 SPECS / 2 FORM FACTORS) and a bottom tab bar (SHOWCASE / DISCOVER / ABOUT).

The new design (`claude/mobile_view/design/plate_gallery.html`) replaces that body with:

1. **Header** — `— PLATE GALLERY` left, `01 / SHOWCASE` right (page index / tab name).
2. **"ONE PLATE PER PACKAGE · SWIPE →"** — horizontal carousel, one card per package: real plate,
   country name, spec id in mono (`ir.car`); next card peeks at the right edge.
3. **"WHAT IT DOES · <DEVICE> PREVIEW"** — a story deck: segmented progress bar split into three groups
   (Mobile / Tablet / Desktop), auto-advance every 4 s, tap right half = next, left half = back, tap a
   segment = jump. Card: glowing accent mark top-left, mono label (`SCALE`), large title, huge outlined
   two-digit numeral bottom-right (slashed zero). Below: `09 / 09` and `TAP TO ADVANCE`.
   The device frame changes to match the card's device group; chips jump to a group's first card.
4. **"THE ARCHIVE, REGISTERED"** — stats as a licence-plate strip: `PG` band with a ring on the left,
   cells PKGS / COUNTRIES / SPECS / FORMS, `ایران / MIT` corner; caption `IRAN MADE · OPEN SOURCE` and
   `V1 · 2026`.
5. **Tab bar** — same three tabs, active tab gets a short accent bar above its label.

## Steps

1. If `design/plate_gallery.html` is missing → **stop and ask**. Do not work from screenshots.
2. Extract from the HTML: every colour, font family/size/weight/letter-spacing, radius, border, spacing,
   timing (the 4 s dwell, any easing). Record design px and the design's frame width.
3. Locate the current mobile path: the breakpoint that selects it, the widget that composes it, the
   widgets for hero / callout cards / stats grid / tab bar / header. `grep -rn` multi-term, re-run
   fresh, `view_range` around hits.
4. Locate the data: where package/country/spec counts are computed, where callout copy lives
   (`calloutSets` or successor), how the device cycle exposes the current device and whether it can be
   driven externally. Do not modify — record.
5. Resolve and record these open questions explicitly (answer from the HTML; if the HTML is silent,
   write `ASK USER` and stop the migration plan at that point):
   - Is the hero (title + buttons) kept above the carousel, moved, or dropped?
   - Where does the device frame sit relative to the deck, and where are the Mobile/Tablet/Desktop chips?
   - Where does the `DESKTOP VIEW` affordance go now that the header shows `01 / SHOWCASE`?
   - Feature count per device group in the real data vs. the design's 3+3+3.

## Deliverable — `claude/mobile_view/MOBILE_SPEC.md`

Sections: tokens table · block → new file → data source table · current-file inventory (keep / delete /
rewrite) · open-question answers · breakpoint · the real stat values. Under 250 lines.

## Out
Every `.dart` file. This session writes markdown only.

## Verify
`git status` shows only `MOBILE_SPEC.md`. Commit.

(SEE IF NEW BRANCH NEEDED OR NOT, IN BOTH SITUATIONS COMMIT YOUR WORK!)
