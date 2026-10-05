"""Stage 5: `flutter test` / `flutter analyze` output, reduced to what to fix.

A failing holder run printed ~40 KB per overflow (the whole widget chain,
the painting stack, the "consider" advice) and the LLM read all of it to
learn three facts: which test, which file:line, how many pixels. This keeps
those facts and drops the rest.
"""
from __future__ import annotations

import re
import subprocess
from pathlib import Path

_TEST_START = re.compile(r'^\d\d:\d\d \+\d+(?: ~\d+)?(?: -\d+)?: (.+?)(?: \[E\])?$')
_OVERFLOW = re.compile(r'A (\w+) overflowed by ([\d.]+) pixels on the (\w+)')
_CREATED = re.compile(r'(?:was|is):\s*\n?\s*(\w+).*?file://(\S+?):(\d+):(\d+)', re.S)
_EXPECT = re.compile(r'^\s*(Expected|Actual|Which):\s*(.*)$')
_LOC = re.compile(r'(?:package:|file://)(\S+?\.dart)[ :](\d+)(?::(\d+))?')
_ANALYZE = re.compile(r'^\s*(error|warning|info) • (.+?) • (\S+?):(\d+):(\d+) • (\S+)$')


def run(cmd: list[str], cwd: Path) -> str:
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    return p.stdout + p.stderr


def tests(log: str) -> dict:
    """Failures grouped by test, each as a few short lines."""
    failures: dict[str, list[str]] = {}
    current = None
    lines = log.splitlines()
    summary = ''
    for i, line in enumerate(lines):
        m = _TEST_START.match(line.strip())
        if m:
            current = m.group(1)
            if line.rstrip().endswith('[E]'):
                failures.setdefault(current, [])
            summary = line.strip()
            continue
        if current is None:
            continue
        o = _OVERFLOW.search(line)
        if o:
            block = '\n'.join(lines[i:i + 40])
            c = _CREATED.search(block)
            where = f'{c.group(2).split("/lib/")[-1]}:{c.group(3)} ({c.group(1)})' if c else '?'
            failures.setdefault(current, []).append(
                f'overflow {o.group(1)} by {o.group(2)} px {o.group(3)} at {where}')
            continue
        e = _EXPECT.match(line)
        if e:
            failures.setdefault(current, []).append(f'{e.group(1)}: {e.group(2)[:160]}')
            continue
        if 'Exception' in line and 'caught by' not in line and len(line) < 300:
            failures.setdefault(current, []).append(line.strip()[:200])
        elif line.lstrip().startswith(('test/', 'lib/')) or (_LOC.search(line) and '/flutter/packages/' not in line
                                                           and 'dart:' not in line and current in failures):
            loc = _LOC.search(line)
            if loc and '/test/' in loc.group(1) or loc and '/lib/' in loc.group(1):
                ref = f'at {loc.group(1).split("/", 1)[-1]}:{loc.group(2)}'
                if ref not in failures.setdefault(current, []):
                    failures[current].append(ref)
    # de-duplicate while keeping order, cap per test
    clean = {k: list(dict.fromkeys(v))[:8] for k, v in failures.items()}
    return {'summary': summary, 'failed': len(clean), 'failures': clean}


def analyze(log: str) -> list[str]:
    out = []
    for line in log.splitlines():
        m = _ANALYZE.match(line)
        if m:
            sev, msg, f, ln, _, code = m.groups()
            out.append(f'{sev} {f}:{ln} {code}: {msg}')
    return out


def render(t: dict) -> str:
    if not t['failures']:
        return f'all passed — {t["summary"]}'
    out = [f'{t["failed"]} failing — {t["summary"]}']
    for name, facts in t['failures'].items():
        out.append(f'* {name}')
        out += [f'    {f}' for f in facts]
    return '\n'.join(out)


def overflow_probe(widget_test: Path) -> str:
    """The trick that found the tile and breadcrumb culprits: a test that
    sets `FlutterError.onError` to print only the creator chain's first
    project-owned frame. Returned as Dart source to drop into test/."""
    return '''import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prints, for every layout overflow, the first widget in the creator
/// chain that lives in this package — instead of the full report.
void reportOverflowsBriefly() {
  FlutterError.onError = (FlutterErrorDetails d) {
    final String text = d.toString();
    final RegExpMatch? amount = RegExp(r'overflowed by ([\\d.]+) pixels on the (\\w+)').firstMatch(text);
    final RegExpMatch? where = RegExp(r'(lib/\\S+\\.dart:\\d+)').firstMatch(text);
    debugPrint('OVERFLOW ${amount?.group(1)} px ${amount?.group(2)} at ${where?.group(1)}');
  };
}
'''
