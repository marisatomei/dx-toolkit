# Repository-Wide Instructions for GitHub Copilot

## About This Repository

This is `dx-toolkit` — a comprehensive developer experience (DX) toolkit that centralizes AI-powered agents, skills, prompts, instructions, hooks, workflows, and templates for software development. It's designed to be the "Swiss army knife" you copy into any new or existing repository.

### Development Lifecycle

All skills and prompts are organized around a six-phase lifecycle:

```
EXPLORE → OUTLINE → DEVELOP → CHECK → POLISH → LAUNCH
```

| Phase   | Command    | What Happens                                        |
| ------- | ---------- | --------------------------------------------------- |
| EXPLORE | `/explore` | Explore ideas, write specs, onboard to codebase     |
| OUTLINE | `/outline` | Outline specs into ordered, verifiable tasks        |
| DEVELOP | `/develop` | Develop in thin vertical slices                     |
| CHECK   | `/check`   | Debug failures, write regression tests              |
| POLISH  | `/polish`  | Simplify code, optimize performance, audit security |
| LAUNCH  | `/launch`  | Version, document, deploy, monitor                  |

### Entry Points

- `CLAUDE.md` — Entry point for Claude Code (references lifecycle, conventions, structure)
- `AGENTS.md` — Agent directory with categories and usage examples
- `README.md` — Full repository documentation

## Code Conventions

- All workflow files use YAML with 2-space indentation
- Workflow names include an emoji prefix for visual identification
- Every workflow is standalone with appropriate event triggers (push, pull_request, schedule, etc.)
- Every job must have `timeout-minutes` and `concurrency` defined
- GitHub Copilot CLI is installed via `curl -fsSL https://gh.io/copilot-install | bash`
- The default AI model is `claude-sonnet-4`

## Agent Conventions

- Agent files live in `templates/agents/` and use the `.agent.md` extension
- Agent names use kebab-case matching their filename (e.g., `bug-fixer.agent.md` → `name: bug-fixer`)
- Every agent must have a clear `description` for discovery
- Agents use `tools: ["read", "edit", "search", "execute", "github/*"]` unless they specifically need fewer tools
- Agent prompts follow a Workflow → Constraints structure
- There are three categories of agents (52+ total):
  - **General-purpose** (9): bug-fixer, feature-implementer, refactorer, test-writer, docs-updater, docs-humanizer, security-fixer, performance-optimizer, dependency-updater
  - **Technology-specialized** (41+): elixir-expert, phoenix-expert, typescript-expert, nextjs-expert, postgresql-expert, supabase-expert, docker-expert, wordpress-expert, design-systems-expert, frontend-expert, backend-expert, conventional-commits-expert, web-development-expert, react-expert, react-native-expert, expo-expert, tdd-expert, bdd-expert, payments-expert, python-expert, go-expert, rust-expert, swift-expert, kotlin-expert, flutter-expert, rails-expert, vue-expert, angular-expert, svelte-expert, graphql-expert, terraform-expert, architecture-advisor, devops-expert, monorepo-expert, csharp-expert, aspnetcore-expert, blazor-expert, deepstream-expert, deepstream-plugin-expert, deepstream-inference-expert, tao-toolkit-expert
  - **Content-specialized** (2): seo-writer, marketing-expert

## Prompt Conventions

- Prompt files live in `templates/prompts/` and use the `.prompt.md` extension
- Two categories of prompts (27+ total):
  - **Lifecycle prompts** (6): explore, outline, develop, check, polish, launch — map to the six development phases
  - **Task prompts** (21+): focused single-task prompts for specific operations
- Include a `description` for discoverability via the `/` slash menu
- Use `agent: "agent"` to run in agent mode by default
- Specify `tools` only when the task needs specific tool access

## Instruction Conventions

- Instruction files live in `templates/instructions/` and use the `.instructions.md` extension
- Use `applyTo` globs for file-type-specific rules (e.g., `**/*.ts` for TypeScript)
- Use `description` (without `applyTo`) for on-demand, task-based instructions
- Context mode instructions (`context-*.instructions.md`) shift agent behavior for development, review, research, or debugging
- One concern per file — don't mix testing rules with API design rules
- Keep instructions concise and actionable — they share context window space

## Skill Conventions

- Skills live in `templates/skills/<skill-name>/SKILL.md` (47+ skills across 12 domain categories)
- Skill folder name must match the `name` field in frontmatter
- Skills include step-by-step procedures with templates
- Skills are self-contained — all necessary context is in the SKILL.md
- Required sections: Overview, When to Use, Process/Procedure
- Recommended sections: Common Rationalizations, Red Flags, Verification
- Full spec: `docs/skill-anatomy.md`

## Reference Conventions

- Reference checklists live in `templates/references/` (10 checklists)
- Available references: testing-patterns, security-checklist, performance-checklist, accessibility-checklist, mobile-checklist, api-patterns, error-handling-patterns, observability-checklist, monorepo-patterns, architecture-patterns
- Referenced by skills and prompts — not used standalone
- Keep checklists actionable with clear pass/fail criteria

## Hook Conventions

- Hook configs live in `templates/hooks/*.json` (10 hooks)
- Hook scripts live in `templates/hooks/scripts/`
- Available hooks: format-on-edit, guard-protected-files, commit-message-validator, secret-scanner, console-log-detector, todo-tracker, file-size-limiter, test-companion-reminder, config-protector, large-dependency-guard
- Keep hooks small, fast, and auditable
- Use `PreToolUse` for guards and validation, `PostToolUse` for analysis and formatting

## PR Guidelines

- PRs should reference the issue they resolve with `Closes #N`
- Keep PRs focused: one concern per PR
- All tests must pass before merging
- Documentation must be updated if behavior changes
- Use the PR template in `.github/PULL_REQUEST_TEMPLATE.md`
