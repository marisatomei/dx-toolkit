#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# bootstrap.sh — Smart installer for dx-toolkit
# ──────────────────────────────────────────────────────────────
# Detects your editor, project type, and installs only the
# agents, skills, instructions, and prompts that apply.
#
# Usage:
#   ./scripts/bootstrap.sh ~/Code/my-project        # interactive
#   ./scripts/bootstrap.sh ~/Code/my-project --all   # install everything
# ──────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Resolve source directory ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Helpers ──
info()    { echo -e "${BLUE}ℹ${NC}  $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "${RED}✗${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}${CYAN}── $* ──${NC}"; }

ask_yn() {
  local prompt="$1" default="${2:-y}"
  local yn
  if [[ "$default" == "y" ]]; then
    read -rp "$(echo -e "${BOLD}$prompt${NC} [Y/n] ")" yn
    yn="${yn:-y}"
  else
    read -rp "$(echo -e "${BOLD}$prompt${NC} [y/N] ")" yn
    yn="${yn:-n}"
  fi
  [[ "$yn" =~ ^[Yy] ]]
}

ask_text() {
  local prompt="$1" default="$2"
  local input
  read -rp "$(echo -e "${BOLD}$prompt${NC} [${DIM}$default${NC}] ")" input
  echo "${input:-$default}"
}

ask_choice() {
  local prompt="$1"
  shift
  local options=("$@")
  local i

  echo -e "\n${BOLD}$prompt${NC}" >&2
  for i in "${!options[@]}"; do
    echo -e "  ${CYAN}$((i + 1))${NC}) ${options[$i]}" >&2
  done

  local choice
  while true; do
    read -rp "$(echo -e "${BOLD}Pick a number [1-${#options[@]}]:${NC} ")" choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
      echo "$((choice - 1))"
      return
    fi
    warn "Enter a number between 1 and ${#options[@]}" >&2
  done
}

ask_multi() {
  local prompt="$1"
  shift
  local options=("$@")
  local i

  echo -e "\n${BOLD}$prompt${NC} ${DIM}(comma-separated, e.g. 1,3,5 — or press Enter to skip)${NC}" >&2
  for i in "${!options[@]}"; do
    echo -e "  ${CYAN}$((i + 1))${NC}) ${options[$i]}" >&2
  done

  local input
  read -rp "$(echo -e "${BOLD}Your choices:${NC} ")" input

  if [[ -z "$input" ]]; then
    echo ""
    return
  fi

  local result=()
  IFS=',' read -ra picks <<< "$input"
  for pick in "${picks[@]}"; do
    pick="$(echo "$pick" | tr -d ' ')"
    if [[ "$pick" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#options[@]} )); then
      result+=("$((pick - 1))")
    fi
  done

  if [[ ${#result[@]} -gt 0 ]]; then
    echo "${result[*]}"
  else
    echo ""
  fi
}

copy_dir() {
  local src="$1" dest="$2" label="$3"
  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    if command -v rsync &>/dev/null; then
      rsync -a "$src/" "$dest/"
    else
      cp -R "$src/." "$dest/"
    fi
    local count
    count=$(find "$src" -type f | wc -l | tr -d ' ')
    success "$label ($count files)"
  else
    warn "Not found: $src"
  fi
}

copy_one() {
  local src="$1" dest="$2" label="${3:-}"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    [[ -n "$label" ]] && success "$label"
    return 0
  fi
  return 1
}

copy_template() {
  local src="$1" dest="$2" label="${3:-}"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    sed -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
        -e "s|{{CONFIG_DIR}}|${CONFIG_DIR}|g" \
        "$src" > "$dest"
    [[ -n "$label" ]] && success "$label"
    return 0
  fi
  return 1
}

copy_agent() {
  local name="$1"
  copy_one "$SOURCE_DIR/templates/agents/${name}.agent.md" \
           "$TARGET/$CONFIG_DIR/agents/${name}.agent.md" 2>/dev/null || true
}

copy_instruction() {
  local name="$1"
  copy_one "$SOURCE_DIR/templates/instructions/${name}.instructions.md" \
           "$TARGET/$CONFIG_DIR/instructions/${name}.instructions.md" 2>/dev/null || true
}

# ── Parse arguments ──
TARGET=""
MODE="interactive"

for arg in "$@"; do
  case "$arg" in
    --all)      MODE="all" ;;
    --help|-h)
      cat <<'EOF'
Usage: bootstrap.sh <target-directory> [--all]

Interactive mode asks about your editor, project type, and tech stack
to install only the relevant components.

Options:
  --all   Install everything without prompting
  --help  Show this help

Components:
  Agents (52+)      Specialized AI coding agents
  Skills (48+)      Multi-step structured workflows
  Prompts (27+)     One-shot task templates
  Instructions (26+) Auto-attached coding rules
  Hooks (10)        Commit validation, secret scanning, auto-format, guard files
  References (10)   Testing, security, performance, accessibility, mobile, API, error handling, observability, monorepo, architecture checklists
  Templates (3)     Issue forms + PR template
  Workflows (27)    CI/CD GitHub Actions
EOF
      exit 0
      ;;
    -*)
      error "Unknown option: $arg"
      exit 1
      ;;
    *)
      TARGET="$arg"
      ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  echo -e "${BOLD}Usage:${NC} bootstrap.sh <target-directory> [--all]"
  echo ""
  echo "Example: ./scripts/bootstrap.sh ~/Code/my-project"
  exit 1
fi

TARGET="${TARGET/#\~/$HOME}"
if [[ -d "$TARGET" ]]; then
  TARGET="$(cd "$TARGET" && pwd)"
else
  TARGET="$(cd "$(dirname "$TARGET")" 2>/dev/null && pwd)/$(basename "$TARGET")" || TARGET="$TARGET"
fi

if [[ "$TARGET" == "$SOURCE_DIR" ]]; then
  error "Target cannot be the dx-toolkit itself"
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  if ask_yn "Directory $TARGET does not exist. Create it?"; then
    mkdir -p "$TARGET"
  else
    exit 1
  fi
fi

# ──────────────────────────────────────────────────────────────
# --all mode: install everything and exit
# ──────────────────────────────────────────────────────────────

if [[ "$MODE" == "all" ]]; then
  echo ""
  echo -e "${BOLD}${CYAN}🤖 DX Toolkit — Installing Everything${NC}"
  echo -e "Target: ${BLUE}$TARGET${NC}"
  echo ""

  # --all always uses .github/ as config dir
  CONFIG_DIR=".github"
  PROJECT_NAME="$(basename "$TARGET")"

  header "Agents"
  copy_dir "$SOURCE_DIR/templates/agents" "$TARGET/$CONFIG_DIR/agents" "All agents"

  header "Skills"
  copy_dir "$SOURCE_DIR/templates/skills" "$TARGET/$CONFIG_DIR/skills" "All skills"

  header "Prompts"
  copy_dir "$SOURCE_DIR/templates/prompts" "$TARGET/$CONFIG_DIR/prompts" "All prompts"

  header "Instructions"
  copy_dir "$SOURCE_DIR/templates/instructions" "$TARGET/$CONFIG_DIR/instructions" "All instructions"
  copy_template "$SOURCE_DIR/templates/copilot-instructions.md" "$TARGET/$CONFIG_DIR/copilot-instructions.md" "copilot-instructions.md"

  header "Hooks"
  copy_dir "$SOURCE_DIR/templates/hooks" "$TARGET/$CONFIG_DIR/hooks" "Hooks"
  chmod +x "$TARGET/$CONFIG_DIR/hooks/scripts/"*.sh 2>/dev/null || true

  header "References"
  copy_dir "$SOURCE_DIR/templates/references" "$TARGET/$CONFIG_DIR/references" "Reference checklists"

  header "Templates"
  copy_dir "$SOURCE_DIR/templates/ISSUE_TEMPLATE" "$TARGET/.github/ISSUE_TEMPLATE" "Issue templates"
  copy_one "$SOURCE_DIR/templates/PULL_REQUEST_TEMPLATE.md" "$TARGET/.github/PULL_REQUEST_TEMPLATE.md" "PR template"

  header "Workflows"
  mkdir -p "$TARGET/.github/workflows"
  for wf in "$SOURCE_DIR"/templates/workflows/*.yml; do
    [[ -f "$wf" ]] || continue
    cp "$wf" "$TARGET/.github/workflows/$(basename "$wf")"
  done
  success "Workflows"

  header "Entry Points"
  copy_template "$SOURCE_DIR/templates/CLAUDE.md" "$TARGET/CLAUDE.md" "CLAUDE.md"
  copy_template "$SOURCE_DIR/templates/AGENTS.md" "$TARGET/AGENTS.md" "AGENTS.md"

  echo ""
  echo -e "${BOLD}${GREEN}Done! All components installed to ${BLUE}$TARGET${NC}"
  echo ""
  warn "Review and customize these files with your project's details:"
  echo -e "  ${DIM}• ${TARGET}/$CONFIG_DIR/copilot-instructions.md  — replace TODO sections with your project info${NC}"
  echo -e "  ${DIM}• ${TARGET}/CLAUDE.md                           — add project description and structure${NC}"
  echo -e "  ${DIM}• ${TARGET}/AGENTS.md                           — already configured (verify agent list)${NC}"
  echo ""
  exit 0
fi

# ──────────────────────────────────────────────────────────────
# Interactive mode — smart setup
# ──────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}🤖 DX Toolkit — Smart Setup${NC}"
echo -e "${DIM}A few questions to install only what your project needs.${NC}"

# ─── Step 0: Project Name ────────────────────────────────────

DEFAULT_PROJECT_NAME="$(basename "$TARGET")"
echo ""
PROJECT_NAME=$(ask_text "What's your project name?" "$DEFAULT_PROJECT_NAME")

# ─── Step 1: Editor / AI Tool ────────────────────────────────

EDITOR_CHOICES=(
  "GitHub Copilot (VS Code)"
  "Claude Code (terminal)"
  "Cursor"
  "Windsurf"
  "Multiple / All of them"
)
editor_idx=$(ask_choice "Which AI coding tool do you use?" "${EDITOR_CHOICES[@]}")

INSTALL_COPILOT=false
INSTALL_CLAUDE=false
INSTALL_CURSOR=false
INSTALL_WINDSURF=false

case "$editor_idx" in
  0) INSTALL_COPILOT=true ;;
  1) INSTALL_CLAUDE=true ;;
  2) INSTALL_CURSOR=true ;;
  3) INSTALL_WINDSURF=true ;;
  4) INSTALL_COPILOT=true; INSTALL_CLAUDE=true; INSTALL_CURSOR=true; INSTALL_WINDSURF=true ;;
esac

# Determine config directory based on primary editor choice
CONFIG_DIR=".github"
case "$editor_idx" in
  1) CONFIG_DIR=".claude" ;;
  2) CONFIG_DIR=".cursor" ;;
  3) CONFIG_DIR=".windsurf" ;;
esac

# ─── Step 2: Project Type ────────────────────────────────────

PROJECT_CHOICES=(
  "Elixir / Phoenix"
  "Ruby on Rails"
  "TypeScript / Node.js (backend)"
  "Next.js (fullstack)"
  "React (frontend SPA)"
  "React Native / Expo"
  "Python (Django / FastAPI / Flask)"
  "WordPress"
  "Go"
  "Rust"
  "Swift / iOS"
  "Kotlin / Android"
  "Flutter"
  "Vue / Nuxt"
  "Angular"
  "Svelte / SvelteKit"
  "C# / ASP.NET Core (backend API)"
  "Blazor (frontend / fullstack)"
  "C# Full-stack (ASP.NET Core + Blazor)"
  "Full-stack (multiple technologies)"
  "Other / Generic"
  "NVIDIA DeepStream (video analytics)"
)
project_idx=$(ask_choice "What type of project are you building?" "${PROJECT_CHOICES[@]}")

# ─── Step 3: Extras ──────────────────────────────────────────

EXTRA_CHOICES=(
  "Docker / Containers"
  "PostgreSQL"
  "Supabase"
  "GraphQL"
  "Terraform / IaC"
  "Observability"
  "CI/CD Workflows (GitHub Actions)"
  "GitHub Templates (issues, PRs)"
  "Editor Tooling (Prettier, EditorConfig)"
)
extra_picks=$(ask_multi "Any extras?" "${EXTRA_CHOICES[@]}")

INSTALL_DOCKER=false
INSTALL_POSTGRES=false
INSTALL_SUPABASE=false
INSTALL_GRAPHQL=false
INSTALL_TERRAFORM=false
INSTALL_OBSERVABILITY=false
INSTALL_WORKFLOWS=false
INSTALL_TEMPLATES=false
INSTALL_TOOLING=false

for pick in $extra_picks; do
  case "$pick" in
    0) INSTALL_DOCKER=true ;;
    1) INSTALL_POSTGRES=true ;;
    2) INSTALL_SUPABASE=true ;;
    3) INSTALL_GRAPHQL=true ;;
    4) INSTALL_TERRAFORM=true ;;
    5) INSTALL_OBSERVABILITY=true ;;
    6) INSTALL_WORKFLOWS=true ;;
    7) INSTALL_TEMPLATES=true ;;
    8) INSTALL_TOOLING=true ;;
  esac
done

# ──────────────────────────────────────────────────────────────
# Build installation plan based on choices
# ──────────────────────────────────────────────────────────────

# General-purpose agents — always installed
AGENTS_CORE=(
  bug-fixer feature-implementer refactorer test-writer
  docs-updater docs-humanizer security-fixer
  performance-optimizer dependency-updater
)

# Tech-specific agents — based on project type
AGENTS_TECH=()

# Universal instructions — always installed
INSTR_CORE=(writing-style git-workflow accessibility api-design testing migrations)

# Tech-specific instructions
INSTR_TECH=()

case "$project_idx" in
  0) # Elixir / Phoenix
    AGENTS_TECH+=(elixir-expert phoenix-expert backend-expert tdd-expert bdd-expert conventional-commits-expert)
    INSTR_TECH+=(elixir)
    INSTALL_POSTGRES=true
    ;;
  1) # Ruby on Rails
    AGENTS_TECH+=(rails-expert backend-expert frontend-expert web-development-expert tdd-expert bdd-expert conventional-commits-expert)
    INSTR_TECH+=(ruby)
    INSTALL_POSTGRES=true
    ;;
  2) # TypeScript / Node.js backend
    AGENTS_TECH+=(typescript-expert backend-expert tdd-expert conventional-commits-expert)
    INSTR_TECH+=(typescript)
    ;;
  3) # Next.js
    AGENTS_TECH+=(nextjs-expert react-expert typescript-expert frontend-expert backend-expert web-development-expert design-systems-expert conventional-commits-expert)
    INSTR_TECH+=(typescript react css)
    ;;
  4) # React SPA
    AGENTS_TECH+=(react-expert typescript-expert frontend-expert design-systems-expert web-development-expert conventional-commits-expert)
    INSTR_TECH+=(typescript react css)
    ;;
  5) # React Native / Expo
    AGENTS_TECH+=(react-native-expert expo-expert react-expert typescript-expert conventional-commits-expert)
    INSTR_TECH+=(typescript react)
    ;;
  6) # Python
    AGENTS_TECH+=(python-expert backend-expert web-development-expert tdd-expert conventional-commits-expert)
    INSTR_TECH+=(python)
    ;;
  7) # WordPress
    AGENTS_TECH+=(wordpress-expert frontend-expert web-development-expert conventional-commits-expert)
    INSTR_TECH+=(css)
    ;;
  8) # Go
    AGENTS_TECH+=(go-expert backend-expert tdd-expert conventional-commits-expert)
    INSTR_TECH+=(go)
    ;;
  9) # Rust
    AGENTS_TECH+=(rust-expert backend-expert tdd-expert conventional-commits-expert)
    INSTR_TECH+=(rust)
    ;;
  10) # Swift / iOS
    AGENTS_TECH+=(swift-expert react-expert conventional-commits-expert)
    INSTR_TECH+=(swift)
    ;;
  11) # Kotlin / Android
    AGENTS_TECH+=(kotlin-expert conventional-commits-expert)
    INSTR_TECH+=(kotlin)
    ;;
  12) # Flutter
    AGENTS_TECH+=(flutter-expert conventional-commits-expert)
    ;;
  13) # Vue / Nuxt
    AGENTS_TECH+=(vue-expert typescript-expert frontend-expert web-development-expert conventional-commits-expert)
    INSTR_TECH+=(typescript vue css)
    ;;
  14) # Angular
    AGENTS_TECH+=(angular-expert typescript-expert frontend-expert web-development-expert conventional-commits-expert)
    INSTR_TECH+=(typescript css)
    ;;
  15) # Svelte / SvelteKit
    AGENTS_TECH+=(svelte-expert typescript-expert frontend-expert web-development-expert conventional-commits-expert)
    INSTR_TECH+=(typescript css)
    ;;
  16) # C# / ASP.NET Core (backend API)
    AGENTS_TECH+=(csharp-expert aspnetcore-expert backend-expert tdd-expert conventional-commits-expert)
    INSTR_TECH+=(csharp)
    INSTALL_POSTGRES=true
    ;;
  17) # Blazor (frontend / fullstack)
    AGENTS_TECH+=(csharp-expert blazor-expert aspnetcore-expert frontend-expert tdd-expert conventional-commits-expert)
    INSTR_TECH+=(csharp)
    ;;
  18) # C# Full-stack (ASP.NET Core + Blazor)
    AGENTS_TECH+=(csharp-expert aspnetcore-expert blazor-expert backend-expert frontend-expert tdd-expert conventional-commits-expert)
    INSTR_TECH+=(csharp)
    INSTALL_DOCKER=true
    INSTALL_POSTGRES=true
    ;;
  19) # Full-stack
    AGENTS_TECH+=(typescript-expert react-expert nextjs-expert frontend-expert backend-expert web-development-expert design-systems-expert conventional-commits-expert tdd-expert)
    INSTR_TECH+=(typescript react css)
    INSTALL_DOCKER=true
    ;;
  20) # Generic
    AGENTS_TECH+=(backend-expert frontend-expert web-development-expert conventional-commits-expert)
    ;;
  21) # NVIDIA DeepStream
    AGENTS_TECH+=(deepstream-expert deepstream-plugin-expert deepstream-inference-expert tao-toolkit-expert backend-expert tdd-expert conventional-commits-expert)
    INSTR_TECH+=(deepstream)
    INSTALL_DOCKER=true
    ;;
esac

# Add extras
if [[ "$INSTALL_DOCKER" == true ]]; then
  AGENTS_TECH+=(docker-expert)
  INSTR_TECH+=(docker)
fi
if [[ "$INSTALL_POSTGRES" == true ]]; then
  AGENTS_TECH+=(postgresql-expert)
fi
if [[ "$INSTALL_SUPABASE" == true ]]; then
  AGENTS_TECH+=(supabase-expert postgresql-expert)
fi
if [[ "$INSTALL_GRAPHQL" == true ]]; then
  AGENTS_TECH+=(graphql-expert)
  INSTR_TECH+=(graphql)
fi
if [[ "$INSTALL_TERRAFORM" == true ]]; then
  AGENTS_TECH+=(terraform-expert)
fi
if [[ "$INSTALL_OBSERVABILITY" == true ]]; then
  # No extra agent, but skill is already installed
  :
fi

# Deduplicate arrays (bash 3.2 compatible — no mapfile)
dedup() {
  [[ $# -eq 0 ]] && return
  printf '%s\n' "$@" | sort -u
}

_dedup_into() {
  local _arr_name="$1"
  shift
  local _tmp=()
  while IFS= read -r _item; do
    _tmp+=("$_item")
  done < <(dedup "$@")
  eval "$_arr_name=(\"\${_tmp[@]}\")"
}

if [[ ${#AGENTS_TECH[@]} -gt 0 ]]; then
  _dedup_into AGENTS_TECH "${AGENTS_TECH[@]}"
fi
if [[ ${#INSTR_TECH[@]} -gt 0 ]]; then
  _dedup_into INSTR_TECH "${INSTR_TECH[@]}"
fi

# ──────────────────────────────────────────────────────────────
# Show plan
# ──────────────────────────────────────────────────────────────

echo ""
header "Installation Plan"
echo ""
echo -e "  ${BOLD}Target:${NC}       $TARGET"
echo -e "  ${BOLD}Editor:${NC}       ${EDITOR_CHOICES[$editor_idx]}"
echo -e "  ${BOLD}Config dir:${NC}   $CONFIG_DIR/"
echo -e "  ${BOLD}Project:${NC}      ${PROJECT_CHOICES[$project_idx]}"
echo -e "  ${BOLD}Agents:${NC}       ${#AGENTS_CORE[@]} core + ${#AGENTS_TECH[@]} specialized"
echo -e "  ${BOLD}Instructions:${NC} ${#INSTR_CORE[@]} universal + ${#INSTR_TECH[@]} tech-specific"
echo -e "  ${BOLD}Skills:${NC}       48+ (language-agnostic)"
echo -e "  ${BOLD}Prompts:${NC}      27+ (language-agnostic)"

extras_summary=""
[[ "$INSTALL_WORKFLOWS" == true ]]     && extras_summary+="workflows "
[[ "$INSTALL_TEMPLATES" == true ]]     && extras_summary+="templates "
[[ "$INSTALL_TOOLING" == true ]]       && extras_summary+="tooling "
[[ "$INSTALL_DOCKER" == true ]]        && extras_summary+="docker "
[[ "$INSTALL_POSTGRES" == true ]]      && extras_summary+="postgresql "
[[ "$INSTALL_SUPABASE" == true ]]      && extras_summary+="supabase "
[[ "$INSTALL_GRAPHQL" == true ]]       && extras_summary+="graphql "
[[ "$INSTALL_TERRAFORM" == true ]]     && extras_summary+="terraform "
[[ "$INSTALL_OBSERVABILITY" == true ]] && extras_summary+="observability "
[[ -n "$extras_summary" ]] && echo -e "  ${BOLD}Extras:${NC}       $extras_summary"
echo ""

if ! ask_yn "Proceed?"; then
  info "Cancelled."
  exit 0
fi

# ──────────────────────────────────────────────────────────────
# Install
# ──────────────────────────────────────────────────────────────

TOTAL=0

# ── Agents ──
header "Agents"
mkdir -p "$TARGET/$CONFIG_DIR/agents"

for agent in "${AGENTS_CORE[@]}"; do
  copy_agent "$agent"
  TOTAL=$((TOTAL + 1))
done

if [[ ${#AGENTS_TECH[@]} -gt 0 ]]; then
  for agent in "${AGENTS_TECH[@]}"; do
    copy_agent "$agent"
    TOTAL=$((TOTAL + 1))
  done
fi
success "Installed ${#AGENTS_CORE[@]} core + ${#AGENTS_TECH[@]} specialized agents"

# ── Skills ──
header "Skills"
copy_dir "$SOURCE_DIR/templates/skills" "$TARGET/$CONFIG_DIR/skills" "All skills"
TOTAL=$((TOTAL + 33))

# ── Prompts ──
header "Prompts"
copy_dir "$SOURCE_DIR/templates/prompts" "$TARGET/$CONFIG_DIR/prompts" "All prompts"
TOTAL=$((TOTAL + 27))

# ── Instructions ──
header "Instructions"
mkdir -p "$TARGET/$CONFIG_DIR/instructions"

for inst in "${INSTR_CORE[@]}"; do
  copy_instruction "$inst"
  TOTAL=$((TOTAL + 1))
done

if [[ ${#INSTR_TECH[@]} -gt 0 ]]; then
  for inst in "${INSTR_TECH[@]}"; do
    copy_instruction "$inst"
    TOTAL=$((TOTAL + 1))
  done
fi
success "Installed ${#INSTR_CORE[@]} universal + ${#INSTR_TECH[@]} tech-specific instructions"

# ── Hooks ──
header "Hooks"
copy_dir "$SOURCE_DIR/templates/hooks" "$TARGET/$CONFIG_DIR/hooks" "Hooks"
if [[ -d "$TARGET/$CONFIG_DIR/hooks/scripts" ]]; then
  chmod +x "$TARGET/$CONFIG_DIR/hooks/scripts/"*.sh 2>/dev/null || true
fi
TOTAL=$((TOTAL + 4))

# ── References ──
header "References"
copy_dir "$SOURCE_DIR/templates/references" "$TARGET/$CONFIG_DIR/references" "Reference checklists"
TOTAL=$((TOTAL + 8))

# ── Editor-specific files ──
header "Editor Setup"

if [[ "$INSTALL_COPILOT" == true ]]; then
  copy_template "$SOURCE_DIR/templates/copilot-instructions.md" \
                "$TARGET/.github/copilot-instructions.md" \
                "copilot-instructions.md"
  TOTAL=$((TOTAL + 1))
fi

if [[ "$INSTALL_CLAUDE" == true ]]; then
  copy_template "$SOURCE_DIR/templates/CLAUDE.md" "$TARGET/CLAUDE.md" "CLAUDE.md"
  TOTAL=$((TOTAL + 1))
fi

if [[ "$INSTALL_CURSOR" == true ]]; then
  if [[ -f "$SOURCE_DIR/templates/copilot-instructions.md" ]]; then
    copy_template "$SOURCE_DIR/templates/copilot-instructions.md" "$TARGET/.cursorrules" ".cursorrules"
    TOTAL=$((TOTAL + 1))
  fi
fi

if [[ "$INSTALL_WINDSURF" == true ]]; then
  if [[ -f "$SOURCE_DIR/templates/copilot-instructions.md" ]]; then
    copy_template "$SOURCE_DIR/templates/copilot-instructions.md" "$TARGET/.windsurfrules" ".windsurfrules"
    TOTAL=$((TOTAL + 1))
  fi
fi

copy_template "$SOURCE_DIR/templates/AGENTS.md" "$TARGET/AGENTS.md" "AGENTS.md"
TOTAL=$((TOTAL + 1))

# ── Templates ──
if [[ "$INSTALL_TEMPLATES" == true ]]; then
  header "Templates"
  copy_dir "$SOURCE_DIR/templates/ISSUE_TEMPLATE" "$TARGET/.github/ISSUE_TEMPLATE" "Issue templates"
  copy_one "$SOURCE_DIR/templates/PULL_REQUEST_TEMPLATE.md" \
           "$TARGET/.github/PULL_REQUEST_TEMPLATE.md" "PR template"
  TOTAL=$((TOTAL + 4))
fi

# ── Workflows ──
if [[ "$INSTALL_WORKFLOWS" == true ]]; then
  header "Workflows"
  mkdir -p "$TARGET/.github/workflows"
  wf_count=0
  for wf in "$SOURCE_DIR"/templates/workflows/*.yml; do
    [[ -f "$wf" ]] || continue
    cp "$wf" "$TARGET/.github/workflows/$(basename "$wf")"
    wf_count=$((wf_count + 1))
  done
  success "Workflows ($wf_count)"
  TOTAL=$((TOTAL + wf_count))
fi

# ── Tooling ──
if [[ "$INSTALL_TOOLING" == true ]]; then
  header "Editor Tooling"
  for f in .editorconfig .prettierrc .prettierignore .gitattributes; do
    if copy_one "$SOURCE_DIR/$f" "$TARGET/$f" "$f" 2>/dev/null; then
      TOTAL=$((TOTAL + 1))
    fi
  done
fi

# ──────────────────────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}  Done! ~${TOTAL} files installed.${NC}"
echo -e "${BLUE}  ${TARGET}${NC}"
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
info "Next steps:"
echo "  1. cd $TARGET"
echo "  2. Review installed files in $CONFIG_DIR/"

if [[ "$INSTALL_COPILOT" == true ]]; then
  echo "  3. Open in VS Code — agents and prompts are ready via Copilot Chat"
fi
if [[ "$INSTALL_CLAUDE" == true ]]; then
  echo "  3. Run 'claude' — CLAUDE.md provides context automatically"
fi
if [[ "$INSTALL_CURSOR" == true ]]; then
  echo "  3. Open in Cursor — .cursorrules is configured"
fi
if [[ "$INSTALL_WINDSURF" == true ]]; then
  echo "  3. Open in Windsurf — .windsurfrules is configured"
fi

echo ""
warn "Customize these files with your project's details (look for TODO comments):"
if [[ "$INSTALL_COPILOT" == true ]]; then
  echo -e "  ${DIM}• $CONFIG_DIR/copilot-instructions.md${NC}"
fi
if [[ "$INSTALL_CLAUDE" == true ]]; then
  echo -e "  ${DIM}• CLAUDE.md${NC}"
fi
if [[ "$INSTALL_CURSOR" == true ]]; then
  echo -e "  ${DIM}• .cursorrules${NC}"
fi
if [[ "$INSTALL_WINDSURF" == true ]]; then
  echo -e "  ${DIM}• .windsurfrules${NC}"
fi
echo -e "  ${DIM}• AGENTS.md${NC}"

echo ""
echo -e "  ${DIM}git add . && git commit -m 'feat: add dx-toolkit for AI-assisted development'${NC}"
echo ""
