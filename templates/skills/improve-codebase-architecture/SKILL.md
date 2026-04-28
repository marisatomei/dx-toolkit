---
name: improve-codebase-architecture
description: 'Find and fix shallow modules — code that is complex to use but simple inside. Applies the "deep module" principle from John Ousterhout to identify where abstraction layers are earning their weight and where they are not. Use during architectural review or refactoring sprints.'
---

# Improve Codebase Architecture

## Overview

Good architecture hides complexity. The **deep module principle** (from John Ousterhout's _A Philosophy of Software Design_): the best modules have a **simple interface** and **complex implementation**. Shallow modules are the opposite: complex to use, trivial inside.

Shallow modules create cognitive load everywhere they're used. Deep modules contain complexity in one place and let callers ignore it.

**This skill finds "deepening opportunities"** — places where an abstraction is not pulling its weight and where refactoring to a deeper module would reduce total system complexity.

## When to Use

- Before a refactoring sprint — need to know where to focus effort
- During code review when something feels needlessly complex to call
- When the team spends more time reading interfaces than writing code
- When `CONTEXT.md` vocabulary doesn't align with code structure

**When NOT to use:** You have a specific bug to fix — use `diagnose`. You need an architectural decision — use `grill-with-docs`.

## Signs of Shallow Modules

Look for these patterns as you explore the codebase:

```
# Shallow module patterns:

1. Pass-through methods
   — method does nothing except call one other method
   — interface complexity = implementation complexity

2. Thin wrappers
   — class wraps one other class with no additional logic
   — caller still needs to understand the wrapped type

3. Exposed internals
   — callers must know about internal state to use the module correctly
   — "you must call init() before use()", "don't call X after Y"

4. Configuration explosion
   — requires 8 parameters to construct, most of which callers copy-paste
   — callers know more about the module's internals than the module does

5. Leaky temporality
   — callers must coordinate timing or ordering across module boundaries
   — "call setup() first, then processAll(), then teardown()"

6. Missing vocabulary
   — a concept that appears in CONTEXT.md has no corresponding module
   — teams talk about it but the code doesn't name it
```

## Process

### Step 1 — Read CONTEXT.md

Before exploring code, read `CONTEXT.md` (if it exists) to understand the domain vocabulary.

Build a list of the 10-15 most important domain concepts from CONTEXT.md. These are the concepts the codebase _should_ have explicit modules for.

**If CONTEXT.md doesn't exist:** Run `grill-with-docs` first to establish vocabulary, then return.

### Step 2 — Map Module Depth

For each significant module (file, class, package), score it:

```
INTERFACE COMPLEXITY (1–5):
  1 = one function, zero config
  5 = many functions, many params, ordering constraints, caller must understand internals

IMPLEMENTATION COMPLEXITY (1–5):
  1 = trivially simple (delegates, returns constant)
  5 = nontrivial algorithm, meaningful abstraction

DEPTH SCORE = implementation / interface
  Score < 1.0  → shallow module (refactor candidate)
  Score 1.0–2.0 → acceptable
  Score > 2.0  → deep module (valuable abstraction)
```

### Step 3 — Find Deepening Opportunities

For each shallow module identified:

**Option A: Deepen the interface**

- Can I hide parameters behind sensible defaults?
- Can I merge methods that callers always call together into a single method?
- Can I absorb configuration that callers always set the same way?

**Option B: Deepen the implementation**

- Is there shared logic in callers that belongs in this module?
- Are there error paths callers must handle that the module could handle internally?
- Are there validation rules that callers must know about?

**Option C: Eliminate the layer**

- Is this abstraction adding any value at all?
- Can callers just use the underlying thing directly?
- Would removing this layer reduce total lines of code and complexity?

### Step 4 — Rank and Grill

Rank the top 5 deepening opportunities by impact:

```
RANK | MODULE | DEPTH SCORE | OPPORTUNITY | IMPACT
-----|--------|-------------|-------------|-------
  1  | [path] | [score]     | [option]    | [why]
  2  | ...
```

For each candidate, ask:

- What is the simplest interface this module _could_ have?
- What callers would benefit most from the improved interface?
- What is the migration cost?
- Does this change affect any public API or external contract?

Use `grill-me` if the right approach is unclear.

### Step 5 — Implement (Deepest First)

For each selected opportunity:

1. Write the new interface first (type signatures, method signatures, docstring)
2. Get review on the interface before writing any implementation
3. Implement
4. Migrate callers
5. Delete the old interface once all callers are migrated

**Anti-patterns:**

- Do not add a new deep interface alongside the old shallow one indefinitely — pick a migration date
- Do not deepen an interface by adding magic/implicit behavior — callers must still be able to predict outcomes
- Do not over-abstract: if the "deep" interface hides things callers legitimately need to control, you've gone too far

### Step 6 — Update CONTEXT.md

After refactoring:

- [ ] Update `CONTEXT.md` if module names changed
- [ ] Add new concepts discovered during refactoring
- [ ] Remove or update vocabulary for eliminated abstractions

## Red Flags During Implementation

- You're adding a new abstraction but the depth score is still < 1 — stop, reconsider
- A "deepening" requires callers to pass more information, not less — you're going the wrong direction
- The new interface requires reading the implementation to use correctly — still shallow
- You're creating circular dependencies to achieve depth — rethink module boundaries

## Verification

The session is complete when:

- [ ] Top 3-5 deepening opportunities addressed
- [ ] All tests pass
- [ ] Caller code is simpler (fewer lines, fewer parameters, fewer conditions)
- [ ] `CONTEXT.md` reflects any renamed or restructured concepts
- [ ] PR description explains the before/after depth scores for changed modules
