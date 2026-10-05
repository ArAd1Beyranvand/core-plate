"""Stage 3: everything about a new package that is boilerplate — no model.

Writes the package skeleton, the README (fixed template, one epithet), the
library export file, the golden-test harness, the workspace and gallery
registrations. What it does *not* write is the part that needs judgement:
`_plates.dart` (layout and builders), the validators' rules, and the
gallery labels. Those get stubs with the measured numbers pasted in as
comments, so the LLM starts from data rather than from a blank file.
"""
from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

DONOR = 'vietnam_plate'  # the newest package; its boilerplate is current


def snake(country: str) -> str:
    return re.sub(r'[^a-z0-9]+', '_', country.lower()).strip('_')


def pascal(country: str) -> str:
    return ''.join(w.capitalize() for w in re.split(r'[^A-Za-z0-9]+', country) if w)


README = '''FREE PALESTINE 🇮🇷🇵🇸 پاینده ایران

GO VEGAN 🌱

==================================

From the mighty people of Iran to the {epithet}people of {Country} to view examples:

https://platexample.ir/#/discover/{slug}

# {pkg}

{Country}'s licence plates for [`plate_core`](https://pub.dev/packages/plate_core) — {summary}

```dart
import 'package:plate_core/plate_core.dart';
import 'package:{pkg}/{pkg}.dart';

PlateCanvas(
  spec: {P}Plates.{first},
  theme: {P}Themes.{first_theme},
  validator: const {P}Validator(),
  autoValidate: true,
);
```

'''

LIBRARY = '''/// {Country}'s licence plates for the `plate_core` library.
///
/// {summary}
library;

export 'src/{s}_colors.dart';
export 'src/{s}_country.dart';
export 'src/{s}_themes.dart';
export 'src/{s}_plates.dart';
export 'src/{s}_validators.dart';
export 'package:plate_alphabet/plate_alphabet.dart' show {P}Alphabets;
'''

PUBSPEC = '''name: {pkg}
description: "{Country}'s licence plates for the plate_core library — {summary}"
version: 0.1.0
publish_to: none
resolution: workspace

environment:
  sdk: '>=3.10.0 <4.0.0'
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  plate_core: ^0.11.5
  plate_alphabet: ^0.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
'''

GOLDEN_TEST = '''import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{pkg}/{pkg}.dart';
import 'package:plate_core/plate_core.dart';

/// One golden per category, drawn with real bold faces so the ink can be
/// measured against the references (`platekit golden-check`).
///
/// Regenerate with `flutter test --update-goldens` after a deliberate change.
void main() {{
  setUpAll(() async {{
    final FontLoader loader = FontLoader('Roboto');
    for (final String path in const <String>[
{fonts}
    ]) {{
      final File face = File(path);
      if (!face.existsSync()) continue;
      loader.addFont(face.readAsBytes().then((b) => ByteData.view(b.buffer)));
    }}
    await loader.load();
  }});

  /// category id -> (spec, theme, space-separated sample value)
  final Map<String, (PlateSpec, PlateTheme, String)> cases =
      <String, (PlateSpec, PlateTheme, String)>{{
{cases}
  }};

  for (final MapEntry<String, (PlateSpec, PlateTheme, String)> c
      in cases.entries) {{
    testWidgets(c.key, (tester) async {{
      final (PlateSpec spec, PlateTheme theme, String values) = c.value;
      final PlateController controller = PlateController.fromValues(
        spec,
        values.split(' '),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 680,
                height: 300,
                child: PlateThemeScope(
                  theme: theme,
                  child: PlateView(
                    controller: controller,
                    theme: theme,
                    country: {P}Country.{lc},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(PlateView),
        matchesGoldenFile('goldens/{cc}_${{c.key}}.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }});
  }}
}}
'''

GALLERY_RENDER_TEST = '''import 'package:plate_core/plate_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_number_holder/screens/gallery/sources/sources.dart';

void main() {{
  testWidgets('every {Country} entry renders with its own theme', (t) async {{
    final source = gallerySources.whereType<{P}Source>().single;
    for (final section in source.sections) {{
      for (final e in section.entries) {{
        final c = PlateController.fromValues(e.spec, e.sampleValues!);
        await t.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 460,
              height: 130,
              child: PlateView(controller: c, theme: e.theme!, country: e.country),
            ),
          ),
        );
        expect(t.takeException(), isNull, reason: e.id);
        expect(e.sampleValues!.length, e.spec.slots.length, reason: e.id);
        expect(
          e.validator!
              .validate(PlateEntry(spec: e.spec, values: e.sampleValues!))
              .isValid,
          isTrue,
          reason: e.id,
        );
        await t.pumpWidget(const SizedBox.shrink());
        c.dispose();
      }}
    }}
  }});
}}
'''


def _newest_readme(root: Path) -> str:
    """The country README with the longest "Also available" list is the
    most recent one; each new package adds itself to its own list only."""
    readmes = [p.read_text() for p in root.glob('*_plate/README.md')]
    readmes = [r for r in readmes if '## Also available' in r]
    return max(readmes, key=lambda r: r.count('\n- [`'))


def _also_available(root: Path, pkg: str, Country: str) -> str:
    donor = _newest_readme(root)
    block = donor[donor.index('## Also available'):]
    entry = f"- [`{pkg}`](https://pub.dev/packages/{pkg.replace('_', '-')}) - {Country}'s licence plates."
    lines, out, done = block.rstrip('\n').splitlines(), [], False
    for line in lines:
        m = re.match(r'- \[`(\w+)`\]', line)
        if m and m.group(1) == pkg:
            done = True
        if not done and m and m.group(1).endswith('_plate') and m.group(1) > pkg:
            out.append(entry)
            done = True
        out.append(line)
    if not done:
        out.append(entry)
    return '\n'.join(out) + '\n'


def _register(path: Path, after_pattern: str, line: str) -> bool:
    """Appends `line` after the last line matching `after_pattern`, once."""
    text = path.read_text()
    if line.strip() in text:
        return False
    lines = text.splitlines()
    idx = max(i for i, l in enumerate(lines) if re.match(after_pattern, l))
    lines.insert(idx + 1, line)
    path.write_text('\n'.join(lines) + '\n')
    return True


def package(root: Path, country: str, code: str, *, epithet: str = '', summary: str = '',
            categories: list[dict] | None = None, fonts: list[str] | None = None,
            force: bool = False) -> list[str]:
    """Creates `<country>_plate`. Never overwrites an existing file unless
    `force`; returns the paths written."""
    s, P = snake(country), pascal(country)
    pkg = f'{s}_plate'
    d = root / pkg
    written = []

    def put(rel: str, content: str):
        p = d / rel
        if p.exists() and not force:
            return
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content)
        written.append(str(p.relative_to(root)))

    for f in ('LICENSE', 'analysis_options.yaml'):
        if not (d / f).exists():
            d.mkdir(exist_ok=True)
            shutil.copy(root / DONOR / f, d / f)
            written.append(f'{pkg}/{f}')
    gi = root / 'laos_plate' / '.gitignore'
    if gi.exists() and not (d / '.gitignore').exists():
        shutil.copy(gi, d / '.gitignore')
        written.append(f'{pkg}/.gitignore')

    summary = summary or 'TODO one sentence: categories, colours, themes, alphabets, advisory validator.'
    cats = categories or []
    first = cats[0] if cats else {'getter': 'private', 'theme': 'private'}
    put('pubspec.yaml', PUBSPEC.format(pkg=pkg, Country=country, summary=summary))
    put(f'lib/{pkg}.dart', LIBRARY.format(Country=country, summary=summary, s=s, P=P))
    readme = README.format(epithet=(epithet + ' ') if epithet else '', Country=country, slug=s.replace('_', ''),
                           pkg=pkg, summary=summary, P=P, first=first['getter'],
                           first_theme=first['theme'])
    put('README.md', readme + _also_available(root, pkg, country))
    fonts = fonts or ['/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf']
    put('test/golden_test.dart', GOLDEN_TEST.format(
        pkg=pkg, P=P, cc=code, lc=s.split('_')[0] if '_' not in s else s,
        fonts='\n'.join(f"      '{f}'," for f in fonts),
        cases='\n'.join(
            f"    '{c['id']}': ({P}Plates.{c['getter']}, {P}Themes.{c['theme']}, '{c['value']}'),"
            for c in cats) or f"    // One per category, e.g.\n"
                               f"    // 'private': ({P}Plates.private, {P}Themes.private, 'A B 1 2 3 4'),"))
    return written


def register(root: Path, country: str, code: str) -> list[str]:
    """Workspace member, gallery dependency, gallery render test."""
    s, P = snake(country), pascal(country)
    pkg = f'{s}_plate'
    done = []
    if _register(root / 'pubspec.yaml', r'  - \w+_plate$', f'  - {pkg}'):
        done.append('pubspec.yaml: workspace member')
    holder = root / 'plate_number_holder'
    if holder.exists():
        pub = holder / 'pubspec.yaml'
        text = pub.read_text()
        if f'  {pkg}:' not in text:
            text = re.sub(r'(\n  vietnam_plate:\n    path: \.\./vietnam_plate\n)',
                          rf'\1  {pkg}:\n    path: ../{pkg}\n', text)
            pub.write_text(text)
            done.append('plate_number_holder/pubspec.yaml: dependency')
        src = holder / 'lib/screens/gallery/sources/sources.dart'
        if _register(src, r"import '\w+\.dart';", f"import '{s}.dart';"):
            _register(src, r"export '\w+\.dart';", f"export '{s}.dart';")
            _register(src, r'  \w+Source\(\),', f'  {P}Source(),')
            done.append('sources.dart: import, export, registration')
        test = holder / f'test/{s}_gallery_render_test.dart'
        if not test.exists():
            test.write_text(GALLERY_RENDER_TEST.format(Country=country, P=P))
            done.append(str(test.relative_to(root)))
    return done


def stub_notes(out: Path, measurements: dict) -> str:
    """The measured numbers as a Dart doc-comment block for `_Layout`."""
    lines = ['/// Measured ink, as target for the goldens (platekit measure):', '///']
    for name, m in measurements.items():
        lines.append(f'/// * {name}: aspect {m["aspect"]}, field {m["field"]}, ink {m["ink"]}')
        for r in m['rows']:
            lines.append(f'///   row y {r["y"][0]}–{r["y"][1]}, x {r["x"][0]}–{r["x"][1]}, '
                         f'{len(r["runs"])} runs')
    text = '\n'.join(lines) + '\n'
    out.write_text(text)
    return text


def load_categories(path: Path) -> list[dict]:
    return json.loads(path.read_text())
