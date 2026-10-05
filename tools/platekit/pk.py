#!/usr/bin/env python3
"""platekit — the offline half of the plate_creator skill.

    pk.py fetch    Laos la              article → .plateref/la/facts.json + originals
    pk.py photos   .plateref/la         find, flatten, measure, colour every photo
    pk.py ask      .plateref/la         local-model layout questions per photo
    pk.py sheet    out.png  a.png b.png contact sheet (one Read for many images)
    pk.py brief    .plateref/la         facts + photos → brief.md for the LLM
    pk.py scaffold Laos la              package boilerplate + registrations
    pk.py goldens  laos_plate targets.json   render-free check of goldens vs targets
    pk.py calibrate GLYPH MEASURED TARGET
    pk.py test     laos_plate           flutter test, reduced to failures
    pk.py analyze  laos_plate           flutter analyze, one line per issue
    pk.py commits                       dirty repos, innermost first
    pk.py all      Laos la              fetch → photos → ask → brief

Run from the workspace root. Nothing here edits Dart beyond the scaffold.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import cv2

sys.path.insert(0, str(Path(__file__).resolve().parent))
from platekit import brief, fetch, gitplan, logfilter, scaffold, vision  # noqa: E402

ROOT = Path.cwd()


def _dump(obj) -> None:
    print(json.dumps(obj, ensure_ascii=False, indent=1))


def cmd_fetch(a):
    work = ROOT / '.plateref' / a.code
    f = fetch.run(a.country, work)
    print(f"{work}/facts.json: {len(f['tables'])} tables, {len(f['images'])} images, "
          f"size {f['size_mm']}, israel={f['mentions_israel']}")


def _plate_size(work: Path, override=None) -> tuple[float, float]:
    if override:
        return tuple(override)
    f = json.loads((work / 'facts.json').read_text())
    return tuple(f['size_mm']) if f.get('size_mm') else (520.0, 110.0)


def cmd_photos(a):
    """Two passes: fit every photo, then flatten all of them to one aspect.

    The infobox size is not trusted on its own — Laos's says 520 × 110 while
    the photographed plates are 340 × 150. When the median fitted aspect
    disagrees with it by more than 25 %, the fitted aspect wins (width kept,
    so units stay roughly millimetres) and the conflict is recorded for the
    brief. A fit whose aspect strays more than 8 % from the median is marked
    for checking: a cut edge or a mount caught in the quad shows up that way.
    """
    work = Path(a.work)
    cw, ch = _plate_size(work, getattr(a, 'size', None))
    photos_path = work / 'photos.json'
    photos = json.loads(photos_path.read_text()) if photos_path.exists() else {}
    images = {}
    for p in sorted(work.glob('orig_*')):
        if p.suffix.lower() not in ('.jpg', '.jpeg', '.png', '.webp'):
            continue
        im = cv2.imread(str(p))
        if im is None:
            continue
        name = p.stem[5:]
        entry = photos.setdefault(name, {})
        try:
            entry['found'] = vision.found_dict(vision.find(im))
            images[name] = im
        except RuntimeError as e:
            entry['found'] = {'confident': False, 'error': str(e)}
            print(f'{name}: {e}')

    aspects = sorted(photos[n]['found']['aspect'] for n in images if photos[n]['found']['confident'])
    if aspects:
        median = aspects[len(aspects) // 2]
        if not getattr(a, 'size', None) and abs(median - cw / ch) / median > 0.25:
            print(f'infobox size {cw:g} x {ch:g} (aspect {cw / ch:.2f}) disagrees with the photos '
                  f'(median aspect {median:.2f}); flattening to {cw:g} x {cw / median:.0f}')
            (work / 'size_conflict.json').write_text(json.dumps(
                {'infobox': [cw, ch], 'photo_aspect': median, 'used': [cw, round(cw / median)]}))
            ch = round(cw / median)
        for n in images:
            f = photos[n]['found']
            if f['confident'] and abs(f['aspect'] - median) / median > 0.08:
                f['confident'] = False
                f['why'] = f'aspect {f["aspect"]:.2f} vs median {median:.2f}'

    for name, im in images.items():
        entry = photos[name]
        found = entry['found']
        flat = vision.flatten(im, found['corners'], cw, cw / ch)
        cv2.imwrite(str(work / f'flat_{name}.png'), flat)
        entry['measure'] = vision.measure(flat, cw, ch)
        entry['colours'] = vision.colours(flat)
        if not found['confident']:
            vision.corner_sheet(im, found['corners'], work / f'corners_{name}.png')
        print(f"{name}: {'ok' if found['confident'] else 'CHECK ' + found.get('why', '')} "
              f"aspect {found['aspect']:.2f} field {entry['colours']['field']} "
              f"ink {entry['colours']['ink']} rows {len(entry['measure']['rows'])}")
    photos_path.write_text(json.dumps(photos, ensure_ascii=False, indent=1))
    flats = sorted(work.glob('flat_*.png'))
    if flats:
        vision.contact_sheet(flats, work / 'sheet_flat.png', cell=(540, int(540 * ch / cw)))
        print(f'{work}/sheet_flat.png')


def cmd_ask(a):
    from platekit import local_llm
    if not local_llm.available():
        print('ollama is not running; skipped')
        return
    work = Path(a.work)
    photos_path = work / 'photos.json'
    photos = json.loads(photos_path.read_text())
    for name, entry in photos.items():
        img = work / f'flat_{name}.png'
        if not img.exists():
            continue
        if 'ask' in entry and not a.again:
            continue
        entry['ask'] = local_llm.ask_named('layout', [img])
        print(name, entry['ask'], flush=True)
        # saved per photo: a killed run keeps what it already paid for
        photos_path.write_text(json.dumps(photos, ensure_ascii=False, indent=1))


def cmd_sheet(a):
    vision.contact_sheet([Path(p) for p in a.images], Path(a.out), crop_content=a.crop)
    print(a.out)


def cmd_brief(a):
    out = brief.write(Path(a.work))
    print(f'{out} ({out.stat().st_size} bytes)')


def cmd_scaffold(a):
    cats = scaffold.load_categories(Path(a.categories)) if a.categories else None
    written = scaffold.package(ROOT, a.country, a.code, epithet=a.epithet, summary=a.summary,
                               categories=cats, fonts=a.font or None, force=a.force)
    written += scaffold.register(ROOT, a.country, a.code) if a.register else []
    print('\n'.join(written) or 'nothing new')


def cmd_goldens(a):
    """targets.json: {"<golden stem>": [{"name", "y": [..], "x": [..], "tol"}]}
    in plate units; the plate size comes from --size."""
    cw, ch = a.size
    targets = json.loads(Path(a.targets).read_text())
    gold = ROOT / a.package / 'test' / 'goldens'
    bad = 0
    for stem, rows in targets.items():
        im = cv2.imread(str(gold / f'{stem}.png'))
        if im is None:
            print(f'{stem}: no golden')
            bad += 1
            continue
        plate = vision.crop_to_content(im)
        got = vision.measure(plate, cw, ch)
        for r in vision.compare(rows, got['rows']):
            if r['verdict'] != 'OK' or a.verbose:
                bad += r['verdict'] != 'OK'
                print(f"{stem} {r['name']}: {r['verdict']} " + json.dumps(
                    {k: v for k, v in r.items() if k not in ('name', 'verdict')}))
    print(f'{bad} off' if bad else 'all rows within tolerance')
    sys.exit(1 if bad else 0)


def cmd_calibrate(a):
    print(vision.calibrate(a.glyph, a.measured, a.target))


def cmd_test(a):
    log = logfilter.run(['flutter', 'test', *a.args], ROOT / a.package)
    print(logfilter.render(logfilter.tests(log)))


def cmd_analyze(a):
    log = logfilter.run(['flutter', 'analyze'], ROOT / a.package)
    issues = logfilter.analyze(log)
    print('\n'.join(issues) or 'No issues found')


def cmd_commits(a):
    print(gitplan.render(gitplan.plan(ROOT)))


def cmd_all(a):
    a.work = str(ROOT / '.plateref' / a.code)
    cmd_fetch(a)
    cmd_photos(a)
    if not a.no_ask:
        a.again = False
        cmd_ask(a)
    cmd_brief(a)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)

    s = sub.add_parser('fetch'); s.add_argument('country'); s.add_argument('code'); s.set_defaults(f=cmd_fetch)
    s = sub.add_parser('photos'); s.add_argument('work')
    s.add_argument('--size', nargs=2, type=float, help='plate width height, overrides the infobox')
    s.set_defaults(f=cmd_photos)
    s = sub.add_parser('ask'); s.add_argument('work')
    s.add_argument('--again', action='store_true', help='re-ask photos already answered')
    s.set_defaults(f=cmd_ask)
    s = sub.add_parser('sheet'); s.add_argument('out'); s.add_argument('images', nargs='+')
    s.add_argument('--crop', action='store_true'); s.set_defaults(f=cmd_sheet)
    s = sub.add_parser('brief'); s.add_argument('work'); s.set_defaults(f=cmd_brief)
    s = sub.add_parser('scaffold'); s.add_argument('country'); s.add_argument('code')
    s.add_argument('--epithet', default=''); s.add_argument('--summary', default='')
    s.add_argument('--categories', help='json list of {id, getter, theme, value}')
    s.add_argument('--font', action='append', help='font file for the golden test (repeatable)')
    s.add_argument('--register', action='store_true', help='also edit workspace + gallery')
    s.add_argument('--force', action='store_true'); s.set_defaults(f=cmd_scaffold)
    s = sub.add_parser('goldens'); s.add_argument('package'); s.add_argument('targets')
    s.add_argument('--size', nargs=2, type=float, default=(520, 110))
    s.add_argument('-v', '--verbose', action='store_true'); s.set_defaults(f=cmd_goldens)
    s = sub.add_parser('calibrate'); s.add_argument('glyph', type=float)
    s.add_argument('measured', type=float); s.add_argument('target', type=float); s.set_defaults(f=cmd_calibrate)
    s = sub.add_parser('test'); s.add_argument('package'); s.add_argument('args', nargs='*'); s.set_defaults(f=cmd_test)
    s = sub.add_parser('analyze'); s.add_argument('package'); s.set_defaults(f=cmd_analyze)
    s = sub.add_parser('commits'); s.set_defaults(f=cmd_commits)
    s = sub.add_parser('all'); s.add_argument('country'); s.add_argument('code')
    s.add_argument('--no-ask', action='store_true'); s.set_defaults(f=cmd_all)

    a = p.parse_args()
    a.f(a)


if __name__ == '__main__':
    main()
