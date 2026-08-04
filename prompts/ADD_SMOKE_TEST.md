## Smoke test before refactoring

Before refactoring a Python module, add or improve a small smoke test for that module.

The smoke test should demonstrate that the module can be imported and that its main responsibility can execute through one minimal representative path.

A smoke test should:

* use deterministic, local inputs;
* complete quickly;
* avoid real network calls, external services, databases, and paid APIs;
* use fakes or stubs at external boundaries;
* exercise the public interface rather than internal implementation details;
* fail clearly when the module cannot perform its basic responsibility;
* remain valid while the internal implementation is refactored.

Do not attempt to cover every branch. The purpose is to establish a minimal behavioral safety net before structural changes.

Where practical, place the smoke test in the module behind:

```python
if __name__ == "__main__":
    _smoke_test()
```

The private `_smoke_test()` function should:

1. construct the smallest valid example;
2. execute the module's main behavior;
3. assert a small number of essential outcomes;
4. print a concise success message.

Running the module directly should execute only the smoke test:

```bash
python -m package.module
```

Importing the module must never execute the smoke test.

For modules whose normal `__main__` behavior starts a server, worker, CLI, or long-running process, do not replace that entry point with a smoke test. Put the smoke test in a corresponding test module, for example:

```text
tests/smoke/test_<module_name>.py
```

Before refactoring:

1. run the smoke test against the existing implementation;
2. confirm that it passes;
3. perform one coherent refactoring slice;
4. run the smoke test again;
5. update the smoke test only when the intended public behavior changes.

Do not weaken assertions merely to make a refactoring pass.
