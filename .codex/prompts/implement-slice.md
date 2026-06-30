# Implement slice

Edit mode.

Feature definition:

{{FEATURE}}

Existing plan:

{{PLAN}}

Slice to implement:

{{SLICE}}

Your job:
Implement this slice with the smallest safe change.

Rules:
- Modify only files required for this slice.
- Do not implement later slices.
- Do not perform optional cleanup.
- Do not refactor unrelated code.
- Prefer existing project patterns.
- Preserve public APIs unless this slice explicitly requires changing them.
- Keep diffs minimal and readable.
- If the slice is ambiguous, make the smallest reasonable interpretation and mark the assumption.
- If the slice cannot be implemented safely, stop and explain why.

Before editing:
- Inspect the plan and the slice.
- Identify the exact files/symbols likely needed.
- Avoid broad repo exploration.

After editing:
- Run only the smallest relevant checks if available.
- Do not chase unrelated failures.

Return exactly:

## Slice summary

One short paragraph describing what was implemented.

## Files changed

| File | Change | Reason |
|---|---|---|

## Important decisions

- ...

## Verification

Command run:

```bash
...
```

Result:

```text
...
```

If no command was run, explain why.

## Remaining work

- ...

## Risks / follow-up

- ...