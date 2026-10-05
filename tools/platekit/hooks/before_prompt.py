#!/usr/bin/env python3
"""UserPromptSubmit hook — the "before" stage.

When the prompt names a Wikipedia plates article, run the offline pipeline
(fetch → photos → local model → brief) before the LLM starts, and hand it
the brief's path as context. The LLM then begins by reading a few KB of
facts instead of 120 KB of HTML and a dozen photos.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

TOOL = Path(__file__).resolve().parent.parent / 'pk.py'

event = json.load(sys.stdin)
m = re.search(r'wikipedia\.org/wiki/Vehicle_registration_plates_of_([A-Za-z_%()-]+)', event.get('prompt', ''))
if not m:
    sys.exit(0)
country = m.group(1).replace('_', ' ')
root = Path(event.get('cwd', '.'))
code_m = re.search(r'\bcode[:= ]+([a-z]{2})\b', event['prompt'])
code = code_m.group(1) if code_m else re.sub(r'[^a-z]', '', country.lower())[:2]
work = root / '.plateref' / code
if (work / 'brief.md').exists():
    print(f'platekit: offline brief already at {work}/brief.md — read it first.')
    sys.exit(0)
p = subprocess.run([sys.executable, str(TOOL), 'all', country, code], cwd=root,
                   capture_output=True, text=True, timeout=900)
if p.returncode == 0 and (work / 'brief.md').exists():
    print(f'platekit ran offline for {country}: read {work}/brief.md and '
          f'{work}/sheet_flat.png before anything else; they replace Phase 1 '
          f'reading of the article and photos.')
else:
    print(f'platekit failed for {country} (continue manually):\n{p.stderr[-800:]}')
