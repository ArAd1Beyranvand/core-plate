#!/usr/bin/env python3
"""platekit GUI — run `before` / `after` (or any command) and watch each
step land on a timeline: text output, and every image the step wrote.

    python3 tools/platekit/gui.py        (from the workspace root)
"""
from __future__ import annotations

import queue
import re
import subprocess
import sys
import threading
import time
import tkinter as tk
from pathlib import Path
from tkinter import ttk

from PIL import Image, ImageTk

ROOT = Path.cwd()
PK = Path(__file__).resolve().parent / 'pk.py'
IMG = re.compile(r'\.(png|jpe?g|webp)$', re.I)

BG, CARD, FG, DIM, ACCENT, OK, BAD = '#0f1115', '#181b22', '#e6e6e6', '#8a8f98', '#7aa2f7', '#9ece6a', '#f7768e'
MONO = ('JetBrains Mono', 10) if sys.platform != 'darwin' else ('Menlo', 11)


class Timeline(tk.Frame):
    """A scrollable column of step cards."""

    def __init__(self, master):
        super().__init__(master, bg=BG)
        self.canvas = tk.Canvas(self, bg=BG, highlightthickness=0)
        bar = ttk.Scrollbar(self, orient='vertical', command=self.canvas.yview)
        self.inner = tk.Frame(self.canvas, bg=BG)
        self.inner.bind('<Configure>', lambda e: self.canvas.configure(scrollregion=self.canvas.bbox('all')))
        self.win = self.canvas.create_window((0, 0), window=self.inner, anchor='nw')
        self.canvas.bind('<Configure>', lambda e: self.canvas.itemconfigure(self.win, width=e.width))
        self.canvas.configure(yscrollcommand=bar.set)
        self.canvas.pack(side='left', fill='both', expand=True)
        bar.pack(side='right', fill='y')
        for seq in ('<MouseWheel>', '<Button-4>', '<Button-5>'):
            self.canvas.bind_all(seq, self._wheel)
        self.photos = []  # keep PhotoImage references alive

    def _wheel(self, e):
        self.canvas.yview_scroll(-1 if (e.num == 4 or e.delta > 0) else 1, 'units')

    def card(self, title: str, colour: str = ACCENT) -> 'Card':
        c = Card(self, title, colour)
        c.pack(fill='x', padx=14, pady=6)
        self.after(50, lambda: self.canvas.yview_moveto(1.0))
        return c

    def clear(self):
        for w in self.inner.winfo_children():
            w.destroy()
        self.photos.clear()


class Card(tk.Frame):
    def __init__(self, tl: Timeline, title: str, colour: str):
        super().__init__(tl.inner, bg=CARD, highlightthickness=1, highlightbackground='#262a33')
        self.tl = tl
        head = tk.Frame(self, bg=CARD)
        head.pack(fill='x', padx=10, pady=(8, 4))
        self.dot = tk.Label(head, text='●', fg=colour, bg=CARD, font=('Sans', 11))
        self.dot.pack(side='left')
        tk.Label(head, text=title, fg=FG, bg=CARD, font=('Sans', 11, 'bold')).pack(side='left', padx=6)
        self.clock = tk.Label(head, text=time.strftime('%H:%M:%S'), fg=DIM, bg=CARD, font=('Sans', 9))
        self.clock.pack(side='right')
        self.text = tk.Text(self, bg=CARD, fg=FG, font=MONO, relief='flat', height=1, wrap='word',
                            insertbackground=FG, highlightthickness=0)
        self.text.tag_configure('bad', foreground=BAD)
        self.text.tag_configure('ok', foreground=OK)
        self.text.tag_configure('dim', foreground=DIM)
        self.text.pack(fill='x', padx=10)
        self.gallery = tk.Frame(self, bg=CARD)
        self.gallery.pack(fill='x', padx=10, pady=(4, 8))
        self.lines = 0
        self.shown: set[Path] = set()

    def write(self, line: str):
        tag = ('bad' if re.search(r'FAIL|CHECK|error|Traceback|issues', line)
               else 'ok' if re.search(r'\bok\b|clean|pass|Done', line, re.I) else '')
        self.text.insert('end', line + '\n', tag)
        self.lines += 1
        self.text.configure(height=min(self.lines, 18))
        self.text.see('end')

    def image(self, path: Path, max_w: int = 360, max_h: int = 220):
        if path in self.shown:
            return
        try:
            im = Image.open(path)
            im.thumbnail((max_w, max_h))
        except Exception:
            return
        self.shown.add(path)
        ph = ImageTk.PhotoImage(im)
        self.tl.photos.append(ph)
        cell = tk.Frame(self.gallery, bg=CARD)
        lbl = tk.Label(cell, image=ph, bg=CARD, cursor='hand2')
        lbl.pack()
        lbl.bind('<Button-1>', lambda e: subprocess.Popen(['xdg-open', str(path)]))
        tk.Label(cell, text=path.name[:48], fg=DIM, bg=CARD, font=('Sans', 8)).pack()
        n = len(self.gallery.winfo_children()) - 1
        cell.grid(row=n // 3, column=n % 3, padx=4, pady=4, sticky='nw')

    def done(self, ok: bool):
        self.dot.configure(fg=OK if ok else BAD)
        self.clock.configure(text=self.clock.cget('text') + ' → ' + time.strftime('%H:%M:%S'))


class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title('platekit')
        self.geometry('1180x860')
        self.configure(bg=BG)
        style = ttk.Style(self)
        style.theme_use('clam')
        style.configure('TButton', background='#262a33', foreground=FG, borderwidth=0, padding=(14, 7))
        style.map('TButton', background=[('active', '#323846'), ('disabled', '#1c1f26')])
        style.configure('Accent.TButton', background=ACCENT, foreground='#0f1115')
        style.map('Accent.TButton', background=[('active', '#99b8ff')])
        style.configure('Vertical.TScrollbar', background='#262a33', troughcolor=BG, borderwidth=0, arrowsize=0)

        top = tk.Frame(self, bg=BG)
        top.pack(fill='x', padx=14, pady=(14, 6))
        tk.Label(top, text='Wikipedia URL', fg=DIM, bg=BG).pack(side='left')
        self.url = tk.Entry(top, bg=CARD, fg=FG, insertbackground=FG, relief='flat', font=MONO)
        self.url.insert(0, 'https://en.wikipedia.org/wiki/Vehicle_registration_plates_of_')
        self.url.pack(side='left', fill='x', expand=True, padx=8, ipady=6)
        self.flags = tk.Entry(top, bg=CARD, fg=FG, insertbackground=FG, relief='flat', font=MONO, width=30)
        self.flags.insert(0, '--no-ask --github --push')
        self.flags.pack(side='left', ipady=6)
        self.buttons = [
            ttk.Button(top, text='Before', style='Accent.TButton', command=lambda: self.pk('before')),
            ttk.Button(top, text='After', style='Accent.TButton', command=lambda: self.pk('after')),
            ttk.Button(top, text='Clear', command=lambda: self.tl.clear()),
        ]
        for b in self.buttons:
            b.pack(side='left', padx=(8, 0))
        self.stop_btn = ttk.Button(top, text='Stop', command=self.stop)
        self.stop_btn.pack(side='left', padx=(8, 0))

        bar = tk.Frame(self, bg=BG)
        bar.pack(fill='x', padx=14)
        style.configure('P.Horizontal.TProgressbar', troughcolor=CARD, background=ACCENT,
                        bordercolor=CARD, lightcolor=ACCENT, darkcolor=ACCENT, thickness=8)
        self.prog = ttk.Progressbar(bar, style='P.Horizontal.TProgressbar', maximum=1000)
        self.prog.pack(fill='x')
        self.status = tk.Label(bar, text='idle', fg=DIM, bg=BG, font=('Sans', 9), anchor='w')
        self.status.pack(fill='x', pady=(2, 0))
        self.step = (0, 1, '')   # n, total, title
        self.started = 0.0
        self.after(500, self.tick)

        self.tl = Timeline(self)
        self.tl.pack(fill='both', expand=True, pady=4)

        term = tk.Frame(self, bg=BG)
        term.pack(fill='x', padx=14, pady=(4, 14))
        tk.Label(term, text='$', fg=ACCENT, bg=BG, font=MONO).pack(side='left')
        self.cmd = tk.Entry(term, bg=CARD, fg=FG, insertbackground=FG, relief='flat', font=MONO)
        self.cmd.pack(side='left', fill='x', expand=True, padx=8, ipady=6)
        self.cmd.bind('<Return>', lambda e: self.shell(self.cmd.get()))
        tk.Label(term, text=str(ROOT), fg=DIM, bg=BG, font=('Sans', 8)).pack(side='left')

        self.q: queue.Queue = queue.Queue()
        self.proc: subprocess.Popen | None = None
        self.after(60, self.pump)

    # --------------------------------------------------------------- running
    def pk(self, stage: str):
        url = self.url.get().strip()
        before_only = {'--no-ask', '--github', '--public'}
        after_only = {'--push', '--full'}
        drop = after_only if stage == 'before' else before_only
        flags = [f for f in self.flags.get().split() if f not in drop]
        self.run([sys.executable, '-u', str(PK), stage, url, *flags],
                 f'pk {stage}', watch=True)

    def shell(self, line: str):
        if line.strip():
            self.cmd.delete(0, 'end')
            self.run(['bash', '-lc', line], f'$ {line}', watch=True)

    def run(self, argv: list[str], title: str, watch: bool):
        if self.proc and self.proc.poll() is None:
            self.tl.card('busy — stop the running command first', BAD).done(False)
            return
        self.q.put(('card', title))
        self.proc = subprocess.Popen(argv, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                     text=True, bufsize=1, env={**__import__('os').environ,
                                                                'PYTHONUNBUFFERED': '1'})
        threading.Thread(target=self._read, args=(self.proc, watch), daemon=True).start()

    def _read(self, proc: subprocess.Popen, watch: bool):
        since = time.time()
        for raw in proc.stdout:
            line = raw.rstrip('\n')
            if line.startswith('== '):  # a pk step boundary
                if watch:
                    self.q.put(('images', since))
                since = time.time()
                self.q.put(('card', line[3:]))
                continue
            self.q.put(('line', line))
        code = proc.wait()
        if watch:
            self.q.put(('images', since))
        self.q.put(('end', code))

    def set_progress(self, sub: float):
        n, total, _ = self.step
        if n:
            self.prog.configure(value=1000 * ((n - 1) + sub) / total)

    def tick(self):
        if self.started:
            n, total, title = self.step
            where = f'step {n}/{total} · {title}' if n else title
            self.status.configure(text=f'{where} · {time.time() - self.started:.0f}s', fg=FG)
        self.after(500, self.tick)

    def stop(self):
        if self.proc and self.proc.poll() is None:
            self.proc.terminate()

    # ---------------------------------------------------------- ui updates
    def pump(self):
        try:
            while True:
                kind, val = self.q.get_nowait()
                if kind == 'card':
                    if getattr(self, 'current', None):
                        self.current.done(True)
                    self.current = self.tl.card(val)
                    m = re.match(r'(\d+)/(\d+)\s*(.*)', val)
                    if m:
                        self.step = (int(m.group(1)), int(m.group(2)), m.group(3))
                        self.set_progress(0)
                    elif not val.startswith(('pk ', '$ ')):
                        self.step = (self.step[0], self.step[1], val)
                    else:
                        self.step, self.started = (0, 1, val), time.time()
                        self.prog.configure(value=0)
                elif kind == 'line':
                    self.current.write(val)
                    m = re.match(r'\[(\d+)/(\d+)\]', val)
                    if m:
                        self.set_progress((int(m.group(1)) - 1) / int(m.group(2)))
                    for m in re.finditer(r'(\S+\.(?:png|jpe?g|webp))', val):
                        p = (ROOT / m.group(1)).resolve()
                        if p.exists():
                            self.current.image(p)
                elif kind == 'images':
                    for p in self._new_images(val):
                        self.current.image(p)
                elif kind == 'end':
                    self.current.write(f'exit {val}')
                    self.current.done(val == 0)
                    self.prog.configure(value=1000)
                    self.status.configure(text=f"{'done' if val == 0 else 'FAILED'} in "
                                               f"{time.time() - self.started:.0f}s",
                                          fg=OK if val == 0 else BAD)
                    self.started = 0.0
                    self.current = None
        except queue.Empty:
            pass
        self.after(60, self.pump)

    def _new_images(self, since: float, limit: int = 12) -> list[Path]:
        """Images written under .plateref/ or test/goldens since `since`."""
        found = []
        for base in [ROOT / '.plateref', *ROOT.glob('*_plate/test/goldens')]:
            if not base.exists():
                continue
            for p in base.rglob('*'):
                if IMG.search(p.name) and p.stat().st_mtime >= since - 1:
                    found.append(p)
        # sheets first, then the rest; originals last (they are huge)
        found.sort(key=lambda p: ('sheet' not in p.name, p.name.startswith('orig_'), p.name))
        return found[:limit]


if __name__ == '__main__':
    App().mainloop()
