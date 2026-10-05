"""The local model: ollama, JSON-constrained, for yes/no questions only.

Measured on the Laos private plate: qwen3.5:4b answered the layout
booleans correctly (one text row above the serial, no badge, Lao script)
in 26 s, and named the field "yellow" where the pixels say FFAF00 amber.
So it gets questions whose answers are categories, never numbers or
colours; those come from `vision`. Every answer is checked against the
schema in the prompt file and anything malformed counts as "unknown".
"""
from __future__ import annotations

import base64
import json
import urllib.request
from pathlib import Path

OLLAMA = 'http://127.0.0.1:11434/api/generate'
PROMPTS = Path(__file__).resolve().parent.parent / 'prompts'
VISION_MODEL = 'qwen3.5:4b'
TEXT_MODEL = 'qwen3.5:0.8b'


def available() -> bool:
    try:
        urllib.request.urlopen('http://127.0.0.1:11434/api/tags', timeout=2)
        return True
    except Exception:
        return False


def load_prompt(name: str) -> tuple[str, dict]:
    """`prompts/<name>.md`: the prompt, then a ```json schema block."""
    text = (PROMPTS / f'{name}.md').read_text()
    body, _, rest = text.partition('```json')
    schema = json.loads(rest.split('```', 1)[0])
    return body.strip(), schema


def ask(prompt: str, schema: dict, *, images: list[Path] = (), model: str | None = None,
        timeout: int = 180) -> dict:
    payload = {
        'model': model or (VISION_MODEL if images else TEXT_MODEL),
        'prompt': prompt,
        'format': schema,
        'stream': False,
        'think': False,
        'options': {'temperature': 0},
    }
    if images:
        payload['images'] = [base64.b64encode(Path(p).read_bytes()).decode() for p in images]
    req = urllib.request.Request(OLLAMA, json.dumps(payload).encode(),
                                 {'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = json.loads(r.read())['response']
    try:
        answer = json.loads(raw)
    except json.JSONDecodeError:
        return {k: 'unknown' for k in schema.get('properties', {})}
    return _validate(answer, schema)


def _validate(answer: dict, schema: dict) -> dict:
    out = {}
    for k, spec in schema.get('properties', {}).items():
        v = answer.get(k, 'unknown')
        if 'enum' in spec and v not in spec['enum']:
            v = 'unknown'
        if spec.get('type') == 'boolean' and not isinstance(v, bool):
            v = 'unknown'
        if spec.get('type') == 'integer' and not isinstance(v, int):
            v = 'unknown'
        out[k] = v
    return out


def ask_named(name: str, images: list[Path] = (), **fill) -> dict:
    prompt, schema = load_prompt(name)
    return ask(prompt.format(**fill) if fill else prompt, schema, images=images)
