---
name: github-triage
description: 'Label-based state machine for GitHub issue triage. Guides maintainers through a structured process to move issues from unlabeled → needs-triage → ready-for-agent / ready-for-human / wontfix / needs-info. Use during issue triage sessions.'
---

# GitHub Triage

## Overview

Untriaged issues are invisible work. This skill uses a label-based state machine to make issue status explicit and actionable — both for human maintainers and AI agents.

The state machine has one entry state, four terminal states, and one hold state:

```
[new issue]
     |
     v
needs-triage
     |
     +──→ needs-info        (blocked on reporter — waiting for more detail)
     |
     +──→ ready-for-agent   (well-defined, AI agent can handle autonomously)
     |
     +──→ ready-for-human   (needs human judgment or context)
     |
     +──→ wontfix           (valid report but out of scope / won't address)
     |
     +──→ [priority label]  (accepted + prioritized, goes into backlog)
```

## When to Use

- Weekly issue triage sessions
- After a new issue is opened and needs review
- Before sprint planning to classify the backlog
- When AI agents need to know which issues they can act on autonomously

**When NOT to use:** Automated webhook-driven labeling (use the `smart-labeler` workflow instead). This skill is for **interactive human-led triage**.

## Label Setup

Create these labels before running your first triage session:

```
needs-triage     #FBCA04   Issues that have not been reviewed yet
needs-info       #D4C5F9   Waiting on more information from the reporter
ready-for-agent  #0075CA   Well-specified, safe for autonomous AI action
ready-for-human  #E4E669   Requires human judgment or domain expertise
wontfix          #FFFFFF   Valid but out of scope or won't be addressed
```

**Priority labels (add all five):**

```
priority: critical   #B60205   Must fix immediately
priority: high       #D93F0B   Fix in current sprint
priority: medium     #E99695   Fix in next sprint
priority: low        #F9D0C4   Fix when time allows
priority: backlog    #FEF2C0   Accepted but not scheduled
```

**Setup command:**

```bash
gh label create "needs-triage"    --color "FBCA04" --description "Not yet reviewed"
gh label create "needs-info"      --color "D4C5F9" --description "Waiting on reporter"
gh label create "ready-for-agent" --color "0075CA" --description "Safe for autonomous AI action"
gh label create "ready-for-human" --color "E4E669" --description "Requires human judgment"
gh label create "wontfix"         --color "FFFFFF" --description "Valid but will not fix"
gh label create "priority: critical" --color "B60205" --description "Immediate fix required"
gh label create "priority: high"     --color "D93F0B" --description "Fix this sprint"
gh label create "priority: medium"   --color "E99695" --description "Fix next sprint"
gh label create "priority: low"      --color "F9D0C4" --description "Fix when able"
gh label create "priority: backlog"  --color "FEF2C0" --description "Accepted, unscheduled"
```

## Triage Process

For each issue, work through these questions in order. Stop at the first decision point.

### Question 1 — Is it reproducible / well-defined?

**Bug reports:**

- Does it have: steps to reproduce, expected behavior, actual behavior, environment info?
- Can you reproduce it with those steps?

**Feature requests:**

- Is the desired behavior clear enough to write acceptance criteria?
- Is the scope bounded?

→ **If NO:** Label `needs-info`, reply with the missing information template (see below), close triage for this issue.

→ **If YES:** Continue to Question 2.

### Question 2 — Is it in scope?

Does this align with the project's goals and roadmap?

→ **If NO:** Label `wontfix`, write a brief explanation in a comment, close the issue.

→ **If YES:** Continue to Question 3.

### Question 3 — Can an AI agent handle this autonomously?

Would a capable coding agent (with full repo access) be able to solve this correctly and safely without additional guidance?

Criteria for `ready-for-agent`:

- The fix/feature is well-scoped (single responsibility)
- No ambiguous design decisions need to be made
- No access to external systems, credentials, or human stakeholders required
- The acceptance criteria are unambiguous
- Tests can be written to verify correctness

→ **If YES:** Label `ready-for-agent` + assign a priority label.

→ **If NO:** Label `ready-for-human` + assign a priority label.

### Assigning Priority

After routing to `ready-for-agent` or `ready-for-human`, assign one priority label:

| Priority             | Criteria                                                |
| -------------------- | ------------------------------------------------------- |
| `priority: critical` | Production is broken, data loss, security vulnerability |
| `priority: high`     | Core feature broken, significant user impact            |
| `priority: medium`   | Non-critical bug, quality-of-life improvement           |
| `priority: low`      | Minor issue, cosmetic, nice-to-have                     |
| `priority: backlog`  | Valid but no immediate impact, schedule later           |

## Response Templates

### needs-info response

```
Thanks for the report! To investigate, I need a bit more information:

- [ ] Steps to reproduce (what exactly did you do?)
- [ ] Expected behavior (what did you expect to happen?)
- [ ] Actual behavior (what happened instead?)
- [ ] Environment (OS, browser/runtime version, relevant config)
- [ ] Minimal reproduction case (if possible)

I'll re-triage once this is available.
```

### wontfix response

```
Thanks for taking the time to file this.

After review, we've decided not to address this because: [reason].

This isn't a reflection on the quality of the report — it's just outside the current scope of the project. Feel free to discuss in [discussions link] or fork and implement it separately.
```

### ready-for-agent comment

```
This issue is well-specified and safe for autonomous implementation. Labeling as `ready-for-agent`.

Acceptance criteria:
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] Tests added/updated to cover the change
```

## Automation Integration

Once labels are in place, the `smart-labeler` and `issue-quality-enhancer` workflows can assist with initial triage. This skill handles the judgment calls those workflows can't make.

**Recommended workflow:**

1. `smart-labeler` applies `needs-triage` automatically on new issues
2. Human runs this skill weekly to process the `needs-triage` queue
3. AI agents pick up `ready-for-agent` issues autonomously

## Verification

A triage session is complete when:

- [ ] No issues remain labeled `needs-triage`
- [ ] Every `ready-for-agent` issue has acceptance criteria in the body or a comment
- [ ] Every `needs-info` issue has a comment explaining what's missing
- [ ] Milestones or project board updated to reflect new priority assignments
