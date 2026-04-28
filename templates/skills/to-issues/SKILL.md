---
name: to-issues
description: 'Break a plan or PRD into GitHub issues as independently-grabbable vertical slices. Each issue contains acceptance criteria, dependency order, and an HITL/AFK classification. Use after to-prd or planning-and-task-breakdown to produce actionable GitHub issues.'
---

# To Issues

## Overview

A plan in a document is not actionable. GitHub issues are. This skill converts a plan or PRD into a set of GitHub issues where each issue represents a **vertical slice** — a thin end-to-end piece of working software.

**Vertical slice principle:** Each issue, when complete, delivers observable value (a working behavior, a passing test, a live endpoint). No issue delivers only a horizontal layer (e.g., "write all the database models").

## When to Use

- You have a PRD, spec, or rough plan and need to turn it into GitHub issues
- Breaking down a large feature for a sprint
- Creating an issue backlog for an AI agent to work through autonomously
- After running `to-prd` (which creates a PRD issue)

**When NOT to use:** You already have issues and need to sequence them — use `planning-and-task-breakdown`. You need a PRD first — run `to-prd` first.

## Issue Classification

Every issue gets one of two labels:

**`🤖 ready-for-agent` (AFK — Away From Keyboard)**
AI agent can implement this without further guidance. Criteria:

- Well-defined acceptance criteria
- No ambiguous design decisions
- No external dependencies requiring human coordination
- Can be verified by running tests

**`👤 ready-for-human` (HITL — Human in the Loop)**
Requires human involvement. Criteria:

- Design decision with multiple valid approaches
- Requires access to external system (credentials, staging, vendor)
- Involves UI/UX judgment calls
- Has downstream dependencies on other teams

## Process

### Step 1 — Read the Plan

Read the plan, PRD, or spec to be broken down. Identify:

- The end-to-end user flows being built
- The key integration points (database, APIs, UI, external services)
- Any explicit constraints or non-functional requirements

### Step 2 — Draft Vertical Slices

List the slices. Each slice should:

- Be independently mergeable
- Have at least one observable output (test, endpoint, UI element, job run)
- Not depend on another incomplete slice to demonstrate its behavior

**Slice ordering rules:**

1. Tracer bullet first — the thinnest path through the full system
2. Data model / schema before business logic that depends on it
3. Core behavior before edge cases
4. Happy path before error paths
5. Internal before external (internal APIs before webhooks)

**Anti-patterns to avoid:**

- "All models" as a single issue (horizontal slice)
- "All API endpoints" as a single issue
- "Write tests" as a separate issue (tests belong in the implementation issue)
- Issues with no verifiable acceptance criteria

### Step 3 — Write Each Issue

For each slice, create a GitHub issue using this template:

**Issue title format:** `[verb] [noun]: [brief description]`
Examples:

- `feat: add user registration endpoint`
- `fix: cart total incorrect with discount codes`
- `refactor: extract payment processing into PaymentService`

**Issue body template:**

```markdown
## Summary

[1-2 sentences: what this issue delivers]

## Acceptance Criteria

- [ ] [Observable behavior 1]
- [ ] [Observable behavior 2]
- [ ] Tests added or updated to cover the above
- [ ] No regressions in existing tests

## Context

[Any relevant background, links to related issues, or architectural decisions]

## Out of Scope

[Explicitly what this issue does NOT include — prevents scope creep]

## Dependencies

Blocked by: #[issue number] (if applicable)
Blocks: #[issue number] (if applicable)
```

### Step 4 — Create Issues with gh CLI

```bash
# Single issue
gh issue create \
  --title "feat: add user registration endpoint" \
  --body "$(cat issue-body.md)" \
  --label "ready-for-agent" \
  --milestone "v1.0"

# Batch from a list (adapt to your shell)
while IFS= read -r title; do
  gh issue create --title "$title" --label "needs-triage"
done < titles.txt
```

### Step 5 — Set Dependencies

For issues that must complete before others:

- Add "Blocked by: #N" in the issue body
- Optionally use a project board to visualize the dependency graph

If your project uses GitHub Projects:

```bash
gh project item-add [project-number] --owner [org] --url [issue-url]
```

### Step 6 — Review the Set

Before closing this session, verify the full issue set:

- [ ] First issue is a tracer bullet (thin end-to-end path)
- [ ] No horizontal slices (no "all models", "all endpoints" etc.)
- [ ] Every issue has at least 2 acceptance criteria
- [ ] Every issue is independently mergeable (no dangling dependencies)
- [ ] AFK/HITL classification is correct for each issue
- [ ] Dependencies are bidirectionally linked
- [ ] Total issue count is reasonable (aim for 3–8 per feature, not 30)

## Example Breakdown

**Plan:** "Add user authentication to the API"

**Horizontal (wrong):**

- Write all user models
- Write all auth endpoints
- Write all auth tests
- Hook up JWT

**Vertical (correct):**

1. 🤖 `feat: register user with email+password (tracer bullet)` — POST /auth/register returns JWT, one passing integration test
2. 🤖 `feat: login with email+password` — POST /auth/login returns JWT
3. 🤖 `feat: protect routes with JWT middleware` — 401 on missing/invalid token
4. 🤖 `feat: refresh token endpoint` — POST /auth/refresh rotates token
5. 👤 `feat: password reset via email` — requires email service configuration
6. 🤖 `fix: rate limit auth endpoints` — depends on #3

Each issue builds on the last, and each is deployable independently.

## Verification

The session is complete when:

- [ ] All issues created in GitHub
- [ ] Labels applied (`ready-for-agent` or `ready-for-human`)
- [ ] Dependencies set
- [ ] Issues added to project/milestone if applicable
- [ ] No horizontal slices remain
