Two flattened licence plates are shown, first and second. Ignore the
colours and the characters. Do they share one layout — the same rows, the
same badge position, text in the same places?

```json
{
  "type": "object",
  "properties": {
    "same_layout": {"type": "boolean"},
    "difference": {"type": "string", "enum": ["rows", "badge", "caption", "prefix", "none", "unknown"]}
  },
  "required": ["same_layout", "difference"]
}
```
