# Review diff

Review mode.

Feature definition:

{{FEATURE}}

Existing plan:

{{PLAN}}

Diff to review:

{{DIFF}}

Your job:
Review whether the diff correctly implements the intended feature slice with minimal risk.

Rules:
- Do not edit files.
- Do not propose broad refactors.
- Do not suggest optional cleanup unless it affects correctness, maintainability, or future slices.
- Prefer existing project patterns.
- Check whether the diff implements only the intended slice.
- Check whether public APIs, data flow, and state ownership remain consistent.
- Separate blocking issues from non-blocking concerns.
- Mark uncertainty explicitly.
- If the diff is good enough, say so clearly.

Return exactly:

## Review summary

One short paragraph describing the overall quality and risk.

## Blocking issues

- ...

If there are no blocking issues, write:

- None.

## Non-blocking concerns

- ...

If there are no non-blocking concerns, write:

- None.

## Plan alignment

Explain whether the diff matches the feature definition and existing plan.

## Files / areas to re-check

| File | Area | Reason | Priority |
|---|---|---|---|

## Suggested verification

Commands or checks to run before accepting the diff.

## Verdict

Choose one:

- Accept
- Accept after minor changes
- Revise before accepting