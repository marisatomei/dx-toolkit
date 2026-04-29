# GitHub Copilot CLI Setup

How to use the DX Toolkit with [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli).

## Quick Start

1. Install Copilot CLI: `curl -fsSL https://gh.io/copilot-install | bash`
2. Copy the toolkit into your project (see [Installation](installation.md))
3. Run `copilot` from your project root — it reads `.copilot/copilot-instructions.md` automatically

## What Copilot CLI Uses

| File                                        | How Copilot CLI Uses It                                            |
| ------------------------------------------- | ------------------------------------------------------------------ |
| `.copilot/copilot-instructions.md`          | Auto-loaded as project context for every session                   |
| `~/.copilot/copilot-instructions.md`        | Global context loaded across all projects                          |
| `.copilot/skills/*/SKILL.md`                | Project skills — loaded when relevant or invoked via `/skill-name` |
| `~/.copilot/skills/*/SKILL.md`              | Personal skills — shared across all your projects                  |
| `.github/instructions/**/*.instructions.md` | Path-specific instructions (auto-attached by glob)                 |
| `AGENTS.md`                                 | Agent discovery and descriptions                                   |

> **Note:** Copilot CLI also reads `.github/copilot-instructions.md` for backward compatibility if `.copilot/copilot-instructions.md` is not present.

## Detecting Copilot CLI

Check if the binary is installed:

```bash
# Check if copilot CLI is available
if command -v copilot &>/dev/null; then
  echo "Copilot CLI is installed: $(copilot --version 2>/dev/null)"
else
  echo "Install with: curl -fsSL https://gh.io/copilot-install | bash"
fi
```

On Windows (PowerShell):

```powershell
if (Get-Command copilot -ErrorAction SilentlyContinue) {
    Write-Host "Copilot CLI is installed"
} else {
    Write-Host "Install from: https://gh.io/copilot-install"
}
```

## Lifecycle Slash Commands

The six lifecycle commands map directly to Copilot CLI skills:

| Command    | Phase   | What It Does                                      |
| ---------- | ------- | ------------------------------------------------- |
| `/explore` | EXPLORE | Explore ideas, write specs, understand codebase   |
| `/outline` | OUTLINE | Break a spec into ordered, verifiable tasks       |
| `/develop` | DEVELOP | Implement the next task with tests                |
| `/check`   | CHECK   | Debug a failing test or error                     |
| `/polish`  | POLISH  | Review code for correctness, simplicity, security |
| `/launch`  | LAUNCH  | Prepare commits, docs, and deploy                 |

These are installed as skills in `.copilot/skills/`. Invoke them directly:

```
/explore Design a notification system
/outline Convert the spec in context to implementation tasks
/develop Implement Task 1
/check Fix the failing test in auth.test.ts
/polish Review src/ for code quality issues
/launch Prepare this feature for release
```

## Skills Commands

Copilot CLI has built-in commands for managing skills:

```
# List all available skills
/skills list

# Get info about a specific skill (including its location)
/skills info code-review

# Enable/disable skills interactively
/skills

# Reload skills after adding new ones mid-session
/skills reload

# Add an alternate skills directory
/skills add ~/my-org-skills
```

## Project vs Personal Skills

**Project skills** live in your repository and apply to that project only:

```
.copilot/skills/
├── tdd/SKILL.md
├── code-review/SKILL.md
├── security-audit/SKILL.md
└── ...
```

**Personal skills** live in your home directory and are shared across all projects:

```
~/.copilot/skills/
├── tdd/SKILL.md
├── code-review/SKILL.md
└── ...
```

Use the bootstrap script to install to either location:

```bash
# Install skills to your project (.copilot/skills/)
./scripts/bootstrap.sh ~/Code/my-project

# When prompted "GitHub Copilot CLI (terminal)" and asked about personal skills,
# say yes to also install to ~/.copilot/skills/
```

## Custom Instructions

Set project-wide instructions in `.copilot/copilot-instructions.md`:

```markdown
## Build Commands

- `npm run build` - Build the project
- `npm run test` - Run all tests
- `npm run lint:fix` - Fix linting issues

## Workflow

- Always run `npm run lint:fix && npm test` after changes
- Follow the EXPLORE → OUTLINE → DEVELOP → CHECK → POLISH → LAUNCH lifecycle
- Skills are in .copilot/skills/ — use /skill-name to invoke them
```

Set global instructions (applied to every project) in `~/.copilot/copilot-instructions.md`:

```markdown
## Personal Conventions

- I prefer TypeScript over JavaScript
- Always write tests before implementation (TDD)
- Use conventional commits format
```

## Advanced: Plan Mode

For complex tasks, use `/plan` before implementing:

```
/plan Add OAuth2 authentication with Google and GitHub providers
```

Copilot analyzes your codebase, asks clarifying questions, creates a structured plan with checkboxes, and waits for your approval before writing any code. Toggle plan mode with `Shift+Tab`.

## Advanced: Delegate

For tasks you don't want to block on:

```
/delegate Add dark mode support to the settings page
```

The cloud agent creates a pull request while you keep working locally.

## Tips

- **Chain lifecycle commands**: run `/explore`, review the output, then `/outline`, then `/develop`
- **Model selection**: use `/model` to switch models mid-session — Opus 4.5 for complex tasks, Sonnet 4.5 for routine work
- **Multi-repo work**: run `copilot` from a parent directory to work across multiple repos, or use `/add-dir` to expand scope
- **Reference checklists**: mention `.copilot/references/security-checklist.md` in your prompt for targeted reviews
- **Session management**: use `/session` to view context usage, `/clear` to start fresh between unrelated tasks
