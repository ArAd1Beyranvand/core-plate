"""Stage 1: the article, its tables and its images — no model involved.

The skill's Phase 1 has an LLM read 120 KB of HTML and open every image to
find the size, the format, the categories and which picture goes with which
row. All of that is structure the page already carries: the infobox is a
<th>/<td> table, the vehicle-type table is a `wikitable`, and every image is a
`/wiki/File:` link inside the row it illustrates. This module turns the page
into `facts.json` (a few hundred tokens) and downloads the originals.
"""
from __future__ import annotations

import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from bs4 import BeautifulSoup

UA = {'User-Agent': 'platekit/0.1 (licence-plate research; offline tooling)'}
WIKI = 'https://en.wikipedia.org'


def _get(url: str, tries: int = 5) -> bytes:
    """upload.wikimedia.org answers 429 to bursts; back off and retry."""
    for i in range(tries):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code != 429 or i == tries - 1:
                raise
            time.sleep(float(e.headers.get('Retry-After') or 0) or 2 ** (i + 1))


def article_url(country: str) -> str:
    return f'{WIKI}/wiki/Vehicle_registration_plates_of_{country.replace(" ", "_")}'


def fetch_article(country: str, out: Path) -> Path:
    """Downloads the article; falls back to the index's `Main article:` link."""
    out.mkdir(parents=True, exist_ok=True)
    dest = out / 'art.html'
    try:
        dest.write_bytes(_get(article_url(country)))
        return dest
    except Exception as e:  # 404 or a redirect title that differs
        index = _get(f'{WIKI}/wiki/Vehicle_registration_plate').decode()
        soup = BeautifulSoup(index, 'lxml')
        for a in soup.select('div.hatnote a'):
            if country.lower() in a.get_text().lower():
                dest.write_bytes(_get(WIKI + a['href']))
                return dest
        raise RuntimeError(f'no article for {country}: {e}') from e


def _text(node) -> str:
    return re.sub(r'\s+', ' ', node.get_text(' ', strip=True)).strip()


def _files(node) -> list[str]:
    names = []
    for a in node.select('a[href*="/wiki/File:"]'):
        n = urllib.parse.unquote(a['href'].split('File:', 1)[1])
        if n not in names:
            names.append(n)
    return names


def parse(html: str) -> dict:
    """Infobox, prose by section, every table row with its images."""
    soup = BeautifulSoup(html, 'lxml')
    body = soup.select_one('#mw-content-text .mw-parser-output')
    # Maintenance boxes, stub notices and navboxes carry icons and links to
    # every other country (an "Israel" link sits in the Asia navbox).
    for junk in body.select('style, script, sup.reference, .mw-editsection, .navbox, .reflist, '
                            '.metadata, .ambox, .asbox, .sistersitebox, .side-box, .hatnote'):
        junk.decompose()
    all_images = [n for n in _files(body) if not n.lower().endswith('.svg')]
    israel = bool(re.search(r'\bIsrael', body.get_text(' ')))

    infobox = {}
    box = body.select_one('table.infobox')
    if box:
        for tr in box.select('tr'):
            th, td = tr.find('th'), tr.find('td')
            if th and td:
                infobox[_text(th)] = _text(td)
        infobox_images = _files(box)
        box.decompose()
    else:
        infobox_images = []

    tables = []
    for t in body.select('table.wikitable'):
        caption = t.find('caption')
        rows = []
        for tr in t.select('tr'):
            cells = tr.find_all(['th', 'td'])
            rows.append({
                'cells': [_text(c) for c in cells],
                'images': _files(tr),
            })
        tables.append({'caption': _text(caption) if caption else '', 'rows': rows})
        t.decompose()

    sections, current = [], {'heading': '(lead)', 'text': []}
    for el in body.find_all(['h2', 'h3', 'p', 'li'], recursive=True):
        if el.name in ('h2', 'h3'):
            if current['text']:
                sections.append(current)
            current = {'heading': _text(el), 'text': []}
        else:
            s = _text(el)
            if s and el.find_parent(['table']) is None:
                current['text'].append(s)
    if current['text']:
        sections.append(current)
    sections = [s for s in sections if s['heading'] not in ('References', 'See also', 'External links')]

    return {
        'infobox': infobox,
        'infobox_images': infobox_images,
        'size_mm': _size(infobox),
        'sections': sections,
        'tables': tables,
        'all_images': all_images,
        'mentions_israel': israel,
    }


def _size(infobox: dict) -> list[float] | None:
    for k, v in infobox.items():
        if k.lower().startswith('size'):
            m = re.search(r'(\d+(?:\.\d+)?)\s*mm\s*[×x]\s*(\d+(?:\.\d+)?)\s*mm', v)
            if m:
                return [float(m.group(1)), float(m.group(2))]
    return None


def resolve_images(names: list[str]) -> dict[str, dict]:
    """One batched imageinfo call (50 titles per request, the API's limit)."""
    out = {}
    for i in range(0, len(names), 50):
        titles = '|'.join('File:' + n for n in names[i:i + 50])
        q = urllib.parse.urlencode({
            'action': 'query', 'format': 'json', 'prop': 'imageinfo',
            'iiprop': 'url|size|mime', 'titles': titles,
        })
        data = json.loads(_get(f'{WIKI}/w/api.php?{q}'))
        norm = {n['to']: n['from'] for n in data['query'].get('normalized', [])}
        for page in data['query']['pages'].values():
            info = (page.get('imageinfo') or [{}])[0]
            title = norm.get(page['title'], page['title'])
            out[title.split(':', 1)[1]] = {
                'url': info.get('url'), 'width': info.get('width'),
                'height': info.get('height'), 'mime': info.get('mime'),
            }
    return out


def safe_name(name: str) -> str:
    return re.sub(r'[^A-Za-z0-9._-]+', '_', name)


def download(names: list[str], out: Path) -> dict[str, dict]:
    meta = resolve_images(names)
    for name, info in meta.items():
        if not info['url']:
            continue
        dest = out / ('orig_' + safe_name(name))
        if not dest.exists():
            dest.write_bytes(_get(info['url']))
            time.sleep(1)
        info['file'] = dest.name
    return meta


def run(country: str, out: Path) -> dict:
    html = fetch_article(country, out).read_text()
    facts = parse(html)
    facts['country'] = country
    facts['source'] = article_url(country)
    facts['images'] = download(facts['all_images'], out)
    (out / 'facts.json').write_text(json.dumps(facts, ensure_ascii=False, indent=1))
    return facts
