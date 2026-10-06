You are looking at one flattened photo of a vehicle licence plate.
Answer only with the categories offered; say "unknown" if you cannot tell.
Do not name colours precisely or read the characters.

- band: is there a coloured strip running the full height or width of one
  side, different from the main background? "left", "right", "top",
  "bottom", "none".
- flag: is a national flag printed on the plate? "left", "right", "top",
  "none".
- emblem: a coat of arms, seal or round logo? "left", "right", "top",
  "centre", "none".
- sticker: a small stuck-on label or inspection sticker? true/false.
- divider: a printed line separating parts of the plate? "vertical",
  "horizontal", "both", "none".
- divider_count: how many such lines (0 if none).
- two_tone: is the background split into two different colours?
  true/false.
- frame_text: is there small text outside the main characters, like a
  dealer name or a country word? true/false.

```json
{
  "type": "object",
  "properties": {
    "band": {"type": "string", "enum": ["left", "right", "top", "bottom", "none", "unknown"]},
    "flag": {"type": "string", "enum": ["left", "right", "top", "none", "unknown"]},
    "emblem": {"type": "string", "enum": ["left", "right", "top", "centre", "none", "unknown"]},
    "sticker": {"type": "boolean"},
    "divider": {"type": "string", "enum": ["vertical", "horizontal", "both", "none", "unknown"]},
    "divider_count": {"type": "integer"},
    "two_tone": {"type": "boolean"},
    "frame_text": {"type": "boolean"}
  },
  "required": ["band", "flag", "emblem", "sticker", "divider", "divider_count", "two_tone", "frame_text"]
}
```
