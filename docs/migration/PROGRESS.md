# Poster migration — progress

Run with `/task <n>`. One task per session, commit between each.

| # | Task | Done | Commit | Notes |
|---|------|------|--------|-------|
| P1 | Bootstrap & demolition | ☑ | deb30f1 | Landed together with P2 — neither half compiles alone. |
| P2 | Theme tokens & responsive metrics | ☑ | deb30f1 | Same commit as P1. |
| P3 | Bevel-panel primitives | ☑ | d72aba8 | |
| P4 | The road backdrop | ☑ | b58b6d4 | Grain drawn with `ui.ImageShader` + `saveLayer`, not `textureDecoration` — see below. `poster_scale.dart` gained `stageScale`/`sx`/`sy`. Backdrop wired into `showcase_screen.dart` ahead of P9. |
| P5 | Sweep light & ground shadow | ☑ | f3fc95c | Landed together with P6 — the gallery's `C` toggle and the bevel-panel fix below are shared by both. |
| P6 | Wordmark & page chrome | ☑ | f3fc95c | Same commit as P5. `poster_links.dart` uses bevel panels; `url_launcher` was not a dependency, so taps are a no-op (see below). |
| P7 | Callout content & cards | ☐ | | |
| P8 | Callout motion | ☐ | | |
| P9 | Responsive assembly & verification | ☐ | | |

## Open issues

- **P4 — `poster_textures.dart` was left alone deliberately.** Its `blendMode`
  becomes `ColorFilter.mode(Colors.white, blend)`, which recolours the tile
  instead of blending it against what is beneath, and `DecorationImage` has no
  blend-against-destination at all. Rather than edit it (which would have
  required a matching fix in P3's `bevel_panel.dart`), the backdrop painter
  draws its own grain with `ui.ImageShader` + `canvas.saveLayer`. If a later
  task fixes `poster_textures.dart` properly, `_paintGrain` in
  `poster_backdrop.dart` can collapse into it.
- **P4 — layer 10 seam.** `PosterBackdrop` takes a `sweep` widget, painted last
  over the dashes in stage coordinates, and exports `beamWedgePath()` for P5 to
  clip against. Nothing is drawn there yet.
- **P4 — verified geometrically, not from a rendered frame.** The wedge's top
  edge computes to 9.27° against rail 1's 9.26°, its bottom edge to 14.51°
  against rail 2's 14.5°, and the 11.8° dash line lands within ~7px of the
  wedge centreline at both `x=0` and `x=1920` — so the dashes lie on the beam
  and converge with it. The gallery and the app both build and run without
  exceptions, but no screenshot was captured for a human look; worth an eyeball
  before P5 builds the sweep on top of this geometry.
- **P5 — the `beamWedgePath()` seam went unused.** `poster_backdrop.dart`'s
  `PosterBackdrop.sweep` parameter and its "P5 can clip it to `beamWedgePath`"
  comment anticipated the sweep being handed in and clipped to the beam wedge.
  §6.10 of `DESIGN_SPEC.md` does not actually call for that clip, so
  `SweepLight` is instead composited as its own full-stage layer above
  `PosterBackdrop` (see `backdrop_gallery.dart`'s `_LiveStage`). The `sweep`
  parameter is still unused and its "Nothing here yet" comment is now stale —
  P9 should either wire `SweepLight` through it or delete the seam.
- **P5/P6 — `flutter analyze` clean and the gallery runs (`S`/`D`/`C` keys
  smoke-tested via `flutter run -d linux`), but no rendered screenshot was
  taken** (headless sandbox, no way to eyeball the diagonal wordmark cut, the
  stamp rotation, or the shadow skew signs against the spec). Worth a human
  look before P9.
- **P6 — bevel-panel grain assertion.** `_GrainLayer` in `cards/bevel_panel.dart`
  passes `backgroundBlendMode` to a `BoxDecoration` with no `color`/`gradient`,
  which asserts. Fixed by giving it a fully transparent `color`, which changes
  nothing visually — needed for `poster_links.dart`'s bevel-panel buttons.
