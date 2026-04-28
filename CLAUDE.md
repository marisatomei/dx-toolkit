# CLAUDE.md — DX Toolkit

This file provides context for AI agents working with this repository.

## What This Repository Is

DX Toolkit is a collection of AI-powered agents, skills, prompts, instructions, hooks, workflows, and templates for software development. You copy its `templates/` directory into any repository's config folder (`.github/`, `.claude/`, `.cursor/`, or `.windsurf/` depending on your editor) to get a complete developer experience setup.

This is NOT a runnable application. It's a toolkit — a library of configuration files.

## Development Lifecycle

Skills and prompts are organized around a six-phase development lifecycle:

```
EXPLORE → OUTLINE → DEVELOP → CHECK → POLISH → LAUNCH
```

| Phase   | Slash Command | Skills                                                                                                                                                 |
| ------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| EXPLORE | `/explore`    | idea-refine, spec-driven-development, codebase-onboarding, grill-me, grill-with-docs, zoom-out                                                        |
| OUTLINE | `/outline`    | planning-and-task-breakdown, issue-to-plan, to-prd, to-issues                                                                                         |
| DEVELOP | `/develop`    | incremental-implementation, context-engineering, api-design, database-schema, tdd                                                                     |
| CHECK   | `/check`      | debugging-and-error-recovery, testing-strategy, diagnose                                                                                               |
| POLISH  | `/polish`     | code-simplification, performance-optimization, code-review, security-audit, accessibility-audit, refactoring-catalog, improve-codebase-architecture   |
| LAUNCH  | `/launch`     | git-workflow-and-versioning, ci-cd-and-automation, documentation-and-adrs, shipping-and-launch, deployment-checklist, pr-description, humanize-writing |

## Repository Structure

```
templates/
├── agents/           52+ Copilot coding agents (.agent.md)
├── skills/           47+ multi-step skills (SKILL.md)
├── prompts/          27+ task prompts (.prompt.md)
├── instructions/     26+ coding rules (.instructions.md)
├── hooks/            10 hook configs + scripts
├── workflows/        25 standalone GitHub Actions
├── references/       10 reference checklists
├── ISSUE_TEMPLATE/   Bug report + Feature request forms
├── PULL_REQUEST_TEMPLATE.md
└── copilot-instructions.md
.github/
├── workflows/        CI for this repo
├── copilot-instructions.md
└── labeler.yml
scripts/              Bootstrap installer (interactive + Windows PS1)
docs/                 Comprehensive documentation + recipes
examples/             Real-world copilot-instructions.md configs
```

## File Conventions

- **Agents**: `templates/agents/<name>.agent.md` — kebab-case, has `description` frontmatter
- **Skills**: `templates/skills/<name>/SKILL.md` — folder name matches `name` frontmatter
- **Prompts**: `templates/prompts/<name>.prompt.md` — has `description` frontmatter
- **Instructions**: `templates/instructions/<name>.instructions.md` — `applyTo` for auto-attach or `description` for on-demand
- **References**: `templates/references/<name>.md` — standalone checklists referenced by skills and prompts
- **Workflows**: `templates/workflows/<name>.yml` — self-contained GitHub Actions, YAML 2-space indent

## Writing Style

- Active voice, direct tone
- "You/we" not "one/the user"
- Specific over vague: "responds in <100ms" not "fast"
- Cut filler: "In order to" → "To"
- No AI phrases: avoid "leverage", "utilize", "it's important to note"

## When Editing This Repo

- One concern per file — don't combine testing instructions with API design
- Skills must be self-contained — all context in a single SKILL.md
- Prompts handle a single task — chain skills for multi-step workflows
- Always include `description` frontmatter for discoverability
- Test workflow changes locally with `act` before committing
