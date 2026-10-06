This is a small crop from a vehicle licence plate: one coloured region
that differs from the plate's background. What is it? Pick one.

- "flag": a national flag
- "text_badge": a box with letters in it (country code, "EV", region code)
- "emblem": coat of arms, seal, round logo
- "sticker": a stuck-on label or inspection sticker
- "band": a plain coloured strip
- "character": part of the plate's own letters or digits
- "noise": a screw, reflection, dirt, the edge or the mount

```json
{
  "type": "object",
  "properties": {
    "kind": {"type": "string", "enum": ["flag", "text_badge", "emblem", "sticker", "band", "character", "noise", "unknown"]},
    "has_text": {"type": "boolean"}
  },
  "required": ["kind", "has_text"]
}
```
