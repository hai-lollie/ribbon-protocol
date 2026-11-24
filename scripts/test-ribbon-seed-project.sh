#!/usr/bin/env bash
# Tests for scripts/ribbon-seed-project (the full install): one function per
# test, run in order by main, once on the host's tools and once as a Mac with
# Homebrew coreutils. Each test builds its own throwaway git repository; the
# real template repo provides the seeds. Names are generic.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RIBBON_HOME="$(dirname "${SCRIPT_DIR}")"
SEEDER="${SCRIPT_DIR}/ribbon-seed-project"
readonly SCRIPT_DIR RIBBON_HOME SEEDER

PASS=0
FAIL=0
SANDBOX=''
MACOS_BIN=''
COREUTILS_BIN=''

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

#######################################
# Remove the last sandbox and the macOS stand-ins when the run ends.
# Globals:
#   MACOS_BIN, COREUTILS_BIN
#######################################
finish() {
  cleanup
  [[ -z "${MACOS_BIN}" ]] || rm -rf "${MACOS_BIN}"
  [[ -z "${COREUTILS_BIN}" ]] || rm -rf "${COREUTILS_BIN}"
}
trap finish EXIT

#######################################
# Put stand-ins for a stock Mac's tools in a fresh directory. Its realpath is
# BSD's: it takes only -q, rejects every other option with BSD's message and
# fails on a path that does not exist (the host's realpath -e resolves). Its
# grealpath is missing, since Homebrew's coreutils is not installed.
# Globals:
#   MACOS_BIN (set)
#######################################
make_stock_macos() {
  local gnu_realpath
  gnu_realpath="$(command -v realpath)"
  MACOS_BIN="$(mktemp -d)"
  {
    printf '#!/usr/bin/env bash\n'
    printf 'gnu_realpath=%q\n' "${gnu_realpath}"
    cat <<'EOF'
quiet=0
while getopts ':q' flag; do
  case "${flag}" in
    q) quiet=1 ;;
    *) printf 'realpath: illegal option -- %s\nusage: realpath [-q] [path ...]\n' "${OPTARG}" >&2
       exit 1 ;;
  esac
done
shift $((OPTIND - 1))
(( $# > 0 )) || set -- .
status=0
for path in "$@"; do
  if (( quiet )); then
    "${gnu_realpath}" -e -- "${path}" 2>/dev/null || status=1
  else
    "${gnu_realpath}" -e -- "${path}" || status=1
  fi
done
exit "${status}"
EOF
  } > "${MACOS_BIN}/realpath"
  cat > "${MACOS_BIN}/grealpath" <<'EOF'
#!/usr/bin/env bash
printf 'grealpath: command not found\n' >&2
exit 127
EOF
  chmod +x "${MACOS_BIN}/realpath" "${MACOS_BIN}/grealpath"
}

#######################################
# Put Homebrew coreutils' grealpath, which is GNU realpath, in a fresh
# directory.
# Globals:
#   COREUTILS_BIN (set)
#######################################
make_homebrew_coreutils() {
  COREUTILS_BIN="$(mktemp -d)"
  printf '#!/usr/bin/env bash\nexec %q "$@"\n' "$(command -v realpath)" > "${COREUTILS_BIN}/grealpath"
  chmod +x "${COREUTILS_BIN}/grealpath"
}

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
  local repo="${SANDBOX}/example-project" stamp
  stamp="Seeded from the Ribbon Protocol, $(template_version)."

  seed "${repo}" >/dev/null 2>&1 || return 1

  [[ "$(head -1 "${repo}/docs/README.md")" == "${stamp}" ]] \
    && [[ "$(git -C "${repo}" show HEAD:docs/.ribbon-full-install)" == "${stamp}" ]]
}

test_appends_protocol_preserving_content() {
  new_repo
  local repo="${SANDBOX}/example-project" bytes
  printf '# Our house rules\r\nNo trailing newline' > "${SANDBOX}/before"
  cp "${SANDBOX}/before" "${repo}/AGENTS.md"
  bytes="$(wc -c < "${SANDBOX}/before")"

  seed "${repo}" >/dev/null 2>&1 || return 1

  head -c "$((bytes))" "${repo}/AGENTS.md" | cmp -s "${SANDBOX}/before" - \
    && grep -q "multi-LLM engineering belt" "${repo}/AGENTS.md" \
    && [[ "$(grep -c 'ribbon:full-install:start' "${repo}/AGENTS.md")" == "1" ]]
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

test_leaves_missing_claude_files_absent() {
  new_repo
  local repo="${SANDBOX}/example-project"

  seed "${repo}" >/dev/null 2>&1 || return 1

  [[ ! -e "${repo}/CLAUDE.md" && ! -L "${repo}/CLAUDE.md" \
     && ! -e "${repo}/CLAUDE.local.md" && ! -L "${repo}/CLAUDE.local.md" ]]
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

test_preserves_existing_claude_files_byte_for_byte() {
  new_repo
  local repo="${SANDBOX}/example-project"
  printf '# Existing shared Claude rules\r\nNo trailing newline' > "${SANDBOX}/CLAUDE.md"
  printf '# Existing local Claude rules' > "${SANDBOX}/CLAUDE.local.md"
  cp "${SANDBOX}/CLAUDE.md" "${SANDBOX}/CLAUDE.local.md" "${repo}/"

  seed "${repo}" >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/CLAUDE.md" "${repo}/CLAUDE.md" \
    && cmp -s "${SANDBOX}/CLAUDE.local.md" "${repo}/CLAUDE.local.md"
}

test_warns_for_unlinked_claude_files_after_seeding() {
  new_repo
  local repo="${SANDBOX}/example-project"
  printf '# Shared Claude rules\n' > "${repo}/CLAUDE.md"
  printf '# Local Claude rules\n' > "${repo}/CLAUDE.local.md"
  printf '# Local agent notes\n' > "${repo}/AGENTS.local.md"

  seed "${repo}" > /dev/null 2> "${SANDBOX}/warnings" || return 1

  grep -Fq 'warning: CLAUDE.md does not point to AGENTS.md' "${SANDBOX}/warnings" \
    && grep -Fq 'warning: CLAUDE.local.md does not point to AGENTS.local.md' "${SANDBOX}/warnings"
}

test_respects_a_claude_symlink_to_agents() {
  new_repo
  local repo="${SANDBOX}/example-project"
  ln -s AGENTS.md "${repo}/CLAUDE.md"

  seed "${repo}" > /dev/null 2> "${SANDBOX}/warnings" || return 1

  [[ "$(readlink "${repo}/CLAUDE.md")" == "AGENTS.md" ]] \
    && ! grep -Fxq '@herdr-config.md' "${repo}/AGENTS.md" \
    && ! grep -Fq 'warning: CLAUDE.md' "${SANDBOX}/warnings"
}

test_rejects_an_agents_hardlink_to_claude_before_seeding() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  printf '# Claude owns this file\r\n' > "${repo}/CLAUDE.md"
  cp "${repo}/CLAUDE.md" "${SANDBOX}/before"
  ln -f "${repo}/CLAUDE.md" "${repo}/AGENTS.md"

  seed "${repo}" > /dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == "1" && ! -e "${repo}/docs" ]] \
    && grep -Eq 'AGENTS\.md.*CLAUDE\.md' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/before" "${repo}/CLAUDE.md"
}

test_rejects_an_overlay_symlink_to_claude_before_seeding() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  printf '# Claude owns this file\r\n' > "${repo}/CLAUDE.local.md"
  cp "${repo}/CLAUDE.local.md" "${SANDBOX}/before"
  ln -s CLAUDE.local.md "${repo}/herdr-config.md"

  seed "${repo}" > /dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == "1" && ! -e "${repo}/docs" ]] \
    && grep -Eq 'herdr-config\.md.*CLAUDE\.local\.md' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/before" "${repo}/CLAUDE.local.md"
}

test_rejects_an_overlay_symlink_to_agents_before_seeding() {
  local name repo rc
  for name in AGENTS.md AGENTS.local.md; do
    new_repo
    repo="${SANDBOX}/example-project"
    printf '# Existing agent instructions\r\nNo final newline' > "${SANDBOX}/before"
    cp "${SANDBOX}/before" "${repo}/${name}"
    ln -s "${name}" "${repo}/herdr-config.md"

    rc=0
    seed "${repo}" > /dev/null 2> "${SANDBOX}/error" || rc=$?

    [[ "${rc}" == "1" && ! -e "${repo}/docs" ]] \
      && grep -Fq "herdr-config.md aliases ${name}" "${SANDBOX}/error" \
      && cmp -s "${SANDBOX}/before" "${repo}/${name}" || return 1
  done
}

test_seeding_rejects_dangling_instruction_aliases_before_writing() {
  local row mode name destination repo head rc failed=0
  local -a flags
  for row in \
      'seed CLAUDE.md herdr-config.md' \
      'seed AGENTS.local.md herdr-config.md' \
      'seed CLAUDE.md docs/.ribbon-full-install' \
      'seed CLAUDE.local.md docs/tasks/_template.task.yaml' \
      'amend CLAUDE.md rules/testing.md' \
      'amend CLAUDE.local.md rules/personal.md'; do
    read -r mode name destination <<< "${row}"
    new_repo
    repo="${SANDBOX}/example-project"
    head="$(git -C "${repo}" rev-parse HEAD)"
    flags=()
    if [[ "${mode}" == amend ]]; then
      mkdir "${repo}/docs"
      printf 'Seeded from the Ribbon Protocol, ribbon 1.\n' > "${repo}/docs/README.md"
      cp "${repo}/docs/README.md" "${SANDBOX}/before-docs"
    fi
    if [[ "${destination}" == rules/personal.md ]]; then
      mkdir -p "${HOME}/.claude/rules"
      printf '# Personal rule\n' > "${HOME}/.claude/rules/personal.md"
      flags=(--import-rules personal.md)
    fi
    ln -s "${destination}" "${repo}/${name}"
    cp "${repo}/AGENTS.md" "${SANDBOX}/before-agents"

    rc=0
    seed "${flags[@]}" "${repo}" > /dev/null 2> "${SANDBOX}/error" || rc=$?

    if [[ "${rc}" != "1" || -e "${repo}/${destination}" || -e "${repo}/rules" ]] \
      || ! grep -Fq "${destination} aliases ${name}" "${SANDBOX}/error" \
      || ! cmp -s "${SANDBOX}/before-agents" "${repo}/AGENTS.md" \
      || [[ "$(readlink "${repo}/${name}")" != "${destination}" ]] \
      || [[ "$(git -C "${repo}" rev-parse HEAD)" != "${head}" ]]; then
      printf 'seed did not protect: %s\n' "${row}" >&2
      failed=1
    fi
    if [[ "${mode}" == amend ]]; then
      cmp -s "${SANDBOX}/before-docs" "${repo}/docs/README.md" || failed=1
    elif [[ -e "${repo}/docs" ]]; then
      failed=1
    fi
  done
  return "${failed}"
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
  local rc=0
  seed "${HOME}" >/dev/null 2> "${SANDBOX}/error" || rc=$?
  [[ "${rc}" == 1 && ! -e "${HOME}/docs" && ! -e "${HOME}/rules" ]] \
    && grep -Fq 'refusing to seed your home directory' "${SANDBOX}/error"
}

test_refuses_template_as_project_repo() {
  new_repo
  local rc=0
  seed "${RIBBON_HOME}" >/dev/null 2> "${SANDBOX}/error" || rc=$?
  [[ "${rc}" == 1 ]] \
    && grep -Fq 'refusing to seed the template repository itself' "${SANDBOX}/error"
}

# A stock Mac's BSD realpath has no -m, so nothing resolves a path that does
# not exist yet: the seeder stops before any write or commit and names the fix.
test_refuses_without_gnu_realpath() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  PATH="${MACOS_BIN}:${PATH}" "${SEEDER}" "${repo}" >/dev/null 2> "${SANDBOX}/error" || rc=$?
  [[ "${rc}" == 1 && ! -e "${repo}/docs" && ! -e "${repo}/rules" ]] \
    && [[ "$(git -C "${repo}" rev-list --count HEAD)" == 1 ]] \
    && grep -Fq 'brew install coreutils' "${SANDBOX}/error"
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

test_seed_preserves_existing_docs_readme_byte_for_byte() {
  new_repo
  local repo="${SANDBOX}/example-project"
  mkdir "${repo}/docs"
  printf '# My API documentation\r\nNo trailing newline' > "${SANDBOX}/before"
  cp "${SANDBOX}/before" "${repo}/docs/README.md"
  git -C "${repo}" add docs/README.md

  seed "${repo}" >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/before" "${repo}/docs/README.md" \
    && [[ -f "${repo}/docs/tasks/_template.plan.yaml" ]] \
    && [[ "$(git -C "${repo}" show HEAD:docs/.ribbon-full-install)" == "Seeded from the Ribbon Protocol, $(template_version)." ]] \
    && ! git -C "${repo}" cat-file -e HEAD:docs/README.md \
    && git -C "${repo}" diff --cached --name-only | grep -Fxq 'docs/README.md'
}

test_seed_refuses_to_change_a_readme_linked_to_agents() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  mkdir "${repo}/docs"
  ln "${repo}/AGENTS.md" "${repo}/docs/README.md"
  cp "${repo}/docs/README.md" "${SANDBOX}/before"

  seed "${repo}" >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs/tasks" && ! -e "${repo}/rules" ]] \
    && grep -Fq 'would change existing project path: docs/README.md' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/before" "${repo}/docs/README.md" \
    && [[ "${repo}/docs/README.md" -ef "${repo}/AGENTS.md" ]]
}

test_seed_rejects_nested_project_directory_links_before_appending() {
  new_repo
  local repo="${SANDBOX}/example-project" outside="${SANDBOX}/outside" rc=0
  mkdir "${repo}/docs" "${outside}"
  ln -s "${outside}" "${repo}/docs/reference"
  ln -s "${repo}/AGENTS.md" "${outside}/README.md"
  cp "${outside}/README.md" "${SANDBOX}/before"

  seed "${repo}" >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs/.ribbon-full-install" && ! -e "${repo}/rules" ]] \
    && grep -Fq 'unsafe project directory link' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/before" "${outside}/README.md"
}

test_seed_keeps_a_link_to_a_missing_docs_directory_dangling() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  mkdir "${repo}/docs"
  ln -s tasks "${repo}/docs/README.md"
  cp "${repo}/AGENTS.md" "${SANDBOX}/before"

  seed "${repo}" >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs/tasks" && ! -e "${repo}/rules" ]] \
    && grep -Fq 'would change existing project path: docs/README.md' "${SANDBOX}/error" \
    && [[ "$(readlink "${repo}/docs/README.md")" == tasks ]] \
    && cmp -s "${SANDBOX}/before" "${repo}/AGENTS.md"
}

test_seed_does_not_complete_a_missing_symlink_traversal() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  mkdir "${repo}/docs"
  printf 'Existing project content\n' > "${repo}/docs/original.md"
  ln -s tasks/../original.md "${repo}/docs/README.md"
  [[ ! -e "${repo}/docs/README.md" ]] || return 1

  seed "${repo}" >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs/tasks" && ! -e "${repo}/docs/README.md" ]] \
    && grep -Fq 'would change existing project path: docs/README.md' "${SANDBOX}/error" \
    && [[ "$(readlink "${repo}/docs/README.md")" == tasks/../original.md ]]
}

test_seed_allows_an_unrelated_missing_symlink_traversal() {
  new_repo
  local repo="${SANDBOX}/example-project"
  mkdir "${repo}/docs"
  printf 'Existing project content\n' > "${repo}/docs/original.md"
  ln -s archive/../original.md "${repo}/docs/README.md"

  seed "${repo}" >/dev/null 2>&1 || return 1

  [[ -f "${repo}/docs/tasks/_template.plan.yaml" && ! -e "${repo}/docs/README.md" ]] \
    && [[ "$(readlink "${repo}/docs/README.md")" == archive/../original.md ]]
}

test_seed_detection_does_not_require_a_ribbon_readme() {
  new_repo
  local repo="${SANDBOX}/example-project" head rc=0
  mkdir "${repo}/docs"
  printf '# Project docs\n' > "${repo}/docs/README.md"
  seed "${repo}" >/dev/null 2>&1 || return 1
  head="$(git -C "${repo}" rev-parse HEAD)"

  seed "${repo}" >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && "$(git -C "${repo}" rev-parse HEAD)" == "${head}" ]] \
    && grep -Fq 'already full-installed' "${SANDBOX}/error"
}

test_similar_readme_text_does_not_select_legacy_amendment() {
  new_repo
  local repo="${SANDBOX}/example-project"
  mkdir "${repo}/docs"
  printf 'Seeded from the Ribbon Protocol, ribbon notes for an unrelated project.\n' > "${SANDBOX}/before"
  cp "${SANDBOX}/before" "${repo}/docs/README.md"

  seed "${repo}" >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/before" "${repo}/docs/README.md" \
    && [[ -f "${repo}/docs/tasks/_template.plan.yaml" && -f "${repo}/docs/.ribbon-full-install" ]]
}

test_seed_refuses_an_unrelated_existing_seed_record() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  mkdir "${repo}/docs"
  printf 'project-owned bytes\r\n' > "${SANDBOX}/before"
  cp "${SANDBOX}/before" "${repo}/docs/.ribbon-full-install"

  seed "${repo}" >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs/README.md" && ! -e "${repo}/rules" ]] \
    && cmp -s "${SANDBOX}/before" "${repo}/docs/.ribbon-full-install" \
    && grep -Fq 'reserved seed record' "${SANDBOX}/error"
}

test_seed_record_is_generated_not_copied_from_the_source() {
  new_repo
  local repo="${SANDBOX}/example-project" template="${SANDBOX}/template"
  mkdir "${template}"
  cp -R "${RIBBON_HOME}/docs" "${RIBBON_HOME}/rules" "${template}/"
  cp "${RIBBON_HOME}/AGENTS.md" "${RIBBON_HOME}/VERSION" "${RIBBON_HOME}/herdr-config.md" "${template}/"
  printf 'Seeded from the Ribbon Protocol, ribbon 999.\n' > "${template}/docs/.ribbon-full-install"

  seed --ribbon-home "${template}" "${repo}" >/dev/null 2>&1 || return 1

  [[ "$(git -C "${repo}" show HEAD:docs/.ribbon-full-install)" == "Seeded from the Ribbon Protocol, $(template_version)." ]]
}

test_ignored_seed_record_blocks_full_install_before_writes() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  printf 'docs/.*\n' > "${repo}/.gitignore"
  cp "${repo}/AGENTS.md" "${SANDBOX}/before"

  seed "${repo}" >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs" && ! -e "${repo}/rules" ]] \
    && grep -Fq 'seed record is ignored by Git' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/before" "${repo}/AGENTS.md"
}

test_seed_skips_dangling_docs_and_rule_entries() {
  new_repo
  local repo="${SANDBOX}/example-project" path
  mkdir -p "${repo}/docs/tasks" "${repo}/rules" "${HOME}/.claude/rules"
  printf 'import candidate\n' > "${HOME}/.claude/rules/personal.md"
  for path in docs/tasks/README.md rules/testing.md rules/personal.md; do
    ln -s "${SANDBOX}/missing-target" "${repo}/${path}"
  done

  seed "${repo}" --import-rules personal.md >/dev/null 2>&1 || return 1

  for path in docs/tasks/README.md rules/testing.md rules/personal.md; do
    [[ "$(readlink "${repo}/${path}")" == "${SANDBOX}/missing-target" && ! -e "${repo}/${path}" ]] || return 1
  done
  [[ -f "${repo}/docs/tasks/_template.plan.yaml" && -f "${repo}/rules/README.md" ]] \
    && [[ -z "$(git -C "${repo}" ls-tree -r --name-only HEAD -- docs/tasks/README.md rules/testing.md rules/personal.md)" ]]
}

test_seed_rejects_unsafe_project_directory_before_writing() {
  local kind repo rc failed=0
  for kind in symlink file; do
    new_repo
    repo="${SANDBOX}/example-project"
    mkdir "${repo}/docs" "${SANDBOX}/outside"
    if [[ "${kind}" == symlink ]]; then
      ln -s "${SANDBOX}/outside" "${repo}/docs/tasks"
    else
      printf 'project task index\n' > "${repo}/docs/tasks"
    fi

    rc=0
    seed "${repo}" >/dev/null 2> "${SANDBOX}/error" || rc=$?

    if [[ "${rc}" != 1 || -e "${repo}/docs/adrs" || -e "${repo}/docs/README.md" || -e "${repo}/rules" ]] \
      || ! grep -Fq 'unsafe project directory' "${SANDBOX}/error" \
      || [[ -n "$(ls -A "${SANDBOX}/outside")" ]]; then
      printf 'seed wrote through or around a %s directory collision\n' "${kind}" >&2
      failed=1
    fi
  done
  return "${failed}"
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
  printf '@AGENTS.md\n' > "${SANDBOX}/example-project/CLAUDE.md"
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
  test_leaves_missing_claude_files_absent
  test_commits_seed
  test_refuses_reseed
  test_preserves_existing_claude_files_byte_for_byte
  test_warns_for_unlinked_claude_files_after_seeding
  test_respects_a_claude_symlink_to_agents
  test_rejects_an_agents_hardlink_to_claude_before_seeding
  test_rejects_an_overlay_symlink_to_claude_before_seeding
  test_rejects_an_overlay_symlink_to_agents_before_seeding
  test_seeding_rejects_dangling_instruction_aliases_before_writing
  test_creates_agents_md_when_missing
  test_rejects_missing_directory
  test_rejects_unwritable_repo
  test_usage_without_args
  test_refuses_home_directory
  test_refuses_template_as_project_repo
  test_refuses_without_gnu_realpath
  test_seeder_merges_into_existing_rules
  test_seeder_merges_into_existing_docs
  test_seed_preserves_existing_docs_readme_byte_for_byte
  test_seed_refuses_to_change_a_readme_linked_to_agents
  test_seed_rejects_nested_project_directory_links_before_appending
  test_seed_keeps_a_link_to_a_missing_docs_directory_dangling
  test_seed_does_not_complete_a_missing_symlink_traversal
  test_seed_allows_an_unrelated_missing_symlink_traversal
  test_seed_detection_does_not_require_a_ribbon_readme
  test_similar_readme_text_does_not_select_legacy_amendment
  test_seed_refuses_an_unrelated_existing_seed_record
  test_seed_record_is_generated_not_copied_from_the_source
  test_ignored_seed_record_blocks_full_install_before_writes
  test_seed_skips_dangling_docs_and_rule_entries
  test_seed_rejects_unsafe_project_directory_before_writing
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

#######################################
# Run every test once, labelling each result with the tools it ran on.
# Arguments:
#   1: the label after each test name, empty for the host's own tools.
#######################################
run_suite() {
  local label="$1" test
  for test in "${TESTS[@]}"; do
    if "${test}" >/dev/null 2>&1; then
      record "${test}${label}" 0
    else
      record "${test}${label}" 1
    fi
  done
}

#######################################
# Run the suite on the host's tools, then again as a Mac with Homebrew
# coreutils, so no guard depends on GNU realpath being named realpath.
#######################################
main() {
  make_stock_macos
  make_homebrew_coreutils
  run_suite ''
  PATH="${COREUTILS_BIN}:${MACOS_BIN}:${PATH}"
  run_suite ' [macOS + coreutils]'
  printf '1..%d\n' "$((PASS + FAIL))"
  (( FAIL == 0 ))
}

main "$@"
