"""Stage 4: the hand-off — what the LLM reads instead of the raw material.

Everything stages 1–3 found goes into one markdown file of a few
kilobytes: the infobox, the category table, per photo the fit, the
measured rows and the balanced colours, the local model's answers, and
which of those need a human (or LLM) look. The LLM then opens only the
contact sheet and the images flagged there.
"""
from __future__ import annotations

import json
from pathlib import Path

from .scaffold import snake

TEMPLATE = Path(__file__).resolve().parent.parent / 'prompts' / 'llm_brief.md'


def _table(t: dict, limit: int = 40) -> str:
    rows = [r for r in t['rows'] if any(r['cells'])][:limit]
    if not rows:
        return ''
    out = []
    for r in rows:
        cells = ' | '.join(c[:80] for c in r['cells'])
        imgs = f"  ← {', '.join(r['images'])}" if r['images'] else ''
        out.append(f'| {cells} |{imgs}')
    return '\n'.join(out)


def facts_section(facts: dict) -> str:
    lines = [f"# {facts['country']}", '', f"Source: {facts['source']}", '']
    if facts.get('size_mm'):
        lines.append(f"Size: {facts['size_mm'][0]:g} × {facts['size_mm'][1]:g} mm")
    lines.append(f"Israel mentioned: {'YES — read those lines' if facts['mentions_israel'] else 'no'}")
    lines += ['', '## Infobox', '']
    lines += [f'- {k}: {v[:200]}' for k, v in facts['infobox'].items()]
    for i, t in enumerate(facts['tables']):
        body = _table(t)
        if body:
            lines += ['', f"## Table {i + 1} {t['caption']}".rstrip(), '', body]
    lines += ['', '## Prose', '']
    for s in facts['sections']:
        text = ' '.join(s['text'])
        lines.append(f"- **{s['heading']}**: {text[:600]}{'…' if len(text) > 600 else ''}")
    return '\n'.join(lines)


def photo_section(photos: dict) -> str:
    """photos: name -> {found, measure, colours, ask} as the CLI saves them."""
    lines = ['## Photos', '', '| photo | fit | aspect | field | ink | rows (y: x-span, runs) | local model |',
             '|---|---|---|---|---|---|---|']
    flagged = []
    for name, p in photos.items():
        f = p.get('found', {})
        fit = 'ok' if f.get('confident') else 'CHECK'
        if not f.get('confident'):
            flagged.append(name)
        m, c = p.get('measure', {}), p.get('colours', {})
        rows = '; '.join(f"{r['y'][0]:g}–{r['y'][1]:g}: {r['x'][0]:g}–{r['x'][1]:g}, {len(r['runs'])}"
                         for r in m.get('rows', []))
        a = ', '.join(f'{k}={v}' for k, v in p.get('ask', {}).items() if v != 'unknown')
        lines.append(f"| {name} | {fit} | {f.get('aspect', 0):.2f} | "
                     f"{c.get('field', '?')} | {c.get('ink', '?')} | {rows} | {a} |")
    lines += ['', '### Structure per photo (plate units)', '']
    for name, p in photos.items():
        z = '; '.join(f"{q['colour']} x {q['x'][0]:g}–{q['x'][1]:g} y {q['y'][0]:g}–{q['y'][1]:g}"
                      for q in p.get('zones', [])) or 'none'
        d = '; '.join(f"{q['axis']} at {q['at']:g}" for q in p.get('dividers', [])) or 'none'
        o = ' / '.join(f"{q['text']!r}" for q in p.get('ocr', []))
        lang = p['ocr'][0]['lang'] if p.get('ocr') else '-'
        lines.append(f'- {name}: zones {z}; dividers {d}; ocr ({lang}, unreliable for non-Latin) {o}')
    if flagged:
        lines += ['', 'Look at these yourself (corner sheets in `corners_<photo>.png`): '
                  + ', '.join(flagged)]
    return '\n'.join(lines)


def write(work: Path) -> Path:
    facts = json.loads((work / 'facts.json').read_text())
    photos = json.loads((work / 'photos.json').read_text()) if (work / 'photos.json').exists() else {}
    parts = [facts_section(facts)]
    if photos:
        parts.append(photo_section(photos))
    parts.append(TEMPLATE.read_text().replace('{country}', snake(facts['country'])))
    out = work / 'brief.md'
    out.write_text('\n\n'.join(parts) + '\n')
    return out
