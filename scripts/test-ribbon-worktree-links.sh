#!/usr/bin/env bash
# Tests for the worktree links of scripts/ribbon-new-project and for
# scripts/ribbon-link-worktree: one function per test, run in order by main.
# Each test builds its own throwaway sandbox with a real git repository (the
# tests that need none excepted) and its own projects dir; the real template
# repo provides the seeds. The git environment is pinned so no user or
# system config leaks into the sandboxes.
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
# Remove the current sandbox, if any, after making it writable again: a
# test may have made a directory read-only (the managed-hooks stand-in).
# Globals:
#   SANDBOX
#######################################
cleanup() {
  [[ -n "${SANDBOX}" ]] || return 0
  chmod -R u+rwX "${SANDBOX}"
  rm -rf "${SANDBOX}"
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
# Create the stand-in for hooks that a tool manages: a read-only directory
# of three stand-in hooks and a gitconfig that points core.hooksPath at it.
# Globals:
#   SANDBOX
#######################################
managed_hooks() {
  mkdir -p "${SANDBOX}/managed-hooks"
  local hook
  for hook in pre-commit pre-push post-checkout; do
    printf '#!/bin/sh\n# a tool manages this hook\nexit 0\n' \
      > "${SANDBOX}/managed-hooks/${hook}"
    chmod 0755 "${SANDBOX}/managed-hooks/${hook}"
  done
  chmod 0555 "${SANDBOX}/managed-hooks"
  printf '[core]\n\thooksPath = %s\n' "${SANDBOX}/managed-hooks" \
    > "${SANDBOX}/managed-gitconfig"
}

#######################################
# Run the installer with the managed-hooks gitconfig as the system
# configuration, so core.hooksPath points at the managed directory and the
# installer leaves the hooks alone.
# Arguments:
#   Remaining installer arguments.
# Globals:
#   SANDBOX, PROJECTS
#######################################
install_with_managed_hooks() {
  env -u GIT_CONFIG_NOSYSTEM GIT_CONFIG_SYSTEM="${SANDBOX}/managed-gitconfig" \
    "${INSTALLER}" --projects "${PROJECTS}" "$@"
}

#######################################
# Add a worktree to the sandbox project under the managed-hooks system
# configuration, so the stand-in post-checkout runs and links nothing.
# Arguments:
#   Branch name, worktree path.
# Globals:
#   SANDBOX, PROJ
#######################################
worktree_add_managed() {
  env -u GIT_CONFIG_NOSYSTEM GIT_CONFIG_SYSTEM="${SANDBOX}/managed-gitconfig" \
    git -C "${PROJ}" -c user.name='Ribbon Test' -c user.email='ribbon@test.invalid' \
    worktree add -q -b "$1" "$2"
}

#######################################
# Run the command under test with its arguments.
# Arguments:
#   Remaining command arguments.
#######################################
link() {
  "${SCRIPT_DIR}/ribbon-link-worktree" "$@"
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

#######################################
# Print the mode of a file as octal digits (GNU or BSD stat).
# Arguments:
#   Path.
#######################################
mode_of() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

#######################################
# Snapshot the three stand-in hooks, bytes and mode, for a later comparison.
# Globals:
#   SANDBOX
#######################################
snapshot_stand_in_hooks() {
  local hook
  for hook in pre-commit pre-push post-checkout; do
    cp -a "${SANDBOX}/managed-hooks/${hook}" "${SANDBOX}/keep-${hook}" || return 1
  done
}

#######################################
# Assert every stand-in hook kept its snapshot's bytes and its 0755 mode.
# Globals:
#   SANDBOX
#######################################
assert_stand_in_hooks_unchanged() {
  local hook
  for hook in pre-commit pre-push post-checkout; do
    cmp -s "${SANDBOX}/managed-hooks/${hook}" "${SANDBOX}/keep-${hook}" || return 1
    [[ "$(mode_of "${SANDBOX}/managed-hooks/${hook}")" = 755 ]] || return 1
  done
}

#######################################
# Run the installer with the managed-hooks gitconfig as the global
# configuration, so core.hooksPath points at the managed directory.
# Arguments:
#   Remaining installer arguments.
# Globals:
#   SANDBOX, PROJECTS
#######################################
install_with_global_managed_hooks() {
  env GIT_CONFIG_GLOBAL="${SANDBOX}/managed-gitconfig" \
    "${INSTALLER}" --projects "${PROJECTS}" "$@"
}

#######################################
# Run the installer with core.hooksPath set through the environment
# (GIT_CONFIG_COUNT), which git reports as the command scope.
# Arguments:
#   Remaining installer arguments.
# Globals:
#   SANDBOX, PROJECTS
#######################################
install_with_environment_hooks() {
  env GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.hooksPath \
    GIT_CONFIG_VALUE_0="${SANDBOX}/env-hooks" \
    "${INSTALLER}" --projects "${PROJECTS}" "$@"
}

#######################################
# Assert the summary holds the worktrees line followed immediately by the
# two worktree links lines of the card.
# Arguments:
#   Summary file, the expected worktrees line.
# Globals:
#   SCRIPT_DIR
#######################################
assert_link_command_after() {
  local block
  block=$(awk '/^  worktrees:/{print; getline; print; getline; print}' "$1")
  local expected="$2
  worktree links:  Ribbon's post-checkout hook is not in place. After each 'git worktree add <path>', run
                   ${SCRIPT_DIR}/ribbon-link-worktree <path>"
  [[ "${block}" = "${expected}" ]]
}

#######################################
# Print the worktree block the installer must append, with the absolute
# path of the command under test in place of {{RIBBON_HOME}}.
# Globals:
#   SCRIPT_DIR
#######################################
expected_worktree_block() {
  cat <<EOF
<!-- ribbon:worktrees:start -->
## Worktrees on this machine

Ribbon's \`post-checkout\` hook was not installed in this repository, so a new \`git worktree\`
gets no links by itself. After each \`git worktree add <path>\`, and before an agent starts in
\`<path>\`, run:

    ${SCRIPT_DIR}/ribbon-link-worktree <path>

It links this checkout's untracked Ribbon files into the new worktree. It changes nothing
that exists.
<!-- ribbon:worktrees:end -->
EOF
}

#######################################
# Count the worktree blocks in a file.
# Arguments:
#   File to inspect.
#######################################
worktree_block_count() {
  grep -c '^<!-- ribbon:worktrees:start -->$' "$1"
}

#######################################
# Print a file from the worktree block's start mark to the end of the file.
# Arguments:
#   File to inspect.
#######################################
worktree_block_tail() {
  awk '/^<!-- ribbon:worktrees:start -->$/{found=1} found{print}' "$1"
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

test_command_links_worktree_added_without_the_hook() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  [[ ! -e "${PROJ}/.git/hooks/post-checkout" ]] || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/wt"
  worktree_add_managed managed "${WT}" || return 1
  [[ ! -e "${WT}/AGENTS.local.md" && ! -e "${WT}/herdr-config.md" \
    && ! -e "${WT}/CLAUDE.md" && ! -e "${WT}/CLAUDE.local.md" ]] || return 1
  link "${WT}" >/dev/null 2>&1 || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.md CLAUDE.local.md
}

test_command_links_local_files_into_linked_worktree() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/wt"
  worktree_add_managed plain "${WT}" || return 1
  local out rc
  out=$(link "${WT}") && rc=0 || rc=$?
  [[ ${rc} -eq 0 ]] || return 1
  [[ "${out}" = "${WT}: worktree links ensured" ]] || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.md CLAUDE.local.md
}

test_command_is_idempotent() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/wt"
  worktree_add_managed twice "${WT}" || return 1
  local first second rc
  first=$(link "${WT}") || return 1
  second=$(link "${WT}") && rc=0 || rc=$?
  [[ ${rc} -eq 0 && "${second}" = "${first}" ]] || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.md CLAUDE.local.md
}

test_command_keeps_tracked_file() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  gitc add CLAUDE.md
  gitc commit -q -m 'track CLAUDE.md' || return 1
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/wt"
  worktree_add_managed tracked "${WT}" || return 1
  link "${WT}" >/dev/null 2>&1 || return 1
  [[ -f "${WT}/CLAUDE.md" && ! -L "${WT}/CLAUDE.md" ]] || return 1
  [[ "$(cat "${WT}/CLAUDE.md")" = '# claude' ]] || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.local.md
}

test_command_leaves_existing_link_alone() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/wt"
  worktree_add_managed dangling "${WT}" || return 1
  ln -s "${PROJ}/no-such-file" "${WT}/CLAUDE.local.md" || return 1
  link "${WT}" >/dev/null 2>&1 || return 1
  [[ "$(readlink "${WT}/CLAUDE.local.md")" = "${PROJ}/no-such-file" ]] || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.md
}

test_command_skips_absent_local_file() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/wt"
  worktree_add_managed absent "${WT}" || return 1
  link "${WT}" >/dev/null 2>&1 || return 1
  [[ ! -e "${WT}/CLAUDE.md" && ! -L "${WT}/CLAUDE.md" ]] || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.local.md
}

test_command_on_main_checkout_links_nothing() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  local out rc
  out=$(link "${PROJ}") && rc=0 || rc=$?
  [[ ${rc} -eq 0 ]] || return 1
  [[ "${out}" = "${PROJ}: main checkout, nothing to link" ]] || return 1
  [[ -f "${PROJ}/AGENTS.local.md" && ! -L "${PROJ}/AGENTS.local.md" ]] || return 1
  [[ -f "${PROJ}/herdr-config.md" && ! -L "${PROJ}/herdr-config.md" ]] || return 1
  [[ ! -e "${PROJ}/CLAUDE.md" && ! -L "${PROJ}/CLAUDE.md" ]] || return 1
  [[ ! -e "${PROJ}/CLAUDE.local.md" && ! -L "${PROJ}/CLAUDE.local.md" ]]
}

test_command_from_subdirectory_links_worktree_root() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/wt"
  worktree_add_managed subdir "${WT}" || return 1
  mkdir -p "${WT}/sub" || return 1
  local out rc
  out=$(link "${WT}/sub") && rc=0 || rc=$?
  [[ ${rc} -eq 0 && "${out}" = "${WT}: worktree links ensured" ]] || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.md CLAUDE.local.md || return 1
  [[ ! -e "${WT}/sub/CLAUDE.md" && ! -L "${WT}/sub/CLAUDE.md" ]]
}

test_command_with_space_in_path_gets_links() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '# claude\n' > "${PROJ}/CLAUDE.md"
  printf '# claude local\n' > "${PROJ}/CLAUDE.local.md"
  WT="${SANDBOX}/my worktree"
  worktree_add_managed spaced "${WT}" || return 1
  local out rc
  out=$(link "${WT}") && rc=0 || rc=$?
  [[ ${rc} -eq 0 && "${out}" = "${WT}: worktree links ensured" ]] || return 1
  assert_linked AGENTS.local.md herdr-config.md CLAUDE.md CLAUDE.local.md
}

test_command_without_argument_prints_usage() {
  cleanup
  SANDBOX="$(mktemp -d)"
  local out rc
  out=$(link 2>"${SANDBOX}/err") && rc=0 || rc=$?
  [[ ${rc} -eq 1 && -z "${out}" ]] || return 1
  [[ "$(cat "${SANDBOX}/err")" \
    = 'ribbon-link-worktree: usage: ribbon-link-worktree <worktree-path>' ]]
}

test_command_with_two_arguments_prints_usage() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  WT="${SANDBOX}/wt"
  worktree_add_managed two "${WT}" || return 1
  local out rc f
  out=$(link "${WT}" "${PROJ}" 2>"${SANDBOX}/err") && rc=0 || rc=$?
  [[ ${rc} -eq 1 && -z "${out}" ]] || return 1
  [[ "$(cat "${SANDBOX}/err")" \
    = 'ribbon-link-worktree: usage: ribbon-link-worktree <worktree-path>' ]] || return 1
  for f in AGENTS.local.md herdr-config.md CLAUDE.md CLAUDE.local.md; do
    [[ ! -e "${WT}/${f}" && ! -L "${WT}/${f}" ]] || return 1
  done
}

test_command_h_prints_usage() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  WT="${SANDBOX}/wt"
  worktree_add_managed help "${WT}" || return 1
  local expected='Usage:
  ribbon-link-worktree <worktree-path>'
  local out rc f
  out=$(cd "${WT}" && link -h 2>"${SANDBOX}/err-h") && rc=0 || rc=$?
  [[ ${rc} -eq 0 && ! -s "${SANDBOX}/err-h" ]] || return 1
  [[ "${out}" = "${expected}" ]] || return 1
  for f in AGENTS.local.md herdr-config.md CLAUDE.md CLAUDE.local.md; do
    [[ ! -e "${WT}/${f}" && ! -L "${WT}/${f}" ]] || return 1
  done
  out=$(link --help 2>"${SANDBOX}/err-help") && rc=0 || rc=$?
  [[ ${rc} -eq 0 && ! -s "${SANDBOX}/err-help" ]] || return 1
  [[ "${out}" = "${expected}" ]]
}

test_command_rejects_path_that_is_not_a_directory() {
  cleanup
  SANDBOX="$(mktemp -d)"
  printf 'plain\n' > "${SANDBOX}/plain-file"
  local out rc
  out=$(link "${SANDBOX}/plain-file" 2>"${SANDBOX}/err") && rc=0 || rc=$?
  [[ ${rc} -eq 1 && -z "${out}" ]] || return 1
  [[ "$(cat "${SANDBOX}/err")" \
    = "ribbon-link-worktree: not a directory: ${SANDBOX}/plain-file" ]]
}

test_command_rejects_path_outside_git_repository() {
  cleanup
  SANDBOX="$(mktemp -d)"
  mkdir -p "${SANDBOX}/nogit"
  local out rc
  out=$(link "${SANDBOX}/nogit" 2>"${SANDBOX}/err") && rc=0 || rc=$?
  [[ ${rc} -eq 1 && -z "${out}" ]] || return 1
  [[ "$(cat "${SANDBOX}/err")" \
    = "ribbon-link-worktree: not a git worktree: ${SANDBOX}/nogit" ]]
}

test_command_reports_missing_hook_file_beside_it() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  WT="${SANDBOX}/wt"
  worktree_add_managed lonely "${WT}" || return 1
  mkdir -p "${SANDBOX}/lonely"
  cp "${SCRIPT_DIR}/ribbon-link-worktree" "${SANDBOX}/lonely/ribbon-link-worktree" \
    || return 1
  local out rc
  out=$("${SANDBOX}/lonely/ribbon-link-worktree" "${WT}" 2>"${SANDBOX}/err") \
    && rc=0 || rc=$?
  [[ ${rc} -eq 1 && -z "${out}" ]] || return 1
  [[ "$(cat "${SANDBOX}/err")" \
    = 'ribbon-link-worktree: cannot find standalone-post-checkout beside this command' ]]
}

test_command_rejects_an_unknown_option() {
  cleanup
  SANDBOX="$(mktemp -d)"
  local out rc
  out=$(link -x 2>"${SANDBOX}/err") && rc=0 || rc=$?
  [[ ${rc} -eq 1 && -z "${out}" ]] || return 1
  [[ "$(cat "${SANDBOX}/err")" \
    = 'ribbon-link-worktree: usage: ribbon-link-worktree <worktree-path>' ]]
}

test_command_exits_with_the_hook_file_status() {
  new_sandbox
  WT="${SANDBOX}/wt"
  gitc worktree add -q -b failing "${WT}" || return 1
  mkdir -p "${SANDBOX}/failing"
  cp "${SCRIPT_DIR}/ribbon-link-worktree" "${SANDBOX}/failing/ribbon-link-worktree" \
    || return 1
  printf '#!/bin/sh\nexit 3\n' > "${SANDBOX}/failing/standalone-post-checkout"
  local out rc
  out=$("${SANDBOX}/failing/ribbon-link-worktree" "${WT}" 2>"${SANDBOX}/err") \
    && rc=0 || rc=$?
  [[ ${rc} -eq 3 && -z "${out}" ]]
}

test_install_with_system_managed_hooks_leaves_every_hook_unchanged() {
  new_sandbox
  managed_hooks
  snapshot_stand_in_hooks || return 1
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  assert_stand_in_hooks_unchanged || return 1
  [[ ! -e "${PROJ}/.git/hooks/post-checkout" ]]
}

test_update_with_system_managed_hooks_leaves_every_hook_unchanged() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  snapshot_stand_in_hooks || return 1
  install_with_managed_hooks --update example-project >/dev/null 2>&1 || return 1
  assert_stand_in_hooks_unchanged || return 1
  [[ ! -e "${PROJ}/.git/hooks/post-checkout" ]]
}

test_install_with_global_managed_hooks_leaves_every_hook_unchanged() {
  new_sandbox
  managed_hooks
  snapshot_stand_in_hooks || return 1
  install_with_global_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 \
    || return 1
  assert_stand_in_hooks_unchanged
}

test_update_leaves_a_stale_ribbon_hook_unchanged() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  local hook="${PROJ}/.git/hooks/post-checkout"
  cp -a "${hook}" "${SANDBOX}/stale-hook-copy" || return 1
  managed_hooks
  install_with_managed_hooks --update example-project >/dev/null 2>&1 || return 1
  cmp -s "${hook}" "${SANDBOX}/stale-hook-copy"
}

test_system_hooks_path_is_reported_with_scope_and_file() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 \
    || return 1
  grep -qxF "  worktrees:       core.hooksPath points elsewhere — left as is, post-checkout hook not installed (core.hooksPath=${SANDBOX}/managed-hooks, system, file:${SANDBOX}/managed-gitconfig)" \
    "${SANDBOX}/summary.txt"
}

test_global_hooks_path_is_reported_with_scope_and_file() {
  new_sandbox
  managed_hooks
  install_with_global_managed_hooks example-project "${PROJ}" \
    > "${SANDBOX}/summary.txt" 2>&1 || return 1
  grep -qxF "  worktrees:       core.hooksPath points elsewhere — left as is, post-checkout hook not installed (core.hooksPath=${SANDBOX}/managed-hooks, global, file:${SANDBOX}/managed-gitconfig)" \
    "${SANDBOX}/summary.txt"
}

test_local_hooks_path_is_reported_with_scope_and_file() {
  new_sandbox
  gitc config core.hooksPath "${SANDBOX}/local-hooks" || return 1
  install example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 || return 1
  grep -qxF "  worktrees:       core.hooksPath points elsewhere — left as is, post-checkout hook not installed (core.hooksPath=${SANDBOX}/local-hooks, local, file:.git/config)" \
    "${SANDBOX}/summary.txt"
}

test_environment_hooks_path_is_reported_as_command_scope() {
  new_sandbox
  install_with_environment_hooks example-project "${PROJ}" > "${SANDBOX}/summary.txt" \
    2>&1 || return 1
  grep -qxF "  worktrees:       core.hooksPath points elsewhere — left as is, post-checkout hook not installed (core.hooksPath=${SANDBOX}/env-hooks, command)" \
    "${SANDBOX}/summary.txt"
}

test_hooks_path_with_space_is_reported_whole() {
  new_sandbox
  printf '[core]\n\thooksPath = %s\n' "${SANDBOX}/hooks with space" \
    > "${SANDBOX}/spaced-gitconfig"
  env -u GIT_CONFIG_NOSYSTEM GIT_CONFIG_SYSTEM="${SANDBOX}/spaced-gitconfig" \
    "${INSTALLER}" --projects "${PROJECTS}" example-project "${PROJ}" \
    > "${SANDBOX}/summary.txt" 2>&1 || return 1
  grep -qxF "  worktrees:       core.hooksPath points elsewhere — left as is, post-checkout hook not installed (core.hooksPath=${SANDBOX}/hooks with space, system, file:${SANDBOX}/spaced-gitconfig)" \
    "${SANDBOX}/summary.txt"
}

test_managed_hooks_summary_prints_the_link_command() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 \
    || return 1
  assert_link_command_after "${SANDBOX}/summary.txt" \
    "  worktrees:       core.hooksPath points elsewhere — left as is, post-checkout hook not installed (core.hooksPath=${SANDBOX}/managed-hooks, system, file:${SANDBOX}/managed-gitconfig)"
}

test_unwritable_hooks_directory_prints_the_link_command() {
  new_sandbox
  chmod 0555 "${PROJ}/.git/hooks" || return 1
  install example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 || return 1
  [[ ! -e "${PROJ}/.git/hooks/post-checkout" ]] || return 1
  assert_link_command_after "${SANDBOX}/summary.txt" \
    '  worktrees:       hooks directory not writable — post-checkout hook not installed'
}

test_read_only_ribbon_hook_prints_the_link_command() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  local hook="${PROJ}/.git/hooks/post-checkout"
  cp -a "${hook}" "${SANDBOX}/readonly-copy" || return 1
  chmod 0555 "${hook}" || return 1
  install --update example-project > "${SANDBOX}/summary.txt" 2>&1 || return 1
  cmp -s "${hook}" "${SANDBOX}/readonly-copy" || return 1
  assert_link_command_after "${SANDBOX}/summary.txt" \
    '  worktrees:       post-checkout hook could not be written — left as is'
}

test_foreign_hook_note_is_followed_by_the_link_command() {
  new_sandbox
  printf '#!/bin/sh\n# some other tool owns this hook\nexit 0\n' \
    > "${PROJ}/.git/hooks/post-checkout"
  cp -a "${PROJ}/.git/hooks/post-checkout" "${SANDBOX}/foreign-copy" || return 1
  install example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 || return 1
  cmp -s "${PROJ}/.git/hooks/post-checkout" "${SANDBOX}/foreign-copy" || return 1
  assert_link_command_after "${SANDBOX}/summary.txt" \
    '  worktrees:       existing post-checkout hook left unchanged — no ribbon mark'
}

test_summary_with_ribbon_hook_has_no_link_command_line() {
  new_sandbox
  install example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 || return 1
  [[ -f "${PROJ}/.git/hooks/post-checkout" ]] || return 1
  ! grep -q 'worktree links:' "${SANDBOX}/summary.txt"
}

test_summary_without_a_repository_has_no_link_command_line() {
  cleanup
  SANDBOX="$(mktemp -d)"
  mkdir -p "${SANDBOX}/ribbon-projects" "${SANDBOX}/repos/example-project"
  printf '# example-project AGENTS\n' > "${SANDBOX}/repos/example-project/AGENTS.md"
  PROJECTS="${SANDBOX}/ribbon-projects"
  PROJ="${SANDBOX}/repos/example-project"
  WT=''
  install example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 || return 1
  ! grep -q 'worktree links:' "${SANDBOX}/summary.txt"
}

test_summary_outside_the_main_worktree_has_no_link_command_line() {
  new_sandbox
  WT="${SANDBOX}/example-wt"
  gitc worktree add -q -b wt-elsewhere "${WT}" || return 1
  WT=''
  install example-project "${SANDBOX}/example-wt" > "${SANDBOX}/summary.txt" 2>&1 \
    || return 1
  ! grep -q 'worktree links:' "${SANDBOX}/summary.txt"
}

test_hooks_directory_that_cannot_be_created_prints_the_link_command() {
  new_sandbox
  rm -rf "${PROJ}/.git/hooks"
  chmod 0555 "${PROJ}/.git" || return 1
  install example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 || return 1
  [[ ! -e "${PROJ}/.git/hooks/post-checkout" ]] || return 1
  assert_link_command_after "${SANDBOX}/summary.txt" \
    '  worktrees:       hooks directory missing and cannot be created — post-checkout hook not installed'
}

test_summary_with_ribbon_hook_keeps_its_shape() {
  new_sandbox
  install example-project "${PROJ}" > "${SANDBOX}/summary.txt" 2>&1 || return 1
  [[ -f "${PROJ}/.git/hooks/post-checkout" ]] || return 1
  local blank next
  blank=$(awk '/^  worktrees:/{getline; print; exit}' "${SANDBOX}/summary.txt")
  next=$(awk '/^  worktrees:/{getline; getline; print; exit}' "${SANDBOX}/summary.txt")
  [[ -z "${blank}" ]] || return 1
  [[ "${next}" = 'Next: read the protocol at '* ]]
}

test_install_without_hook_appends_the_worktree_block() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  [[ "$(worktree_block_count "${PROJ}/AGENTS.local.md")" == "1" ]] || return 1
  [[ "$(worktree_block_tail "${PROJ}/AGENTS.local.md")" = "$(expected_worktree_block)" ]]
}

test_update_appends_a_missing_worktree_block_without_rewriting_bytes() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  printf '%s' "$(cat "${PROJ}/AGENTS.local.md")" > "${SANDBOX}/aged-agents-local"
  cp "${SANDBOX}/aged-agents-local" "${PROJ}/AGENTS.local.md" || return 1
  managed_hooks
  install_with_managed_hooks --update example-project >/dev/null 2>&1 || return 1
  local bytes
  bytes=$(wc -c < "${SANDBOX}/aged-agents-local")
  head -c "${bytes}" "${PROJ}/AGENTS.local.md" | cmp -s "${SANDBOX}/aged-agents-local" - \
    || return 1
  [[ "$(worktree_block_count "${PROJ}/AGENTS.local.md")" == "1" ]] || return 1
  [[ "$(worktree_block_tail "${PROJ}/AGENTS.local.md")" = "$(expected_worktree_block)" ]]
}

test_update_keeps_one_worktree_block() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  install_with_managed_hooks --update example-project >/dev/null 2>&1 || return 1
  [[ "$(worktree_block_count "${PROJ}/AGENTS.local.md")" == "1" ]]
}

test_install_with_ribbon_hook_writes_no_worktree_block() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  [[ -f "${PROJ}/.git/hooks/post-checkout" ]] || return 1
  ! grep -q '<!-- ribbon:worktrees:start -->' "${PROJ}/AGENTS.local.md"
}

test_update_refuses_the_worktree_block_through_an_agents_alias() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  mv "${PROJ}/AGENTS.local.md" "${PROJ}/CLAUDE.local.md"
  ln -s CLAUDE.local.md "${PROJ}/AGENTS.local.md" || return 1
  cp -a "${PROJ}/CLAUDE.local.md" "${SANDBOX}/claude-local-copy" || return 1
  managed_hooks
  local rc
  install_with_managed_hooks --update example-project \
    > "${SANDBOX}/out.txt" 2> "${SANDBOX}/err.txt" && rc=0 || rc=$?
  [[ ${rc} -eq 1 ]] || return 1
  grep -qF 'AGENTS.local.md aliases CLAUDE.local.md; refusing to write it' \
    "${SANDBOX}/err.txt" || return 1
  cmp -s "${PROJ}/CLAUDE.local.md" "${SANDBOX}/claude-local-copy"
}

test_pointer_without_hook_tells_where_to_read_the_local_files() {
  new_sandbox
  managed_hooks
  install_with_managed_hooks example-project "${PROJ}" >/dev/null 2>&1 || return 1
  grep -qxF "Ribbon Protocol (standalone): this machine's working files live outside this repository; read AGENTS.local.md for where each file lives. In a linked worktree where that file is missing, read it in the repository's main worktree (the first path in \`git worktree list --porcelain\`) and report the missing worktree links before you work." \
    "${PROJ}/AGENTS.md" || return 1
  [[ "$(grep -c 'AGENTS\.local\.md' "${PROJ}/AGENTS.md")" == "1" ]]
}

test_pointer_with_ribbon_hook_is_unchanged() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  grep -qxF "Ribbon Protocol (standalone): this machine's working files live outside this repository; read AGENTS.local.md for where each file lives." \
    "${PROJ}/AGENTS.md"
}

test_install_with_unwritable_hooks_directory_appends_the_worktree_block() {
  new_sandbox
  chmod 0555 "${PROJ}/.git/hooks" || return 1
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  [[ "$(worktree_block_count "${PROJ}/AGENTS.local.md")" == "1" ]] || return 1
  [[ "$(worktree_block_tail "${PROJ}/AGENTS.local.md")" = "$(expected_worktree_block)" ]]
}

test_update_with_read_only_ribbon_hook_appends_the_worktree_block() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  chmod 0555 "${PROJ}/.git/hooks/post-checkout" || return 1
  install --update example-project >/dev/null 2>&1 || return 1
  [[ "$(worktree_block_count "${PROJ}/AGENTS.local.md")" == "1" ]] || return 1
  [[ "$(worktree_block_tail "${PROJ}/AGENTS.local.md")" = "$(expected_worktree_block)" ]]
}

test_update_with_a_present_block_leaves_an_agents_alias_alone() {
  new_sandbox
  install example-project "${PROJ}" >/dev/null 2>&1 || return 1
  managed_hooks
  install_with_managed_hooks --update example-project >/dev/null 2>&1 || return 1
  [[ "$(worktree_block_count "${PROJ}/AGENTS.local.md")" == "1" ]] || return 1
  mv "${PROJ}/AGENTS.local.md" "${PROJ}/CLAUDE.local.md"
  ln -s CLAUDE.local.md "${PROJ}/AGENTS.local.md" || return 1
  cp -a "${PROJ}/CLAUDE.local.md" "${SANDBOX}/claude-local-copy" || return 1
  local rc
  install_with_managed_hooks --update example-project \
    > "${SANDBOX}/out.txt" 2> "${SANDBOX}/err.txt" && rc=0 || rc=$?
  [[ ${rc} -eq 0 ]] || return 1
  cmp -s "${PROJ}/CLAUDE.local.md" "${SANDBOX}/claude-local-copy" || return 1
  [[ -L "${PROJ}/AGENTS.local.md" ]] || return 1
  [[ "$(readlink "${PROJ}/AGENTS.local.md")" = 'CLAUDE.local.md' ]]
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
  test_command_links_worktree_added_without_the_hook
  test_command_links_local_files_into_linked_worktree
  test_command_is_idempotent
  test_command_keeps_tracked_file
  test_command_leaves_existing_link_alone
  test_command_skips_absent_local_file
  test_command_on_main_checkout_links_nothing
  test_command_from_subdirectory_links_worktree_root
  test_command_with_space_in_path_gets_links
  test_command_without_argument_prints_usage
  test_command_with_two_arguments_prints_usage
  test_command_h_prints_usage
  test_command_rejects_path_that_is_not_a_directory
  test_command_rejects_path_outside_git_repository
  test_command_reports_missing_hook_file_beside_it
  test_command_rejects_an_unknown_option
  test_command_exits_with_the_hook_file_status
  test_install_with_system_managed_hooks_leaves_every_hook_unchanged
  test_update_with_system_managed_hooks_leaves_every_hook_unchanged
  test_install_with_global_managed_hooks_leaves_every_hook_unchanged
  test_update_leaves_a_stale_ribbon_hook_unchanged
  test_system_hooks_path_is_reported_with_scope_and_file
  test_global_hooks_path_is_reported_with_scope_and_file
  test_local_hooks_path_is_reported_with_scope_and_file
  test_environment_hooks_path_is_reported_as_command_scope
  test_hooks_path_with_space_is_reported_whole
  test_managed_hooks_summary_prints_the_link_command
  test_unwritable_hooks_directory_prints_the_link_command
  test_read_only_ribbon_hook_prints_the_link_command
  test_foreign_hook_note_is_followed_by_the_link_command
  test_summary_with_ribbon_hook_has_no_link_command_line
  test_summary_without_a_repository_has_no_link_command_line
  test_summary_outside_the_main_worktree_has_no_link_command_line
  test_hooks_directory_that_cannot_be_created_prints_the_link_command
  test_summary_with_ribbon_hook_keeps_its_shape
  test_install_without_hook_appends_the_worktree_block
  test_update_appends_a_missing_worktree_block_without_rewriting_bytes
  test_update_keeps_one_worktree_block
  test_install_with_ribbon_hook_writes_no_worktree_block
  test_update_refuses_the_worktree_block_through_an_agents_alias
  test_pointer_without_hook_tells_where_to_read_the_local_files
  test_pointer_with_ribbon_hook_is_unchanged
  test_install_with_unwritable_hooks_directory_appends_the_worktree_block
  test_update_with_read_only_ribbon_hook_appends_the_worktree_block
  test_update_with_a_present_block_leaves_an_agents_alias_alone
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
