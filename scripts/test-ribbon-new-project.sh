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
  mkdir -p "${SANDBOX}/home" "${SANDBOX}/ribbon-projects" "${SANDBOX}/repos/example-project"
  printf '# example-project AGENTS\n' > "${SANDBOX}/repos/example-project/AGENTS.md"
  PROJECTS="${SANDBOX}/ribbon-projects"
  export HOME="${SANDBOX}/home"
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

#######################################
# Count the belt marks in the project AGENTS.local.md.
# Arguments:
#   1: the belt mark text to count.
# Outputs:
#   The mark count on stdout.
#######################################
belt_count() {
  grep -c "$1" "${SANDBOX}/repos/example-project/AGENTS.local.md" 2>/dev/null || true
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

test_install_appends_to_agents_files_without_rewriting_bytes() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" name bytes
  for name in AGENTS.md AGENTS.local.md; do
    printf '# Existing %s\r\nNo trailing newline' "${name}" > "${SANDBOX}/${name}"
    cp "${SANDBOX}/${name}" "${repo}/${name}"
  done

  install example-project "${repo}" >/dev/null 2>&1 || return 1

  for name in AGENTS.md AGENTS.local.md; do
    bytes="$(wc -c < "${SANDBOX}/${name}")"
    head -c "$((bytes))" "${repo}/${name}" | cmp -s "${SANDBOX}/${name}" - || return 1
  done
  grep -Fq 'read AGENTS.local.md' "${repo}/AGENTS.md" && [[ "$(block_count)" == "1" ]]
}

test_update_warns_for_unlinked_claude_files_without_editing_them() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  printf '# Existing shared Claude rules\r\nNo final newline' > "${SANDBOX}/CLAUDE.md"
  printf '# Existing local Claude rules' > "${SANDBOX}/CLAUDE.local.md"
  cp "${SANDBOX}/CLAUDE.md" "${SANDBOX}/CLAUDE.local.md" "${repo}/"

  install example-project --update > /dev/null 2> "${SANDBOX}/warnings" || return 1

  cmp -s "${SANDBOX}/CLAUDE.md" "${repo}/CLAUDE.md" \
    && cmp -s "${SANDBOX}/CLAUDE.local.md" "${repo}/CLAUDE.local.md" \
    && grep -Fq 'warning: CLAUDE.md does not point to AGENTS.md' "${SANDBOX}/warnings" \
    && grep -Fq 'warning: CLAUDE.local.md does not point to AGENTS.local.md' "${SANDBOX}/warnings"
}

test_install_does_not_warn_for_linked_claude_files() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  printf '@./AGENTS.md\n' > "${repo}/CLAUDE.md"
  ln -s AGENTS.local.md "${repo}/CLAUDE.local.md"

  install example-project "${repo}" > /dev/null 2> "${SANDBOX}/warnings" || return 1

  ! grep -E '^warning: CLAUDE(\.local)?\.md ' "${SANDBOX}/warnings"
}

test_copies_herdr_config() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/repos/example-project/herdr-config.md" ]]
}

test_seeds_rules_into_repo() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/repos/example-project/rules/README.md" ]] \
    && [[ -f "${SANDBOX}/repos/example-project/rules/testing.md" ]]
}

test_update_seeds_rules_when_missing() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  rm -rf "${SANDBOX}/repos/example-project/rules"
  install example-project --update >/dev/null 2>&1
  [[ -f "${SANDBOX}/repos/example-project/rules/README.md" ]] \
    && [[ -f "${SANDBOX}/repos/example-project/rules/testing.md" ]]
}

test_update_does_not_resurrect_deleted_theme() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  rm "${SANDBOX}/repos/example-project/rules/testing.md"
  echo 'corrupted' > "${SANDBOX}/repos/example-project/rules/README.md"
  install example-project --update >/dev/null 2>&1
  [[ ! -e "${SANDBOX}/repos/example-project/rules/testing.md" ]] \
    && grep -q '# Coding rules' "${SANDBOX}/repos/example-project/rules/README.md"
}

test_import_rules_flag() {
  new_sandbox
  mkdir -p "${HOME}/.claude/rules"
  printf '# one\n' > "${HOME}/.claude/rules/one.md"
  printf '# two\n' > "${HOME}/.claude/rules/two.md"
  install example-project "${SANDBOX}/repos/example-project" --import-rules one.md \
    >/dev/null 2>&1
  [[ -f "${SANDBOX}/repos/example-project/rules/one.md" ]] \
    && [[ ! -f "${SANDBOX}/repos/example-project/rules/two.md" ]]
}

test_import_rules_missing_file_fails() {
  new_sandbox
  ! install example-project "${SANDBOX}/repos/example-project" --import-rules nope.md \
      >/dev/null 2>&1
}

test_import_rules_preflight_before_any_write() {
  new_sandbox
  ! install example-project "${SANDBOX}/repos/example-project" --import-rules nope.md \
      >/dev/null 2>&1
  [[ ! -e "${SANDBOX}/repos/example-project/AGENTS.local.md" ]] \
    && [[ ! -d "${PROJECTS}/example-project" ]]
}

test_non_interactive_imports_nothing() {
  new_sandbox
  mkdir -p "${HOME}/.claude/rules"
  printf '# one\n' > "${HOME}/.claude/rules/one.md"
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/repos/example-project/rules/testing.md" ]] \
    && [[ ! -f "${SANDBOX}/repos/example-project/rules/one.md" ]]
}

test_update_refreshes_rules_templates() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  echo 'corrupted' > "${SANDBOX}/repos/example-project/rules/testing.md"
  printf 'project-owned theme\n' > "${SANDBOX}/repos/example-project/rules/clojure.md"
  install example-project --update >/dev/null 2>&1
  local rules_now rules_want
  rules_now="$(head -1 "${SANDBOX}/repos/example-project/rules/testing.md")"
  rules_want="$(head -1 "${RIBBON_HOME}/rules/testing.md")"
  [[ "${rules_now}" == "${rules_want}" ]] \
    && [[ "$(cat "${SANDBOX}/repos/example-project/rules/clojure.md")" \
          == "project-owned theme" ]]
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

test_update_keeps_filled_belt() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  local local_md="${SANDBOX}/repos/example-project/AGENTS.local.md"
  sed -i "s/TODO(belt): a person's name/Ana/" "${local_md}"
  install example-project --update >/dev/null 2>&1
  grep -q '^| Senior architect | Ana |' "${local_md}"
}

test_update_leaves_managed_instructions_byte_identical() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  sed -i '/ribbon:standalone:start/a preserved line inside the managed block' "${repo}/AGENTS.local.md"
  cp "${repo}/AGENTS.md" "${repo}/AGENTS.local.md" "${SANDBOX}/"

  install example-project --update >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/AGENTS.md" "${repo}/AGENTS.md" \
    && cmp -s "${SANDBOX}/AGENTS.local.md" "${repo}/AGENTS.local.md"
}

test_update_leaves_legacy_block_byte_identical() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1 || return 1
  local local_md="${SANDBOX}/repos/example-project/AGENTS.local.md"
  cat > "${local_md}" <<'EOF'
# my local notes

<!-- ribbon:standalone:start -->
# Ribbon Protocol, standalone mode

old intro text from before belt marks

## The belt

old belt intro

| Role | Agent | Model | Writes | Never |
|---|---|---|---|---|
| Senior architect | Ana | human | the problem | nothing |

old closing line

## Rules for every agent

old rules text
<!-- ribbon:standalone:end -->

trailing local content
EOF
  cp "${local_md}" "${SANDBOX}/before"

  install example-project --update >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/before" "${local_md}"
}

test_force_leaves_managed_instructions_byte_identical() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  sed -i "s/TODO(belt): a person's name/Ana/" "${repo}/AGENTS.local.md"
  sed -i '/ribbon:standalone:start/a preserved line inside the managed block' "${repo}/AGENTS.local.md"
  cp "${repo}/AGENTS.md" "${repo}/AGENTS.local.md" "${SANDBOX}/"

  install example-project "${repo}" --force >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/AGENTS.md" "${repo}/AGENTS.md" \
    && cmp -s "${SANDBOX}/AGENTS.local.md" "${repo}/AGENTS.local.md"
}

test_update_keeps_one_belt_section() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  install example-project --update >/dev/null 2>&1
  install example-project --update >/dev/null 2>&1
  local local_md="${SANDBOX}/repos/example-project/AGENTS.local.md"
  [[ "$(belt_count 'ribbon:belt:start')" == "1" ]] \
    && [[ "$(belt_count 'ribbon:belt:end')" == "1" ]] \
    && [[ "$(grep -c '^| Role | Agent | Model | Writes | Never |$' "${local_md}")" == "1" ]]
}

test_update_keeps_belt_text_verbatim() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  local local_md="${SANDBOX}/repos/example-project/AGENTS.local.md"
  sed -i "s/TODO(belt): a person's name/{{INSTANCE}}/" "${local_md}"
  install example-project --update >/dev/null 2>&1
  [[ "$(grep -c '{{INSTANCE}}' "${local_md}")" == "1" ]]
}

test_update_refuses_block_without_end_mark() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  local local_md="${SANDBOX}/repos/example-project/AGENTS.local.md"
  sed -i '/ribbon:standalone:end/d' "${local_md}"
  cp "${local_md}" "${SANDBOX}/local-md-before.md"
  local refused=0
  install example-project --update >/dev/null 2>"${SANDBOX}/refusal.txt" || refused=1
  (( refused == 1 )) \
    && [[ -s "${SANDBOX}/refusal.txt" ]] \
    && cmp -s "${local_md}" "${SANDBOX}/local-md-before.md"
}

test_update_refuses_unbalanced_belt_marks() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  local local_md="${SANDBOX}/repos/example-project/AGENTS.local.md"
  sed -i '/ribbon:belt:end/d' "${local_md}"
  cp "${local_md}" "${SANDBOX}/local-md-before.md"
  local refused=0
  install example-project --update >/dev/null 2>"${SANDBOX}/refusal.txt" || refused=1
  (( refused == 1 )) \
    && [[ -s "${SANDBOX}/refusal.txt" ]] \
    && cmp -s "${local_md}" "${SANDBOX}/local-md-before.md"
}

test_install_marks_belt_section() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  local local_md="${SANDBOX}/repos/example-project/AGENTS.local.md"
  [[ "$(belt_count 'ribbon:belt:start')" == "1" ]] \
    && [[ "$(belt_count 'ribbon:belt:end')" == "1" ]] \
    && sed -n '/ribbon:belt:start/,/ribbon:belt:end/p' "${local_md}" | grep -q '^## The belt$'
}

test_refuses_force_and_update() {
  new_sandbox
  ! install example-project "${SANDBOX}/repos/example-project" --force --update \
      >/dev/null 2>&1
}

test_usage_without_args() {
  ! "${INSTALLER}" >/dev/null 2>&1
}

test_refuses_home_directory() {
  new_sandbox
  printf '# home AGENTS\n' > "${HOME}/AGENTS.md"
  ! install example-project "${HOME}" >/dev/null 2>&1
  [[ ! -e "${HOME}/AGENTS.local.md" ]]
}

test_refuses_template_as_project_repo() {
  new_sandbox
  ! install example-project "${RIBBON_HOME}" >/dev/null 2>&1
}

test_refuses_symlinked_overlap() {
  new_sandbox
  ln -s "${SANDBOX}/repos" "${SANDBOX}/repos-link"
  local rc=0
  "${INSTALLER}" --projects "${SANDBOX}/repos-link" example-project \
    "${SANDBOX}/repos/example-project" >/dev/null 2>&1 || rc=1
  [[ "${rc}" == "1" ]] && [[ ! -e "${SANDBOX}/repos/example-project/docs" ]]
}

test_refuses_template_as_instance() {
  new_sandbox
  local tmpl="${PROJECTS}/example-project"
  mkdir -p "${tmpl}/docs/tasks" "${tmpl}/docs/llm-context" "${tmpl}/rules" "${tmpl}/scripts"
  printf '# fake template\n' > "${tmpl}/AGENTS.standalone.md"
  printf '# fake\n' > "${tmpl}/AGENTS.md"
  printf 'ribbon 1\n' > "${tmpl}/VERSION"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${tmpl}/scripts/"
  local rc=0
  install --ribbon-home "${tmpl}" example-project \
      "${SANDBOX}/repos/example-project" --force >/dev/null 2>&1 || rc=1
  [[ "${rc}" == "1" ]] && [[ -f "${tmpl}/AGENTS.standalone.md" ]]
}

test_refuses_template_inside_instance() {
  new_sandbox
  local tmpl="${PROJECTS}/example-project/inner-template"
  mkdir -p "${tmpl}/docs/tasks" "${tmpl}/docs/llm-context" "${tmpl}/rules" "${tmpl}/scripts"
  printf '# fake\n' > "${tmpl}/AGENTS.standalone.md"
  printf '# fake\n' > "${tmpl}/AGENTS.md"
  printf 'ribbon 1\n' > "${tmpl}/VERSION"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${tmpl}/scripts/"
  local rc=0
  install --ribbon-home "${tmpl}" example-project \
      "${SANDBOX}/repos/example-project" --force >/dev/null 2>&1 || rc=1
  [[ "${rc}" == "1" ]] && [[ -f "${tmpl}/AGENTS.standalone.md" ]]
}

test_force_preflights_local_block() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  printf '<!-- ribbon:standalone:start -->\nbroken\n' \
    > "${SANDBOX}/repos/example-project/AGENTS.local.md"
  printf 'live work\n' > "${PROJECTS}/example-project/docs/tasks/live-card.yaml"
  local rc=0
  install example-project "${SANDBOX}/repos/example-project" --force --yes \
      >/dev/null 2>&1 || rc=1
  [[ "${rc}" == "1" ]] && [[ -f "${PROJECTS}/example-project/docs/tasks/live-card.yaml" ]]
}

test_force_preflights_marker_order() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  printf 'text\n<!-- ribbon:standalone:end -->\ntext\n<!-- ribbon:standalone:start -->\ntext\n' \
    > "${SANDBOX}/repos/example-project/AGENTS.local.md"
  printf 'live work\n' > "${PROJECTS}/example-project/docs/tasks/live-card.yaml"
  local rc=0
  install example-project "${SANDBOX}/repos/example-project" --force --yes \
      >/dev/null 2>&1 || rc=1
  [[ "${rc}" == "1" ]] && [[ -f "${PROJECTS}/example-project/docs/tasks/live-card.yaml" ]]
}

test_force_preflights_belt_markers() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  cat > "${SANDBOX}/repos/example-project/AGENTS.local.md" <<'EOF'
<!-- ribbon:standalone:start -->
# Ribbon Protocol, standalone mode
<!-- ribbon:belt:start -->
## The belt
| Role | Agent |
|---|---|
<!-- ribbon:standalone:end -->
EOF
  printf 'live work\n' > "${PROJECTS}/example-project/docs/tasks/live-card.yaml"
  local rc=0
  install example-project "${SANDBOX}/repos/example-project" --force --yes \
      >/dev/null 2>&1 || rc=1
  [[ "${rc}" == "1" ]] && [[ -f "${PROJECTS}/example-project/docs/tasks/live-card.yaml" ]]
}

test_force_rejects_duplicate_blocks_before_rebuild() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/first-block"
  cat "${SANDBOX}/first-block" >> "${repo}/AGENTS.local.md"
  printf 'live work\n' > "${PROJECTS}/example-project/docs/tasks/live-card.yaml"

  install example-project "${repo}" --force --yes >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == "1" ]] \
    && grep -Fq 'AGENTS.local.md has unclosed, duplicated or out-of-order Ribbon markers' "${SANDBOX}/error" \
    && grep -Fxq 'live work' "${PROJECTS}/example-project/docs/tasks/live-card.yaml"
}

test_force_rejects_an_agents_alias_of_claude_before_rebuild() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  printf '# Claude owns this file\r\n' > "${repo}/CLAUDE.local.md"
  cp "${repo}/CLAUDE.local.md" "${SANDBOX}/before"
  ln -sf CLAUDE.local.md "${repo}/AGENTS.local.md"
  printf 'live work\n' > "${PROJECTS}/example-project/docs/tasks/live-card.yaml"

  install example-project "${repo}" --force --yes >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == "1" ]] \
    && grep -Eq 'AGENTS\.local\.md.*CLAUDE\.local\.md' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/before" "${repo}/CLAUDE.local.md" \
    && grep -Fxq 'live work' "${PROJECTS}/example-project/docs/tasks/live-card.yaml"
}

test_force_refuses_to_rebuild_an_instance_holding_project_instructions() {
  local name repo instance rc
  for name in AGENTS.local.md CLAUDE.md; do
    new_sandbox
    repo="${SANDBOX}/repos/example-project"
    instance="${PROJECTS}/example-project"
    install example-project "${repo}" >/dev/null 2>&1 || return 1
    if [[ "${name}" == AGENTS.local.md ]]; then
      cp "${repo}/${name}" "${SANDBOX}/before"
    else
      printf '# Claude instructions\r\n' > "${SANDBOX}/before"
    fi
    cp "${SANDBOX}/before" "${instance}/instruction"
    ln -sf "${instance}/instruction" "${repo}/${name}"

    rc=0
    install example-project "${repo}" --force --yes >/dev/null 2> "${SANDBOX}/error" || rc=$?

    if [[ "${rc}" != "1" ]] \
      || ! grep -Fq "${name} points inside the instance" "${SANDBOX}/error" \
      || ! cmp -s "${SANDBOX}/before" "${repo}/${name}"; then
      printf 'rebuild did not protect %s\n' "${name}" >&2
      return 1
    fi
  done
}

test_force_keeps_legacy_block_without_belt_marks() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  cat > "${repo}/AGENTS.local.md" <<'EOF'
<!-- ribbon:standalone:start -->
# Ribbon Protocol, standalone mode
## The belt
| Role | Agent |
|---|---|
<!-- ribbon:standalone:end -->
EOF
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before"

  install example-project "${repo}" --force --yes >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.local.md"
}

test_rejects_surplus_positionals() {
  new_sandbox
  ! install example-project "${SANDBOX}/repos/example-project" extra-arg \
      >/dev/null 2>&1
  [[ ! -e "${SANDBOX}/repos/example-project/AGENTS.local.md" ]]
}

test_import_rejects_directory_operand() {
  new_sandbox
  mkdir -p "${HOME}/.claude/rules/dir.md"
  ! install example-project "${SANDBOX}/repos/example-project" --import-rules dir.md \
      >/dev/null 2>&1
}

test_refuses_overlapping_repo_and_instance() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  mkdir -p "${PROJECTS}/example-project/repo-inside"
  printf '# inside AGENTS\n' > "${PROJECTS}/example-project/repo-inside/AGENTS.md"
  ! install example-project "${PROJECTS}/example-project/repo-inside" --force \
      >/dev/null 2>&1
  [[ -d "${PROJECTS}/example-project/docs" ]]
}

test_import_rules_usage_order_works() {
  new_sandbox
  mkdir -p "${HOME}/.claude/rules"
  printf '# one\n' > "${HOME}/.claude/rules/one.md"
  install --import-rules one.md example-project "${SANDBOX}/repos/example-project" \
    >/dev/null 2>&1
  [[ -f "${SANDBOX}/repos/example-project/rules/one.md" ]]
}

test_import_rules_requires_one_value() {
  new_sandbox
  ! install example-project "${SANDBOX}/repos/example-project" --import-rules \
      >/dev/null 2>&1
}

test_import_rules_rejects_paths() {
  new_sandbox
  mkdir -p "${HOME}/.claude"
  printf '# x\n' > "${HOME}/.claude/x.md"
  ! install example-project "${SANDBOX}/repos/example-project" --import-rules ../x.md \
      >/dev/null 2>&1
  [[ ! -e "${SANDBOX}/repos/example-project/AGENTS.local.md" ]] \
    && [[ ! -e "${SANDBOX}/repos/example-project/x.md" ]]
}

test_install_keeps_existing_project_theme() {
  new_sandbox
  mkdir -p "${SANDBOX}/repos/example-project/rules"
  printf 'custom testing rules\n' > "${SANDBOX}/repos/example-project/rules/testing.md"
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  [[ "$(cat "${SANDBOX}/repos/example-project/rules/testing.md")" == "custom testing rules" ]] \
    && [[ -f "${SANDBOX}/repos/example-project/rules/README.md" ]]
}

readonly TESTS=(
  test_installer_exists
  test_creates_layout
  test_seeds_version
  test_writes_pointer
  test_writes_agents_local_md
  test_agents_md_gets_single_pointer
  test_install_appends_to_agents_files_without_rewriting_bytes
  test_update_warns_for_unlinked_claude_files_without_editing_them
  test_install_does_not_warn_for_linked_claude_files
  test_copies_herdr_config
  test_seeds_rules_into_repo
  test_update_seeds_rules_when_missing
  test_update_does_not_resurrect_deleted_theme
  test_import_rules_flag
  test_import_rules_missing_file_fails
  test_import_rules_preflight_before_any_write
  test_non_interactive_imports_nothing
  test_update_refreshes_rules_templates
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
  test_update_keeps_filled_belt
  test_update_leaves_managed_instructions_byte_identical
  test_update_leaves_legacy_block_byte_identical
  test_force_leaves_managed_instructions_byte_identical
  test_update_keeps_one_belt_section
  test_update_keeps_belt_text_verbatim
  test_update_refuses_block_without_end_mark
  test_update_refuses_unbalanced_belt_marks
  test_install_marks_belt_section
  test_refuses_force_and_update
  test_usage_without_args
  test_refuses_home_directory
  test_refuses_template_as_project_repo
  test_refuses_symlinked_overlap
  test_refuses_template_as_instance
  test_refuses_template_inside_instance
  test_force_preflights_local_block
  test_force_preflights_marker_order
  test_force_preflights_belt_markers
  test_force_rejects_duplicate_blocks_before_rebuild
  test_force_rejects_an_agents_alias_of_claude_before_rebuild
  test_force_refuses_to_rebuild_an_instance_holding_project_instructions
  test_force_keeps_legacy_block_without_belt_marks
  test_rejects_surplus_positionals
  test_import_rejects_directory_operand
  test_refuses_overlapping_repo_and_instance
  test_import_rules_usage_order_works
  test_import_rules_requires_one_value
  test_import_rules_rejects_paths
  test_install_keeps_existing_project_theme
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
