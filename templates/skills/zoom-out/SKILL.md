---
name: zoom-out
description: 'Quickly go up one level of abstraction to see the module map. Use when navigating an unfamiliar codebase, after getting deep in implementation details, or when you need to understand how the current piece fits into the larger system.'
---

# Zoom Out

## Overview

When you're deep in a file or a function, it's easy to lose sight of how it fits into the larger system. This skill is a quick **orientation reset** — a prompt to step back, look at the module map, and reconnect the current code to the domain vocabulary and system boundaries.

**Use it as a single command:** `/zoom-out`

## When to Use

- You've been reading one file for a while and lost track of the bigger picture
- You're about to make a change and want to confirm you're in the right place
- You're onboarding to a new area of the codebase
- Before opening a PR, to verify your change is appropriately scoped
- After a `diagnose` session, to see whether the bug lives in the right module

**When NOT to use:** You need a full codebase walkthrough — use `codebase-onboarding` instead. You need to understand domain vocabulary — use `grill-with-docs`.

## The Zoom-Out Prompt

When triggered, execute this sequence:

### Step 1 — Read CONTEXT.md (if present)

```bash
cat CONTEXT.md 2>/dev/null || echo "No CONTEXT.md found"
```

If CONTEXT.md exists, use its vocabulary for the module map you're about to produce.

### Step 2 — Produce the Module Map

Generate a one-level-up view of the current area. Format:

```
MODULE MAP: [Area name]

[module-a/]        — [one-line purpose]
[module-b/]        — [one-line purpose]  ← you are here
  [sub-module/]    — [one-line purpose]
[module-c/]        — [one-line purpose]

Dependencies (what this area depends on):
  → [external module or service]
  → [external module or service]

Dependents (what depends on this area):
  ← [module that imports/uses this]
  ← [module that imports/uses this]
```

**Rules for the module map:**

- One line per module — no deep dives
- Use CONTEXT.md vocabulary for names and descriptions
- Mark the current location with `← you are here`
- Include external dependencies (external packages, services, databases)
- Show what imports this area (dependents)

### Step 3 — State the Current Task in Context

After the map, one sentence:

```
CURRENT TASK: [What you are doing, placed in context of the map]
Example: "Adding email validation to the user registration flow in auth/registration — this touches auth/validators and will be called by api/routes/auth."
```

### Step 4 — Identify Adjacent Risk

One question: **"What else could be affected by this change?"**

Scan the dependents list. For each, ask:

- Does my change affect the contract this module relies on?
- Does my change change timing, error behavior, or data shape?

List anything that needs a second look:

```
RISK CHECK:
  [module] — [why it might be affected]
  [module] — [why it might be affected]
```

If the list is empty, say so explicitly.

## Quick Reference

The full zoom-out sequence in one block:

```
1. Read CONTEXT.md                          (30 seconds)
2. List modules in current area             (1 minute)
3. Mark "you are here"                      (10 seconds)
4. List dependencies and dependents         (1 minute)
5. State current task in context            (1 sentence)
6. List adjacent risk modules               (30 seconds)
```

Total: under 3 minutes.

## Integration with Other Skills

- Run before `diagnose` to confirm you're looking in the right area
- Run before `tdd` to understand which module owns the behavior you're testing
- Run after `improve-codebase-architecture` to see if module boundaries changed
- Run before opening a PR to write an accurate PR description

## Verification

A successful zoom-out produces:

- [ ] Module map with current location marked
- [ ] Dependencies and dependents listed
- [ ] Current task placed in the context of the map
- [ ] Adjacent risk modules identified (or explicitly none)
