# Feature: Improve agent trace display

## Context

The trace output generated from:

/home/wspahn/Projects/Python/AIDu_NG/aidu-ai-llm/src/aidu/ai/llm/agent.py

already shows a useful rich trace for agent execution, for example:

- target agent
- artifact type
- producer
- content
- step
- trace messages
- state keys
- agents

Current trace message preview is too weak:

```text
[1] user placeholders: no | content: Applet event: applet-create-a-molecule
```

For applet events, this does not give the right impression of what is actually inside the message content.

## Required change

Adapt the trace output so that:

1. The trace display shows the source path of the trace code.

   Expected intent:

   ```text
   Source path  /home/wspahn/Projects/Python/AIDu_NG/aidu-ai-llm/src/aidu/ai/llm/agent.py
   ```

   It does not have to be exactly this label, but the trace output should clearly expose the source path of the trace implementation or trace source.

2. Trace message previews should show a compact representation of the actual content payload.

   For applet messages, instead of:

   ```text
   content: Applet event: applet-create-a-molecule
   ```

   it should show something like:

   ```text
   content: {'applet': 'applet-create-a-molecule', 'infoStore': {...}}
   ```

   or, if pretty-printed:

   ```text
   content: {
       'applet': 'applet-create-a-molecule',
       'infoStore': { ... }
   }
   ```

## Important behavior

- The preview should be compact.
- It should not dump the full huge applet state into the trace message line.
- It should preserve enough structure to show that the content is a dictionary-like applet payload.
- Nested structures should be abbreviated with `...`.
- Strings should remain readable.
- The full artifact content block can remain detailed as it is now.

## Constraints

- Keep the existing rich trace style.
- Prefer changing only the trace formatting code.
- Do not change agent execution semantics.
- Do not change artifact or message data models unless absolutely required.
- Do not refactor unrelated tracing code.
- Preserve existing tests if any.