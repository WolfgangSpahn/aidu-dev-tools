# Lesson Learned: Dev and Build Integration for Tailwind Applets

## Core message

We need two integration modes for modular Tailwind applets:

```text
build integration
  the applet package runs its own Tailwind build
  the applet emits dist/style.css
  the integration imports the built applet stylesheet

dev integration
  the applet is consumed directly from source
  Tailwind runs via the integration dev build
  the integration aliases the applet style contract to the applet source CSS
```

The integration code should stay the same in both modes:

```ts
import { BuildAnAtom } from "applet-build-an-atom";
import "applet-build-an-atom/style.css";
```

Only resolution changes.

---

## Observation

In build integration, the applet is built as a package.

The applet owns its Tailwind input:

```css
/* applet/src/index.css */
@import "tailwindcss";

@source "./**/*.{js,jsx,ts,tsx,html}";
```

The applet build runs Tailwind and emits:

```text
applet/dist/style.css
```

The integration then consumes the built stylesheet:

```ts
import "applet-build-an-atom/style.css";
```

In dev integration, the applet package is not rebuilt locally after each change.

Instead, the integration imports the same public style contract:

```ts
import "applet-build-an-atom/style.css";
```

and Vite aliases it to the applet source CSS:

```ts
"applet-build-an-atom/style.css": "../applet-build-an-atom/src/index.css"
```

So Tailwind runs as part of the integration dev build, while the applet source CSS still declares which applet files must be scanned.

---

## Lesson

The applet must expose a stable style contract:

```ts
import "applet-build-an-atom/style.css";
```

In build mode, this resolves to:

```text
applet-build-an-atom/dist/style.css
```

In dev mode, this resolves to:

```text
../applet-build-an-atom/src/index.css
```

That gives us direct-source development without changing application imports and without making the production shell responsible for applet internals.

---

## Consequences

### 1. Build mode and dev mode have different Tailwind execution points

```text
Build integration
  Tailwind runs in the applet package build.
  The applet emits dist/style.css.
  The integration consumes already generated CSS.

Dev integration
  Tailwind runs via the integration dev build.
  The integration aliases applet/style.css to applet/src/index.css.
  The applet package itself is not built.
```

### 2. Keep the import contract stable

Avoid this:

```ts
// dev only
import { BuildAnAtom } from "../../applet-build-an-atom/src/index";
import "../../applet-build-an-atom/src/index.css";
```

Use this everywhere:

```ts
import { BuildAnAtom } from "applet-build-an-atom";
import "applet-build-an-atom/style.css";
```

Then configure dev resolution in Vite:

```ts
resolve: {
  alias: {
    "applet-build-an-atom/style.css": resolve(
      buildAnAtomRoot,
      "src/index.css"
    ),
    "applet-build-an-atom": resolve(
      buildAnAtomRoot,
      "src/index.tsx"
    )
  }
}
```

### 3. Allow Vite to read the local applet source

```ts
server: {
  fs: {
    allow: [
      buildAnAtomRoot
    ]
  }
}
```

### 4. Do not make production scan applet internals from the shell

Avoid this as the production architecture:

```css
@source "../../../../applets/build-an-atom/src/**/*.{js,jsx,ts,tsx,html}";
```

The production architecture should stay:

```text
applet builds CSS
applet exports CSS
integration imports CSS
```

### 5. Keep integration CSS scoped

Even when Tailwind is generated correctly, shell CSS can override applet utilities.

Avoid broad unlayered rules:

```css
button {
  font: inherit;
}
```

Prefer scoped shell CSS:

```css
.aidu-user-form button {
  font: inherit;
}
```

or Tailwind classes on integration-owned elements:

```tsx
<button class="font-sans rounded-md bg-aidu-primary">
```

---

## Final architecture

```text
Build integration
  applet source CSS declares @source
  applet build runs Tailwind
  applet emits dist/style.css
  integration imports applet/style.css from package

Dev integration
  applet source CSS declares @source
  integration aliases applet/style.css to applet/src/index.css
  Tailwind runs via the integration dev build
  integration imports stay identical

Both modes
  same public imports
  different resolution
  no production dependency on shell-side scanning of applet internals
```
