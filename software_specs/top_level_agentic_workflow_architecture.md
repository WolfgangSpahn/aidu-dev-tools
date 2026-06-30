# Top-Level Agentic Workflow Architecture

## Core Statement

The Director interacts with Actors via REST messages. The frontend is one Actor among others.

A `session_id` distinguishes different tutoring sessions.

The persistent message stack is session state, currently maintained by the frontend/backend session layer. In the current implementation, the durable stack lives in backend session storage as chat turns and is rendered by the frontend.

The Director is stateless with respect to message history. It receives selected session-scoped messages in the request and forwards them to Actors according to its hardcoded routing and forwarding schema.

According to that forwarding schema, the Director selects the next Actor. It forwards the current message plus necessary session information, including selected recent history and other context.

When an Actor receives a request from the Director, it converts the request into an input Artifact and an AgentContext.

The Actor's Controller then runs a graph of Agents. The graph always starts with `BeginAgent` and ends with `EndAgent`.

Agents process Artifacts and may update the AgentContext. Each Agent can recommend the next Agent step dynamically. The Controller may accept or override these recommendations.

The final Artifact and AgentContext are converted by the Actor into an output message and returned to the Director.

---

## Message Stack Contract

The message stack exists as session state and as forwarded message payloads.

```text
backend session chat.turns
  -> frontend-visible chat history
  -> Director message.messages
  -> RunRequest.info.messages
  -> Actor-derived AgentContext.trace.messages
```

The Director does not own a persistent per-session message stack. It forwards the session-scoped messages it receives.

Actors derive `AgentContext.trace.messages` from the forwarded messages. This trace is dialog and event history only.

`AgentContext.trace.messages` must not require or assume a leading system message.

---

## System Prompt Contract

LLM calls clearly require a system prompt, but system prompts are not part of the persistent/global dialog trace.

When an LLM Agent calls a model, the LLM layer constructs a call-local context that prepends the active system prompt for that Agent.

```text
global AgentContext.trace.messages
  dialog/event history only

LLM call-local context.trace.messages
  system prompt for active LLM Agent
  + dialog/event history
  + current user message
```

This keeps the global trace stable across Agents while still giving each LLM Agent its own current system prompt at call time.

---

## Workflow Shape

```text
Frontend / Session Layer
  maintains session chat turns
  sends current message plus selected recent history

Director
  receives actor-style message
  routes to next Actor
  forwards current message and session-scoped info

Actor REST endpoint
  builds Artifact
  builds AgentContext
  starts Controller

Controller
  starts with BeginAgent
  runs recommended Agent steps
  stops at EndAgent or workflow termination

Agent
  consumes Artifact
  reads/updates AgentContext
  emits Artifacts
  recommends next Agent step

Actor
  converts final Artifact and AgentContext into output message
  returns message to Director
```

---

## Implementation Notes

The backend session handler currently forwards selected recent turns with:

```python
messages=[turn.model_dump(mode="json") for turn in chat.turns[-12:]]
```

The GUI chemistry tutor Actor receives these as `RunRequest.info.messages` and converts selected messages into `context.trace.messages`.

Applet events may be normalized into concise dialog trace text, for example:

```text
Applet event: applet-periodic-table with elementName=Hydrogen, elementSymbol=H, atomicNumber=1
```

The Controller must preserve dialog-only traces when building agent-local contexts.

The LLM requester is responsible for prepending the active system prompt only for the actual provider call.
