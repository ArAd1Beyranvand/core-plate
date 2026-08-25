# Poster assets

Extracted from `Plate Number Poster.html`. Drop the two folders into
`example/assets/` and register them in `example/pubspec.yaml` (prompt P1 does this).

## textures/
| File | Design tile | Opacity | Blend |
|---|---|---|---|
| bg_grain_a.png | 256px | .15 | normal |
| bg_grain_b.png | 320 / 250px | .44 / .62 | normal / overlay |
| tex_screen.png | 140–220px | .30–.60 | screen |
| tex_overlay.png | 200–240px | .14–.24 | overlay |

## fonts/
Variable TTFs converted from the design's own woff2 subsets — the `wght`, `wdth` and
`opsz` axes are intact, which matters because the design uses `wdth` heavily
(Archivo at 79 / 84 / 86 / 104).

| Family | Axes | Files |
|---|---|---|
| Archivo | wght 100–900, wdth 62–125 | latin, latin-ext |
| MartianMono | wght 100–800, wdth 75–112.5 | latin, latin-ext |
| Newsreader | wght 200–800, opsz 6–72 | latin, latin-ext |
| Vazirmatn | wght 100–900 | arabic, latin, latin-ext |

These are **subsets**. Flutter resolves fonts per family, not per Unicode range, so
register one file per family and accept the coverage, or fetch the full variable TTFs
from Google Fonts (all four families are there) and use those instead. For Vazirmatn
you want the full file — the Arabic and Latin subsets are separate here and the poster
needs both.
