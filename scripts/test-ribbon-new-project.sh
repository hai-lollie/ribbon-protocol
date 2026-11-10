#!/usr/bin/env bash
# Tests for scripts/ribbon-new-project: one function per test, run in order
# by main. Each test builds its own throwaway projects dir; the real template
# repo provides the seeds. Project and instance names are generic.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RIBBON_HOME="$(dirname "${SCRIPT_DIR}")"
INSTALLER="${SCRIPT_DIR}/ribbon-new-project"
readonly SCRIPT_DIR RIBBON_HOME INSTALLER

PASS=0
FAIL=0
SANDBOX=''
PROJECTS=''

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
# Replace the sandbox with a fresh one: projects dir plus one fake project
# repo with a minimal AGENTS.md.
# Globals:
#   SANDBOX, PROJECTS (set)
#######################################
new_sandbox() {
  cleanup
  SANDBOX="$(mktemp -d)"
  mkdir -p "${SANDBOX}/ribbon-projects" "${SANDBOX}/repos/example-project"
  printf '# example-project AGENTS\n' > "${SANDBOX}/repos/example-project/AGENTS.md"
  PROJECTS="${SANDBOX}/ribbon-projects"
}

#######################################
# Run the installer against the sandbox projects dir.
# Arguments:
#   Remaining installer arguments.
#######################################
install() {
  "${INSTALLER}" --projects "${PROJECTS}" "$@"
}

#######################################
# Count the marked standalone blocks in the project AGENTS.local.md.
# Outputs:
#   The block count on stdout.
#######################################
block_count() {
  grep -c 'ribbon:standalone:start' "${SANDBOX}/repos/example-project/AGENTS.local.md" 2>/dev/null || true
}

test_installer_exists() {
  [[ -x "${INSTALLER}" ]]
}

test_creates_layout() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1 \
    && [[ -f "${PROJECTS}/example-project/docs/tasks/README.md" ]] \
    && [[ -f "${PROJECTS}/example-project/docs/tasks/_template.plan.yaml" ]] \
    && [[ -f "${PROJECTS}/example-project/docs/llm-context/_report.md" ]] \
    && [[ -d "${PROJECTS}/example-project/docs/llm-context/history" ]] \
    && [[ -f "${PROJECTS}/example-project/docs/README.md" ]]
}

test_seeds_version() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  local expected
  expected="$(head -1 "${RIBBON_HOME}/VERSION")"
  [[ "$(head -1 "${PROJECTS}/example-project/docs/README.md" 2>/dev/null)" == "${expected}" ]]
}

test_writes_pointer() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  [[ "$(cat "${PROJECTS}/example-project/project-repo" 2>/dev/null)" \
      == "${SANDBOX}/repos/example-project" ]]
}

test_writes_agents_local_md() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/repos/example-project/AGENTS.local.md" ]] \
    && [[ "$(block_count)" == "1" ]] \
    && grep -q "${PROJECTS}/example-project" "${SANDBOX}/repos/example-project/AGENTS.local.md" \
    && grep -q "${SANDBOX}/repos/example-project" "${SANDBOX}/repos/example-project/AGENTS.local.md" \
    && ! grep -q '{{' "${SANDBOX}/repos/example-project/AGENTS.local.md}"
}

test_agents_md_gets_single_pointer() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  install example-project "${SANDBOX}/repos/example-project" --force >/dev/null 2>&1
  [[ "$(grep -c 'AGENTS\.local\.md' "${SANDBOX}/repos/example-project/AGENTS.md")" == "1" ]] \
    && grep -q 'example-project AGENTS' "${SANDBOX}/repos/example-project/AGENTS.md" \
    && [[ "$(grep -c 'ribbon:standalone:start' "${SANDBOX}/repos/example-project/AGENTS.md")" == "0" ]]
}

test_preserves_existing_agents_local_md() {
  new_sandbox
  printf '# my local notes\n' > "${SANDBOX}/repos/example-project/AGENTS.local.md"
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  grep -q 'my local notes' "${SANDBOX}/repos/example-project/AGENTS.local.md" \
    && [[ "$(block_count)" == "1" ]]
}

test_copies_herdr_config() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/repos/example-project/herdr-config.md" ]]
}

test_rerun_keeps_one_block() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  install example-project "${SANDBOX}/repos/example-project" --force >/dev/null 2>&1
  [[ "$(block_count)" == "1" ]]
}

test_requires_projects_flag() {
  new_sandbox
  local without_flag=0 with_env=0
  "${INSTALLER}" example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1 \
    || without_flag=1
  env RIBBON_PROJECTS="${PROJECTS}" \
    "${INSTALLER}" example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1 \
    || with_env=1
  (( without_flag == 1 && with_env == 1 ))
}

test_rejects_invalid_name() {
  new_sandbox
  ! install "Bad Name" "${SANDBOX}/repos/example-project" >/dev/null 2>&1
}

test_rejects_missing_projects_dir() {
  new_sandbox
  rmdir "${PROJECTS}"
  ! install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
}

test_rejects_unwritable_projects_dir() {
  new_sandbox
  chmod 0555 "${PROJECTS}"
  local failed=0
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1 || failed=1
  chmod 0700 "${PROJECTS}"
  (( failed == 1 ))
}

test_rejects_unwritable_repo() {
  new_sandbox
  chmod 0555 "${SANDBOX}/repos/example-project"
  local failed=0
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1 || failed=1
  chmod 0700 "${SANDBOX}/repos/example-project"
  (( failed == 1 ))
}

test_rejects_unwritable_agents_md() {
  new_sandbox
  chmod 0444 "${SANDBOX}/repos/example-project/AGENTS.md"
  local failed=0
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1 || failed=1
  chmod 0644 "${SANDBOX}/repos/example-project/AGENTS.md"
  (( failed == 1 ))
}

test_rejects_unwritable_agents_local_md() {
  new_sandbox
  printf '# my local notes\n' > "${SANDBOX}/repos/example-project/AGENTS.local.md"
  chmod 0444 "${SANDBOX}/repos/example-project/AGENTS.local.md"
  local failed=0
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1 || failed=1
  chmod 0644 "${SANDBOX}/repos/example-project/AGENTS.local.md"
  (( failed == 1 ))
}

test_update_refuses_unwritable_instance() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  chmod 0555 "${PROJECTS}/example-project"
  local failed=0
  install example-project --update >/dev/null 2>&1 || failed=1
  chmod 0700 "${PROJECTS}/example-project"
  (( failed == 1 ))
}

test_rejects_missing_repo() {
  new_sandbox
  ! install example-project "${SANDBOX}/repos/nope" >/dev/null 2>&1
}

test_rejects_repo_without_agents_md() {
  new_sandbox
  mkdir -p "${SANDBOX}/repos/no-agents"
  ! install example-project "${SANDBOX}/repos/no-agents" >/dev/null 2>&1
}

test_refuses_overwrite_without_force() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  ! install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
}

test_force_rebuilds() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" --force >/dev/null 2>&1
  [[ -f "${PROJECTS}/example-project/docs/tasks/README.md" ]]
}

test_update_refuses_missing_instance() {
  new_sandbox
  ! install ghost-project --update "${SANDBOX}/repos/example-project" >/dev/null 2>&1
}

test_update_refreshes_templates() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  echo 'corrupted' > "${PROJECTS}/example-project/docs/tasks/_template.plan.yaml"
  printf 'live plan, do not touch\n' > "${PROJECTS}/example-project/docs/tasks/real-plan.yaml"
  install example-project --update >/dev/null 2>&1
  local template_now template_want
  template_now="$(head -1 "${PROJECTS}/example-project/docs/tasks/_template.plan.yaml")"
  template_want="$(head -1 "${RIBBON_HOME}/docs/tasks/_template.plan.yaml")"
  [[ "${template_now}" == "${template_want}" ]] \
    && [[ "$(cat "${PROJECTS}/example-project/docs/tasks/real-plan.yaml")" \
          == "live plan, do not touch" ]]
}

test_update_rewrites_version() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  install example-project --update >/dev/null 2>&1
  local expected
  expected="$(head -1 "${RIBBON_HOME}/VERSION")"
  [[ "$(head -1 "${PROJECTS}/example-project/docs/README.md")" == "${expected}" ]]
}

test_update_keeps_one_block() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  install example-project --update >/dev/null 2>&1
  [[ "$(block_count)" == "1" ]]
}

test_refuses_force_and_update() {
  new_sandbox
  ! install example-project "${SANDBOX}/repos/example-project" --force --update \
      >/dev/null 2>&1
}

test_usage_without_args() {
  ! "${INSTALLER}" >/dev/null 2>&1
}

readonly TESTS=(
  test_installer_exists
  test_creates_layout
  test_seeds_version
  test_writes_pointer
  test_writes_agents_local_md
  test_agents_md_gets_single_pointer
  test_preserves_existing_agents_local_md
  test_copies_herdr_config
  test_rerun_keeps_one_block
  test_requires_projects_flag
  test_rejects_missing_projects_dir
  test_rejects_unwritable_projects_dir
  test_rejects_unwritable_repo
  test_rejects_unwritable_agents_md
  test_rejects_unwritable_agents_local_md
  test_update_refuses_unwritable_instance
  test_rejects_invalid_name
  test_rejects_missing_repo
  test_rejects_repo_without_agents_md
  test_refuses_overwrite_without_force
  test_force_rebuilds
  test_update_refuses_missing_instance
  test_update_refreshes_templates
  test_update_rewrites_version
  test_update_keeps_one_block
  test_refuses_force_and_update
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
