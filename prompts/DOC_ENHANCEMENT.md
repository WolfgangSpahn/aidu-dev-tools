## Documentation before refactoring

Before changing structure or responsibilities, improve the documentation of the affected code.

For each relevant module, class, and non-obvious function, add or improve a concise docstring that explains:

* the purpose of the code;
* the responsibility it owns;
* the important constraints or invariants;
* why the implementation cannot be reduced to an obviously simpler form;
* which surrounding components depend on this behavior.

Document design intent, not a line-by-line description of the implementation.

Do not add docstrings to trivial functions where the name and type signature already explain the behavior.

Do not invent architectural intent. Derive it from the code, tests, call sites, and existing documentation. When the reason for a design is unclear, state that uncertainty rather than guessing.

Documentation changes should be completed and reviewed before structural refactoring begins.

After documenting the current design, identify any mismatch between:

* documented responsibility;
* actual behavior;
* dependency direction;
* and state ownership.

Use those mismatches to guide the refactoring, but do not change code in this step. The goal is to improve understanding of the current design, not to change it.

### Style

Example js,ts

~~~
//
// Title of the ts/js docstring block
//
// THis is a concise docstring that explains the purpose, responsibility, and constraints of the code.
// It is not a line-by-line description of the implementation.
//
~~

Example python
~~~
"""
  Title of the python docstring block
 
  This is a concise docstring that explains the purpose, responsibility, and constraints of the code.
  It is not a line-by-line description of the implementation.
"""
~~~~
