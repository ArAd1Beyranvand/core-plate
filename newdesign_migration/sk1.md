# sk1 — Unpack the design reference, record a baseline, open the branch

**Model: Haiku 4.5 · thinking off.** This is mechanical: unzip, read, write a map.

---

You are working in `~/StudioProjects/plate/plate_number_holder` (a Flutter app in
the `plate` monorepo). We are migrating it to a new visual design.

## Do this

1. **Branch.** `git checkout -b newdesign-nocturne`. Confirm the tree is clean first;
   if it is not, stop and report what is dirty.

2. **Unpack the design.** `newdesign.zip` sits in the app root. Extract it to
   `design_ref/` (create it). Add `design_ref/` to `.gitignore` *except* keep the
   two HTML files and the `_ds/` folder tracked — they are the spec:
   ```
   design_ref/Plate Gallery.dc.html        # the design, with logic + mobile panel
   design_ref/Plate Gallery.export.html    # flat export
   design_ref/_ds/nocturne-*/styles.css    # base Nocturne design-system tokens
   design_ref/_ds/nocturne-*/readme.md     # what each DS class means
   design_ref/uploads/*.png                # reference screenshots
   ```
   Delete `design_ref/uploads/project/` after extraction — it is a stale copy of
   our own `lib/` and will confuse later sessions. Delete `newdesign.zip` from the
   repo root once extraction succeeds.

3. **Write `design_ref/MAP.md`.** Read `Plate Gallery.dc.html` and produce a
   navigation map for the sessions that follow. It must contain, for each of the
   four screens (Showcase, Discover, About, Plate detail) and both layouts
   (desktop and the `.pg-m` mobile panel):
   - the character offset range of that block in the file,
   - the outermost element's class and inline style,
   - a one-line description of what it renders.

   Also record: the `:root` token block offsets, the `<style>` block offsets, the
   `devicePresets()` JS function offsets, and the `pg-sidenav` / bottom-`nav`
   offsets. Later prompts will say "read the Discover block per MAP.md" — this file
   is what makes that cheap.

4. **Record the baseline** in `design_ref/BASELINE.md`:
   - output of `flutter analyze` (must already be clean — if not, note every issue),
   - output of `flutter test`,
   - whether `flutter build web` succeeds and how long it takes,
   - `find lib -name '*.dart' | wc -l` and total `wc -l lib/**/*.dart`,
   - the current route list from `lib/app/app_routes.dart`.

5. **Confirm the fonts.** `pubspec.yaml` should already declare Archivo,
   MartianMono, Newsreader and Vazirmatn with both `-latin` and `-latin-ext`
   subsets. Verify every declared asset file exists under `assets/fonts/`. If any
   is missing, say so loudly in `BASELINE.md` — **do not** add Google Fonts or a
   network font dependency; the design uses exactly these four families and they
   are supposed to be vendored already.

## Do not

- Do not touch anything under `lib/`. This prompt writes no Dart.
- Do not add any dependency to `pubspec.yaml`.
- Do not copy any plate artwork, plate geometry or plate colour out of the design
  file. The design's plates are drawn wrong. Ours stay.

## Gate

```
flutter analyze   # clean
flutter test      # pass
flutter build web # succeeds
```
Then `git add -A && git commit -m "newdesign: sk1 design reference + baseline"`.

Report: the MAP.md screen list, and anything in BASELINE.md that is not clean.
