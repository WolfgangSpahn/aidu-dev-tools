# Debug failure

Debug mode.

Feature definition:

{{FEATURE}}

Existing plan:

{{PLAN}}

Failure / error output:

{{ERROR}}

Your job:
Find the most likely cause of the failure and propose the smallest corrective change.

Rules:
- Do not perform unrelated cleanup.
- Do not refactor unless the failure directly requires it.
- Prefer existing project patterns.
- Treat the current feature plan as the intended design, but question it if the error shows the plan is wrong.
- Use targeted search only.
- Avoid broad repo exploration.
- Separate confirmed facts from hypotheses.
- Mark uncertainty explicitly.
- Do not change files unless explicitly asked in a follow-up.

Return exactly:

## Failure summary

One short paragraph describing what failed.

## Confirmed facts

- ...

## Most likely cause

Explain the likely root cause.

## Change points

| Priority | File | Symbol / Area | Reason | Confidence |
|---|---|---|---|---|

## Minimal fix plan

1. ...
2. ...
3. ...

## Suggested verification

Commands or checks to run after the fix.

## If this is wrong

List the next 2–3 places to inspect.