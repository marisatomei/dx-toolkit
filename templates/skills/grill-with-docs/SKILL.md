---
name: grill-with-docs
description: 'Relentless Q&A session to align on a plan, build a shared CONTEXT.md domain vocabulary, and capture decisions as ADRs. Use before major features, architecture changes, or any time the team lacks a shared language for the problem.'
---

# Grill with Docs

## Overview

Before writing code, align on language. Miscommunication costs more than any technical debt. This skill runs a structured questioning session that simultaneously:

1. Surfaces assumptions and gaps in a plan
2. Builds a `CONTEXT.md` shared vocabulary so the whole team — humans and AI — uses the same terms
3. Captures key decisions as Architecture Decision Records (ADRs)

**Core insight:** If you and your collaborator (human or AI) can't agree on what a word means, you're not disagreeing about the solution — you're speaking different languages.

## When to Use

- Starting a major feature or system change
- Onboarding AI agents to a domain they don't understand yet
- After requirements come in with ambiguous terminology
- Before writing a spec or PRD (run this first, then use `to-prd`)
- When architectural decisions need to be documented

**When NOT to use:** You have a clear spec and just need to implement it. Use `planning-and-task-breakdown` or `to-issues` instead.

## Process

### Step 1 — Present the Plan

State the plan or idea to be grilled. Be as rough as needed — the point is to have something to interrogate.

```
PLAN: [2-5 sentences describing what you want to build or change]
GOAL: [The outcome you're optimizing for]
CONSTRAINTS: [Known limitations: time, compatibility, team size, etc.]
```

### Step 2 — Ground in CONTEXT.md

Before grilling, check whether a `CONTEXT.md` exists at the repo root.

**If CONTEXT.md exists:**

- Read it first
- Use its defined terms throughout the session
- If the plan introduces new terms not in CONTEXT.md, add them

**If CONTEXT.md doesn't exist:**

- This session will create the first version
- Start with a minimal vocabulary section

### Step 3 — The Grill

Ask one question at a time. For each question:

- State the question clearly
- Provide a recommended answer (default assumption if the person doesn't have a preference)
- Wait for confirmation or correction before proceeding

**Question categories to cover:**

**Terminology:**

- What do you mean by [X]? Is it the same as [Y]?
- When you say [term], do you mean [interpretation A] or [interpretation B]?

**Scope:**

- What is explicitly OUT of scope for this change?
- What existing behavior must not change?
- What are the failure modes we need to handle?

**Decisions:**

- Why [this approach] over [alternative]?
- What would make you reconsider this decision?
- Who needs to sign off before we proceed?

**Dependencies:**

- What does this touch that isn't obvious?
- What other teams, systems, or features depend on this?

Continue until the plan has no unresolved ambiguity.

### Step 4 — Update CONTEXT.md

After the grilling session, update (or create) `CONTEXT.md` with any new or clarified terms.

**CONTEXT.md format:**

```markdown
# Context

## Domain Vocabulary

### [Term]

[One-sentence definition as used in THIS codebase — not the dictionary definition]
Example: `User` — an authenticated account holder. Distinct from `Guest` (unauthenticated) and `Admin` (elevated permissions).

### [Term]

...

## Key Constraints

- [Constraint discovered in grilling sessions]
- ...

## Open Questions

- [Question not yet resolved with a link to the GitHub issue]
```

**Rules for CONTEXT.md:**

- Use the terms the codebase actually uses, not ideal names
- Each term gets one definition — no synonyms, no alternatives
- If a term means different things in different contexts, define both with their context qualifier
- Keep it short: if a term needs more than 3 sentences, it needs its own `docs/` document

### Step 5 — Capture ADRs

For each significant decision made during the grill, create an ADR.

**Location:** `docs/adr/NNNN-short-title.md`

**ADR template:**

```markdown
# ADR-NNNN: [Short title]

## Status

Accepted | Proposed | Superseded by ADR-MMMM

## Context

[1-3 sentences: what situation led to this decision?]

## Decision

[1-2 sentences: what was decided?]

## Consequences

**Positive:** [what this enables]
**Negative:** [what this prevents or costs]
**Neutral:** [what changes but is neither good nor bad]
```

Number ADRs sequentially. Link from CONTEXT.md when a vocabulary term is shaped by an architectural decision.

### Step 6 — Confirm Alignment

Before closing:

- [ ] Summarize the key decisions from the session
- [ ] Confirm CONTEXT.md reflects the agreed vocabulary
- [ ] Any ADRs created are linked
- [ ] All "open questions" are either resolved or tracked as GitHub issues

## Verification

The session is complete when:

- [ ] The plan has no unresolved terminology ambiguity
- [ ] `CONTEXT.md` is updated with all new terms from this session
- [ ] Significant architectural decisions have ADRs
- [ ] Everyone in the session agrees on what will be built
