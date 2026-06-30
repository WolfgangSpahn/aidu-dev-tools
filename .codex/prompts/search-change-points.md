# Search change points

Search mode only.

Feature definition:

{{FEATURE}}

Your job:
Find the minimal set of change points needed to implement this feature.

Rules:
- Do not edit files.
- Do not implement yet.
- Do not run broad refactors.
- Prefer existing project patterns.
- Use targeted search.
- Avoid reading unrelated files.
- Assume the feature may require several coordinated changes.
- Separate required changes from optional cleanup.
- Mark uncertainty explicitly.
- If there is already a similar feature or flow, identify it as the pattern to follow.

Return exactly:

## Change-point map

| Priority | File | Symbol / Area | Required? | Reason | Risk |
|---|---|---|---|---|---|

## Existing pattern to follow

Describe the nearest already-working feature, flow, or test pattern that should guide the implementation.

## Minimal implementation slices

1. ...
2. ...
3. ...

## Required tests / checks

- ...

## Optional cleanup

- ...

If there is no optional cleanup, write:

- None.

## Risk points

- ...

## Blocking questions

Only list questions that block implementation.

If there are no blocking questions, write:

- None.