---
name: context-checkpointing
description: Use checkpoint/resume patterns for long or risky tasks so every step is reversible.
---

# context-checkpointing

## What Council does with it

- Persist task context to disk so work survives a restart.
- Checkpoint before mutating steps (for example a shadow git commit or branch).
- Run a read-only planning pass before any mutating pass.

See ../../CONSTITUTION.md for the rules every run follows.
