---
name: build-safety-handoff
description: Require a safety gate before code changes land: isolated staging, checks, and a recorded handoff.
---

# build-safety-handoff

## What Council does with it

- Stage code changes in a separate branch or git worktree, never directly on the main checkout.
- Require type-check/tests and a boot or smoke check before calling a change done.
- Record who handed what to whom; flag any dispatch that would bypass the gate as a risk.

See ../../CONSTITUTION.md for the rules every run follows.
