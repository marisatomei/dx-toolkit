---
name: write-a-skill
description: 'Create a new skill for dx-toolkit. Guides through gathering requirements, drafting the SKILL.md in the correct format, and reviewing against the skill anatomy checklist. Use when adding a new repeatable workflow to the toolkit.'
---

# Write a Skill

## Overview

A skill is a structured, repeatable workflow for a specific task. This meta-skill guides you through creating a new one correctly — from understanding what makes a good skill to writing the file and reviewing it against standards.

**Skills that work well:**

- Have a clear trigger condition ("use when X")
- Have a clear stop condition ("done when Y")
- Give enough structure that two different people would produce similar results
- Are self-contained — all necessary context is in the SKILL.md

**Skills that don't work:**

- Vague at either end (unclear when to start, unclear when to stop)
- Require reading other files to understand
- Describe what to do without explaining why the steps are in that order
- Try to cover too many related tasks (should be split)

## When to Use

- You've done the same type of task 3+ times and want to formalize the pattern
- A new tool, framework, or process has been adopted and needs a workflow guide
- An existing skill needs significant rework (treat as a new skill)
- Adding skills from external sources (adapt them to dx-toolkit format)

**When NOT to use:** The task is a one-off. If you'll never do this again, don't write a skill.

## The SKILL.md Format

All skills live at `templates/skills/<name>/SKILL.md`.

**Required frontmatter:**

```yaml
---
name: skill-name # kebab-case, matches folder name
description: '...' # one sentence: what it does + when to use it
---
```

**Required sections:**

- `## Overview` — What this skill does and the core insight behind it
- `## When to Use` — Clear trigger conditions + "When NOT to use" to prevent misapplication
- `## Process` (or `## The [Name] Loop/Cycle/Steps`) — The step-by-step procedure

**Recommended sections:**

- `## Verification` — How to know the skill is complete (checklist)
- `## Common Rationalizations` or `## Red Flags` — Anti-patterns to catch
- Examples with before/after where the workflow transforms something

## Process

### Step 1 — Define the Skill

Answer these questions before writing anything:

```
TRIGGER: When should someone reach for this skill?
         (Be specific: "when tests fail" not "when debugging")

OUTCOME: What does the person have when this skill is done?
         (Be concrete: "a passing test suite" not "resolved issue")

CORE INSIGHT: What's the one non-obvious thing that makes this skill work?
              (If there's no insight, it might just be a checklist)

SIMILAR SKILLS: Which existing skills are closest?
                How is this different from each?
```

If you can't answer TRIGGER and OUTCOME clearly, the skill isn't ready to be written.

### Step 2 — Draft the Skeleton

Create the folder and file:

```bash
mkdir -p templates/skills/<name>
touch templates/skills/<name>/SKILL.md
```

Write the frontmatter and section headers first — no content yet:

```markdown
---
name: [name]
description: '[one sentence]'
---

# [Title Case Name]

## Overview

## When to Use

## Process

### Step 1 — [Name]

### Step 2 — [Name]

...

## Verification
```

Validate the structure before filling in content:

- [ ] Is the name kebab-case and matching the folder?
- [ ] Does the description say what it does AND when to use it?
- [ ] Are the process steps numbered and named?

### Step 3 — Write the Overview

Two parts:

1. **What it does** — one paragraph, plain prose
2. **Core insight** — the non-obvious principle behind why the steps are in this order

The overview should answer: "Why should I follow this process rather than just winging it?"

### Step 4 — Write When to Use

```markdown
## When to Use

- [Specific trigger 1]
- [Specific trigger 2]
- [Specific trigger 3]

**When NOT to use:** [Adjacent skill] handles [related case]. [Another skill] is better for [other case].
```

The "When NOT to use" section is as important as the triggers. It prevents misapplication and helps people navigate to the right skill.

### Step 5 — Write the Steps

For each step:

- Name it with a verb: "Step 1 — Reproduce" not "Step 1 — Reproduction"
- Explain what you're doing AND why
- Include the output/deliverable: "Output: a command that reliably fails"
- Add a checklist for complex steps
- Add a code example if commands or templates are involved

**Anti-patterns in step writing:**

- "Do X" with no explanation of when X is done
- Generic advice ("be thorough") without specific actions
- Steps that assume implicit knowledge not in the skill

### Step 6 — Write Verification

The done checklist — the conditions that confirm the skill was applied correctly:

```markdown
## Verification

The session is complete when:

- [ ] [Observable outcome 1]
- [ ] [Observable outcome 2]
- [ ] [Artifact exists: test, ADR, issue, PR, etc.]
```

Every item must be verifiable. "Code is clean" is not verifiable. "No linting errors on `npm run lint`" is.

### Step 7 — Review Against the Checklist

```
SKILL REVIEW CHECKLIST:

Structure:
- [ ] Frontmatter has name + description
- [ ] Name is kebab-case matching folder name
- [ ] Description: one sentence with what + when
- [ ] All required sections present
- [ ] Process steps are numbered and named

Content quality:
- [ ] Overview explains the core insight (not just what to do)
- [ ] Trigger conditions are specific (not vague)
- [ ] "When NOT to use" section exists with alternatives
- [ ] Every step has a named output/deliverable
- [ ] Verification checklist has only verifiable items
- [ ] Examples show real code/commands, not pseudocode

Self-containment:
- [ ] Skill can be understood without reading other files
- [ ] References to other skills name them explicitly
- [ ] All templates/formats needed are in the file
- [ ] No assumed context that isn't explained
```

### Step 8 — Update Documentation

After writing the skill, update the toolkit's documentation:

**README.md** — add to the Skills table in the correct category  
**CLAUDE.md** — update skill count  
**.github/copilot-instructions.md** — update skill count  
**templates/copilot-instructions.md** — update skill count

Skill categories:

- Development Lifecycle (explore, outline, develop, check, polish, launch)
- Engineering Discipline (tdd, diagnose, code-review, etc.)
- Architecture (api-design, database-schema, improve-codebase-architecture, etc.)
- Security & Quality
- Documentation & Communication
- DevOps & Deployment
- Domain-Specific

## Description Writing Rules

The description field appears in slash command menus. It must:

- Fit in ~120 characters
- Say what it does: "Six-phase debugging loop" not "A skill for debugging"
- Say when to use it: "Use when tests fail" not "Use for debugging"
- Not start with "A skill that..." or "This skill..."

**Formula:** `[Core action/output]. Use when [trigger condition].`

**Good:**

```
'Six-phase debugging loop: build feedback loop → reproduce → hypothesise → instrument → fix → cleanup. Use when tests fail or a bug is reported.'
```

**Bad:**

```
'This skill helps you debug issues in your codebase.'
```

## Verification

The skill is ready when:

- [ ] SKILL.md passes the full review checklist (Step 7)
- [ ] Someone unfamiliar with the topic could follow the steps independently
- [ ] The trigger and done conditions are unambiguous
- [ ] Documentation updated with new skill
