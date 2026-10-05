"""Stage 6: commit order across the nested repositories — no model.

The workspace has repositories inside it (plate_number_holder, plate_alphabet,
older country packages). A change has to be committed innermost first so
the parent records the new gitlink. This lists dirty repos in that order
with their changed files; the LLM only writes the messages.
"""
from __future__ import annotations

import subprocess
from pathlib import Path


def _git(repo: Path, *args: str) -> str:
    return subprocess.run(['git', '-C', str(repo), *args], capture_output=True, text=True).stdout


def repos(root: Path) -> list[Path]:
    found = [root]
    for d in sorted(root.iterdir()):
        if (d / '.git').exists():
            found.append(d)
    return found


def plan(root: Path) -> list[dict]:
    out = []
    for repo in repos(root)[1:] + [root]:  # inner first, parent last
        # build/ caches are tracked in some older packages; never commit them
        status = [s for s in _git(repo, 'status', '--porcelain').splitlines()
                  if not s[3:].startswith('build/')]
        if status:
            out.append({'repo': str(repo.relative_to(root)) or '.', 'changes': status})
    return out


def render(p: list[dict]) -> str:
    if not p:
        return 'nothing to commit'
    lines = []
    for i, r in enumerate(p, 1):
        lines.append(f"{i}. {r['repo']}")
        lines += [f'     {c}' for c in r['changes'][:30]]
        if len(r['changes']) > 30:
            lines.append(f"     … {len(r['changes']) - 30} more")
    return '\n'.join(lines)
