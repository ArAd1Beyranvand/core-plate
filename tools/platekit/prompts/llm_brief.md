## What is left for you

Everything above was produced offline: the article parsed into tables,
each photo fitted, flattened to plate units, measured and colour-balanced.
Trust the numbers over your own reading of a photo; open a photo only when
its fit says CHECK or the numbers contradict the article.

1. Group the categories into designs (one builder per design). Use the
   rows column: same row count and spans means one design.
2. Write `lib/src/{country}_plates.dart` — `_Layout` from the measured rows,
   one builder per design, glyph sizes from ink heights (glyph ≈ ink / 0.72).
3. Write the validators' rules from the table's format column.
4. Write the gallery labels and section notes.
5. Then run, in order: `pk.py analyze`, `pk.py test`, `pk.py goldens` —
   each prints only what failed.

Already done, do not redo: README, pubspec, library export, golden test
harness, workspace and gallery registration (`pk.py scaffold --register`).
