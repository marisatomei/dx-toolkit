# 🤖 DX Toolkit

> The Swiss army knife for developer experience — AI-powered agents, workflows, prompts, instructions, skills, hooks, and templates you copy into any repository.

[![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?logo=github-actions&logoColor=white)](https://github.com/features/actions)
[![GitHub Copilot](https://img.shields.io/badge/GitHub%20Copilot-000?logo=github-copilot&logoColor=white)](https://github.com/features/copilot)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## What's Inside

| Component                                | Count | What it does                                                  |
| ---------------------------------------- | ----- | ------------------------------------------------------------- |
| [**Agents**](docs/agents.md)             | 52+   | Specialized Copilot coding agents — assign to issues, get PRs |
| [**Prompts**](docs/prompts.md)           | 34+   | One-shot task templates via the `/` slash menu                |
| [**Instructions**](docs/instructions.md) | 26+   | Auto-attached rules per file type + context modes             |
| [**Skills**](docs/skills.md)             | 48+   | Multi-step structured workflows organized by domain           |
| [**Workflows**](docs/workflows.md)       | 27    | AI-powered GitHub Actions (review, triage, security, docs)    |
| [**Hooks**](docs/hooks.md)               | 10    | Quality gates — format, guard, scan, lint, track, protect     |
| [**References**](docs/skills.md)         | 10    | Checklists for testing, security, performance, mobile, APIs   |
| [**Templates**](docs/templates.md)       | 3     | Structured issue forms + PR template                          |
| [**Tooling**](docs/tooling.md)           | —     | Prettier, VS Code config, 7 MCP servers, DevContainer         |
| [**Examples**](examples/)                | 4     | Real-world copilot-instructions.md for popular stacks         |

---

## Quick Start

```bash
# Clone
git clone https://github.com/dreamingechoes/dx-toolkit.git

# Copy to your project (all components)
TARGET=~/Code/my-project
cp -r templates/agents/ "$TARGET/.github/agents/"
cp -r templates/skills/ "$TARGET/.github/skills/"
cp -r templates/prompts/ "$TARGET/.github/prompts/"
cp -r templates/instructions/ "$TARGET/.github/instructions/"
cp -r templates/hooks/ "$TARGET/.github/hooks/"
cp -r templates/ISSUE_TEMPLATE/ "$TARGET/.github/ISSUE_TEMPLATE/"
cp templates/PULL_REQUEST_TEMPLATE.md "$TARGET/.github/"
cp templates/copilot-instructions.md "$TARGET/.github/"
cp templates/workflows/*.yml "$TARGET/.github/workflows/"
chmod +x "$TARGET/.github/hooks/scripts/"*.sh
```

**Local bootstrap** (interactive — no GitHub API needed):

```bash
./scripts/bootstrap.sh ~/Code/my-project
```

**Windows bootstrap** (PowerShell):

```powershell
.\scripts\bootstrap.ps1 C:\Code\my-project
```

---

## Development Lifecycle

Skills and prompts follow a six-phase development lifecycle:

```
  EXPLORE  ──→  OUTLINE  ──→  DEVELOP  ──→  CHECK  ──→  POLISH  ──→  LAUNCH
  /explore      /outline      /develop      /check      /polish      /launch
```

| Phase       | Command    | What Happens                                                            |
| ----------- | ---------- | ----------------------------------------------------------------------- |
| **EXPLORE** | `/explore` | Explore a vague idea, refine it into a spec with requirements and scope |
| **OUTLINE** | `/outline` | Outline the spec into small, ordered, verifiable tasks                  |
| **DEVELOP** | `/develop` | Develop the next task in a thin vertical slice with tests               |
| **CHECK**   | `/check`   | Reproduce, localize, fix, and guard against regressions                 |
| **POLISH**  | `/polish`  | Review code for correctness, simplicity, security, and performance      |
| **LAUNCH**  | `/launch`  | Clean commits, update docs, run pre-launch checklist, deploy            |

Each command activates the relevant skills automatically. Use them individually or chain them: `/explore` → `/outline` → `/develop` → `/check` → `/polish` → `/launch`.

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    YOUR EDITOR                                          │
│                                                                         │
│  Agents ──── Assign to issues → get PRs automatically                   │
│  Prompts ─── /explore, /outline, /develop, /check, /polish, /launch     │
│  Skills ──── 47+ structured workflows by lifecycle phase                │
│  Instructions ── Auto-rules + context modes for .ts, .ex, .py, .go, .rs │
│  Hooks ───── Quality gates — format, guard, scan, protect               │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                     DEVELOPER TOOLING                                   │
│                                                                         │
│  VS Code ──── Settings, extensions, format-on-save                      │
│  MCP ──────── GitHub, Fetch, Filesystem, Memory, Thinking, Context7     │
│  Prettier ─── Format MD, YML, JSON — npm run format                     │
│  DevContainer  Ready-to-use Codespaces / container env                  │
│                                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│                  YOUR REPOSITORY (GitHub)                               │
│                                                                         │
│  Workflows ── PR review, labeling, security scanning                    │
│  Templates ── Structured issue forms, PR checklist                      │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

**Agents** handle autonomous issue-to-PR workflows. **Prompts** are quick single-task actions. **Instructions** silently shape every suggestion Copilot makes. **Skills** guide multi-step procedures. **Hooks** run scripts on tool calls. **Workflows** automate CI/CD and triage. **Templates** standardize issues and PRs.

---

## Agents (52+)

**9 General-Purpose**: bug-fixer, feature-implementer, refactorer, test-writer, docs-updater, docs-humanizer, security-fixer, performance-optimizer, dependency-updater

**38+ Technology-Specialized**: elixir-expert, phoenix-expert, typescript-expert, nextjs-expert, postgresql-expert, supabase-expert, docker-expert, wordpress-expert, design-systems-expert, frontend-expert, backend-expert, conventional-commits-expert, web-development-expert, react-expert, react-native-expert, expo-expert, tdd-expert, bdd-expert, payments-expert, python-expert, go-expert, rust-expert, swift-expert, kotlin-expert, flutter-expert, rails-expert, vue-expert, angular-expert, svelte-expert, graphql-expert, terraform-expert, csharp-expert, aspnetcore-expert, blazor-expert, deepstream-expert, deepstream-plugin-expert, deepstream-inference-expert, tao-toolkit-expert

**2 Content-Specialized**: seo-writer, marketing-expert

→ [Full agent guide with usage examples](docs/agents.md)

## Prompts (34+)

**Lifecycle commands**: `/explore` · `/outline` · `/develop` · `/check` · `/polish` · `/launch`

**Task prompts**: `/scaffold-component` · `/write-tests` · `/explain-code` · `/refactor-function` · `/create-api-endpoint` · `/write-migration` · `/create-dockerfile` · `/review-security` · `/generate-types` · `/debug-error` · `/optimize-query` · `/commit-message` · `/refine-issue` · `/setup-monorepo` · `/write-adr` · `/create-workflow` · `/analyze-deps` · `/create-api-client` · `/document-api` · `/setup-ci` · `/create-test-fixtures` · `/review-accessibility` · `/setup-logging`

**DeepStream prompts**: `/deepstream-video-infer` · `/deepstream-multi-stream-tracker` · `/deepstream-video-object-count` · `/deepstream-yolo-detection` · `/deepstream-rtvi-vlm-app` · `/deepstream-rtvi-vlm-microservice` · `/deepstream-nvdsanalytics`

→ [Full prompt guide with examples](docs/prompts.md)

## Instructions (25+)

**Auto-attached**: Elixir · TypeScript · React · CSS · Docker · Testing · Migrations · Writing Style · Python · Ruby · Go · Rust · Swift · Kotlin · Vue · GraphQL · C#

**Context modes**: Development · Review · Research · Debugging

**On-demand**: API Design · Accessibility · Git Workflow

→ [Full instructions guide](docs/instructions.md)

## Skills (48+)

| Category                          | Skills                                                                                                                                                                                                  |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Product & Discovery**           | idea-refine · spec-driven-development · codebase-onboarding · grill-me · grill-with-docs · to-prd                                                                                                       |
| **Planning & Design**             | planning-and-task-breakdown · issue-to-plan · to-issues · api-design · database-schema · architecture-review                                                                                            |
| **Engineering Discipline**        | tdd · diagnose · zoom-out · improve-codebase-architecture · github-triage                                                                                                                               |
| **Development**                   | incremental-implementation · context-engineering · debugging-and-error-recovery · token-optimization · caveman                                                                                          |
| **Code Quality**                  | code-review · code-simplification · performance-optimization · security-audit · refactoring-catalog · accessibility-audit                                                                               |
| **Testing & Quality**             | testing-strategy · dependency-audit                                                                                                                                                                     |
| **Documentation & Communication** | documentation-and-adrs · pr-description · humanize-writing · write-a-skill                                                                                                                              |
| **DevOps & Delivery**             | git-workflow-and-versioning · ci-cd-and-automation · deployment-checklist · shipping-and-launch · feature-flag-management · infrastructure-as-code · error-monitoring-setup · logging-and-observability |
| **Mobile**                        | mobile-release · mobile-testing                                                                                                                                                                         |
| **Architecture**                  | monorepo-setup · architecture-review                                                                                                                                                                    |
| **Project Management**            | estimation-and-sizing · incident-response                                                                                                                                                               |
| **AI / Video Analytics**          | deepstream-dev · deepstream-pipeline · deepstream-plugin                                                                                                                                                |

→ [Full skills guide](docs/skills.md) · [Skill anatomy](docs/skill-anatomy.md)

## Workflows (27)

| Category         | Workflows                                                                                                                                                                             |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Issue & PR**   | Smart Labeler · Issue Quality Enhancer · Duplicate Detector · First Contributor Welcome · Stale Issue Manager · Auto Assign Reviewers · PR Size Checker · Conventional Commit Checker |
| **Planning**     | Issue Effort Estimator · Project Timeline Generator                                                                                                                                   |
| **Code Quality** | PR Code Reviewer · Continuous Docs · Code Coverage Report · License Compliance · Todo Tracker                                                                                         |
| **Security**     | Security Scanner · Container Image Scanner                                                                                                                                            |
| **Maintenance**  | Release Notes Generator · Auto Changelog · Dependency Update Checker · Branch Cleanup · Broken Link Checker                                                                           |
| **Monorepo**     | Monorepo Change Detector                                                                                                                                                              |
| **Docs**         | API Docs Generator · Wiki Docs Sync                                                                                                                                                   |
| **Tooling**      | Copilot Suggester · Label Beautifier                                                                                                                                                  |

→ [Full workflow guide](docs/workflows.md)

---

## Documentation

| Guide                                      | Description                                                    |
| ------------------------------------------ | -------------------------------------------------------------- |
| [Getting Started](docs/getting-started.md) | Prerequisites, quickstart, what happens automatically          |
| [Agents](docs/agents.md)                   | All 52+ agents with purpose, workflow, and usage examples      |
| [Prompts](docs/prompts.md)                 | All 27+ prompts with inputs, outputs, and examples             |
| [Instructions](docs/instructions.md)       | All 25+ instructions — auto-attached, context modes, on-demand |
| [Skills](docs/skills.md)                   | All 48+ skills organized by domain                             |
| [Skill Anatomy](docs/skill-anatomy.md)     | How to write and structure skills                              |
| [Workflows](docs/workflows.md)             | All 27 workflows with triggers, inputs, and setup              |
| [Hooks](docs/hooks.md)                     | 10 hooks — formatting, guards, scanning, tracking, protection  |
| [Templates](docs/templates.md)             | Issue forms and PR template customization                      |
| [Installation](docs/installation.md)       | Automated installer, manual copy, git subtree                  |
| [Customization](docs/customization.md)     | Create your own agents, prompts, instructions, skills, hooks   |
| [Architecture](docs/architecture.md)       | Component hierarchy, lifecycle model, data flow                |
| [Monorepo Guide](docs/monorepo-guide.md)   | Strategies for monorepo setups with scoped agents              |
| [Mobile Guide](docs/mobile-guide.md)       | React Native, Expo, Flutter, Swift, Kotlin workflows           |
| [FAQ](docs/faq.md)                         | Common questions answered                                      |
| [Troubleshooting](docs/troubleshooting.md) | Symptom → cause → fix for common issues                        |
| [Recipes](docs/recipes/README.md)          | Step-by-step guides for common setups                          |
| [Changelog](docs/changelog.md)             | Version history and breaking changes                           |
| [Editor & Tooling](docs/tooling.md)        | Prettier, VS Code, MCP servers, DevContainer, EditorConfig     |

### Multi-Tool Setup

| Guide                                    | Description                                    |
| ---------------------------------------- | ---------------------------------------------- |
| [Copilot Setup](docs/copilot-setup.md)   | GitHub Copilot in VS Code — native integration |
| [Claude Setup](docs/claude-setup.md)     | Claude Code — uses CLAUDE.md as entry point    |
| [Cursor Setup](docs/cursor-setup.md)     | Cursor — .cursorrules and @file references     |
| [Windsurf Setup](docs/windsurf-setup.md) | Windsurf — .windsurfrules and Cascade          |

---

## Project Structure

```
templates/
├── agents/                   45+ Copilot agents (.agent.md)
├── skills/                   34+ multi-step skills (SKILL.md)
├── prompts/                  27+ task prompts (.prompt.md)
├── instructions/             25+ coding rules (.instructions.md)
├── hooks/                    10 hook configs + scripts
├── references/               10 reference checklists
├── workflows/                27 standalone GitHub Actions
├── ISSUE_TEMPLATE/           Bug report + Feature request (YAML forms)
├── PULL_REQUEST_TEMPLATE.md
└── copilot-instructions.md
.github/
├── workflows/                CI for this repo (ci, pr-checks, link-checker, stale, welcome)
├── ISSUE_TEMPLATE/           Issue forms for this repo
├── PULL_REQUEST_TEMPLATE.md  PR template for this repo
├── copilot-instructions.md   Copilot config for this repo
└── labeler.yml               Path-based label rules
CLAUDE.md                     Entry point for Claude Code
AGENTS.md                     Agent directory for AI tools
scripts/                      Bootstrap installer script
docs/                         Comprehensive documentation + recipes
examples/                     Real-world copilot-instructions.md configs
.vscode/                      VS Code settings, extensions, MCP servers
.devcontainer/                Dev container (Codespaces-ready)
```

---

## CI & Repository Protection

This repository runs its own CI on every PR and push to `main`:

| Workflow            | Trigger               | What it checks                                                 |
| ------------------- | --------------------- | -------------------------------------------------------------- |
| **✅ CI**           | PR + push to main     | Prettier, YAML/JSON/bash syntax, frontmatter, file conventions |
| **🛡️ PR Checks**    | PR open/edit          | Conventional Commits title, size label, path-based labels      |
| **🔗 Link Checker** | Push to main + weekly | Broken internal and external links in markdown                 |
| **🧹 Stale**        | Daily                 | Marks inactive issues/PRs stale, closes after 7 more days      |
| **👋 Welcome**      | First issue/PR        | Greets first-time contributors                                 |

Recommended branch protection rules for `main`:

- Require PR reviews before merging
- Require status checks: `Format Check`, `Validate YAML`, `Validate JSON`, `Validate Shell Scripts`, `Validate Frontmatter`, `Validate File Structure`, `Conventional Commits Title`
- Require branches to be up to date
- Do not allow bypassing the above settings

---

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
