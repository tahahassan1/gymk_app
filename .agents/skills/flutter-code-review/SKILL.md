---
name: flutter-code-review
description: Run a self-review checklist before completing a task. Use when the user says "task done", "work is done", "finished", "review this", or when verifying code quality and safety before approval.
---

# Code Completion Self-Review

Run this checklist before marking any task as done. This is a read-only review — do not modify code during this step.

## Correctness

- [ ] The root cause is correctly identified and addressed (not just symptoms).
- [ ] The solution handles the specific problem described in the task.
- [ ] Edge cases are handled: null, empty, loading, and error states.
- [ ] No silent failures — errors propagate cleanly through layers.

## Architecture Compliance

- [ ] Layer boundaries respected: ui → logic → data.
- [ ] No business logic in UI layer.
- [ ] Cubits depend only on repos, not data sources.
- [ ] Logic layer has no Flutter/UI imports.
- [ ] Shared logic placed in `core/`, not duplicated across features.

## Safety

- [ ] No existing functionality, APIs, flows, or UX broken.
- [ ] No performance regressions (unnecessary rebuilds, heavy build methods, missing const).
- [ ] No security risks (hardcoded secrets, unvalidated input, sensitive data in logs).
- [ ] No unused imports, dead code, or debug artifacts left behind.
- [ ] Controllers and focus nodes properly disposed.

## Code Quality

- [ ] Code is clean, readable, and follows project conventions.
- [ ] Files and functions are small and focused.
- [ ] No unnecessary duplication.
- [ ] Dart naming conventions followed.
- [ ] Import ordering correct.

## Output

After completing the checklist, provide a brief summary:

1. **What** was changed
2. **Why** it was changed
3. **Why** the solution is safe and correct

If any checklist item fails, flag it and suggest a fix before proceeding.
