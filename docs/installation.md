# 📦 Installation

Three ways to install the toolkit — from fully automated to fully manual.

## Option 1: Bootstrap Script (Recommended)

An interactive script that copies selected components to any project — no GitHub API needed:

```bash
# Interactive — pick what to install
./scripts/bootstrap.sh ~/Code/my-project

# Install everything without prompts
./scripts/bootstrap.sh ~/Code/my-project --all

# Minimal — just agents + instructions
./scripts/bootstrap.sh ~/Code/my-project --minimal
```

### Interactive Flow

When you run the script without flags, it walks you through three choices:

**1. Architecture** — how your project is structured:

| Option        | What it configures                                               |
| ------------- | ---------------------------------------------------------------- |
| Monorepo      | Workspace config, change detection, per-package scoping          |
| Monolith      | Standard single-project layout                                   |
| Microservices | Service-level agents, Docker configs, inter-service instructions |
| Library       | Minimal setup focused on API design, testing, and publishing     |
| Generic       | Base components only — you pick the rest                         |

**2. Project Type** — your primary language/framework:

| Type               | Agents & Instructions Installed                                   |
| ------------------ | ----------------------------------------------------------------- |
| TypeScript/Node.js | typescript-expert, testing, TypeScript instructions               |
| Next.js            | nextjs-expert, react-expert, typescript-expert                    |
| React              | react-expert, typescript-expert, React + CSS instructions         |
| React Native/Expo  | react-native-expert, expo-expert, mobile-release/testing skills   |
| Vue/Nuxt           | vue-expert, typescript-expert, Vue instructions                   |
| Angular            | angular-expert, typescript-expert, Angular instructions           |
| Svelte/SvelteKit   | svelte-expert, typescript-expert, Svelte instructions             |
| Elixir/Phoenix     | elixir-expert, phoenix-expert, Elixir + migrations instructions   |
| Python/Django      | python-expert, backend-expert, Python instructions                |
| Python/FastAPI     | python-expert, backend-expert, api-design skill                   |
| Go                 | go-expert, backend-expert, Go instructions                        |
| Rust               | rust-expert, Rust instructions                                    |
| Swift/iOS          | swift-expert, mobile-release/testing skills, Swift instructions   |
| Kotlin/Android     | kotlin-expert, mobile-release/testing skills, Kotlin instructions |
| Flutter            | flutter-expert, mobile-release/testing skills                     |
| WordPress          | wordpress-expert, Docker + PHP instructions                       |
| Generic            | General-purpose agents only                                       |

**3. Extras** — optional add-ons:

| Extra          | What it adds                                                   |
| -------------- | -------------------------------------------------------------- |
| Observability  | logging-and-observability, error-monitoring-setup skills       |
| GraphQL        | graphql-expert agent, GraphQL instructions                     |
| Terraform/IaC  | terraform-expert agent, infrastructure-as-code skill           |
| Mobile Release | mobile-release, mobile-testing skills                          |
| Docker         | docker-expert agent, Docker instructions, Dockerfile templates |

### Example Session

```
$ ./scripts/bootstrap.sh ~/Code/my-saas-app

📦 DX Toolkit Bootstrap

? Architecture: Monolith
? Project type: Next.js
? Extras: Docker, Observability

✔ Copied 8 agents (nextjs-expert, react-expert, typescript-expert, ...)
✔ Copied 6 instructions (typescript, react, css, docker, ...)
✔ Copied 12 skills
✔ Copied 5 prompts
✔ Copied hooks + scripts
✔ Copied issue/PR templates

Done! Open your project in VS Code and type / in Copilot Chat.
```

---

## Option 2: Manual Copy

Clone the repo and copy what you need:

```bash
# Clone
git clone https://github.com/dreamingechoes/dx-toolkit.git
cd dx-toolkit

# Copy everything to your project
TARGET=~/Code/my-project

# Copilot primitives
cp -r templates/agents/ "$TARGET/.github/agents/"
cp -r templates/skills/ "$TARGET/.github/skills/"
cp -r templates/prompts/ "$TARGET/.github/prompts/"
cp -r templates/instructions/ "$TARGET/.github/instructions/"
cp -r templates/hooks/ "$TARGET/.github/hooks/"
cp templates/copilot-instructions.md "$TARGET/.github/"

# Templates
cp -r .github/ISSUE_TEMPLATE/ "$TARGET/.github/ISSUE_TEMPLATE/"
cp .github/PULL_REQUEST_TEMPLATE.md "$TARGET/.github/"

# Workflows
cp templates/workflows/*.yml "$TARGET/.github/workflows/"

# VS Code + MCP servers
cp -r .vscode/ "$TARGET/.vscode/"

# DevContainer
cp -r .devcontainer/ "$TARGET/.devcontainer/"

# Editor tooling
cp .editorconfig .prettierrc .prettierignore "$TARGET/"

# Make hook scripts executable
chmod +x "$TARGET/.github/hooks/scripts/"*.sh
```

### Copy Just What You Need

Pick individual components:

```bash
# Just the TypeScript/React instructions
cp .github/instructions/typescript.instructions.md "$TARGET/.github/instructions/"
cp .github/instructions/react.instructions.md "$TARGET/.github/instructions/"

# Just the code review skill
cp -r .github/skills/code-review/ "$TARGET/.github/skills/code-review/"

# Just the PR reviewer workflow
cp templates/workflows/pr-code-reviewer.yml "$TARGET/.github/workflows/"

# Just the VS Code settings and MCP servers
cp -r .vscode/ "$TARGET/.vscode/"
```

---

## Option 3: Git Subtree

Add this repo as a subtree to keep it synced:

```bash
# Add the subtree (first time)
git subtree add \
  --prefix=.github/dx-toolkit \
  https://github.com/dreamingechoes/dx-toolkit.git \
  main \
  --squash

# Pull updates later
git subtree pull \
  --prefix=.github/dx-toolkit \
  https://github.com/dreamingechoes/dx-toolkit.git \
  main \
  --squash
```

Then symlink or copy what you need from `.github/dx-toolkit/` into the right locations.

---

## Post-Installation Setup

### 1. Repository Secrets

For workflows that use GitHub Copilot CLI:

| Secret     | Required For     | How to Get                                             |
| ---------- | ---------------- | ------------------------------------------------------ |
| `GH_TOKEN` | All AI workflows | Settings → Developer Settings → Personal Access Tokens |

### 1b. Copilot CLI — Personal Skills (Optional)

If you use [GitHub Copilot CLI](copilot-cli-setup.md) (`copilot` binary), you can also install skills as personal skills shared across all your projects:

```bash
# Install skills to ~/.copilot/skills/ (personal, applies everywhere)
mkdir -p ~/.copilot/skills
cp -r .copilot/skills/* ~/.copilot/skills/

# Install global instructions
cp .copilot/copilot-instructions.md ~/.copilot/copilot-instructions.md
```

The bootstrap script offers this automatically when you select **GitHub Copilot CLI** as your editor.

### 2. Adapt copilot-instructions.md

The included `copilot-instructions.md` describes this toolkit. Replace or merge it with your project's instructions:

```bash
# Option A: Use as-is (if this is a new project)
# Nothing to do — it's already copied

# Option B: Merge with existing instructions
cat "$TARGET/.github/copilot-instructions.md" >> "$TARGET/.github/copilot-instructions-merged.md"
cat .github/copilot-instructions.md >> "$TARGET/.github/copilot-instructions-merged.md"
mv "$TARGET/.github/copilot-instructions-merged.md" "$TARGET/.github/copilot-instructions.md"
```

### 3. Remove Irrelevant Components

Not every project needs every agent or instruction. Remove files that don't apply:

```bash
# Example: Remove Elixir-specific files from a TypeScript-only project
rm "$TARGET/.github/agents/elixir-expert.agent.md"
rm "$TARGET/.github/agents/phoenix-expert.agent.md"
rm "$TARGET/.github/instructions/elixir.instructions.md"
rm "$TARGET/.github/instructions/migrations.instructions.md"
```

### 4. Hook Scripts

Ensure hook scripts are executable and their tools are installed:

```bash
# Make executable
chmod +x "$TARGET/.github/hooks/scripts/"*.sh

# Verify formatters (format-on-edit hook)
which prettier  # or npx prettier --version
which mix       # for Elixir projects
which ruff      # for Python projects
```

### 5. Test Workflows

After installing workflows, verify they work:

1. Create a test issue → should trigger Smart Labeler, Issue Quality Enhancer
2. Open a small PR → should trigger PR Code Reviewer, PR Size Checker
3. Check the Actions tab for successful runs

---

## Updating

### From Source

```bash
cd dx-toolkit
git pull origin main

# Re-copy updated files
cp -r .github/agents/ "$TARGET/.github/agents/"
# ... repeat for each component
```

### Subtree

```bash
git subtree pull \
  --prefix=.github/dx-toolkit \
  https://github.com/dreamingechoes/dx-toolkit.git \
  main \
  --squash
```

---

## Troubleshooting

| Problem                                  | Solution                                                       |
| ---------------------------------------- | -------------------------------------------------------------- |
| Workflows don't trigger                  | Check the workflow's `on:` triggers match your events          |
| "Resource not accessible by integration" | Ensure `GH_TOKEN` secret has `repo` and `workflow` permissions |
| Hook scripts don't run                   | Run `chmod +x .github/hooks/scripts/*.sh`                      |
| Instructions not applied                 | Verify the `applyTo` glob matches your file paths              |
| Agents not visible                       | Ensure `.agent.md` files are in `.github/agents/`              |
| Skills not in `/` menu                   | Ensure `SKILL.md` is in `.github/skills/<name>/SKILL.md`       |
