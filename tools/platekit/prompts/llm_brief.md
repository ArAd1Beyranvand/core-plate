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
5. Write the gallery source `plate_number_holder/lib/screens/gallery/sources/{country}.dart`
   and fill the cases map in `test/golden_test.dart` (one line per category).

Already done, do not redo: pubspec, LICENSE, analysis_options, README
(only fix its summary line and the usage example), library export, the
golden test harness.

Done afterwards by `pk after`, do not do: gallery registration, the
gallery render test, goldens, the full test runs, the commit plan. To
check your code while writing, `python3 tools/platekit/pk.py analyze
<package>` is enough. Stop when the code above is written and analyzes
clean.
