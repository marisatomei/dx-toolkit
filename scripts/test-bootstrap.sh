#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────
# test-bootstrap.sh — Tests for bootstrap.sh
# ──────────────────────────────────────────────────────────────
# Validates interactive functions, --all mode, and per-project
# type installations work correctly on macOS bash 3.2+.
#
# Usage: ./scripts/test-bootstrap.sh
# ──────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="$SCRIPT_DIR/bootstrap.sh"
PASS=0
FAIL=0
ERRORS=()

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# ── Test helpers ──
setup_tmpdir() {
  TMPDIR_TEST="$(mktemp -d)"
}

teardown_tmpdir() {
  [[ -n "${TMPDIR_TEST:-}" && -d "$TMPDIR_TEST" ]] && rm -rf "$TMPDIR_TEST"
}

pass() {
  PASS=$((PASS + 1))
  echo -e "  ${GREEN}✓${NC} $1"
}

fail() {
  FAIL=$((FAIL + 1))
  ERRORS+=("$1: $2")
  echo -e "  ${RED}✗${NC} $1"
  echo -e "    ${RED}$2${NC}"
}

assert_eq() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label" "expected '$expected', got '$actual'"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" label="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    pass "$label"
  else
    fail "$label" "expected to contain '$needle'"
  fi
}

assert_file_exists() {
  local path="$1" label="$2"
  if [[ -f "$path" ]]; then
    pass "$label"
  else
    fail "$label" "file not found: $path"
  fi
}

assert_dir_exists() {
  local path="$1" label="$2"
  if [[ -d "$path" ]]; then
    pass "$label"
  else
    fail "$label" "directory not found: $path"
  fi
}

assert_file_not_exists() {
  local path="$1" label="$2"
  if [[ ! -f "$path" ]]; then
    pass "$label"
  else
    fail "$label" "file should not exist: $path"
  fi
}

# ──────────────────────────────────────────────────────────────
# Source only the functions from bootstrap.sh for unit testing
# ──────────────────────────────────────────────────────────────

# Extract and source just the function definitions
extract_functions() {
  # We need the color variables and functions
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'; export BLUE
  CYAN='\033[0;36m'; export CYAN
  BOLD='\033[1m'
  DIM='\033[2m'; export DIM
  NC='\033[0m'

  # Used by eval'd functions from bootstrap.sh
  # shellcheck disable=SC2329
  warn() { echo -e "${YELLOW}⚠${NC}  $*"; }

  # Source the functions by extracting them
  eval "$(sed -n '/^ask_choice()/,/^}/p' "$BOOTSTRAP")"
  eval "$(sed -n '/^ask_multi()/,/^}/p' "$BOOTSTRAP")"
  eval "$(sed -n '/^dedup()/,/^}/p' "$BOOTSTRAP")"
  eval "$(sed -n '/^_dedup_into()/,/^}/p' "$BOOTSTRAP")"
  eval "$(sed -n '/^copy_dir()/,/^}/p' "$BOOTSTRAP")"
  eval "$(sed -n '/^copy_one()/,/^}/p' "$BOOTSTRAP")"
}

# ══════════════════════════════════════════════════════════════
echo -e "\n${BOLD}🧪 Bootstrap Script Tests${NC}\n"
# ══════════════════════════════════════════════════════════════

# ── Test 1: ask_choice returns correct index on stdout ────────
echo -e "${BOLD}Test: ask_choice${NC}"
extract_functions

# Simulate picking option 2
result=$(echo "2" | ask_choice "Pick" "Alpha" "Beta" "Gamma" 2>/dev/null)
assert_eq "$result" "1" "ask_choice returns 0-based index (pick 2 → 1)"

result=$(echo "1" | ask_choice "Pick" "Alpha" "Beta" "Gamma" 2>/dev/null)
assert_eq "$result" "0" "ask_choice returns 0 for first option"

result=$(echo "3" | ask_choice "Pick" "Alpha" "Beta" "Gamma" 2>/dev/null)
assert_eq "$result" "2" "ask_choice returns 2 for third option"

# ── Test 2: ask_choice displays options on stderr ─────────────
echo -e "\n${BOLD}Test: ask_choice displays on stderr${NC}"

stderr_output=$(echo "1" | ask_choice "Pick color" "Red" "Blue" "Green" 2>&1 1>/dev/null)
assert_contains "$stderr_output" "Red" "ask_choice shows option 1 on stderr"
assert_contains "$stderr_output" "Blue" "ask_choice shows option 2 on stderr"
assert_contains "$stderr_output" "Green" "ask_choice shows option 3 on stderr"
assert_contains "$stderr_output" "Pick color" "ask_choice shows prompt on stderr"

# ── Test 3: ask_multi returns correct indices ─────────────────
echo -e "\n${BOLD}Test: ask_multi${NC}"

result=$(echo "1,3" | ask_multi "Pick extras" "Docker" "Postgres" "Redis" 2>/dev/null)
assert_eq "$result" "0 2" "ask_multi returns 0-based indices for 1,3"

result=$(echo "" | ask_multi "Pick extras" "Docker" "Postgres" 2>/dev/null)
assert_eq "$result" "" "ask_multi returns empty on Enter (skip)"

result=$(echo "2" | ask_multi "Pick extras" "Docker" "Postgres" "Redis" 2>/dev/null)
assert_eq "$result" "1" "ask_multi returns single index"

# ── Test 4: ask_multi displays on stderr ──────────────────────
echo -e "\n${BOLD}Test: ask_multi displays on stderr${NC}"

stderr_output=$(echo "" | ask_multi "Choose" "A" "B" "C" 2>&1 1>/dev/null)
assert_contains "$stderr_output" "A" "ask_multi shows option A on stderr"
assert_contains "$stderr_output" "B" "ask_multi shows option B on stderr"
assert_contains "$stderr_output" "Choose" "ask_multi shows prompt on stderr"

# ── Test 5: dedup function ────────────────────────────────────
echo -e "\n${BOLD}Test: dedup${NC}"

result=$(dedup "a" "b" "a" "c" "b")
assert_eq "$result" "$(printf 'a\nb\nc')" "dedup removes duplicates"

result=$(dedup "z" "a" "m")
assert_eq "$result" "$(printf 'a\nm\nz')" "dedup sorts output"

result=$(dedup)
assert_eq "$result" "" "dedup handles empty input"

# ── Test 6: _dedup_into ──────────────────────────────────────
echo -e "\n${BOLD}Test: _dedup_into${NC}"

TEST_ARR=(docker-expert typescript-expert docker-expert react-expert)
_dedup_into TEST_ARR "${TEST_ARR[@]}"
assert_eq "${#TEST_ARR[@]}" "3" "_dedup_into removes duplicates (4 → 3)"

# Check sorted
assert_eq "${TEST_ARR[0]}" "docker-expert" "_dedup_into first element"
assert_eq "${TEST_ARR[1]}" "react-expert" "_dedup_into second element"
assert_eq "${TEST_ARR[2]}" "typescript-expert" "_dedup_into third element"

# ── Test 7: --all mode installs everything ────────────────────
echo -e "\n${BOLD}Test: --all mode${NC}"
setup_tmpdir
mkdir -p "$TMPDIR_TEST/all-test"

"$BOOTSTRAP" "$TMPDIR_TEST/all-test" --all > /dev/null 2>&1
assert_eq "$?" "0" "--all exits cleanly"
assert_dir_exists "$TMPDIR_TEST/all-test/.github/agents" "--all creates agents dir"
assert_dir_exists "$TMPDIR_TEST/all-test/.github/skills" "--all creates skills dir"
assert_dir_exists "$TMPDIR_TEST/all-test/.github/prompts" "--all creates prompts dir"
assert_dir_exists "$TMPDIR_TEST/all-test/.github/instructions" "--all creates instructions dir"
assert_dir_exists "$TMPDIR_TEST/all-test/.github/hooks" "--all creates hooks dir"
assert_dir_exists "$TMPDIR_TEST/all-test/.github/references" "--all creates references dir"
assert_dir_exists "$TMPDIR_TEST/all-test/.github/workflows" "--all creates workflows dir"
assert_file_exists "$TMPDIR_TEST/all-test/.github/copilot-instructions.md" "--all creates copilot-instructions"
assert_file_exists "$TMPDIR_TEST/all-test/CLAUDE.md" "--all creates CLAUDE.md"
assert_file_exists "$TMPDIR_TEST/all-test/AGENTS.md" "--all creates AGENTS.md"
assert_file_exists "$TMPDIR_TEST/all-test/.github/PULL_REQUEST_TEMPLATE.md" "--all creates PR template"

# Verify agent count
agent_count=$(find "$TMPDIR_TEST/all-test/.github/agents" -name "*.agent.md" | wc -l | tr -d ' ')
expected_count=$(find "$SCRIPT_DIR/../templates/agents" -name "*.agent.md" | wc -l | tr -d ' ')
assert_eq "$agent_count" "$expected_count" "--all installs all $expected_count agents"

# Verify workflow count
wf_count=$(find "$TMPDIR_TEST/all-test/.github/workflows" -name "*.yml" | wc -l | tr -d ' ')
expected_wf=$(find "$SCRIPT_DIR/../templates/workflows" -name "*.yml" | wc -l | tr -d ' ')
assert_eq "$wf_count" "$expected_wf" "--all installs all $expected_wf workflows"

teardown_tmpdir

# ── Test 8: Interactive — GitHub Copilot + Next.js + no extras ─
echo -e "\n${BOLD}Test: Interactive — Copilot + Next.js${NC}"
setup_tmpdir
mkdir -p "$TMPDIR_TEST/nextjs-test"
# Input: 1 (Copilot), 4 (Next.js), empty (no extras), y (proceed)
printf '1\n4\n\ny\n' | "$BOOTSTRAP" "$TMPDIR_TEST/nextjs-test" 2>/dev/null

assert_dir_exists "$TMPDIR_TEST/nextjs-test/.github/agents" "interactive creates agents dir"
assert_dir_exists "$TMPDIR_TEST/nextjs-test/.github/skills" "interactive creates skills dir"
assert_dir_exists "$TMPDIR_TEST/nextjs-test/.github/prompts" "interactive creates prompts dir"

# Verify core agents installed
assert_file_exists "$TMPDIR_TEST/nextjs-test/.github/agents/bug-fixer.agent.md" "core agent: bug-fixer"
assert_file_exists "$TMPDIR_TEST/nextjs-test/.github/agents/test-writer.agent.md" "core agent: test-writer"

# Verify Next.js-specific agents
assert_file_exists "$TMPDIR_TEST/nextjs-test/.github/agents/nextjs-expert.agent.md" "tech agent: nextjs-expert"
assert_file_exists "$TMPDIR_TEST/nextjs-test/.github/agents/react-expert.agent.md" "tech agent: react-expert"
assert_file_exists "$TMPDIR_TEST/nextjs-test/.github/agents/typescript-expert.agent.md" "tech agent: typescript-expert"

# Verify unrelated agents NOT installed
assert_file_not_exists "$TMPDIR_TEST/nextjs-test/.github/agents/elixir-expert.agent.md" "no elixir-expert for Next.js"
assert_file_not_exists "$TMPDIR_TEST/nextjs-test/.github/agents/rails-expert.agent.md" "no rails-expert for Next.js"
assert_file_not_exists "$TMPDIR_TEST/nextjs-test/.github/agents/python-expert.agent.md" "no python-expert for Next.js"

# Verify copilot-instructions.md
assert_file_exists "$TMPDIR_TEST/nextjs-test/.github/copilot-instructions.md" "copilot-instructions.md installed"

# Verify tech-specific instructions
assert_file_exists "$TMPDIR_TEST/nextjs-test/.github/instructions/typescript.instructions.md" "typescript instruction"
assert_file_exists "$TMPDIR_TEST/nextjs-test/.github/instructions/react.instructions.md" "react instruction"

# Verify workflows NOT installed (no extras selected)
assert_file_not_exists "$TMPDIR_TEST/nextjs-test/.github/workflows" "no workflows without extras"

teardown_tmpdir

# ── Test 9: Interactive — Claude Code + Elixir/Phoenix ────────
echo -e "\n${BOLD}Test: Interactive — Claude + Elixir/Phoenix${NC}"
setup_tmpdir
mkdir -p "$TMPDIR_TEST/elixir-test"
# Input: 2 (Claude), 1 (Elixir/Phoenix), empty (no extras), y (proceed)
printf '2\n1\n\ny\n' | "$BOOTSTRAP" "$TMPDIR_TEST/elixir-test" 2>/dev/null

assert_dir_exists "$TMPDIR_TEST/elixir-test/.claude/agents" "Claude uses .claude/ config dir"
assert_file_exists "$TMPDIR_TEST/elixir-test/.claude/agents/elixir-expert.agent.md" "elixir-expert installed"
assert_file_exists "$TMPDIR_TEST/elixir-test/.claude/agents/phoenix-expert.agent.md" "phoenix-expert installed"
assert_file_exists "$TMPDIR_TEST/elixir-test/.claude/agents/postgresql-expert.agent.md" "postgresql auto-added for Elixir"
assert_file_exists "$TMPDIR_TEST/elixir-test/CLAUDE.md" "CLAUDE.md installed"
assert_file_exists "$TMPDIR_TEST/elixir-test/.claude/instructions/elixir.instructions.md" "elixir instruction"
assert_file_not_exists "$TMPDIR_TEST/elixir-test/.github/copilot-instructions.md" "no copilot-instructions for Claude"

teardown_tmpdir

# ── Test 10: Interactive — with extras (workflows + templates) ─
echo -e "\n${BOLD}Test: Interactive — with extras${NC}"
setup_tmpdir
mkdir -p "$TMPDIR_TEST/extras-test"
# Input: 1 (Copilot), 18 (Generic), 7,8 (workflows + templates), y (proceed)
printf '1\n18\n7,8\ny\n' | "$BOOTSTRAP" "$TMPDIR_TEST/extras-test" 2>/dev/null

assert_dir_exists "$TMPDIR_TEST/extras-test/.github/workflows" "workflows installed via extras"
assert_dir_exists "$TMPDIR_TEST/extras-test/.github/ISSUE_TEMPLATE" "issue templates via extras"
assert_file_exists "$TMPDIR_TEST/extras-test/.github/PULL_REQUEST_TEMPLATE.md" "PR template via extras"

wf_count=$(find "$TMPDIR_TEST/extras-test/.github/workflows" -name "*.yml" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$wf_count" -gt 0 ]]; then
  pass "workflows installed ($wf_count files)"
else
  fail "workflows installed" "no workflow files found"
fi

teardown_tmpdir

# ── Test 11: Interactive — Cursor editor config ───────────────
echo -e "\n${BOLD}Test: Interactive — Cursor editor${NC}"
setup_tmpdir
mkdir -p "$TMPDIR_TEST/cursor-test"
# Input: 3 (Cursor), 18 (Generic), empty (no extras), y (proceed)
printf '3\n18\n\ny\n' | "$BOOTSTRAP" "$TMPDIR_TEST/cursor-test" 2>/dev/null

assert_dir_exists "$TMPDIR_TEST/cursor-test/.cursor/agents" "Cursor uses .cursor/ config dir"
assert_file_exists "$TMPDIR_TEST/cursor-test/.cursorrules" ".cursorrules installed for Cursor"

teardown_tmpdir

# ── Test 12: Interactive — Windsurf editor config ─────────────
echo -e "\n${BOLD}Test: Interactive — Windsurf editor${NC}"
setup_tmpdir
mkdir -p "$TMPDIR_TEST/windsurf-test"
# Input: 4 (Windsurf), 18 (Generic), empty (no extras), y (proceed)
printf '4\n18\n\ny\n' | "$BOOTSTRAP" "$TMPDIR_TEST/windsurf-test" 2>/dev/null

assert_dir_exists "$TMPDIR_TEST/windsurf-test/.windsurf/agents" "Windsurf uses .windsurf/ config dir"
assert_file_exists "$TMPDIR_TEST/windsurf-test/.windsurfrules" ".windsurfrules installed for Windsurf"

teardown_tmpdir

# ── Test 13: Interactive — All editors ────────────────────────
echo -e "\n${BOLD}Test: Interactive — All editors${NC}"
setup_tmpdir
mkdir -p "$TMPDIR_TEST/all-editors"
# Input: 5 (All), 18 (Generic), empty (no extras), y (proceed)
printf '5\n18\n\ny\n' | "$BOOTSTRAP" "$TMPDIR_TEST/all-editors" 2>/dev/null

assert_file_exists "$TMPDIR_TEST/all-editors/.github/copilot-instructions.md" "copilot-instructions for All"
assert_file_exists "$TMPDIR_TEST/all-editors/CLAUDE.md" "CLAUDE.md for All"
assert_file_exists "$TMPDIR_TEST/all-editors/.cursorrules" ".cursorrules for All"
assert_file_exists "$TMPDIR_TEST/all-editors/.windsurfrules" ".windsurfrules for All"

teardown_tmpdir

# ── Test 14: Each project type runs without error ─────────────
echo -e "\n${BOLD}Test: All project types run without error${NC}"

for i in $(seq 1 22); do
  setup_tmpdir
  mkdir -p "$TMPDIR_TEST/proj-$i"
  label="project type $i"
  if printf "1\n%s\n\ny\n" "$i" | "$BOOTSTRAP" "$TMPDIR_TEST/proj-$i" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label" "exited with non-zero status"
  fi
  teardown_tmpdir
done

# ── Test 15: Docker extra adds docker-expert ──────────────────
echo -e "\n${BOLD}Test: Docker extra${NC}"
setup_tmpdir
mkdir -p "$TMPDIR_TEST/docker-test"

# Input: 1 (Copilot), 18 (Generic), 1 (Docker), y (proceed)
printf '1\n18\n1\ny\n' | "$BOOTSTRAP" "$TMPDIR_TEST/docker-test" 2>/dev/null

assert_file_exists "$TMPDIR_TEST/docker-test/.github/agents/docker-expert.agent.md" "docker-expert added via extras"
assert_file_exists "$TMPDIR_TEST/docker-test/.github/instructions/docker.instructions.md" "docker instruction added"

teardown_tmpdir

# ── Test 16: --help ───────────────────────────────────────────
echo -e "\n${BOLD}Test: --help${NC}"

help_output=$("$BOOTSTRAP" --help 2>&1)
assert_contains "$help_output" "Usage:" "--help shows Usage"
assert_contains "$help_output" "Agents (52+)" "--help shows agent count"
assert_contains "$help_output" "Workflows (27)" "--help shows workflow count"

# ── Test 17: No arguments shows usage ─────────────────────────
echo -e "\n${BOLD}Test: No arguments${NC}"

no_args_output=$("$BOOTSTRAP" 2>&1 || true)
assert_contains "$no_args_output" "Usage:" "no args shows usage"

# ── Test 18: Rejects self as target ───────────────────────────
echo -e "\n${BOLD}Test: Self-target rejection${NC}"

self_output=$("$BOOTSTRAP" "$SCRIPT_DIR/.." 2>&1 || true)
assert_contains "$self_output" "Target cannot be the dx-toolkit itself" "rejects self as target"

# ══════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${GREEN}${BOLD}Passed: $PASS${NC}"
if [[ $FAIL -gt 0 ]]; then
  echo -e "  ${RED}${BOLD}Failed: $FAIL${NC}"
  echo ""
  for err in "${ERRORS[@]}"; do
    echo -e "  ${RED}✗${NC} $err"
  done
fi
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

exit "$FAIL"
