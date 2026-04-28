---
name: to-prd
description: 'Synthesize current conversation context and codebase state into a Product Requirements Document submitted as a GitHub issue. Use after a design conversation to capture what was decided — not to start a new requirements interview.'
---

# To PRD

## Overview

A PRD captures **what was already decided** so the team can act on it. This skill synthesizes everything discussed — in the current conversation, in linked issues, in the codebase — into a single structured PRD and submits it as a GitHub issue.

**Key distinction from other spec skills:**
- `idea-refine` — starts from a rough idea and develops it through divergent/convergent thinking
- `grill-with-docs` — runs a structured Q&A to reach alignment and build domain vocabulary
- `to-prd` — **writes down what's already been decided** and creates the issue

Run `to-prd` after a design conversation has concluded. Not before.

## When to Use

- A design discussion has concluded and decisions need to be captured
- A stakeholder described a feature verbally/in chat and you need to formalize it
- A GitHub issue exists but the description is too vague to act on — replace it with a PRD
- Before running `to-issues` (PRD provides the source material for issue breakdown)

**When NOT to use:** Requirements are still unclear or contested — resolve with `grill-with-docs` or `grill-me` first.

## PRD Structure

The PRD issue uses this template:

```markdown
# PRD: [Feature Name]

## Problem
[1-3 sentences: what problem are we solving and for whom?
Include the current pain point, not the solution.]

## Goal
[1 sentence: what does success look like? Make it measurable if possible.]
Example: "Users can register with email+password and receive a welcome email within 5 seconds."

## Non-Goals
[Explicitly what this feature does NOT include.
Non-goals prevent scope creep and set expectations.]
- [Non-goal 1]
- [Non-goal 2]

## Proposed Solution
[2-5 sentences: the technical approach agreed upon.
Enough detail to write acceptance criteria, not a full design doc.]

## Acceptance Criteria
- [ ] [Observable behavior: user can do X and sees Y]
- [ ] [Observable behavior: system does X when Y occurs]
- [ ] [Non-functional: performance, security, accessibility requirement]
- [ ] Existing tests pass without modification
- [ ] New tests cover all new behaviors

## Open Questions
- [ ] [Any unresolved decision with a proposed default]

## Out of Scope (Future Consideration)
- [Related features that came up but are explicitly deferred]

## References
- Related issue: #[number]
- Design doc: [link]
- ADR: [link]
```

## Process

### Step 1 — Gather Context

Collect everything relevant before writing:

```
CONVERSATION: [Summary of what was discussed and decided]
EXISTING CODE: [Relevant files or modules that will be affected]
RELATED ISSUES: [GitHub issue numbers that provide context]
CONSTRAINTS: [Non-negotiables: performance, compatibility, deadline]
```

Read the codebase for any relevant existing patterns, naming conventions, or adjacent features.

### Step 2 — Draft the PRD

Fill in each section:

**Problem section:**
- Describe the current state (without the feature)
- Name the user or system experiencing the pain
- Avoid solution language — "users cannot..." not "we need to add..."

**Goal section:**
- One sentence, present tense, measurable
- Avoid vague success criteria like "improved experience" or "better performance"
- Good: "API returns results in under 200ms for 95th percentile of requests"
- Bad: "Fast API responses"

**Acceptance Criteria:**
- Each criterion must be verifiable (automated test or explicit manual check)
- Use present tense: "User sees error message" not "User will see error message"
- Cover the happy path, the main error paths, and any non-functional requirements
- Aim for 4-8 criteria — not too few to be vague, not too many to be a spec

**Non-Goals:**
- Include at least 2-3 explicit non-goals
- These are often the "yes, but what about X" questions that came up in discussion
- Phrase positively when possible: "This does not handle multi-tenant setups" not "NOT multi-tenant"

### Step 3 — Review Before Submitting

Before creating the issue:
- [ ] Problem section does not mention the solution
- [ ] Goal is measurable (not "better" or "improved")
- [ ] Every acceptance criterion is verifiable
- [ ] At least 2 non-goals listed
- [ ] Open questions captured (even if answered — for the record)
- [ ] References to related issues and ADRs included

### Step 4 — Submit as GitHub Issue

```bash
gh issue create \
  --title "PRD: [Feature Name]" \
  --body "$(cat prd.md)" \
  --label "prd,needs-triage" \
  --assignee "@me"
```

After submission:
- Share with stakeholders for review
- Run `to-issues` to break the PRD into implementation issues
- Link the PRD issue from each implementation issue: `Implements #[PRD issue number]`

## Common Pitfalls

**Solution in the problem statement:**
```
# Bad
Problem: We need to add OAuth login

# Good
Problem: Users who use Google or GitHub for authentication must create a separate password to use our app, leading to 40% drop-off at the registration step.
```

**Unmeasurable goals:**
```
# Bad
Goal: Users have a better login experience

# Good
Goal: Registration completion rate increases from 60% to 85% as measured by funnel analytics.
```

**Acceptance criteria that test implementation:**
```
# Bad
- [ ] AuthController.handleOAuthCallback is called

# Good
- [ ] User clicking "Login with Google" completes sign-in and lands on dashboard
```

## Verification

The PRD is ready when:
- [ ] A stakeholder who wasn't in the design discussion can understand the feature from the PRD alone
- [ ] An engineer can write acceptance tests from the criteria without asking questions
- [ ] Non-goals prevent at least 2 likely scope creep directions
- [ ] GitHub issue created and linked to related issues
