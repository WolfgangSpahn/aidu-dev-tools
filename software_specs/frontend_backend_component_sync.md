# AIDu Component State Synchronization Specification

## Goal

Provide a generic mechanism to synchronize state between:

```text
SolidJS Frontend
        ⇅
FastAPI Backend
        ⇅
Pydantic Session State
```

without creating custom API endpoints for every component.

The system must support:

* Header
* Chat
* Network Simulator
* Atom Builder
* Light Ray Simulator
* Future components

using the same infrastructure.

---

# Design Principles

## Backend owns canonical state

The backend is the source of truth.

Frontend components render state and send updates.

```text
Frontend State
    ↓
PATCH
    ↓
Backend Session State
    ↓
SSE Broadcast
    ↓
Frontend Update
```

---

## Components are typed

Every component defines:

### Backend

```python
HeaderState
ChatState
NetworkSimState
AtomBuilderState
```

using Pydantic.

### Frontend

```typescript
HeaderState
ChatState
NetworkSimState
AtomBuilderState
```

using TypeScript.

---

## Generic API

No component-specific API files.

Avoid:

```text
header_api.py
chat_api.py
network_api.py
atom_api.py
```

Instead provide one generic API.

---

# Backend Structure

```text
backend/

components/

    header/
        header.py

    chat/
        chat.py

    network_sim/
        network_sim.py

    atom_builder/
        atom_builder.py

api/

    components.py

session_state.py
```

---

# Component State Models

Example:

```python
class HeaderState(BaseModel):
    subject: str
    language: str
    token_budget: int
```

```python
class ChatState(BaseModel):
    turns: list[Message]
```

```python
class NetworkSimState(BaseModel):
    pc_ip: str
    printer_ip: str
```

---

# Session State

All component states are stored inside one session object.

```python
class SessionState(BaseModel):

    header: HeaderState

    chat: ChatState

    network_sim: NetworkSimState

    atom_builder: AtomBuilderState
```

Session storage:

```python
sessions: dict[str, SessionState]
```

---

# Generic API

## Get Component State

```http
GET /sessions/{session_id}/components/{component_id}
```

Examples:

```http
GET /sessions/123/components/header
```

```http
GET /sessions/123/components/chat
```

```http
GET /sessions/123/components/network_sim
```

---

## Update Component State

```http
PATCH /sessions/{session_id}/components/{component_id}
```

Request:

```json
{
  "patch": {
    "language": "de"
  }
}
```

Response:

```json
{
  "subject": "Physics",
  "language": "de",
  "token_budget": 10000
}
```

---

# Generic Backend Logic

Component lookup:

```python
component = getattr(
    session,
    component_id
)
```

Update:

```python
updated = component.model_copy(
    update=patch
)
```

Store:

```python
setattr(
    session,
    component_id,
    updated
)
```

No component-specific routes.

No component-specific update logic.

---

# Frontend Structure

```text
frontend/

components/

    Header/
        Header.tsx
        header.types.ts

    Chat/
        Chat.tsx
        chat.types.ts

    NetworkSim/
        NetworkSim.tsx
        network.types.ts

api/

    components.ts

stores/

    sessionStore.ts
```

---

# Generic Frontend API

```typescript
loadComponent(
    sessionId,
    componentId
)
```

Example:

```typescript
loadComponent(
    sessionId,
    "header"
)
```

---

```typescript
patchComponent(
    sessionId,
    componentId,
    patch
)
```

Example:

```typescript
patchComponent(
    sessionId,
    "header",
    {
        language: "de"
    }
)
```

Same API for every component.

---

# SSE Synchronization

Backend broadcasts state changes.

Event:

```json
{
  "component": "header",
  "state": {
    "subject": "Physics",
    "language": "de"
  }
}
```

Frontend receives:

```typescript
setState(
    component,
    state
)
```

---

# Component Responsibilities

## Backend Component

Example:

```python
components/header/header.py
```

Contains:

* Pydantic state model
* Optional business logic

Must not contain:

* API routes
* HTTP logic

---

## Frontend Component

Example:

```tsx
Header.tsx
```

Contains:

* Rendering
* User interaction

Must not contain:

* Direct state persistence logic
* Session management

---

# Adding a New Component

Create:

```python
class LightRayState(BaseModel):
    angle: float
    material: str
```

Add to:

```python
class SessionState(BaseModel):
    ...
    light_ray: LightRayState
```

Create:

```text
LightRay.tsx
light_ray.types.ts
```

No API changes required.

No router changes required.

No infrastructure changes required.

---

# Target Outcome

Students should be able to add a new synchronized component by implementing only:

```text
Backend:
    component_state.py

Frontend:
    component.types.ts
    Component.tsx
```

The generic synchronization layer automatically provides:

* State loading
* State updates
* Validation
* Session storage
* SSE synchronization
* Multi-user support
* Future extensibility for all AIDu applets and widgets.
