#!/usr/bin/env python3
"""PostToolUse hook on Edit|Write — the "while" stage.

After every Dart edit: format the file and analyze its package, and hand
back only the issues (one line each). Exit 2 puts them in front of the LLM
immediately, so it fixes them in the next step instead of discovering them
from a 40 KB test log later. Silent when clean.
"""
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from platekit import logfilter  # noqa: E402

event = json.load(sys.stdin)
path = Path(event.get('tool_input', {}).get('file_path', ''))
if path.suffix != '.dart' or not path.exists():
    sys.exit(0)
pkg = next((d for d in path.parents if (d / 'pubspec.yaml').exists()), None)
if pkg is None:
    sys.exit(0)
subprocess.run(['dart', 'format', str(path)], capture_output=True)
issues = logfilter.analyze(logfilter.run(['dart', 'analyze', str(path)], pkg))
issues = [i for i in issues if not i.startswith('info')]
if issues:
    print('\n'.join(issues[:15]), file=sys.stderr)
    sys.exit(2)
