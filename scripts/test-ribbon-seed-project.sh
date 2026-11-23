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
  mkdir -p "${SANDBOX}/home" "${SANDBOX}/example-project"
  export HOME="${SANDBOX}/home"
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

test_seeds_rules() {
  new_repo
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/example-project/rules/README.md" ]] \
    && [[ -f "${SANDBOX}/example-project/rules/testing.md" ]] \
    && git -C "${SANDBOX}/example-project" ls-files --error-unmatch rules/testing.md >/dev/null 2>&1
}

test_amends_pre_rules_project() {
  new_repo
  mkdir -p "${SANDBOX}/example-project/docs"
  printf 'Seeded from the Ribbon Protocol, ribbon 1.\n' > "${SANDBOX}/example-project/docs/README.md"
  printf '# rules\n<!-- ribbon:full-install:start -->\nprotocol text\n<!-- ribbon:full-install:end -->\n' \
    > "${SANDBOX}/example-project/AGENTS.md"
  printf 'unrelated\n' > "${SANDBOX}/example-project/app.js"
  git -C "${SANDBOX}/example-project" add app.js
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/example-project/rules/README.md" ]] \
    && [[ "$(grep -c 'ribbon:full-install:start' "${SANDBOX}/example-project/AGENTS.md")" == "1" ]] \
    && git -C "${SANDBOX}/example-project" log --oneline | grep -q "Add Ribbon coding rules" \
    && ! git -C "${SANDBOX}/example-project" show --name-only --format= HEAD | grep -qx 'app.js' \
    && git -C "${SANDBOX}/example-project" diff --cached --name-only | grep -qx 'app.js'
}

test_import_rules_flag() {
  new_repo
  mkdir -p "${HOME}/.claude/rules"
  printf '# one\n' > "${HOME}/.claude/rules/one.md"
  printf '# two\n' > "${HOME}/.claude/rules/two.md"
  seed "${SANDBOX}/example-project" --import-rules one.md >/dev/null 2>&1
  [[ -f "${SANDBOX}/example-project/rules/one.md" ]] \
    && [[ ! -f "${SANDBOX}/example-project/rules/two.md" ]] \
    && git -C "${SANDBOX}/example-project" ls-files --error-unmatch rules/one.md >/dev/null 2>&1
}

test_import_rules_missing_file_fails() {
  new_repo
  ! seed "${SANDBOX}/example-project" --import-rules nope.md >/dev/null 2>&1
}

test_non_interactive_imports_nothing() {
  new_repo
  mkdir -p "${HOME}/.claude/rules"
  printf '# one\n' > "${HOME}/.claude/rules/one.md"
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/example-project/rules/testing.md" ]] \
    && [[ ! -f "${SANDBOX}/example-project/rules/one.md" ]]
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

test_refuses_home_directory() {
  cleanup
  SANDBOX="$(mktemp -d)"
  mkdir -p "${SANDBOX}/home" "${SANDBOX}/example-project"
  export HOME="${SANDBOX}/home"
  printf '# home AGENTS\n' > "${HOME}/AGENTS.md"
  ! seed "${HOME}" >/dev/null 2>&1
  [[ ! -e "${HOME}/docs" ]] && [[ ! -e "${HOME}/rules" ]]
}

test_refuses_template_as_project_repo() {
  new_repo
  ! seed "${RIBBON_HOME}" >/dev/null 2>&1
}

test_seed_commit_includes_docs_subdirs() {
  new_repo
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  git -C "${SANDBOX}/example-project" ls-files --error-unmatch docs/adrs/README.md \
      >/dev/null 2>&1 \
    && git -C "${SANDBOX}/example-project" ls-files --error-unmatch docs/adrs/_template.md \
      >/dev/null 2>&1
}

test_seeder_merges_into_existing_rules() {
  new_repo
  mkdir -p "${SANDBOX}/example-project/rules"
  printf 'house rules\n' > "${SANDBOX}/example-project/rules/house.md"
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ "$(cat "${SANDBOX}/example-project/rules/house.md")" == "house rules" ]] \
    && [[ -f "${SANDBOX}/example-project/rules/testing.md" ]] \
    && [[ ! -d "${SANDBOX}/example-project/rules/rules" ]]
}

test_seeder_merges_into_existing_docs() {
  new_repo
  mkdir -p "${SANDBOX}/example-project/docs"
  printf 'my notes\n' > "${SANDBOX}/example-project/docs/notes.md"
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ "$(cat "${SANDBOX}/example-project/docs/notes.md")" == "my notes" ]] \
    && [[ -f "${SANDBOX}/example-project/docs/README.md" ]] \
    && [[ ! -d "${SANDBOX}/example-project/docs/docs" ]]
}

test_amend_requires_ribbon_stamp() {
  new_repo
  mkdir -p "${SANDBOX}/example-project/docs"
  printf '# My API documentation\n' > "${SANDBOX}/example-project/docs/README.md"
  ! seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ ! -e "${SANDBOX}/example-project/rules" ]]
}

test_amend_rejects_false_stamp() {
  new_repo
  mkdir -p "${SANDBOX}/example-project/docs"
  printf 'Seeded from the Ribbon Protocol, ribbon notes for an unrelated project.\n' \
    > "${SANDBOX}/example-project/docs/README.md"
  ! seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ ! -e "${SANDBOX}/example-project/rules" ]]
}

test_seeder_keeps_existing_docs_files() {
  new_repo
  mkdir -p "${SANDBOX}/example-project/docs/tasks"
  printf 'our own task guide\n' > "${SANDBOX}/example-project/docs/tasks/README.md"
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ "$(cat "${SANDBOX}/example-project/docs/tasks/README.md")" == "our own task guide" ]] \
    && [[ -f "${SANDBOX}/example-project/docs/README.md" ]]
}

test_literal_pathspec_import() {
  new_repo
  mkdir -p "${HOME}/.claude/rules" "${SANDBOX}/example-project/rules"
  printf '# p\n' > "${HOME}/.claude/rules/practice[12].md"
  printf 'decoy\n' > "${SANDBOX}/example-project/rules/practice1.md"
  git -C "${SANDBOX}/example-project" add rules/practice1.md
  seed "${SANDBOX}/example-project" --import-rules 'practice[12].md' >/dev/null 2>&1
  git -C "${SANDBOX}/example-project" show --name-only --format= HEAD \
      | grep -qx 'rules/practice\[12\].md' \
    && ! git -C "${SANDBOX}/example-project" show --name-only --format= HEAD \
      | grep -qx 'rules/practice1.md' \
    && git -C "${SANDBOX}/example-project" diff --cached --name-only \
      | grep -qx 'rules/practice1.md'
}

test_import_rejects_directory_operand() {
  new_repo
  mkdir -p "${HOME}/.claude/rules/dir.md"
  ! seed "${SANDBOX}/example-project" --import-rules dir.md >/dev/null 2>&1
}

test_amend_commit_keeps_staged_rules() {
  new_repo
  mkdir -p "${SANDBOX}/example-project/docs" "${SANDBOX}/example-project/rules"
  printf 'Seeded from the Ribbon Protocol, ribbon 1.\n' > "${SANDBOX}/example-project/docs/README.md"
  printf 'house\n' > "${SANDBOX}/example-project/rules/house.md"
  git -C "${SANDBOX}/example-project" add rules/house.md
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  ! git -C "${SANDBOX}/example-project" show --name-only --format= HEAD | grep -qx 'rules/house.md' \
    && git -C "${SANDBOX}/example-project" diff --cached --name-only | grep -qx 'rules/house.md' \
    && git -C "${SANDBOX}/example-project" show --name-only --format= HEAD | grep -qx 'rules/testing.md'
}

test_seeder_keeps_existing_project_theme() {
  new_repo
  mkdir -p "${SANDBOX}/example-project/rules"
  printf 'custom testing rules\n' > "${SANDBOX}/example-project/rules/testing.md"
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ "$(cat "${SANDBOX}/example-project/rules/testing.md")" == "custom testing rules" ]] \
    && [[ -f "${SANDBOX}/example-project/rules/README.md" ]]
}

test_import_rules_usage_order_works() {
  new_repo
  mkdir -p "${HOME}/.claude/rules"
  printf '# one\n' > "${HOME}/.claude/rules/one.md"
  seed --import-rules one.md "${SANDBOX}/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/example-project/rules/one.md" ]]
}

test_import_rules_requires_one_value() {
  new_repo
  ! seed "${SANDBOX}/example-project" --import-rules >/dev/null 2>&1
}

test_import_rules_rejects_paths() {
  new_repo
  mkdir -p "${HOME}/.claude"
  printf '# x\n' > "${HOME}/.claude/x.md"
  ! seed "${SANDBOX}/example-project" --import-rules ../x.md >/dev/null 2>&1
  [[ ! -e "${SANDBOX}/example-project/docs" ]] \
    && [[ ! -e "${SANDBOX}/example-project/x.md" ]]
}

test_seed_docs_enumeration_failure_aborts() {
  new_repo
  local tmpl="${SANDBOX}/template-copy"
  mkdir -p "${tmpl}"
  cp -R "${RIBBON_HOME}/." "${tmpl}/"
  rm -rf "${tmpl}/.git"
  chmod 000 "${tmpl}/docs/adrs"
  local rc=0
  seed --ribbon-home "${tmpl}" "${SANDBOX}/example-project" >/dev/null 2>&1 || rc=1
  chmod 0755 "${tmpl}/docs/adrs"
  [[ "${rc}" == "1" ]] \
    && [[ ! -e "${SANDBOX}/example-project/docs/README.md" ]] \
    && ! git -C "${SANDBOX}/example-project" log --oneline | grep -q "Seed the Ribbon Protocol"
}

test_commit_excludes_untouched_agent_files() {
  new_repo
  printf '# ours\n<!-- ribbon:full-install:start -->\nx\n<!-- ribbon:full-install:end -->\n' \
    > "${SANDBOX}/example-project/AGENTS.md"
  printf '@AGENTS.md\n@herdr-config.md\n' > "${SANDBOX}/example-project/CLAUDE.md"
  printf 'staged edit\n' >> "${SANDBOX}/example-project/AGENTS.md"
  printf 'staged edit\n' >> "${SANDBOX}/example-project/CLAUDE.md"
  git -C "${SANDBOX}/example-project" add AGENTS.md CLAUDE.md
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  ! git -C "${SANDBOX}/example-project" show HEAD:AGENTS.md 2>/dev/null | grep -q 'staged edit' \
    && ! git -C "${SANDBOX}/example-project" show HEAD:CLAUDE.md 2>/dev/null | grep -q 'staged edit' \
    && git -C "${SANDBOX}/example-project" diff --cached --name-only | grep -qx 'AGENTS.md' \
    && git -C "${SANDBOX}/example-project" diff --cached --name-only | grep -qx 'CLAUDE.md'
}

readonly TESTS=(
  test_seeder_exists
  test_seeds_docs
  test_stamps_version
  test_appends_protocol_preserving_content
  test_copies_herdr_config
  test_seeds_rules
  test_amends_pre_rules_project
  test_import_rules_flag
  test_import_rules_missing_file_fails
  test_non_interactive_imports_nothing
  test_creates_claude_md
  test_commits_seed
  test_refuses_reseed
  test_extends_existing_claude_md
  test_creates_agents_md_when_missing
  test_rejects_missing_directory
  test_rejects_unwritable_repo
  test_usage_without_args
  test_refuses_home_directory
  test_refuses_template_as_project_repo
  test_seeder_merges_into_existing_rules
  test_seeder_merges_into_existing_docs
  test_amend_requires_ribbon_stamp
  test_amend_rejects_false_stamp
  test_seeder_keeps_existing_docs_files
  test_literal_pathspec_import
  test_import_rejects_directory_operand
  test_amend_commit_keeps_staged_rules
  test_seeder_keeps_existing_project_theme
  test_import_rules_usage_order_works
  test_import_rules_requires_one_value
  test_import_rules_rejects_paths
  test_seed_docs_enumeration_failure_aborts
  test_commit_excludes_untouched_agent_files
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
