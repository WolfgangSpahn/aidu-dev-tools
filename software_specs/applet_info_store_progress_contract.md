# Applet Info Store and Progress Contract

## Core message

Each interactive applet owns its own applet state, progress bar, and submit timing.

The integration shell must not reimplement the applet progress bar. It only connects the applet to AIDu and tells the applet when dialog text input is active.

```text
applet
  owns infoStore
  owns progress bar
  owns pause/reset behavior
  emits a summary when its progress bar completes

integration shell
  renders the applet
  passes dialog activity into the applet
  forwards completed applet summaries to AIDu
```

---

## Public applet contract

Every applet should expose an info store from its package entrypoint:

```ts
export { infoStore, setInfoStore } from "./infoStore";
export type { InfoType } from "./infoStore";
```

The applet component should accept these integration hooks:

```ts
type AppletProps = {
  info?: InfoType;
  setInfo?: SetStoreFunction<InfoType>;
  onSubmit?: (message: string) => void;
  onStateChange?: (state: InfoType) => void;
  inputPaused?: boolean;
  submitDelayMs?: number;
};
```

The exact `InfoType` is applet-specific. It should describe the meaningful simulation state, not DOM state.

---

## Progress ownership

The progress bar is part of the applet UI.

The applet starts or restarts its progress bar when the user changes applet state. When the progress bar reaches the end, the applet builds a concise summary from `infoStore` and calls:

```ts
props.onSubmit?.(summary);
```

The integration shell may forward that summary to AIDu, but it must not create a second competing applet-progress timer.

---

## Dialog input pause hook

When the user starts typing in the text dialog, the shell must pass that activity into the applet:

```tsx
<Applet inputPaused={dialogInputActive()} />
```

Inside the applet:

```ts
createEffect(() => {
  if (props.inputPaused) {
    clearProgressBar();
    return;
  }

  if (hasPendingAppletInput && !progressTimer) {
    startProgressBar();
  }
});
```

This is the required reset hook.

If the learner starts writing text, pending applet submission is canceled visually and logically. After dialog input stops, later applet changes can start a fresh applet progress cycle.

---

## Required behavior

```text
User changes applet state
  applet updates infoStore
  applet starts/restarts its own progress bar

User changes applet again before completion
  applet resets its own progress bar

User starts typing in dialog
  shell sets inputPaused=true
  applet clears its progress bar
  no applet summary is submitted

User stops typing and later changes applet
  applet starts a new progress cycle

Applet progress reaches 100%
  applet summarizes infoStore
  applet calls onSubmit(summary)
  shell forwards summary to AIDu
```

---

## Non-goals

Do not put applet progress bars in the chat component.

Do not make the shell inspect applet internals to decide when the applet is ready.

Do not forward every tiny applet state change immediately. The applet progress bar is the debounce and readiness signal.

Do not make dialog typing and applet submission race each other. Dialog input wins and resets the applet progress bar.

