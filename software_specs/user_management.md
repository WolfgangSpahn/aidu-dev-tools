# AIDu User State Synchronization Architecture v2

## Component Categories

Not all components are equal.

### 1. Session Components

State exists only during a learning session.

Examples:

```text
Header
Chat
NetworkSimulator
AtomBuilder
LightRaySimulator
```

Stored in:

```python
SessionState
```

---

### 2. User Components

State belongs to a user and survives logout.

Examples:

```text
Login
Register
ForgotPassword
UserProfile
UserSettings
Preferences
```

Stored in database.

Example:

```python
User
├── username
├── email
├── language
├── avatar
├── school
└── preferences
```

---

### 3. System Components

Administrative state.

Examples:

```text
AdminDashboard
UserManagement
CurriculumEditor
LessonEditor
```

---

# Backend

## Session State

```python
class SessionState(BaseModel):

    header: HeaderState

    chat: ChatState

    network_sim: NetworkSimState
```

Memory only.

---

## User State

```python
class UserProfileState(BaseModel):

    username: str

    email: str

    language: str

    avatar: str
```

Database backed.

---

# Component API

The generic API remains:

```http
GET
/sessions/{id}/components/{component}
```

and

```http
PATCH
/sessions/{id}/components/{component}
```

for session data.

---

## User API

Same idea.

```http
GET
/users/me/components/profile
```

```http
PATCH
/users/me/components/profile
```

Example response:

```json
{
  "username": "wolfgang",
  "email": "wolfgang@example.com",
  "language": "de"
}
```

---

# Authentication Components

These are special.

They perform actions rather than state synchronization.

---

## Login

Frontend:

```tsx
<Login />
```

Backend:

```http
POST /auth/login
```

Request:

```json
{
  "username": "alice",
  "password": "secret"
}
```

Response:

```json
{
  "access_token": "...",
  "user_id": 123
}
```

---

## Register

```http
POST /auth/register
```

---

## Forgot Password

```http
POST /auth/forgot-password
```

---

## Reset Password

```http
POST /auth/reset-password
```

---

# Component Classification

Every component belongs to one of two categories:

```python
class ComponentScope(Enum):

    SESSION = "session"

    USER = "user"
```

Examples:

```python
HeaderState.scope = SESSION

ChatState.scope = SESSION

UserProfileState.scope = USER
```

---

# Frontend Layout

```text
components/

  auth/
    Login.tsx
    Register.tsx
    ForgotPassword.tsx

  user/
    UserProfile.tsx
    UserSettings.tsx

  learning/
    Header.tsx
    Chat.tsx
    NetworkSimulator.tsx
```

---

# User Profile Example

Backend:

```python
class UserProfileState(BaseModel):

    username: str

    email: str

    language: str

    avatar: str
```

Frontend:

```tsx
<UserProfile />
```

Generic loader:

```ts
loadUserComponent(
    "profile"
)
```

Generic patch:

```ts
patchUserComponent(
    "profile",
    {
        avatar: "owl"
    }
)
```

Backend:

```http
PATCH
/users/me/components/profile
```

No profile-specific API required.

---

# Student Assignment

Students implementing a new component should only create:

## Backend

```python
class MyComponentState(BaseModel):
    ...
```

## Frontend

```tsx
MyComponent.tsx
```

and register it inside either:

```python
SessionState
```

or

```python
UserState
```

The framework automatically provides:

* GET state
* PATCH state
* validation
* persistence
* SSE updates
* authentication checks

without writing new routes.

This is the point where the architecture starts to resemble a lightweight version of systems like Firebase, Supabase, or Redux-backed web applications, but using FastAPI, Pydantic, and SolidJS.
