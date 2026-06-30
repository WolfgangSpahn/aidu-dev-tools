## Change-point map

| Priority | File | Symbol / Area | Required? | Reason | Risk |
|---|---|---|---|---|---|
| P0 | `/home/wspahn/Projects/Python/AIDu_NG/aidu-ai-llm/src/aidu/ai/llm/agent.py` | `BeginAgent._show_actor_input` | Yes | Add a clear source-path row to the existing rich trace panel, probably using `__file__` or `Path(__file__).resolve()`. | Low: display-only change. |
| P0 | `/home/wspahn/Projects/Python/AIDu_NG/aidu-ai-llm/src/aidu/ai/llm/agent.py` | `BeginAgent._trace_message_rows` | Yes | It currently extracts only `message["content"]`, so applet messages with `applet_input` still preview as `"Applet event: ..."`. Needs access to the whole message so applet payload can be preferred. | Medium-low: tuple contract is tested; keep returned shape stable. |
| P0 | `/home/wspahn/Projects/Python/AIDu_NG/aidu-ai-llm/src/aidu/ai/llm/agent.py` | `BeginAgent._content_to_text` / new compact-preview helper near it | Yes | Current `repr(content)` plus string truncation does not abbreviate nested structures intentionally. Add compact dict/list formatting with nested structures replaced by `...`. | Medium: must avoid dumping huge applet state while keeping strings readable. |
| P1 | `/home/wspahn/Projects/Python/AIDu_NG/aidu-ai-llm/tests/test_begin_agent.py` | BeginAgent trace row tests | Yes | Existing tests cover truncation, placeholder detection, default length, and empty content. Add applet payload preview and source-path/display coverage if possible. | Low: focused unit tests already exist. |
| P2 | `/home/wspahn/Projects/Python/AIDu_NG/aidu-ai-llm/src/aidu/ai/core/applet_info.py` | `AppletInfo.from_message` | No | Existing structured applet detection is useful context, but implementation likely does not need model/helper changes. | Low if untouched. |

## Existing pattern to follow

The nearest pattern is `AppletInfo.from_message` in `/home/wspahn/Projects/Python/AIDu_NG/aidu-ai-llm/src/aidu/ai/core/applet_info.py`. It already treats messages with `kind == "applet"` and a dict `applet_input` as structured applet payloads, while keeping textual `content` as a compact dialog summary.

For testing, follow `/home/wspahn/Projects/Python/AIDu_NG/aidu-ai-llm/tests/test_begin_agent.py`, especially the direct unit tests for `BeginAgent._trace_message_rows`.

## Minimal implementation slices

1. Add a source-path row in `BeginAgent._show_actor_input`, near the existing `Target`, `Artifact`, `Producer`, `Content`, and `Step` rows.

2. Change trace preview construction so `_trace_message_rows` can detect applet messages and preview `message["applet_input"]` instead of only `message["content"]`.

3. Add a small compact representation helper for mappings/sequences:
   - top-level dict keeps key/value shape;
   - nested dict/list/set/tuple becomes `{...}` or `[...]` / `...`;
   - strings remain quoted/readable;
   - final one-line result still passes through existing length truncation.

4. Add focused tests for:
   - applet message preview includes `'applet': 'applet-create-a-molecule'`;
   - preview includes `infoStore` shape but not deep/full nested state;
   - normal string message behavior remains unchanged.

## Required tests / checks

- `pytest aidu-ai-llm/tests/test_begin_agent.py`
- Existing `test_begin_agent_trace_rows_*` expectations should remain valid unless deliberately adjusted for helper naming only.
- Optional but sensible: `pytest aidu-ai-llm/tests/test_applet_info.py` to confirm applet structure assumptions still hold.

## Optional cleanup

- None.

## Risk points

- `DebugAgent` later in `agent.py` has its own older trace display, but the example output and tests point to `BeginAgent`; changing both would likely exceed the minimal scope.
- Placeholder detection currently runs against preview/source text. For dict previews, keep using a string that does not falsely treat dict keys like placeholders; existing test covers this.
- If applet messages sometimes arrive as `"Applet input:\n{json...}"` instead of `applet_input`, implementation may optionally support that via existing `AppletInfo.from_message`, but it is not clearly required by the stated example.
- Rich rendering tests for `_show_actor_input` may be more brittle than helper-level tests; source path can be tested via a small helper or captured console output if added carefully.

## Blocking questions

- None.