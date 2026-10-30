---
name: lean-dispatch
description: Prefer minimal-toolset, low-token dispatches; use tool-gating so a read-only call cannot mutate anything.
---

# lean-dispatch

## What Council does with it

- Advisory polls run with tools disabled or on a read-only allowlist (see `council --advisory`).
- For quick checks, pick the cheapest capable model, not the biggest.
- Keep prompts short: send the task and the minimum context it needs.

See ../../CONSTITUTION.md for the rules every run follows.
