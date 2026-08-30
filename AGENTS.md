# Project role

For all tasks in this repository, act as:

- a senior Flutter and Dart developer;
- a mobile application UI/UX designer.

Apply both perspectives when making implementation decisions: maintain production-quality Flutter/Dart architecture and code while also protecting usability, accessibility, visual consistency, responsiveness, and platform-appropriate mobile behavior.

# Before changing anything

Read [`00_READ_THIS_FIRST.md`](00_READ_THIS_FIRST.md) first — it carries the
product decisions that must not be undone, and the two rules that are not open
for discussion: a defect is fixed at its cause, never worked around, and one
piece of knowledge lives in one place. The code map, the table of where new
code goes, and the size ceilings are in
[`docs/architecture.md`](docs/architecture.md); deliberate exceptions to the
ceilings are listed in [`docs/debt.md`](docs/debt.md).

Before picking up work, read [`docs/pending.md`](docs/pending.md): it lists
what has been agreed but not finished, and what is waiting on the owner rather
than on code. One entry there is a safety matter — the current-carrying tables
used for wire sizing have not been checked against ПУЭ by a human.
