# Repository-Wide Instructions for GitHub Copilot

## About This Repository

<!-- TODO: Replace this placeholder with a description of your project.
     Describe what it does, its architecture, and key technologies. -->

This is `{{PROJECT_NAME}}`.

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

## Code Conventions

<!-- TODO: Add your project's code conventions. Examples:
     - Language and framework version requirements
     - Naming conventions (files, functions, variables)
     - File and folder organization rules
     - Testing requirements and patterns
     - Linting and formatting standards -->

## Agent Conventions

- Agent files live in `.github/agents/` and use the `.agent.md` extension
- Agent names use kebab-case matching their filename (e.g., `bug-fixer.agent.md` → `name: bug-fixer`)
- Every agent must have a clear `description` for discovery
- Agents use `tools: ["read", "edit", "search", "execute", "github/*"]` unless they specifically need fewer tools
- Agent prompts follow a Workflow → Constraints structure
- There are three categories of agents:
  - **General-purpose**: bug-fixer, feature-implementer, refactorer, test-writer, docs-updater, docs-humanizer, security-fixer, performance-optimizer, dependency-updater
  - **Technology-specialized**: domain-specific experts for various tech stacks including C# (csharp-expert, aspnetcore-expert, blazor-expert) and NVIDIA DeepStream (deepstream-expert, deepstream-plugin-expert, deepstream-inference-expert, tao-toolkit-expert)
  - **Content-specialized**: seo-writer, marketing-expert

## Prompt Conventions

- Prompt files live in `.github/prompts/` and use the `.prompt.md` extension
- Two categories of prompts:
  - **Lifecycle prompts**: explore, outline, develop, check, polish, launch — map to the six development phases
  - **Task prompts**: focused single-task prompts for specific operations
- Include a `description` for discoverability via the `/` slash menu
- Use `agent: "agent"` to run in agent mode by default
- Specify `tools` only when the task needs specific tool access

## Instruction Conventions

- Instruction files live in `.github/instructions/` and use the `.instructions.md` extension
- Use `applyTo` globs for file-type-specific rules (e.g., `**/*.ts` for TypeScript)
- Use `description` (without `applyTo`) for on-demand, task-based instructions
- Context mode instructions (`context-*.instructions.md`) shift agent behavior for development, review, research, or debugging
- One concern per file — don't mix testing rules with API design rules
- Keep instructions concise and actionable — they share context window space

## Skill Conventions

- Skills live in `.github/skills/<skill-name>/SKILL.md`
- Skill folder name must match the `name` field in frontmatter
- Skills include step-by-step procedures with templates
- Skills are self-contained — all necessary context is in the SKILL.md
- Required sections: Overview, When to Use, Process/Procedure
- Recommended sections: Common Rationalizations, Red Flags, Verification

## Reference Conventions

- Reference checklists live in `.github/references/`
- Available references: testing-patterns, security-checklist, performance-checklist, accessibility-checklist, mobile-checklist, api-patterns, error-handling-patterns, observability-checklist, monorepo-patterns, architecture-patterns
- Referenced by skills and prompts — not used standalone
- Keep checklists actionable with clear pass/fail criteria

## Hook Conventions

- Hook configs live in `.github/hooks/*.json`
- Hook scripts live in `.github/hooks/scripts/`
- Available hooks: format-on-edit, guard-protected-files, commit-message-validator, secret-scanner, console-log-detector, todo-tracker, file-size-limiter, test-companion-reminder, config-protector, large-dependency-guard
- Keep hooks small, fast, and auditable
- Use `PreToolUse` for guards and validation, `PostToolUse` for analysis and formatting

## PR Guidelines

- PRs should reference the issue they resolve with `Closes #N`
- Keep PRs focused: one concern per PR
- All tests must pass before merging
- Documentation must be updated if behavior changes
- Use the PR template in `.github/PULL_REQUEST_TEMPLATE.md`
