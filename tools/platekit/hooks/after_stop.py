#!/usr/bin/env python3
"""Stop hook — the "after" stage.

When the LLM says it is done, run the checks it would otherwise run (and
read in full): analyze and test for every package touched since HEAD, the
golden targets if a `.plateref/<code>/targets.json` exists, and the commit
plan. If anything fails, exit 2 with the reduced report so the LLM keeps
going; `stop_hook_active` prevents a loop when it cannot fix it.
"""
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from platekit import gitplan, logfilter  # noqa: E402

event = json.load(sys.stdin)
if event.get('stop_hook_active'):
    sys.exit(0)
root = Path(event.get('cwd', '.'))
changed = subprocess.run(['git', '-C', str(root), 'status', '--porcelain'],
                         capture_output=True, text=True).stdout.splitlines()
pkgs = sorted({l[3:].split('/')[0] for l in changed if l[3:].split('/')[0].endswith(('_plate', '_holder'))})
pkgs = [p for p in pkgs if (root / p / 'pubspec.yaml').exists()]
report = []
for p in pkgs:
    issues = [i for i in logfilter.analyze(logfilter.run(['flutter', 'analyze'], root / p))
              if not i.startswith('info')]
    report += [f'{p}: {i}' for i in issues]
    t = logfilter.tests(logfilter.run(['flutter', 'test'], root / p))
    if t['failures']:
        report.append(f'{p}: ' + logfilter.render(t))
if report:
    print('\n'.join(report), file=sys.stderr)
    sys.exit(2)
plan = gitplan.plan(root)
if plan:
    print('checks pass. uncommitted, innermost first:\n' + gitplan.render(plan))
