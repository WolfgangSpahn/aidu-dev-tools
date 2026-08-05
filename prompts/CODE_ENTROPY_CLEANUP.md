# Vertical Concept Consolidation

Clean up the following concept through its complete implementation depth:

| 1 | CON-002 | Most central compatibility boundary: strict message, enriched dict, provider dict, flattened session payload, and routed event all compete | CON-010 terminology and boundary understood | Introduce a typed persisted-turn record and migrate `Messages` plus adapters |

The authoritative inventory is:

'aidu-ai-llm/docs/architecture/concept-aidu-ai-llm_core-inventory.md'

Read the complete inventory entry for `CON-002` before inspecting or editing code.

The objective is to reduce the number of representations, execution paths, owners, compatibility branches, and abstractions associated with this concept while preserving required observable behaviour.

This is not a cosmetic refactor.

Do not merely rename, move, wrap, reorganize, or generalize duplicated structures. The intended result is one coherent concept, one canonical internal representation, one owner for each invariant, and one normal execution path.

## Scope

Primary scope:

`AIDU-NG/aidu-ai-llm`

Related repositories, packages, or directories that may need inspection:

`AIDU-NG/` python packages

Do not modify unrelated concepts unless a small change is strictly required to complete this consolidation. Report such changes explicitly.

## Repository rules

Follow the project architecture and repository instructions, including `AGENTS.md`.

In particular:

* trace the relevant execution path before editing;
* identify the layer that owns each violated invariant;
* fix the problem in the owning layer;
* do not compensate in a higher layer for incorrect lower-layer behaviour;
* prefer removing incorrect or obsolete paths over adding fallback behaviour;
* let invalid internal state fail visibly rather than silently normalizing it deep inside the system;
* preserve the existing architecture unless consolidation of this concept requires a deliberate change;
* prefer the smallest coherent change that fixes the conceptual duplication;
* minimize changed concepts, not merely changed lines.

Do not create a Git commit.

# Phase 1: Read and verify the inventory

Read:

`docs/architecture/concept-inventory.md`

Locate the complete entry for `<CONCEPT_ID>` and extract:

* current status;
* purpose;
* observed names;
* representations;
* creation points;
* consumers;
* execution paths;
* invariant;
* current owner;
* preferred owner;
* tests and contracts;
* entropy findings;
* likely canonical form;
* cleanup boundary;
* dependencies;
* open questions.

Do not assume that the inventory is fully correct or current.

Verify every relevant claim against the repository.

Identify:

* findings that remain valid;
* findings that are outdated;
* missing representations or execution paths;
* dependencies not captured in the inventory;
* assumptions that cannot be confirmed;
* scope changes required before consolidation.

If the inventory entry is materially wrong, update your working understanding before proceeding. Do not edit the inventory yet.

# Phase 2: Trace the concept vertically

Before editing code, trace the concept through its complete implementation depth.

Inspect, where applicable:

* external input;
* UI event or frontend state;
* transport request;
* parsing and validation;
* API schema;
* messages and events;
* orchestration;
* routing;
* application service;
* domain operation;
* domain state;
* persistence;
* background processing;
* result construction;
* transport response;
* frontend consumption;
* rendering;
* logging and telemetry;
* tests and fixtures.

For every relevant path, identify:

1. where the concept enters the system;
2. where it is created;
3. where it is copied;
4. where it is converted;
5. where it is enriched;
6. where it is validated;
7. where its invariant is enforced;
8. where it is persisted;
9. where it is consumed;
10. where it leaves the system.

Produce a concrete trace using file paths and symbols.

Do not edit code until this trace is complete.

# Phase 3: Find all competing forms

Search explicitly for every observed name, type, field, function, schema, message, and alias associated with the concept.

Also search semantically for equivalent concepts using different names.

Identify all of the following:

* duplicate domain concepts;
* duplicate representations;
* parallel execution paths;
* old and new implementations;
* compatibility aliases;
* fallback field names;
* input-shape detection;
* wrappers around equivalent operations;
* multiple constructors or factories;
* duplicate validators;
* duplicate lifecycle transitions;
* repeated conversions;
* transport types used as domain types;
* domain types duplicated in transport or frontend layers;
* frontend and backend state representing the same source of truth;
* synchronous and asynchronous variants serving the same use case;
* functions with overlapping responsibilities;
* abstractions with only one trivial caller;
* adapters compensating for inconsistent internal contracts;
* tests that preserve obsolete behaviour;
* documentation describing an older path;
* dead code;
* unreachable branches;
* configuration switches selecting historical implementations.

For each competing form, record:

* file and symbol;
* callers;
* consumers;
* whether it is internal or boundary-facing;
* whether it is currently active;
* whether it is needed for compatibility;
* whether it can be deleted;
* evidence for that conclusion.

Do not treat two concepts as duplicates merely because their names are similar. Confirm that they have overlapping meaning or responsibility.

# Phase 4: Establish behavioural requirements

Determine what observable behaviour must be preserved.

Use:

* tests;
* public APIs;
* schemas;
* user-facing behaviour;
* documented contracts;
* integration points;
* actual callers;
* persisted data formats;
* externally consumed messages.

Distinguish between:

* required behaviour;
* accidental current behaviour;
* obsolete compatibility;
* test-only behaviour;
* implementation details;
* unsupported but silently accepted input;
* behaviour protected only by legacy tests.

Do not preserve behaviour merely because a test currently asserts it.

When a test protects obsolete behaviour, remove or replace the test together with the obsolete implementation.

When external compatibility is genuinely required, contain it at a boundary.

# Phase 5: Define the target concept

Before implementation, write a concise target design.

It must contain the following sections.

## Canonical meaning

Define in one paragraph what `<CONCEPT_ID>` means in the system.

The definition must distinguish it from neighbouring concepts.

## Canonical internal representation

Specify the one representation used by core application and domain code.

State:

* type or schema;
* required fields;
* optional fields;
* invariants;
* prohibited states;
* where it is defined.

Do not select a transport-specific representation as the domain representation unless the transport layer genuinely owns the concept.

## Canonical owner

Specify the one layer or component responsible for maintaining each invariant.

For each invariant, identify exactly one owner.

Examples:

* parsing belongs to the transport boundary;
* domain validity belongs to the domain model;
* persistence consistency belongs to the persistence boundary;
* UI presentation belongs to the frontend;
* routing decisions belong to orchestration.

Do not enforce the same invariant independently in multiple layers.

## Canonical creation point

Specify where valid instances may originate.

Avoid multiple independent constructors unless they serve genuinely different external boundaries and normalize immediately into the same internal representation.

## Canonical execution path

Describe the normal path from entry point to observable result.

There should be one normal path for each actual use case.

Do not unify genuinely different use cases merely to reach an artificial count of one.

## Boundary normalization

Specify where external, legacy, transport, or alternate forms are converted into the canonical representation.

Normalization must occur once, at a named boundary.

Core code must not repeatedly detect or convert alternate forms.

## Failure behaviour

State where invalid input or invalid state fails.

Prefer explicit failure at the boundary or invariant owner.

Do not add fallback behaviour merely to keep processing incomplete or contradictory internal state.

## Removed alternatives

List every representation, path, alias, wrapper, validator, fallback, and abstraction that should be deleted.

## Retained compatibility

For every compatibility mechanism that must remain, provide:

* exact external or legacy caller;
* exact boundary module containing it;
* reason it cannot yet be removed;
* supported legacy form;
* canonical output form;
* concrete removal condition;
* repository search or test that can identify when removal is safe.

Compatibility must not spread into application or domain logic.

## Target concept count

State the expected result in measurable terms:

* number of internal representations;
* number of normal execution paths;
* number of invariant owners;
* number of compatibility adapters;
* number of public entry points.

Do not proceed if the target design merely adds another abstraction around existing alternatives.

# Phase 6: Plan the consolidation

Create a staged implementation plan.

Each stage must leave the repository in a coherent state.

Prefer this order:

1. establish or confirm the canonical representation;
2. establish the canonical invariant owner;
3. create boundary normalization where genuinely needed;
4. redirect callers to the canonical path;
5. migrate tests to the canonical contract;
6. remove obsolete callers;
7. remove obsolete implementations;
8. remove unused adapters and helpers;
9. remove obsolete schemas, fields, aliases, and configuration;
10. update documentation and the concept inventory.

Avoid a long-lived intermediate state where both old and new paths are treated as equally valid.

Do not add deprecation layers for purely internal code unless migration cannot be completed in the current task.

# Phase 7: Implement the consolidation

Apply the smallest coherent change that establishes the target design.

Follow these rules.

## Canonical representation

* Use one internal representation.
* Convert external forms once at a boundary.
* Do not pass dictionaries or transport schemas through core logic when a domain type exists.
* Do not introduce a union of old and new forms merely to avoid migration.
* Do not preserve duplicate fields with synchronization logic.
* Do not derive the same state independently in several places.

## Ownership

* Assign each invariant to one owner.
* Remove duplicate validation from non-owning layers.
* Call the owning operation rather than reimplementing its rules.
* Do not let frontend checks hide invalid backend state.
* Do not let orchestration compensate for invalid domain behaviour.
* Do not let persistence models define domain meaning accidentally.

## Execution paths

* Redirect all internal callers to the canonical path.
* Remove superseded entry points after their callers have migrated.
* Do not retain old paths as fallback paths.
* Do not select implementations dynamically unless multiple implementations are an actual requirement.
* Do not preserve a configuration switch whose only purpose is selecting an obsolete implementation.
* Do not create a dispatcher merely to keep several equivalent implementations alive.

## Compatibility

* Keep compatibility only at a named external boundary.
* Normalize legacy input immediately.
* Emit only the canonical internal form.
* Do not allow legacy aliases in core code.
* Do not silently search several field names throughout the codebase.
* Do not add catch-all parsing for hypothetical historical data.
* Document retained compatibility and its removal condition.

## Failure handling

* Fail fast on violated internal invariants.
* Do not create default values for missing required state.
* Do not catch errors merely to continue through an invalid path.
* Do not turn programming errors into empty states.
* Do not accept malformed internal state because tests currently depend on permissive behaviour.

## Abstractions

* Do not create a generic framework unless at least two current concrete use cases require it.
* Do not introduce an interface with only one meaningful implementation unless it enforces a necessary boundary.
* Do not extract helpers that merely hide conceptual duplication.
* Do not replace duplicated concepts with a larger “universal” concept unless their semantics are truly identical.
* Prefer direct and explicit code when it makes ownership clearer.

## Deletion

Delete code made obsolete by the consolidation, including:

* functions;
* classes;
* types;
* fields;
* schemas;
* aliases;
* wrappers;
* adapters;
* converters;
* validators;
* factories;
* configuration;
* feature flags;
* fixtures;
* tests;
* documentation;
* comments describing obsolete behaviour.

Do not leave commented-out code.

Do not leave TODO comments instead of completing safe removal.

Do not preserve an obsolete abstraction merely because deletion increases the diff.

## Tests

Update tests to validate:

* the canonical representation;
* the canonical execution path;
* the correct invariant owner;
* explicit boundary normalization;
* expected failure for invalid input or state;
* required external compatibility.

Remove tests whose only purpose is protecting an obsolete internal path.

Do not duplicate the complete test suite for old and new paths.

# Phase 8: Validate the result

Run all relevant validation available in the repository:

* focused unit tests;
* integration tests;
* end-to-end tests;
* type checks;
* static analysis;
* linting;
* formatting checks;
* production build;
* architecture tests;
* dependency checks.

Report commands and results.

If a test fails:

1. diagnose the root cause;
2. determine whether the test or implementation protects obsolete behaviour;
3. fix the owning layer;
4. do not add fallback behaviour merely to satisfy the test.

Do not declare completion based only on passing tests.

# Phase 9: Perform a repository-wide residue search

After implementation, search for all obsolete names and forms identified earlier.

Search for:

* old type names;
* old function names;
* old field names;
* old schemas;
* old message names;
* compatibility aliases;
* fallback branches;
* removed configuration switches;
* duplicate constructors;
* duplicate validators;
* alternate entry points;
* comments mentioning obsolete behaviour;
* tests invoking removed paths;
* imports of removed modules.

For each remaining match, classify it as:

* required boundary compatibility;
* historical documentation;
* unrelated use;
* missed cleanup;
* false positive.

Remove missed cleanup.

Do not finish while unexplained internal matches remain.

# Phase 10: Re-trace the concept after cleanup

Trace the concept again from entry point to observable result.

Confirm:

* one canonical internal representation;
* one owner per invariant;
* one normal execution path per real use case;
* no hidden fallback path;
* no duplicated validation;
* no repeated normalization;
* no old implementation still reachable;
* compatibility contained at explicit boundaries;
* tests aligned with the canonical contract.

Compare this trace directly with the Phase 2 trace.

# Phase 11: Update the concept inventory

Update:

`docs/architecture/concept-inventory.md`

Modify only entries and relationships affected by this cleanup.

For `<CONCEPT_ID>`:

* update its status;
* update observed names;
* remove deleted representations;
* update creation points;
* update consumers;
* update execution paths;
* update the invariant;
* update current and preferred owner;
* update tests and contracts;
* mark resolved entropy findings;
* retain unresolved findings;
* update the likely canonical form;
* update the cleanup boundary;
* update dependencies;
* update cleanup value and risk if appropriate.

Also update:

* the concept index;
* relationship map;
* cleanup queue;
* cross-cutting findings;
* open questions;
* resolved findings;
* change log.

In `Resolved findings`, record:

* current date;
* `<CONCEPT_ID>`;
* concise resolution;
* commit as `uncommitted` unless a commit already exists.

Do not rewrite unrelated concept entries.

Do not falsely mark the concept as canonical when meaningful parallel paths or split ownership remain.

Use `transitional` when required external compatibility remains.

# Completion criteria

The cleanup is complete only when all of the following are true:

* the concept has one clear meaning;
* core code uses one canonical representation;
* each invariant has one owner;
* each real use case has one normal execution path;
* alternate external representations are normalized at a boundary;
* obsolete internal paths are deleted;
* duplicate validation is removed;
* compatibility is explicit and contained;
* invalid internal state fails at the correct layer;
* tests validate the canonical contract;
* residue searches contain no unexplained internal legacy references;
* the concept inventory reflects the resulting architecture;
* the concept can be explained without describing several competing implementations.

If these criteria cannot all be met safely, complete the largest coherent subset and explicitly report the remaining blocker. Do not disguise incomplete consolidation with another adapter or fallback.

# Required final report

At completion, provide the following report.

## Concept cleaned

* concept ID;
* concept name;
* scope inspected.

## Verified problem

Summarize the actual duplication, fragmentation, or ownership problem found.

Distinguish confirmed findings from incorrect or outdated inventory assumptions.

## Before

Report:

* internal representations;
* external representations;
* creation points;
* invariant owners;
* normal execution paths;
* alternate execution paths;
* compatibility branches;
* aliases and fallbacks;
* public entry points.

## Target design

Report:

* canonical meaning;
* canonical internal representation;
* canonical owner;
* canonical creation point;
* canonical execution path;
* boundary normalization;
* failure behaviour.

## Changes made

List concrete changes grouped by:

* caller migration;
* representation consolidation;
* ownership correction;
* path removal;
* compatibility containment;
* test changes;
* documentation changes.

Include relevant file paths and symbols.

## Removed

List deleted:

* concepts;
* representations;
* functions;
* classes;
* schemas;
* fields;
* aliases;
* wrappers;
* adapters;
* validators;
* configuration;
* tests;
* documentation.

## Retained compatibility

For each retained compatibility mechanism, report:

* exact location;
* exact caller;
* reason;
* removal condition.

Write `none` when no compatibility remains.

## Validation

Report:

* commands run;
* tests passed;
* checks passed;
* checks not run and why.

## Residue search

Report remaining matches for old names or forms and classify each remaining match.

## After

Report:

* canonical internal representations;
* creation points;
* invariant owners;
* normal execution paths;
* compatibility adapters;
* public entry points.

## Net conceptual change

State explicitly:

* concepts added;
* concepts removed;
* internal representations added;
* internal representations removed;
* execution paths added;
* execution paths removed;
* invariant owners before;
* invariant owners after;
* compatibility branches before;
* compatibility branches after.

## Remaining debt

List only concrete unresolved issues.

For each issue, state:

* location;
* reason it remains;
* dependency or blocker;
* recommended later action.

Write `none` when the concept is fully consolidated.

## Inventory update

Confirm:

* inventory file updated;
* new concept status;
* resolved findings recorded;
* cleanup queue updated.

Do not create a Git commit.
