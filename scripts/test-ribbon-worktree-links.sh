#!/usr/bin/env bash
# Tests for the worktree links of scripts/ribbon-new-project: one function
# per test, run in order by main. Each test builds its own throwaway sandbox
# with a real git repository (the non-git test excepted) and its own projects
# dir; the real template repo provides the seeds. The git environment is
# pinned so no user or system config leaks into the sandboxes.
set -u

export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER="${SCRIPT_DIR}/ribbon-new-project"
HOOK_TEMPLATE="${SCRIPT_DIR}/standalone-post-checkout"
readonly SCRIPT_DIR INSTALLER HOOK_TEMPLATE

PASS=0
FAIL=0
SANDBOX=''
PROJECTS=''
PROJ=''
WT=''

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
# Replace the sandbox with a fresh one: projects dir plus one project repo
# with a minimal committed AGENTS.md.
# Globals:
#   SANDBOX, PROJECTS, PROJ, WT (set)
#######################################
new_sandbox() {
  cleanup
  SANDBOX="$(mktemp -d)"
  mkdir -p "${SANDBOX}/ribbon-projects" "${SANDBOX}/repos/example-project"
  printf '# example-project AGENTS\n' > "${SANDBOX}/repos/example-project/AGENTS.md"
  PROJECTS="${SANDBOX}/ribbon-projects"
  PROJ="${SANDBOX}/repos/example-project"
  WT=''
  git -C "${PROJ}" init -q -b main
  gitc add AGENTS.md
  gitc commit -q -m 'root'
}

#######################################
# Run git in the sandbox project repo, committing as a pinned identity.
# Arguments:
#   Remaining git arguments.
#######################################
gitc() {
  git -C "${PROJ}" -c user.name='Ribbon Test' -c user.email='ribbon@test.invalid' "$@"
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
# Assert every named local file is a symlink in the worktree to its
# absolute main-checkout path.
# Arguments:
#   File names to check, relative to the worktree root.
# Globals:
#   WT, PROJ
#######################################
assert_linked() {
  local f
  for f in "$@"; do
    [[ -L "${WT}/${f}" ]] || return 1
    [[ "$(readlink "${WT}/${f}")" = "${PROJ}/${f}" ]] || return 1
  done
}

test_install_writes_managed_hook() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  local hook="${PROJ}/.git/hooks/post-checkout"
  [[ -f "${hook}" ]] || return 1
  [[ -x "${hook}" ]] || return 1
  cmp -s "${hook}" "${HOOK_TEMPLATE}"
}

test_worktree_gets_links_to_local_files() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/wt"
  gitc worktree add -q -b links "${WT}" || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.md CLAUDE.local.md
}

test_worktree_keeps_tracked_file() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  gitc add CLAUDE.md
  gitc commit -q -m 'track CLAUDE.md' || return 1
  WT="${SANDBOX}/wt"
  gitc worktree add -q -b tracked "${WT}" || return 1
  [[ -f "${WT}/CLAUDE.md" && ! -L "${WT}/CLAUDE.md" ]] || return 1
  [[ "$(cat "${WT}/CLAUDE.md")" = '# claude' ]] || return 1
  assert_linked AGENTS.local.md herdr-config.md
}

test_worktree_skips_absent_local_file() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/wt"
  gitc worktree add -q -b absent "${WT}" || return 1
  [[ ! -e "${WT}/CLAUDE.md" && ! -L "${WT}/CLAUDE.md" ]] || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.local.md
}

test_worktree_status_clean_when_files_ignored() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf 'AGENTS.local.md\nherdr-config.md\nCLAUDE.md\nCLAUDE.local.md\n' > "${PROJ}/.gitignore"
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  gitc add -A
  gitc commit -q -m 'ignore local files' || return 1
  WT="${SANDBOX}/wt"
  gitc worktree add -q -b ignored "${WT}" || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.md CLAUDE.local.md || return 1
  [[ -z "$(git -C "${WT}" status --porcelain)" ]]
}

test_main_checkout_gets_no_links() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  gitc switch -q -c elsewhere || return 1
  [[ -f "${PROJ}/AGENTS.local.md" && ! -L "${PROJ}/AGENTS.local.md" ]] || return 1
  [[ -f "${PROJ}/herdr-config.md" && ! -L "${PROJ}/herdr-config.md" ]] || return 1
  [[ ! -e "${PROJ}/CLAUDE.local.md" && ! -L "${PROJ}/CLAUDE.local.md" ]]
}

test_worktree_path_with_space_gets_links() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/my worktree"
  gitc worktree add -q -b spaced "${WT}" || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.md CLAUDE.local.md
}

test_hook_leaves_existing_link_alone() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  WT="${SANDBOX}/wt"
  gitc worktree add -q -b dangling "${WT}" || return 1
  [[ -L "${WT}/CLAUDE.md" ]] || return 1
  rm "${WT}/CLAUDE.md"
  ln -s "${PROJ}/no-such-file" "${WT}/CLAUDE.md" || return 1
  git -C "${WT}" switch -q -c again || return 1
  [[ "$(readlink "${WT}/CLAUDE.md")" = "${PROJ}/no-such-file" ]]
}

test_foreign_hook_left_unchanged_and_reported() {
  new_sandbox
  mkdir -p "${PROJ}/.git/hooks"
  printf '#!/bin/sh\n# some other tool owns this hook\nexit 0\n' \
    > "${PROJ}/.git/hooks/post-checkout"
  cp "${PROJ}/.git/hooks/post-checkout" "${SANDBOX}/foreign-hook-copy"
  install example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 || return 1
  cmp -s "${PROJ}/.git/hooks/post-checkout" "${SANDBOX}/foreign-hook-copy" \
    || return 1
  [[ ! -x "${PROJ}/.git/hooks/post-checkout" ]] || return 1
  grep -q 'existing post-checkout hook left unchanged' "${SANDBOX}/summary.txt"
}

test_update_refreshes_managed_hook() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  local hook="${PROJ}/.git/hooks/post-checkout"
  printf '# tampered line\n' >> "${hook}"
  install --update example-project > "${SANDBOX}/summary.txt" 2>&1 || return 1
  cmp -s "${hook}" "${HOOK_TEMPLATE}" || return 1
  [[ -x "${hook}" ]] || return 1
  grep -q 'post-checkout hook refreshed' "${SANDBOX}/summary.txt"
}

test_update_installs_missing_hook() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  local hook="${PROJ}/.git/hooks/post-checkout"
  rm "${hook}"
  install --update example-project > "${SANDBOX}/summary.txt" 2>&1 || return 1
  [[ -f "${hook}" ]] || return 1
  [[ -x "${hook}" ]] || return 1
  cmp -s "${hook}" "${HOOK_TEMPLATE}"
}

test_update_reports_unwritable_managed_hook() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  local hook="${PROJ}/.git/hooks/post-checkout"
  cp "${hook}" "${SANDBOX}/readonly-hook-copy"
  chmod 0555 "${hook}"
  install --update example-project > "${SANDBOX}/summary.txt" 2>&1 || return 1
  cmp -s "${hook}" "${SANDBOX}/readonly-hook-copy" || return 1
  grep -q 'could not be written' "${SANDBOX}/summary.txt" || return 1
  chmod 0755 "${hook}"
}

test_non_git_project_installs_without_hook() {
  cleanup
  SANDBOX="$(mktemp -d)"
  mkdir -p "${SANDBOX}/ribbon-projects" "${SANDBOX}/repos/example-project"
  printf '# example-project AGENTS\n' > "${SANDBOX}/repos/example-project/AGENTS.md"
  PROJECTS="${SANDBOX}/ribbon-projects"
  PROJ="${SANDBOX}/repos/example-project"
  WT=''
  install example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 || return 1
  [[ -f "${PROJ}/AGENTS.local.md" ]] || return 1
  [[ ! -e "${PROJ}/.git" ]] || return 1
  grep -q 'no git repository' "${SANDBOX}/summary.txt"
}

test_custom_hooks_path_left_alone() {
  new_sandbox
  gitc config core.hooksPath "${SANDBOX}/custom-hooks" || return 1
  install example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 || return 1
  [[ ! -e "${SANDBOX}/custom-hooks" ]] || return 1
  [[ ! -e "${PROJ}/.git/hooks/post-checkout" ]] || return 1
  grep -q 'core.hooksPath' "${SANDBOX}/summary.txt"
}

test_subdirectory_project_gets_no_hook() {
  new_sandbox
  mkdir -p "${PROJ}/subdir"
  printf '# subdir AGENTS\n' > "${PROJ}/subdir/AGENTS.md"
  install example-project "${PROJ}/subdir" > "${SANDBOX}/summary.txt" 2>&1 \
    || return 1
  [[ ! -e "${PROJ}/.git/hooks/post-checkout" ]] || return 1
  grep -q "not the repository's main worktree" "${SANDBOX}/summary.txt"
}

test_linked_worktree_project_gets_no_hook() {
  new_sandbox
  WT="${SANDBOX}/example-wt"
  gitc worktree add -q -b wt-main "${WT}" || return 1
  WT=''
  install example-project "${SANDBOX}/example-wt" > "${SANDBOX}/summary.txt" \
    2>&1 || return 1
  [[ ! -e "${PROJ}/.git/hooks/post-checkout" ]] || return 1
  grep -q "not the repository's main worktree" "${SANDBOX}/summary.txt"
}

TESTS=(
  test_install_writes_managed_hook
  test_worktree_gets_links_to_local_files
  test_worktree_keeps_tracked_file
  test_worktree_skips_absent_local_file
  test_worktree_status_clean_when_files_ignored
  test_main_checkout_gets_no_links
  test_worktree_path_with_space_gets_links
  test_hook_leaves_existing_link_alone
  test_foreign_hook_left_unchanged_and_reported
  test_update_refreshes_managed_hook
  test_update_installs_missing_hook
  test_update_reports_unwritable_managed_hook
  test_non_git_project_installs_without_hook
  test_custom_hooks_path_left_alone
  test_subdirectory_project_gets_no_hook
  test_linked_worktree_project_gets_no_hook
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
