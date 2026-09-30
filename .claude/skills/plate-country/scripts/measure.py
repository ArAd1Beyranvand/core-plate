"""Normalise a plate image to its true coordinate space and project the ink.

Run it over a reference and over the matching golden to get two comparable
sets of numbers.

    python3 measure.py ref.png "REF taxi" FFEC00 1D1D1B 335 155
    python3 measure.py golden.png "MINE taxi" FFEC00 1D1D1B 335 155 --crop

--crop first trims the image to its content, for goldens rendered on a page
background that a colour mask would otherwise swallow the whole image into.
"""
import sys

import numpy as np
from PIL import Image


def _runs(mask, min_len=1):
    on, out, start = mask, [], None
    for i, v in enumerate(on):
        if v and start is None:
            start = i
        elif not v and start is not None:
            if i - start >= min_len:
                out.append((start, i - 1))
            start = None
    if start is not None:
        out.append((start, len(on) - 1))
    return out


def crop_to_content(path, out='/tmp/_plate_crop.png'):
    """Trim a golden to its plate, using the corner pixel as the page colour."""
    im = Image.open(path).convert('RGB')
    a = np.array(im).astype(int)
    m = np.abs(a - a[0, 0]).sum(2) > 20
    c, r = np.where(m.any(0))[0], np.where(m.any(1))[0]
    im.crop((c[0], r[0], c[-1] + 1, r[-1] + 1)).save(out)
    return out


def analyse(path, field, ink, cw, ch, label=''):
    im = np.array(Image.open(path).convert('RGB')).astype(int)
    near = lambda c, t=60: np.abs(im - np.array(c)).sum(2) < t
    plate = near(field) | near(ink)
    cols, rows = np.where(plate.any(0))[0], np.where(plate.any(1))[0]
    x0, x1, y0, y1 = cols[0], cols[-1], rows[0], rows[-1]
    pw, ph = x1 - x0 + 1, y1 - y0 + 1
    sx, sy = cw / pw, ch / ph
    # Inset 5% to keep the frame and its rounded corners out of the numbers.
    dx, dy = int(pw * .05), int(ph * .05)
    sub = near(ink)[y0 + dy:y1 - dy, x0 + dx:x1 - dx]

    print(f'== {label or path}   plate {pw}x{ph}  ar={pw / ph:.3f}')

    # A near-full-height column of ink is a divider rule, not a glyph.
    colfrac = sub.sum(0) / sub.shape[0]
    rule = [i for i, v in enumerate(colfrac) if v > 0.85]
    if rule:
        print(f'   rule  x {(rule[0] + dx) * sx:6.1f}..{(rule[-1] + 1 + dx) * sx:6.1f}')
        rx = rule[-1] + 1
    else:
        print('   rule  none')
        rx = 0

    right = sub[:, rx:]
    for a, b in _runs(right.any(1)):
        if (b - a) * sy < 3:
            continue
        c = np.where(right[a:b + 1].any(0))[0]
        print(f'   row   y {(a + dy) * sy:6.1f}..{(b + 1 + dy) * sy:6.1f} '
              f'h={(b - a + 1) * sy:5.1f}   '
              f'x {(c[0] + rx + dx) * sx:6.1f}..{(c[-1] + 1 + rx + dx) * sx:6.1f}')

    if rx:
        left = sub[:, :max(rx - 2, 1)]
        if left.any():
            c, r = np.where(left.any(0))[0], np.where(left.any(1))[0]
            print(f'   left  x {(c[0] + dx) * sx:6.1f}..{(c[-1] + 1 + dx) * sx:6.1f} '
                  f'y {(r[0] + dy) * sy:6.1f}..{(r[-1] + 1 + dy) * sy:6.1f}')


def region(path, field, ink, cw, ch, box, label=''):
    """Ink bbox inside an explicit window, for bands the full-image bbox pollutes."""
    im = np.array(Image.open(path).convert('RGB')).astype(int)
    near = lambda c, t=60: np.abs(im - np.array(c)).sum(2) < t
    plate = near(field) | near(ink)
    cols, rows = np.where(plate.any(0))[0], np.where(plate.any(1))[0]
    x0, y0 = cols[0], rows[0]
    pw, ph = cols[-1] - x0 + 1, rows[-1] - y0 + 1
    sx, sy = cw / pw, ch / ph
    lo_x, lo_y, hi_x, hi_y = box
    ax, bx = int(x0 + lo_x / sx), int(x0 + hi_x / sx)
    ay, by = int(y0 + lo_y / sy), int(y0 + hi_y / sy)
    sub = near(ink)[ay:by, ax:bx]
    if not sub.any():
        print(f'{label}: no ink in {box}')
        return
    c, r = np.where(sub.any(0))[0], np.where(sub.any(1))[0]
    print(f'{label or path}  x {(ax + c[0] - x0) * sx:6.1f}..{(ax + c[-1] + 1 - x0) * sx:6.1f}'
          f'  y {(ay + r[0] - y0) * sy:6.1f}..{(ay + r[-1] + 1 - y0) * sy:6.1f}')


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if a != '--crop']
    hx = lambda s: tuple(int(s[i:i + 2], 16) for i in (0, 2, 4))
    path, label, field, ink = args[0], args[1], hx(args[2]), hx(args[3])
    cw = float(args[4]) if len(args) > 4 else 335.0
    ch = float(args[5]) if len(args) > 5 else 155.0
    if '--crop' in sys.argv:
        path = crop_to_content(path)
    analyse(path, field, ink, cw, ch, label)
