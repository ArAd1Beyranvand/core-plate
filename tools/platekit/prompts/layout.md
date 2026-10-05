You are looking at one flattened photo of a vehicle licence plate.
Answer only about layout, with the categories offered. Do not guess
colours, sizes or the characters themselves. If you cannot tell, answer
"unknown".

- text_rows: how many separate rows of characters are on the plate?
- top_row: what the uppermost row holds — "caption" (a word or name in
  smaller letters), "serial" (the main registration characters), or "none".
- badge: is there a separate box, emblem, flag or coloured band at one end?
  "left", "right", "none".
- script: the writing of the serial — "latin", "arabic", "lao", "thai",
  "cyrillic", "chinese", "other".
- separator: between the serial's groups — "dash", "dot", "space", "none".
- border: is there a printed border line inside the plate's edge?
- vertical_text: is any text rotated 90° or stacked letter over letter?

```json
{
  "type": "object",
  "properties": {
    "text_rows": {"type": "integer"},
    "top_row": {"type": "string", "enum": ["caption", "serial", "none", "unknown"]},
    "badge": {"type": "string", "enum": ["left", "right", "none", "unknown"]},
    "script": {"type": "string", "enum": ["latin", "arabic", "lao", "thai", "cyrillic", "chinese", "other", "unknown"]},
    "separator": {"type": "string", "enum": ["dash", "dot", "space", "none", "unknown"]},
    "border": {"type": "boolean"},
    "vertical_text": {"type": "boolean"}
  },
  "required": ["text_rows", "top_row", "badge", "script", "separator", "border", "vertical_text"]
}
```
