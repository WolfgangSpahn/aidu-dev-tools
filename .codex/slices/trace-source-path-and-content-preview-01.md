# Slice 01: Improve trace message content preview

Implement only the trace message preview change.

Required behavior:

- In the trace message list, replace weak semantic summaries like:

  ```text
  content: Applet event: applet-create-a-molecule
  ```

  with a compact structural preview of the actual message content.

- For dictionary-like content, show top-level keys and abbreviate nested values.

Expected style:

```text
content: {'applet': 'applet-create-a-molecule', 'infoStore': {...}}
```

or similar.

Constraints:

- Do not dump the full applet state into the trace message line.
- Keep the existing rich trace layout.
- Do not change agent execution.
- Do not change the artifact content block.
- Do not implement source-path display in this slice.