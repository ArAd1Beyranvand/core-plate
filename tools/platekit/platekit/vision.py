"""Stage 2: find, flatten and measure plates in photos — no model involved.

Generalises the scripts the Laos pass wrote by hand (`rectify.py`,
`refine.py`, `ink.py`, `corners.py`). The one step that needed the LLM there
was choosing a seed pixel or rough corners by looking at the photo; `find`
does it from colour statistics and reports a confidence, so the LLM is asked
for corners only when the automatic fit is poor.
"""
from __future__ import annotations

from collections import Counter
from dataclasses import dataclass, asdict
from pathlib import Path

import cv2
import numpy as np

PX_PER_UNIT = 4


# ---------------------------------------------------------------- finding --

@dataclass
class Found:
    corners: list[list[float]]  # tl tr br bl, source pixels
    aspect: float
    residual_px: float           # mean edge-fit residual; > ~3 is suspect
    area_frac: float             # plate area / image area
    confident: bool


def _plate_mask(lab: np.ndarray, seed: tuple[int, int], tol: float, close: int) -> np.ndarray:
    sx, sy = seed
    ref = np.median(lab[sy - 7:sy + 8, sx - 7:sx + 8].reshape(-1, 3), 0)
    mask = (np.abs(lab - ref).sum(2) < tol).astype(np.uint8)
    k = cv2.getStructuringElement(cv2.MORPH_RECT, (close, close))
    closed = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, k)
    _, lbl = cv2.connectedComponents(closed)
    return (lbl == lbl[sy, sx]).astype(np.uint8)


def _quad(comp: np.ndarray) -> np.ndarray:
    cnts, _ = cv2.findContours(comp, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    c = max(cnts, key=cv2.contourArea)
    hull = cv2.convexHull(c)
    for eps in np.linspace(0.005, 0.08, 40):
        a = cv2.approxPolyDP(hull, eps * cv2.arcLength(hull, True), True)
        if len(a) == 4:
            q = a.reshape(4, 2).astype(np.float32)
            break
    else:
        q = cv2.boxPoints(cv2.minAreaRect(c)).astype(np.float32)
    s, d = q.sum(1), np.diff(q, axis=1).ravel()
    return np.float32([q[s.argmin()], q[d.argmin()], q[s.argmax()], q[d.argmax()]])


def _fit_side(lab, a, b, centre, search, first=0.5):
    h, w = lab.shape[:2]
    d = (b - a) / np.linalg.norm(b - a)
    n = np.array([-d[1], d[0]])
    if np.dot(centre - a, n) < 0:
        n = -n
    pts = []
    for t in np.linspace(0.2, 0.8, 80):
        base = a + (b - a) * t
        prof = []
        for s in range(-search, search + 1):
            x, y = np.clip(np.round(base + n * s).astype(int), 0, [w - 1, h - 1])
            prof.append(lab[y, x])
        prof = np.array(prof)
        step = np.linalg.norm(prof[2:] - prof[:-2], axis=1)
        k = int(np.argmax(step > step.max() * first)) + 1
        pts.append(base + n * (k - search))
    pts = np.array(pts, np.float32)
    res = np.zeros(1)
    for _ in range(2):
        vx, vy, x0, y0 = cv2.fitLine(pts, cv2.DIST_HUBER, 0, .01, .01).ravel()
        res = np.abs((pts[:, 0] - x0) * vy - (pts[:, 1] - y0) * vx)
        pts = pts[res < max(2.0, np.median(res) * 3)]
    return (x0, y0, vx, vy), float(np.median(res))


def _meet(l1, l2):
    x1, y1, a1, b1 = l1
    x2, y2, a2, b2 = l2
    t = np.linalg.solve(np.array([[a1, -a2], [b1, -b2]]), np.array([x2 - x1, y2 - y1]))
    return np.array([x1 + a1 * t[0], y1 + b1 * t[0]])


def refine(im: np.ndarray, coarse: np.ndarray, search: int = 35) -> tuple[np.ndarray, float]:
    """Fits a line to each side (middle 60%, clear of rounded corners)."""
    lab = cv2.GaussianBlur(cv2.cvtColor(im, cv2.COLOR_BGR2LAB).astype(np.float32), (5, 5), 0)
    c = coarse.mean(0)
    sides = [_fit_side(lab, coarse[i], coarse[(i + 1) % 4], c, search) for i in range(4)]
    L = [s[0] for s in sides]
    q = np.float32([_meet(L[3], L[0]), _meet(L[0], L[1]), _meet(L[1], L[2]), _meet(L[2], L[3])])
    return q, float(np.mean([s[1] for s in sides]))


def _seeds(im: np.ndarray) -> list[tuple[int, int]]:
    """Candidate field pixels: the dominant colour clusters near the centre.

    A plate photo is framed on the plate, so the field is the largest
    uniform colour in the middle third. Two clusters are tried (field and
    ink swap roles on dark plates)."""
    h, w = im.shape[:2]
    lab = cv2.cvtColor(im, cv2.COLOR_BGR2LAB).astype(np.float32)
    mid = lab[h // 3:2 * h // 3, w // 4:3 * w // 4]
    small = cv2.resize(mid, (min(160, mid.shape[1]), min(80, mid.shape[0])))
    data = small.reshape(-1, 3)
    _, lbl, _ = cv2.kmeans(data, 3, None, (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, .5),
                           3, cv2.KMEANS_PP_CENTERS)
    lbl = lbl.reshape(small.shape[:2])
    seeds = []
    for k in np.argsort(-np.bincount(lbl.ravel())):
        ys, xs = np.where(lbl == k)
        # the pixel of this cluster with the most same-cluster neighbours
        m = (lbl == k).astype(np.uint8)
        dist = cv2.distanceTransform(m, cv2.DIST_L2, 3)
        y, x = np.unravel_index(dist.argmax(), dist.shape)
        seeds.append((int(w // 4 + x * mid.shape[1] / small.shape[1]),
                      int(h // 3 + y * mid.shape[0] / small.shape[0])))
    return seeds


def find(im: np.ndarray, seed: tuple[int, int] | None = None, tol: float = 60,
         close: int = 25) -> Found:
    cv2.setRNGSeed(0)  # k-means seeding; same photo, same fit
    lab = cv2.cvtColor(im, cv2.COLOR_BGR2LAB).astype(int)
    h, w = im.shape[:2]
    best = None
    for s in ([seed] if seed else _seeds(im)):
        comp = _plate_mask(lab, s, tol, close)
        frac = comp.sum() / (h * w)
        if not 0.05 < frac < 0.97:
            continue
        coarse = _quad(comp)
        try:
            q, res = refine(im, coarse)
        except (np.linalg.LinAlgError, cv2.error):
            continue
        wpx = (np.linalg.norm(q[1] - q[0]) + np.linalg.norm(q[2] - q[3])) / 2
        hpx = (np.linalg.norm(q[3] - q[0]) + np.linalg.norm(q[2] - q[1])) / 2
        # A fit is good when the refined quad stays near the mask's quad and
        # the edges are straight.
        drift = float(np.abs(q - coarse).max()) / max(w, h)
        cand = Found(q.tolist(), float(wpx / hpx), res, float(frac),
                     bool(res < 3 and drift < 0.05 and 1.2 < wpx / hpx < 6))
        if best is None or (cand.confident, cand.area_frac) > (best.confident, best.area_frac):
            best = cand
    if best is None:
        raise RuntimeError('no plate-shaped region found; give a seed or corners')
    return best


def flatten(im: np.ndarray, corners, width: float, aspect: float) -> np.ndarray:
    W = int(round(width * PX_PER_UNIT))
    H = int(round(width / aspect * PX_PER_UNIT))
    M = cv2.getPerspectiveTransform(np.float32(corners),
                                    np.float32([[0, 0], [W, 0], [W, H], [0, H]]))
    return cv2.warpPerspective(im, M, (W, H))


def corner_sheet(im: np.ndarray, corners, out: Path, r: int = 60, z: int = 3) -> None:
    """Zoomed, gridded crops of four corners — what an LLM looks at when the
    automatic fit is not confident (the only geometry step that needs eyes)."""
    tiles = []
    h, w = im.shape[:2]
    for (x, y) in np.clip(np.int32(corners), 0, [w - 1, h - 1]):
        pad = cv2.copyMakeBorder(im, r, r, r, r, cv2.BORDER_CONSTANT, value=(128, 128, 128))
        c = cv2.resize(pad[y:y + 2 * r, x:x + 2 * r], (2 * r * z, 2 * r * z),
                       interpolation=cv2.INTER_NEAREST)
        for g in range(-r, r + 1, 10):
            col = (0, 255, 255) if g == 0 else (255, 0, 255)
            cv2.line(c, ((g + r) * z, 0), ((g + r) * z, 2 * r * z), col, 1)
            cv2.line(c, (0, (g + r) * z), (2 * r * z, (g + r) * z), col, 1)
        for g in range(-r, r + 1, 20):
            cv2.putText(c, str(x + g), ((g + r) * z + 2, 12), cv2.FONT_HERSHEY_SIMPLEX, .35, (0, 255, 0), 1)
            cv2.putText(c, str(y + g), (2, (g + r) * z - 2), cv2.FONT_HERSHEY_SIMPLEX, .35, (0, 255, 0), 1)
        tiles.append(c)
    cv2.imwrite(str(out), np.vstack([np.hstack(tiles[:2]), np.hstack([tiles[3], tiles[2]])]))


def contact_sheet(paths: list[Path], out: Path, cell=(540, 240), cols: int = 3,
                  crop_content: bool = False) -> None:
    """Many images, one Read. Keeps each image's aspect (letterboxed)."""
    tiles = []
    for p in paths:
        im = cv2.imread(str(p))
        if crop_content:
            im = crop_to_content(im)
        s = min(cell[0] / im.shape[1], cell[1] / im.shape[0])
        im = cv2.resize(im, (int(im.shape[1] * s), int(im.shape[0] * s)))
        t = np.full((cell[1] + 18, cell[0], 3), 255, np.uint8)
        t[:im.shape[0], :im.shape[1]] = im
        cv2.putText(t, p.stem[:60], (2, cell[1] + 13), cv2.FONT_HERSHEY_SIMPLEX, .4, (0, 0, 0), 1)
        tiles.append(t)
    while len(tiles) % cols:
        tiles.append(np.full_like(tiles[0], 255))
    rows = [np.hstack(tiles[i:i + cols]) for i in range(0, len(tiles), cols)]
    cv2.imwrite(str(out), np.vstack(rows))


# -------------------------------------------------------------- measuring --

def crop_to_content(im: np.ndarray, thresh: int = 30) -> np.ndarray:
    a = im.astype(int)
    m = np.abs(a - a[0, 0]).sum(2) > thresh
    c, r = np.where(m.any(0))[0], np.where(m.any(1))[0]
    return im[r[0]:r[-1] + 1, c[0]:c[-1] + 1]


def _runs(v, gap):
    out, start, last = [], None, None
    for i, on in enumerate(v):
        if on:
            if start is None:
                start = i
            elif i - last > gap:
                out.append((start, last))
                start = i
            last = i
    if start is not None:
        out.append((start, last))
    return out


def _hex(rgb) -> str:
    return '%02X%02X%02X' % tuple(int(v) for v in rgb)


def ink_mask(im: np.ndarray, chroma: float | None = None):
    """Field vs ink by 2-means in Lab over the inner plate."""
    cv2.setRNGSeed(0)
    H, W = im.shape[:2]
    lab = cv2.cvtColor(im, cv2.COLOR_BGR2LAB).astype(np.float32)
    inner = lab[int(H * .1):int(H * .9), int(W * .05):int(W * .95)].reshape(-1, 3)
    _, lbl, cen = cv2.kmeans(inner, 2, None, (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, .5),
                             3, cv2.KMEANS_PP_CENTERS)
    counts = np.bincount(lbl.ravel())
    field_c, ink_c = (cen[0], cen[1]) if counts[0] > counts[1] else (cen[1], cen[0])
    if chroma is not None:
        ch = np.hypot(lab[..., 1] - 128, lab[..., 2] - 128)
        m = ch > chroma
        ink_c, field_c = np.median(lab[m], 0), np.median(lab[~m][::50], 0)
    return np.linalg.norm(lab - ink_c, axis=2) < np.linalg.norm(lab - field_c, axis=2)


def measure(im: np.ndarray, cw: float, ch: float, *, win=None, gap: float = 2.5,
            chroma: float | None = None) -> dict:
    """Rows of ink and the glyph runs inside each, in plate units."""
    H, W = im.shape[:2]
    sx, sy = cw / W, ch / H
    ink = ink_mask(im, chroma)
    rgb = cv2.cvtColor(im, cv2.COLOR_BGR2RGB)

    def modal(mask):
        px = Counter(map(tuple, (rgb[mask] // 2 * 2).reshape(-1, 3)))
        return _hex(px.most_common(1)[0][0])

    x0, y0, x1, y1 = win or (cw * .04, ch * .07, cw * .96, ch * .93)
    X0, Y0, X1, Y1 = int(x0 / sx), int(y0 / sy), int(x1 / sx), int(y1 / sy)
    sub = cv2.morphologyEx(ink[Y0:Y1, X0:X1].astype(np.uint8), cv2.MORPH_OPEN,
                           np.ones((3, 3), np.uint8)).astype(bool)
    rows = []
    for a, b in _runs(sub.sum(1) > 2, int(1.2 / sy)):
        if (b - a) * sy < 3:
            continue
        cols = _runs(sub[a:b + 1].sum(0) > 0, int(gap / sx))
        rows.append({
            'y': [round((Y0 + a) * sy, 1), round((Y0 + b + 1) * sy, 1)],
            'x': [round((X0 + cols[0][0]) * sx, 1), round((X0 + cols[-1][1] + 1) * sx, 1)],
            'runs': [[round((X0 + p) * sx, 1), round((X0 + q + 1) * sx, 1)]
                     for p, q in cols if (q - p) * sx > 1],
        })
    return {'size_px': [W, H], 'aspect': round(W / H, 3), 'field': modal(~ink),
            'ink': modal(ink), 'rows': rows}


def colours(im: np.ndarray, white: str = 'auto', erode: int = 9) -> dict:
    """Field and ink colour, white-balanced against a known white.

    Photos are paint × light; the Laos pass rescaled each channel so a
    region known to be white came out FFFFFF. `white='auto'` takes the
    brightest low-chroma cluster with real area; 'field' or 'ink' name a
    white role explicitly; 'none' skips balancing."""
    ink = ink_mask(im)
    k = np.ones((erode, erode), np.uint8)
    core_ink = cv2.erode(ink.astype(np.uint8), k).astype(bool)
    core_field = cv2.erode((~ink).astype(np.uint8), k).astype(bool)
    rgb = cv2.cvtColor(im, cv2.COLOR_BGR2RGB).astype(np.float32)
    f, i = np.median(rgb[core_field], 0), np.median(rgb[core_ink], 0)
    ref = None
    if white == 'field':
        ref = f
    elif white == 'ink':
        ref = i
    elif white == 'auto':
        lab = cv2.cvtColor(im, cv2.COLOR_BGR2LAB).astype(np.float32)
        light = (lab[..., 0] > np.percentile(lab[..., 0], 97)) & \
                (np.hypot(lab[..., 1] - 128, lab[..., 2] - 128) < 12)
        if light.sum() > 0.002 * light.size:
            ref = np.median(rgb[light], 0)
    gain = 255 / np.maximum(ref, 1) if ref is not None else np.ones(3)
    return {'field_raw': _hex(f), 'ink_raw': _hex(i),
            'field': _hex(np.clip(f * gain, 0, 255)), 'ink': _hex(np.clip(i * gain, 0, 255)),
            'white_ref': _hex(ref) if ref is not None else None}


# ------------------------------------------------------------- comparing --

def compare(target_rows: list[dict], got_rows: list[dict]) -> list[dict]:
    """Matches each target row to the golden row it overlaps most."""
    out = []
    for t in target_rows:
        ty0, ty1 = t['y']
        best, ov = None, 0
        for g in got_rows:
            o = min(ty1, g['y'][1]) - max(ty0, g['y'][0])
            if o > ov:
                best, ov = g, o
        r = {'name': t.get('name', ''), 'target_y': t['y'], 'target_x': t.get('x')}
        if best is None:
            r['verdict'] = 'MISSING'
        else:
            th, gh = ty1 - ty0, best['y'][1] - best['y'][0]
            r.update(got_y=best['y'], got_x=best['x'],
                     height_pct=round(100 * gh / th), dy_centre=round((sum(best['y']) - sum(t['y'])) / 2, 1))
            if t.get('x'):
                r['dx_left'] = round(best['x'][0] - t['x'][0], 1)
                r['dx_right'] = round(best['x'][1] - t['x'][1], 1)
            tol = t.get('tol', 3)
            off = [abs(r['dy_centre'])] + [abs(r[k]) for k in ('dx_left', 'dx_right') if k in r]
            r['verdict'] = 'OK' if max(off) <= tol and 85 <= r['height_pct'] <= 115 else 'OFF'
        out.append(r)
    return out


def calibrate(glyph: float, measured_span: float, target_span: float) -> float:
    """The width-limited text fix: scale the glyph by target/measured span."""
    return round(glyph * target_span / measured_span, 1)


def found_dict(f: Found) -> dict:
    return asdict(f)


# ------------------------------------------------------------ structure --

def zones(im: np.ndarray, cw: float, ch: float, min_frac: float = 0.004, far: float = 35) -> list[dict]:
    """Coloured regions that are neither field nor ink: bands, badges,
    flags, a differently coloured section. Solid blocks only. Plate units."""
    H, W = im.shape[:2]
    small = cv2.resize(im, (W // 2, H // 2))
    lab = cv2.cvtColor(small, cv2.COLOR_BGR2LAB).astype(np.float32)
    ink = cv2.resize(ink_mask(im).astype(np.uint8), (W // 2, H // 2)).astype(bool)
    f, i = np.median(lab[~ink], 0), np.median(lab[ink], 0)
    other = (np.linalg.norm(lab - f, axis=2) > far) & (np.linalg.norm(lab - i, axis=2) > far)
    mask = cv2.morphologyEx(other.astype(np.uint8), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    n, lbl, stats, _ = cv2.connectedComponentsWithStats(mask)
    rgb = cv2.cvtColor(small, cv2.COLOR_BGR2RGB)
    sx, sy = cw / lab.shape[1], ch / lab.shape[0]
    out = []
    for c in range(1, n):
        x, y, w, h, area = stats[c]
        if area < min_frac * mask.size or area / (w * h) < 0.6:
            continue
        out.append({'x': [round(x * sx, 1), round((x + w) * sx, 1)],
                    'y': [round(y * sy, 1), round((y + h) * sy, 1)],
                    'colour': _hex(np.median(rgb[lbl == c], 0)), 'fill': round(float(area / (w * h)), 2)})
    return sorted(out, key=lambda z: z['x'][0])


def dividers(im: np.ndarray, cw: float, ch: float, runs: list | None = None) -> list[dict]:
    """Thin straight lines inside the plate: vertical separators between
    sections and horizontal rules between rows (not the border)."""
    H, W = im.shape[:2]
    ink = ink_mask(im).astype(np.uint8)
    out = []
    for axis, kern, span in (('vertical', (1, int(H * .7)), H), ('horizontal', (int(W * .5), 1), W)):
        lines = cv2.morphologyEx(ink, cv2.MORPH_OPEN, np.ones(kern[::-1], np.uint8))
        glyphs = [r for row in (runs or []) for r in row['runs']]
        n, _, stats, _ = cv2.connectedComponentsWithStats(lines)
        for x, y, w, h, _ in stats[1:]:
            thick, pos = (w, x + w / 2) if axis == 'vertical' else (h, y + h / 2)
            limit = W if axis == 'vertical' else H
            if thick > 0.015 * limit or pos < 0.04 * limit or pos > 0.96 * limit:
                continue  # glyph stem or the border
            u = cw / W if axis == 'vertical' else ch / H
            if axis == 'vertical' and any(a - 1 <= pos * u <= b + 1 for a, b in glyphs):
                continue  # inside a character
            out.append({'axis': axis, 'at': round(pos * u, 1), 'thickness': round(thick * u, 1)})
    return out


def ocr_rows(im: np.ndarray, rows: list[dict], cw: float, ch: float) -> list[dict]:
    """tesseract per measured row. Languages: every installed one that is
    not osd; the result says which, so a Latin-only read of Lao is visible."""
    import shutil
    import subprocess
    import tempfile
    if not shutil.which('tesseract'):
        return []
    langs = [l for l in subprocess.run(['tesseract', '--list-langs'], capture_output=True,
                                       text=True).stdout.split()[1:] if l not in ('osd', 'snum')]
    lang = '+'.join(langs) or 'eng'
    H, W = im.shape[:2]
    out = []
    for r in rows:
        y0, y1 = int(r['y'][0] / ch * H), int(r['y'][1] / ch * H)
        x0, x1 = int(r['x'][0] / cw * W), int(r['x'][1] / cw * W)
        crop = cv2.cvtColor(im[max(0, y0 - 4):y1 + 4, max(0, x0 - 4):x1 + 4], cv2.COLOR_BGR2GRAY)
        crop = cv2.threshold(cv2.resize(crop, None, fx=2, fy=2), 0, 255,
                             cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]
        if crop.mean() < 127:
            crop = 255 - crop
        with tempfile.NamedTemporaryFile(suffix='.png') as f:
            cv2.imwrite(f.name, crop)
            text = subprocess.run(['tesseract', f.name, '-', '--psm', '7', '-l', lang],
                                  capture_output=True, text=True).stdout.strip()
        out.append({'y': r['y'], 'text': text, 'lang': lang})
    return out
