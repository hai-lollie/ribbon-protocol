#!/usr/bin/env bash
# Tests for scripts/ribbon-seed-project (the full install): one function per
# test, run in order by main. Each test builds its own throwaway git
# repository; the real template repo provides the seeds. Names are generic.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RIBBON_HOME="$(dirname "${SCRIPT_DIR}")"
SEEDER="${SCRIPT_DIR}/ribbon-seed-project"
readonly SCRIPT_DIR RIBBON_HOME SEEDER

PASS=0
FAIL=0
SANDBOX=''

#######################################
# Record a test result (TAP, one line per test).
# Arguments:
#   Test name, exit status of the test function.
#######################################
record() {
  if [[ "$2" -eq 0 ]]; then
    PASS=$((PASS + 1))
    printf 'ok   - %s\n' "$1"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL - %s\n' "$1"
  fi
}

#######################################
# Remove the current sandbox, if any.
# Globals:
#   SANDBOX
#######################################
cleanup() {
  [[ -n "${SANDBOX}" ]] && rm -rf "${SANDBOX}"
}
trap cleanup EXIT

#######################################
# Replace the sandbox with a fresh git repository holding a minimal AGENTS.md.
# Globals:
#   SANDBOX (set)
#######################################
new_repo() {
  cleanup
  SANDBOX="$(mktemp -d)"
  mkdir -p "${SANDBOX}/example-project"
  printf '# Our house rules\n' > "${SANDBOX}/example-project/AGENTS.md"
  git -C "${SANDBOX}/example-project" init -q
  git -C "${SANDBOX}/example-project" config user.email test@example.com
  git -C "${SANDBOX}/example-project" config user.name test
  git -C "${SANDBOX}/example-project" add AGENTS.md
  git -C "${SANDBOX}/example-project" commit -qm "init"
}

#######################################
# Run the seeder against the sandbox repository.
# Arguments:
#   Remaining seeder arguments.
#######################################
seed() {
  "${SEEDER}" "$@"
}

#######################################
# The template version line, e.g. "ribbon 1".
# Outputs:
#   The version on stdout.
#######################################
template_version() {
  head -1 "${RIBBON_HOME}/VERSION"
}

test_seeder_exists() {
  [[ -x "${SEEDER}" ]]
}

test_seeds_docs() {
  new_repo
  seed "${SANDBOX}/example-project" >/dev/null 2>&1 \
    && [[ -f "${SANDBOX}/example-project/docs/README.md" ]] \
    && [[ -f "${SANDBOX}/example-project/docs/tasks/_template.plan.yaml" ]] \
    && [[ -f "${SANDBOX}/example-project/docs/llm-context/_report.md" ]] \
    && [[ -f "${SANDBOX}/example-project/docs/field-guide.md" ]]
}

test_stamps_version() {
  new_repo
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  head -1 "${SANDBOX}/example-project/docs/README.md" \
    | grep -q "Seeded from the Ribbon Protocol, $(template_version)"
}

test_appends_protocol_preserving_content() {
  new_repo
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  grep -q "Our house rules" "${SANDBOX}/example-project/AGENTS.md" \
    && grep -q "multi-LLM engineering belt" "${SANDBOX}/example-project/AGENTS.md" \
    && [[ "$(grep -c 'ribbon:full-install:start' "${SANDBOX}/example-project/AGENTS.md")" == "1" ]]
}

test_copies_herdr_config() {
  new_repo
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/example-project/herdr-config.md" ]]
}

test_creates_claude_md() {
  new_repo
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/example-project/CLAUDE.md" ]] \
    && grep -qxF '@AGENTS.md' "${SANDBOX}/example-project/CLAUDE.md" \
    && grep -qxF '@herdr-config.md' "${SANDBOX}/example-project/CLAUDE.md"
}

test_commits_seed() {
  new_repo
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  git -C "${SANDBOX}/example-project" log --oneline \
    | grep -q "Seed the Ribbon Protocol, $(template_version)"
}

test_refuses_reseed() {
  new_repo
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  ! seed "${SANDBOX}/example-project" >/dev/null 2>&1
}

test_extends_existing_claude_md() {
  new_repo
  printf '# precious\n' > "${SANDBOX}/example-project/CLAUDE.md"
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  grep -qxF '# precious' "${SANDBOX}/example-project/CLAUDE.md" \
    && [[ "$(grep -c '@herdr-config.md' "${SANDBOX}/example-project/CLAUDE.md")" == "1" ]]
}

test_creates_agents_md_when_missing() {
  new_repo
  rm "${SANDBOX}/example-project/AGENTS.md"
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  grep -q "multi-LLM engineering belt" "${SANDBOX}/example-project/AGENTS.md"
}

test_rejects_missing_directory() {
  new_repo
  ! seed "${SANDBOX}/nope" >/dev/null 2>&1
}

test_rejects_unwritable_repo() {
  new_repo
  chmod 0555 "${SANDBOX}/example-project"
  local failed=0
  seed "${SANDBOX}/example-project" >/dev/null 2>&1 || failed=1
  chmod 0700 "${SANDBOX}/example-project"
  (( failed == 1 ))
}

test_usage_without_args() {
  ! "${SEEDER}" >/dev/null 2>&1
}

readonly TESTS=(
  test_seeder_exists
  test_seeds_docs
  test_stamps_version
  test_appends_protocol_preserving_content
  test_copies_herdr_config
  test_creates_claude_md
  test_commits_seed
  test_refuses_reseed
  test_extends_existing_claude_md
  test_creates_agents_md_when_missing
  test_rejects_missing_directory
  test_rejects_unwritable_repo
  test_usage_without_args
)

main() {
  local test
  for test in "${TESTS[@]}"; do
    if "${test}" >/dev/null 2>&1; then
      record "${test}" 0
    else
      record "${test}" 1
    fi
  done
  printf '1..%d\n' "$((PASS + FAIL))"
  (( FAIL == 0 ))
}

main "$@"
