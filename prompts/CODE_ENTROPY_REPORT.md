# Concept Inventory and Entropy Audit

Inspect the repository and create or update:

`docs/architecture/concept-<scope>-inventory.md`

The file is the persistent source of truth for the current conceptual structure of the inspected subsystem.

## Scope

Inspect:

`<SCOPE>`

Use source code, tests, schemas, configuration, documentation, API contracts, state types, adapters, and relevant entry points.

Do not edit application code during this task.

## File handling

If `docs/architecture/concept-inventory.md` already exists:

1. Read it before inspecting the code.
2. Verify every existing claim against the current repository.
3. Update outdated entries.
4. Preserve still-valid findings.
5. Add newly discovered concepts and relationships.
6. Mark resolved entropy findings as resolved rather than silently deleting their history.
7. Remove an entry only when the concept itself no longer exists and its removal is recorded in the change log.

Do not create a second inventory file for the same scope.

## What counts as a concept

A concept can be:

* a domain entity;
* a state representation;
* an operation or capability;
* an execution path;
* an invariant;
* an ownership responsibility;
* a protocol or message;
* an API contract;
* a lifecycle state;
* a data representation;
* an abstraction coordinating several components.

Do not list every class, function, or file. Group implementation elements that represent the same underlying idea.

## Required document structure

Write the file with this structure:

# Concept Inventory

## Scope

Describe the inspected directories, repositories, and exclusions.

## Inventory metadata

Include:

* date of audit;
* Git branch;
* current commit;
* whether uncommitted changes were included;
* directories inspected;
* important directories excluded.

## Concept index

Provide a compact table:

| ID | Concept | Area | Status | Cleanup value | Cleanup risk | Depends on |
| -- | ------- | ---- | ------ | ------------- | ------------ | ---------- |

Use stable IDs such as:

* `CON-001`
* `CON-002`
* `CON-003`

Do not renumber existing concepts in later audits.

Use these statuses:

* canonical;
* duplicated;
* fragmented;
* transitional;
* obsolete;
* uncertain;
* resolved.

## Concepts

For each concept, use:

### CON-XXX — `<canonical descriptive name>`

**Status**

One of the defined statuses.

**Purpose**

What the concept represents in the system.

**Observed names**

Important identifiers, class names, function names, schema fields, messages, and terminology referring to it.

**Representations**

Concrete forms in which the concept exists.

**Creation points**

Where instances or values originate.

**Consumers**

Where the concept is used.

**Execution paths**

The important paths through which it flows.

**Invariant**

What must remain true.

**Current owner**

Which layer currently enforces the invariant.

**Preferred owner**

Which layer should own it, when current ownership is fragmented or incorrect.

**Tests and contracts**

Tests, schemas, APIs, and documentation defining expected behaviour.

**Entropy findings**

Classify findings using:

* duplicate concept;
* duplicate representation;
* parallel execution path;
* split ownership;
* compatibility residue;
* obsolete concept;
* misleading naming;
* unnecessary abstraction;
* missing canonical representation;
* unclear lifecycle.

**Evidence**

Give concrete file paths and symbols.

**Likely canonical form**

State the most suitable representation, path, or owner. Mark uncertain conclusions explicitly.

**Cleanup boundary**

Describe the smallest meaningful vertical cleanup unit.

**Dependencies**

List concept IDs that must be understood or cleaned first.

## Relationship map

Add a Mermaid graph showing:

* dependencies;
* alternate representations;
* ownership;
* adapters;
* obsolete concepts;
* cleanup prerequisites.

Use concept IDs in the graph.

## Cleanup queue

Rank unresolved concepts using:

1. number of parallel paths;
2. number of representations;
3. amount of compatibility logic;
4. ambiguity of ownership;
5. frequency of change;
6. architectural centrality;
7. risk of further entropy.

Use this table:

| Priority | Concept ID | Reason | Prerequisites | Suggested cleanup scope |
| -------- | ---------- | ------ | ------------- | ----------------------- |

## Cross-cutting findings

Record patterns affecting several concepts, such as:

* repeated compatibility aliases;
* duplicated validation;
* multiple state sources;
* competing message formats;
* frontend/backend ownership overlap;
* recurring fallback behaviour.

Do not invent a shared abstraction merely because a pattern appears more than once.

## Open questions

List uncertainties that could not be resolved from repository evidence.

## Resolved findings

Keep a compact record of findings resolved by later cleanup work:

| Date | Concept ID | Resolution | Commit |
| ---- | ---------- | ---------- | ------ |

## Change log

Append one row per audit:

| Date | Commit | Scope | Added concepts | Changed concepts | Resolved concepts |
| ---- | ------ | ----- | -------------- | ---------------- | ----------------- |

## Investigation procedure

For each concept:

1. Identify its meaning and responsibility.
2. Find all names used for it.
3. Find all representations.
4. Find where it is created.
5. Find where it is transformed.
6. Find where it is consumed.
7. Identify the layer that owns its invariant.
8. Trace its main execution paths.
9. Identify tests that define or protect it.
10. Identify alternate or obsolete paths.

Search explicitly for:

* synonyms for the same idea;
* old and new names used simultaneously;
* duplicate schemas or state objects;
* conversion functions between similar representations;
* compatibility aliases;
* fallback field names;
* equivalent wrappers;
* multiple factories or constructors;
* duplicated validation;
* duplicated lifecycle logic;
* parallel execution paths;
* legacy and replacement APIs used together;
* split frontend/backend/orchestration ownership;
* abstractions compensating for incompatible abstractions.

## Constraints

* Modify only `docs/architecture/concept-inventory.md`.
* Do not edit application code.
* Do not propose a generic framework.
* Do not reduce findings to naming or file organization.
* Distinguish deliberate variants from accidental duplication.
* Distinguish boundary compatibility from duplication in the core.
* Clearly mark uncertainty.
* Back every important claim with repository evidence.
* Stop after writing and reviewing the inventory file.

At completion, report only:

1. the file created or updated;
2. the concepts added or materially changed;
3. the three highest-priority cleanup candidates;
4. unresolved questions.
