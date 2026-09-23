# sk7 — The Showcase stat band, computed from the registry

**Model: Sonnet 5 · medium thinking on.**

---

Repo: `~/StudioProjects/plate/plate_number_holder`, branch `newdesign-nocturne`.
Read `lib/screens/gallery/catalogue.dart`, `catalogue_index.dart`,
`lib/screens/gallery/sources/*.dart`, and the stat-band markup at the bottom of
the Showcase section in `design_ref/Plate Gallery.dc.html`.

## What the design specifies

A full-bleed band pinned to the bottom of the 100vh Showcase section: four equal
columns separated by `1px divider` verticals, each cell padded generously, each
showing a very large number in Archivo w800 (~52px, `n100`) above a MartianMono
uppercase label (+0.12em, `n500`). At `max-width: 760px` it becomes two columns.

The design's four tiles read `5 PACKAGES · 7 COUNTRIES · 51 SPECS · 2 FORM FACTORS`.

## The important part: the numbers are ours, not the design's

**Do not hardcode 5 / 7 / 51 / 2.** Compute all four from the catalogue registry at
build time, so they stay true as packages come and go:

- **PACKAGES** — count of country packages the app depends on and draws
  (`iran_plate`, `palestine_plate`, `yemen_plate`, `lebanon_plate`,
  `germany_plate`). Derive it from the registry, not from `pubspec.yaml`.
- **COUNTRIES** — distinct countries represented, which is *not* the same as
  packages: `iran_plate` also ships Bahrain and Azerbaijan. Count the distinct
  country blocks across every catalogue entry.
- **SPECS** — distinct `PlateSpec`s across all packages.
- **FORM FACTORS** — distinct vehicle form factors (car / motorbike / bicycle …).
  If the registry does not model this today, add a minimal derivation rather than
  a constant, and say in the report exactly where the data comes from.

Put the derivation in `lib/screens/gallery/catalogue_stats.dart` as a small
`CatalogueStats` value type with a `CatalogueStats.of(catalogue)` factory, and
**cover it with a unit test** in `test/catalogue_stats_test.dart` asserting each
count against the current registry. That test is what stops the numbers silently
drifting.

Note: the live site currently shows `5 countries / 13 systems / 67 plates` on
Discover while the design shows four different metrics on Showcase. Both are
fine — Discover's own header stats are sk11's problem. Keep the design's four
*labels* here and make the *values* real.

## Do this

- `lib/screens/showcase/stat_band.dart` → `StatBand`, consuming `CatalogueStats`.
- Slot it into the `1fr auto` grid's bottom row in `showcase_screen.dart`.
- Dividers between cells are **solid** 1px `divider`, not `NRule` — they are box
  separators, and Nocturne's fade applies only to freestanding rules.
- Two columns under `NBreak.stats` (760).

## Do not

- Do not reach into a country package's internals to count things; go through the
  catalogue the gallery already builds.
- Do not animate the numbers counting up. The design has no such motion.

## Gate

`flutter analyze` clean · `flutter test` passes (including the new test) ·
`flutter build web` succeeds.

Report the four computed values and where each came from.

Commit: `newdesign: sk7 stat band`.
