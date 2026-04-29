# 📚 Documentation

Welcome to the **dx-toolkit** documentation. This is your comprehensive guide to the DX toolkit.

## Quick Navigation

| Guide                                            | Description                                                       |
| ------------------------------------------------ | ----------------------------------------------------------------- |
| [Getting Started](getting-started.md)            | Installation, setup, and your first 5 minutes                     |
| [Agents](agents.md)                              | 45+ custom Copilot agents — general-purpose and tech-specialized  |
| [Prompts](prompts.md)                            | 27+ reusable task templates for common development tasks          |
| [Instructions](instructions.md)                  | 25+ file-type-specific coding standards                           |
| [Skills](skills.md)                              | 34+ multi-step workflow procedures                                |
| [Hooks](hooks.md)                                | 10 lifecycle hooks for automated formatting and file protection   |
| [Workflows](workflows.md)                        | 25 GitHub Actions workflows for repository automation             |
| [Templates](templates.md)                        | Issue and PR templates for consistent collaboration               |
| [Editor & Tooling](tooling.md)                   | VS Code config, MCP servers, Prettier, DevContainer, EditorConfig |
| [Installation](installation.md)                  | Detailed installation methods and customization                   |
| [Customization](customization.md)                | How to adapt the toolkit to your stack                            |
| [GitHub Copilot CLI Setup](copilot-cli-setup.md) | Using the toolkit with Copilot CLI (`copilot` terminal binary)    |

## What's in the Box

```
┌────────────────────────────────────────────────────────────────┐
│                        dx-toolkit                              │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│   Agents     │   Prompts    │ Instructions │     Skills        │
│  (45+ AI     │  (27+ task   │ (25+ coding  │ (34+ multi-step   │
│   personas)  │   templates) │  standards)  │   procedures)     │
├──────────────┼──────────────┼──────────────┼───────────────────┤
│    Hooks     │  Workflows   │  Templates   │   Copilot Config  │
│ (10 lifecycle│ (25 GitHub   │ (issue + PR  │  (repo-wide       │
│   automators)│  Actions)    │  templates)  │   instructions)   │
├──────────────┼──────────────┼──────────────┼───────────────────┤
│  VS Code     │  MCP Servers │  Prettier    │  DevContainer     │
│  (settings + │ (GitHub,     │ (format MD,  │  (ready-to-code   │
│   extensions)│  fetch, FS)  │  YML, JSON)  │   environment)    │
└──────────────┴──────────────┴──────────────┴───────────────────┘
```

## How It Works

The toolkit operates at **three levels**:

1. **Editor Level** — Agents, prompts, instructions, skills, and hooks work inside VS Code (and JetBrains, Copilot CLI) to enhance your coding with AI-powered assistance and automated quality checks.

2. **Repository Level** — Templates standardize how your team creates issues and PRs. The `copilot-instructions.md` file ensures Copilot knows your project conventions.

3. **CI/CD Level** — GitHub Actions workflows automate issue triage, code review, labeling, security scanning, and more — running on every push, PR, or schedule.

## Philosophy

- **Copy what you need** — every component is independent and optional
- **Convention over configuration** — sensible defaults, override when needed
- **AI-augmented, not AI-dependent** — the tools enhance your workflow, they don't replace your judgment
- **Latest best practices** — agents and instructions target the latest stable versions of each technology
