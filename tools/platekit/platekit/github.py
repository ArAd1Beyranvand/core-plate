"""GitHub repo per package: created by `before`, pushed by `after` (gh CLI)."""
from __future__ import annotations

import shutil
import subprocess
from pathlib import Path


def _run(cmd: list[str], cwd: Path) -> tuple[int, str]:
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    return p.returncode, (p.stdout + p.stderr).strip()


def ready() -> str | None:
    """None when gh is installed and logged in, else the reason."""
    if not shutil.which('gh'):
        return 'gh is not installed (https://cli.github.com)'
    code, out = _run(['gh', 'auth', 'status'], Path.cwd())
    return None if code == 0 else 'gh is not logged in: run `gh auth login`'


def create(pkg_dir: Path, public: bool = False) -> str:
    """git init + an empty GitHub repo named after the package + origin."""
    if not (pkg_dir / '.git').exists():
        _run(['git', 'init', '-b', 'main'], pkg_dir)
    code, url = _run(['git', 'remote', 'get-url', 'origin'], pkg_dir)
    if code == 0:
        return f'origin already set: {url}'
    code, out = _run(['gh', 'repo', 'create', pkg_dir.name, '--public' if public else '--private'], pkg_dir)
    if code != 0 and 'already exists' not in out:
        raise RuntimeError(out)
    _, login = _run(['gh', 'api', 'user', '-q', '.login'], pkg_dir)
    url = f'https://github.com/{login}/{pkg_dir.name}.git'
    _run(['git', 'remote', 'add', 'origin', url], pkg_dir)
    return f'created {url}'


def push(pkg_dir: Path, message: str) -> str:
    if not (pkg_dir / '.git').exists():
        return 'no repo (run before with --github); skipped'
    _run(['git', 'add', '-A'], pkg_dir)
    _run(['git', 'commit', '-q', '-m', message], pkg_dir)
    code, out = _run(['git', 'push', '-u', 'origin', 'HEAD'], pkg_dir)
    if code != 0:
        raise RuntimeError(out)
    return out.splitlines()[-1] if out else 'pushed'
