---
name: grill-me
description: 'Relentless one-question-at-a-time interview about a plan, design, or decision. Asks every question needed to resolve all ambiguity, always providing a recommended answer. Use when you have a rough plan and want to pressure-test it before committing.'
---

# Grill Me

## Overview

You have a plan. You think it's ready. But have you actually thought through all the edge cases? The failure modes? The alternatives you dismissed?

This skill runs a structured interrogation of your plan — one question at a time, until every branch of the decision tree is resolved.

**Key rule:** Every question comes with a recommended answer. You shouldn't have to think from scratch — just confirm or override the recommendation.

## When to Use

- You have a rough plan and want to find the holes before writing code
- Making a significant architectural decision that will be hard to reverse
- Reviewing a plan with someone who isn't domain-familiar yet (recommended answers help them participate)
- Before running `to-prd` or `to-issues` — get alignment first

**When NOT to use:**
- Requirements are completely unknown — use `idea-refine` to explore first
- You need domain vocabulary alignment — use `grill-with-docs` (it does this AND creates docs)
- You're confident the plan is solid and just need to execute — just start

## The Protocol

### Start

Present your plan:
```
PLAN: [2-5 sentences describing what you want to build or change]
```

Then say: **"Grill me."**

### During the session

For each question:

1. **One question at a time** — never bundle multiple questions
2. **Recommended answer** — always provide a default ("I'd recommend X because Y")
3. **Wait** for confirmation or override before moving to the next question
4. **Acknowledge and continue** — confirm what was decided, then move on

**Question format:**
```
[Question number]. [The question]?
→ Recommended: [recommended answer + brief reason]
```

**Example exchange:**
```
1. Should authentication be stateless (JWT) or stateful (sessions)?
→ Recommended: JWT — simpler to scale horizontally and works with the existing API clients.

[User confirms or overrides]

2. Should the JWT expire after 15 minutes, 1 hour, or 24 hours?
→ Recommended: 1 hour — balances security (short enough to limit exposure) with UX (long enough that users aren't re-authing constantly).

[User confirms or overrides]
```

### Question coverage

Work through these categories (skip any that don't apply):

**Scope:**
- What is explicitly out of scope?
- What existing behavior must not change?
- Is this change reversible? What's the rollback plan?

**Data and state:**
- What new data is created, modified, or deleted?
- Who owns this data and for how long?
- What are the consistency requirements?

**Error handling:**
- What are the failure modes?
- How does the user experience each failure?
- Are there partial success states?

**Performance:**
- What are the latency expectations?
- What's the expected load (requests/sec, data volume)?
- Are there any caching requirements?

**Security:**
- What data is sensitive?
- Who should have access to what?
- What are the authentication and authorization requirements?

**Dependencies:**
- What does this change depend on?
- What depends on this change?
- Are there breaking changes to existing consumers?

**Deployment:**
- Does this require a migration?
- Is there a feature flag strategy?
- What monitoring/alerting is needed?

### Close

When all categories are covered:
```
DECISIONS SUMMARY:
1. [Decision]: [Outcome]
2. [Decision]: [Outcome]
...

OPEN QUESTIONS REMAINING:
- [Any question that couldn't be answered yet]
```

If there are open questions, note who owns each one and how to resolve it.

## Tips for Better Grilling

**Be adversarial (in a useful way):**
- "What happens when this fails at step 3?"
- "Why this approach and not [obvious alternative]?"
- "Who's the user who will most hate this decision?"

**Probe assumptions:**
- "You said [X] — is that a requirement or a preference?"
- "This assumes [Y]. What if that assumption is wrong?"
- "Is there a simpler way to solve this problem?"

**Surface hidden decisions:**
- "Is the order of operations important here?"
- "What does 'success' look like for the hardest user case?"
- "What would you change if you had twice the time?"

## Relationship to Other Skills

| Need | Use instead |
|---|---|
| Start from vague idea, explore options | `idea-refine` |
| Align on domain language + create ADRs | `grill-with-docs` |
| Quick pressure test of a concrete plan | `grill-me` ← this skill |
| Turn decisions into a formal PRD | `to-prd` |

## Verification

The session is complete when:
- [ ] Every category was covered (or explicitly declared out of scope)
- [ ] No question is in "maybe" state — each is resolved or explicitly deferred
- [ ] Decisions summary written
- [ ] Open questions have owners
