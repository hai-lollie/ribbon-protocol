#!/usr/bin/env bash
# Tests for scripts/ribbon-seed-project (the full install): one function per
# test, run in order by main, once on the host's tools and once as a Mac with
# Homebrew coreutils. Each test builds its own throwaway git repository; the
# real template repo provides the seeds. Names are generic.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RIBBON_HOME="$(dirname "${SCRIPT_DIR}")"
SEEDER="${SCRIPT_DIR}/ribbon-seed-project"
START_MARK='<!-- ribbon:full-install:start -->'
END_MARK='<!-- ribbon:full-install:end -->'
STANDALONE_MARK='<!-- ribbon:standalone:start -->'
readonly SCRIPT_DIR RIBBON_HOME SEEDER START_MARK END_MARK STANDALONE_MARK

PASS=0
FAIL=0
SANDBOX=''
MACOS_BIN=''
COREUTILS_BIN=''
HOST_GNU_REALPATH=''

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
# Find the host's GNU realpath, which both stand-ins resolve with: realpath
# on Linux, grealpath on a Mac with Homebrew coreutils.
# Globals:
#   HOST_GNU_REALPATH (set)
#######################################
find_host_gnu_realpath() {
  local candidate
  for candidate in realpath grealpath; do
    if "${candidate}" -m -- / >/dev/null 2>&1; then
      HOST_GNU_REALPATH="$(command -v "${candidate}")"
      return 0
    fi
  done
  printf 'needs GNU realpath on the host; on macOS: brew install coreutils\n' >&2
  return 1
}

#######################################
# Put stand-ins for a stock Mac's tools in a fresh directory. Its realpath is
# BSD's: it takes only -q, rejects every other option with BSD's message and
# fails on a path that does not exist (the host's GNU realpath -e resolves).
# Its grealpath is missing, since Homebrew's coreutils is not installed.
# Globals:
#   HOST_GNU_REALPATH
#   MACOS_BIN (set)
#######################################
make_stock_macos() {
  MACOS_BIN="$(mktemp -d)"
  {
    printf '#!/usr/bin/env bash\n'
    printf 'gnu_realpath=%q\n' "${HOST_GNU_REALPATH}"
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
#   HOST_GNU_REALPATH
#   COREUTILS_BIN (set)
#######################################
make_homebrew_coreutils() {
  COREUTILS_BIN="$(mktemp -d)"
  printf '#!/usr/bin/env bash\nexec %q "$@"\n' "${HOST_GNU_REALPATH}" > "${COREUTILS_BIN}/grealpath"
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

#######################################
# The template's renderer, the oracle for the block and the seat files.
# Arguments:
#   The renderer's arguments.
#######################################
render_protocol() {
  "${RIBBON_HOME}/scripts/ribbon-render-protocol" \
    --protocol "${RIBBON_HOME}/protocol" \
    --set PROTOCOL_DIR=.ribbon/protocol "$@"
}

#######################################
# The seat plan of a full install: '<piece><TAB><installed path>' lines.
#######################################
seat_plan() {
  render_protocol --seat-files project-structure.md
}

#######################################
# The full-install block of I6, byte for byte.
#######################################
expected_block() {
  printf '\n%s\n' "${START_MARK}"
  render_protocol project-structure.md
  printf '%s\n' "${END_MARK}"
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

test_seeding_rejects_dangling_instruction_aliases_before_writing() {
  local row mode name destination repo head rc failed=0
  local -a flags
  for row in \
      'seed CLAUDE.md .ribbon/protocol/actors/architect.md' \
      'seed AGENTS.local.md .ribbon/protocol/flows/adr.md' \
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
  cp -R "${RIBBON_HOME}/docs" "${RIBBON_HOME}/rules" "${RIBBON_HOME}/protocol" "${template}/"
  mkdir "${template}/scripts"
  cp "${RIBBON_HOME}/scripts/ribbon-render-protocol" "${template}/scripts/"
  cp "${RIBBON_HOME}/VERSION" "${template}/"
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
  printf '@AGENTS.md\n' > "${SANDBOX}/example-project/CLAUDE.md"
  printf 'staged edit\n' >> "${SANDBOX}/example-project/CLAUDE.md"
  git -C "${SANDBOX}/example-project" add CLAUDE.md
  seed "${SANDBOX}/example-project" >/dev/null 2>&1
  ! git -C "${SANDBOX}/example-project" show HEAD:CLAUDE.md 2>/dev/null | grep -q 'staged edit' \
    && git -C "${SANDBOX}/example-project" diff --cached --name-only | grep -qx 'CLAUDE.md'
}

test_uninstall_preview_leaves_installation_unchanged() {
  new_repo
  local repo="${SANDBOX}/example-project" head
  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  head="$(git -C "${repo}" rev-parse HEAD)"
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents-before"

  seed --uninstall --yes "${repo}" </dev/null > "${SANDBOX}/preview" 2>&1 || return 1

  grep -Fq 'docs/tasks/_template.plan.yaml' "${SANDBOX}/preview" \
    && [[ -f "${repo}/docs/tasks/_template.plan.yaml" && -f "${repo}/docs/.ribbon-full-install" ]] \
    && [[ -f "${repo}/docs/.ribbon-full-install-receipt" ]] \
    && cmp -s "${SANDBOX}/agents-before" "${repo}/AGENTS.md" \
    && [[ "$(git -C "${repo}" rev-parse HEAD)" == "${head}" ]] \
    && [[ -z "$(git -C "${repo}" status --porcelain)" ]]
}

test_uninstall_without_terminal_requires_explicit_yes() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1

  seed --uninstall --remove-ribbon "${repo}" </dev/null > "${SANDBOX}/error" 2>&1 || rc=$?

  [[ "${rc}" != 0 && -f "${repo}/docs/tasks/_template.plan.yaml" && -f "${repo}/docs/.ribbon-full-install" ]] \
    && grep -Fq -- '--yes' "${SANDBOX}/error" \
    && [[ -z "$(git -C "${repo}" status --porcelain)" ]]
}

test_uninstall_removes_only_unchanged_owned_full_install_content() {
  new_repo
  local repo="${SANDBOX}/example-project" head
  mkdir "${repo}/docs"
  printf '# Project README\r\nNo trailing newline' > "${repo}/docs/README.md"
  cp "${repo}/docs/README.md" "${SANDBOX}/readme-before"
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents-before"
  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  head="$(git -C "${repo}" rev-parse HEAD)"
  printf 'changed template bytes\r\n' > "${repo}/docs/tasks/_template.plan.yaml"
  printf '# Live plan\n' > "${repo}/docs/tasks/live.plan.yaml"

  seed --uninstall --remove-ribbon --yes "${repo}" </dev/null > "${SANDBOX}/output" 2>&1 || return 1

  [[ ! -e "${repo}/docs/tasks/_template.task.yaml" && ! -e "${repo}/docs/.ribbon-full-install" ]] \
    && [[ ! -e "${repo}/docs/.ribbon-full-install-receipt" ]] \
    && [[ -f "${repo}/docs/adrs/_template.md" && -f "${repo}/docs/diagrams/README.md" && -f "${repo}/rules/testing.md" ]] \
    && grep -Fq 'changed template bytes' "${repo}/docs/tasks/_template.plan.yaml" \
    && grep -Fxq '# Live plan' "${repo}/docs/tasks/live.plan.yaml" \
    && cmp -s "${SANDBOX}/readme-before" "${repo}/docs/README.md" \
    && cmp -s "${SANDBOX}/agents-before" "${repo}/AGENTS.md" \
    && grep -Fq 'Review changed files manually' "${SANDBOX}/output" \
    && grep -Fq 'docs/tasks/_template.plan.yaml' "${SANDBOX}/output" \
    && [[ "$(git -C "${repo}" rev-parse HEAD)" == "${head}" ]] \
    && [[ -z "$(git -C "${repo}" diff --cached --name-only)" ]]
}

test_uninstall_refuses_unproven_ownership() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  mkdir -p "${repo}/docs/tasks"
  printf 'Seeded from the Ribbon Protocol, ribbon 1.\n' > "${repo}/docs/.ribbon-full-install"
  printf '# Keep this file\n' > "${repo}/docs/tasks/_template.plan.yaml"

  seed --uninstall --remove-ribbon --yes "${repo}" </dev/null > "${SANDBOX}/error" 2>&1 || rc=$?

  [[ "${rc}" != 0 && -f "${repo}/docs/.ribbon-full-install" ]] \
    && grep -Fq 'ownership' "${SANDBOX}/error" \
    && grep -Fxq '# Keep this file' "${repo}/docs/tasks/_template.plan.yaml"
}

# Uninstall never runs on the template repository, here named by --ribbon-home.
test_uninstall_refuses_the_template_repository() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1

  seed --ribbon-home "${repo}" --uninstall --remove-ribbon --yes "${repo}" \
    </dev/null >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && -f "${repo}/docs/tasks/_template.plan.yaml" ]] \
    && [[ -f "${repo}/docs/.ribbon-full-install-receipt" ]] \
    && grep -Fq 'refusing to uninstall from the filesystem root, home, or template repository' "${SANDBOX}/error"
}

test_uninstall_stops_before_removal_when_a_parent_is_not_writable() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents-before"
  chmod u-w "${repo}/docs/tasks"

  seed --uninstall --remove-ribbon --yes "${repo}" </dev/null > "${SANDBOX}/error" 2>&1 || rc=$?

  chmod u+w "${repo}/docs/tasks"
  [[ "${rc}" != 0 && -f "${repo}/docs/.ribbon-full-install" && -f "${repo}/docs/tasks/_template.task.yaml" ]] \
    && grep -Fiq 'permission' "${SANDBOX}/error" \
    && grep -Fq 'docs/tasks' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/agents-before" "${repo}/AGENTS.md"
}

test_uninstall_keeps_an_edited_agents_block() {
  new_repo
  local repo="${SANDBOX}/example-project"
  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  sed -i '/ribbon:full-install:start/a project edit inside the installed block' "${repo}/AGENTS.md"
  cp "${repo}/AGENTS.md" "${SANDBOX}/before"

  seed --uninstall --remove-ribbon --yes "${repo}" </dev/null > "${SANDBOX}/output" 2>&1 || return 1

  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.md" \
    && grep -Fq 'Review changed files manually' "${SANDBOX}/output" \
    && grep -Fxq '  AGENTS.md' "${SANDBOX}/output" \
    && [[ ! -e "${repo}/docs/tasks/_template.task.yaml" ]]
}

test_uninstall_default_no_prompt_is_visible_with_stdout_redirected() {
  new_repo
  local repo="${SANDBOX}/example-project"
  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1

  python3 - "${SEEDER}" "${repo}" "${SANDBOX}/stdout" <<'PY' || return 1
import os, pty, select, subprocess, sys, time
seeder, repo, log = sys.argv[1:]
master, slave = pty.openpty()
with open(log, "wb") as output:
    child = subprocess.Popen([seeder, "--uninstall", "--remove-ribbon", repo],
                             stdin=slave, stdout=output, stderr=slave)
    os.close(slave)
    try:
        terminal = b""
        deadline = time.monotonic() + 4
        while b"[y/N]" not in terminal and (remaining := deadline - time.monotonic()) > 0:
            if not select.select([master], [], [], remaining)[0]:
                break
            terminal += os.read(master, 4096)
        os.write(master, b"\n")
        assert child.wait(timeout=4) == 0
        assert b"[y/N]" in terminal, "confirmation prompt was not visible in the terminal"
    finally:
        os.close(master)
        if child.poll() is None:
            child.terminate()
            child.wait(timeout=4)
PY
  grep -Fq 'Uninstall declined; nothing removed.' "${SANDBOX}/stdout" \
    && [[ -f "${repo}/docs/.ribbon-full-install-receipt" ]] \
    && [[ -z "$(git -C "${repo}" status --porcelain)" ]]
}

uninstall_fault_fixture() {
  mkdir "${SANDBOX}/python"
  cat > "${SANDBOX}/python/sitecustomize.py" <<'PY'
import errno, os
from pathlib import Path

real_unlink = os.unlink
first = True

def unlink(path, *args, **kwargs):
    global first
    name = os.path.basename(os.fsdecode(path))
    mode = os.environ["RIBBON_FAULT_MODE"]
    if mode == "permission" and name == "architect.md":
        raise PermissionError(errno.EACCES, "Permission denied", path)
    result = real_unlink(path, *args, **kwargs)
    if mode == "swap" and first and name == "README.md":
        first = False
        docs = Path(os.environ["RIBBON_TEST_REPO"]) / "docs"
        (docs / "tasks").rename(docs / "tasks-before")
        (docs / "tasks").symlink_to(os.environ["RIBBON_TEST_OUTSIDE"], target_is_directory=True)
    return result

os.unlink = unlink
PY
}

test_uninstall_reports_completed_paths_when_a_later_removal_fails() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  uninstall_fault_fixture

  PYTHONPATH="${SANDBOX}/python" RIBBON_FAULT_MODE=permission \
    seed --uninstall --remove-ribbon --yes "${repo}" </dev/null > "${SANDBOX}/error" 2>&1 || rc=$?

  [[ "${rc}" != 0 && ! -e "${repo}/docs/README.md" ]] \
    && [[ -f "${repo}/.ribbon/protocol/actors/architect.md" && -f "${repo}/docs/.ribbon-full-install-receipt" ]] \
    && grep -Fq 'Completed before uninstall stopped:' "${SANDBOX}/error" \
    && grep -Fxq '  docs/README.md' "${SANDBOX}/error" \
    && grep -Fq 'Permission denied' "${SANDBOX}/error"
}

test_uninstall_never_follows_a_parent_swapped_during_removal() {
  new_repo
  local repo="${SANDBOX}/example-project" outside="${SANDBOX}/outside" rc=0
  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  cp -R "${repo}/docs/tasks" "${outside}"
  uninstall_fault_fixture

  PYTHONPATH="${SANDBOX}/python" RIBBON_FAULT_MODE=swap RIBBON_TEST_REPO="${repo}" RIBBON_TEST_OUTSIDE="${outside}" \
    seed --uninstall --remove-ribbon --yes "${repo}" </dev/null > "${SANDBOX}/error" 2>&1 || rc=$?

  [[ "${rc}" != 0 && -L "${repo}/docs/tasks" && ! -e "${repo}/docs/README.md" ]] \
    && cmp -s "${outside}/_template.plan.yaml" "${RIBBON_HOME}/docs/tasks/_template.plan.yaml" \
    && [[ -f "${repo}/docs/tasks-before/_template.task.yaml" && -f "${repo}/docs/.ribbon-full-install-receipt" ]] \
    && grep -Fq 'docs/tasks/' "${SANDBOX}/error"
}

#######################################
# Build a v1 full install by hand: ribbon 1's line-oriented block, the seed
# record and a v1 receipt whose digests match the bytes on disk.
# Arguments:
#   The project repository.
# Globals:
#   START_MARK, END_MARK, SANDBOX
#######################################
create_older_full_install() {
  local repo="$1" block="${SANDBOX}/older-block" record="${SANDBOX}/older-record"
  mkdir -p "${repo}/docs"
  printf 'Seeded from the Ribbon Protocol, ribbon 1.\n' > "${record}"
  cp "${record}" "${repo}/docs/.ribbon-full-install"
  printf '\n%s\nold protocol text\n%s\n' "${START_MARK}" "${END_MARK}" > "${block}"
  cat "${block}" >> "${repo}/AGENTS.md"
  {
    printf 'ribbon-full-install-receipt-v1\0'
    printf 'file\0docs/.ribbon-full-install\0%s\0' "$(sha256sum < "${record}" | cut -d' ' -f1)"
    printf 'block\0AGENTS.md\0%s\0' "$(sha256sum < "${block}" | cut -d' ' -f1)"
  } > "${repo}/docs/.ribbon-full-install-receipt"
}

test_block_is_the_rendering_of_the_project_structure() {
  new_repo
  local repo="${SANDBOX}/example-project"
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents-before"

  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1

  {
    cat "${SANDBOX}/agents-before"
    expected_block
  } > "${SANDBOX}/agents-expected"
  cmp -s "${SANDBOX}/agents-expected" "${repo}/AGENTS.md"
}

test_new_agents_md_is_the_block_alone() {
  new_repo
  local repo="${SANDBOX}/example-project"
  rm "${repo}/AGENTS.md"

  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1

  expected_block > "${SANDBOX}/agents-expected"
  cmp -s "${SANDBOX}/agents-expected" "${repo}/AGENTS.md"
}

test_installs_the_seat_files_under_ribbon_protocol() {
  new_repo
  local repo="${SANDBOX}/example-project" path installed count=0

  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  seat_plan > "${SANDBOX}/seat-plan" || return 1

  while IFS=$'\t' read -r path installed; do
    [[ -n "${path}" ]] || continue
    render_protocol "${path}" > "${SANDBOX}/seat-expected" || return 1
    cmp -s "${SANDBOX}/seat-expected" "${repo}/.ribbon/protocol/${installed}" || return 1
    git -C "${repo}" ls-files --error-unmatch ".ribbon/protocol/${installed}" \
      >/dev/null 2>&1 || return 1
    count=$((count + 1))
  done < "${SANDBOX}/seat-plan"
  (( count > 0 ))
}

test_writes_no_herdr_config() {
  new_repo
  local repo="${SANDBOX}/example-project"

  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1

  [[ ! -e "${repo}/herdr-config.md" && ! -L "${repo}/herdr-config.md" ]] \
    && ! git -C "${repo}" show --name-only --format= HEAD | grep -qx 'herdr-config.md'
}

test_leaves_an_overlay_link_alone() {
  new_repo
  local repo="${SANDBOX}/example-project"
  printf '# Claude owns this file\r\nNo final newline' > "${repo}/CLAUDE.local.md"
  cp "${repo}/CLAUDE.local.md" "${SANDBOX}/claude-before"
  ln -s CLAUDE.local.md "${repo}/herdr-config.md"

  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1

  [[ "$(readlink "${repo}/herdr-config.md")" == CLAUDE.local.md ]] \
    && cmp -s "${SANDBOX}/claude-before" "${repo}/CLAUDE.local.md" \
    && ! git -C "${repo}" show --name-only --format= HEAD | grep -qx 'herdr-config.md'
}

test_refuses_a_project_with_a_standalone_install() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0 head
  printf '# Local rules\n%s\n' "${STANDALONE_MARK}" > "${repo}/AGENTS.local.md"
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents-before"
  head="$(git -C "${repo}" rev-parse HEAD)"

  seed "${repo}" </dev/null >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs" && ! -e "${repo}/.ribbon" ]] \
    && grep -Fq 'has a standalone install in AGENTS.local.md' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/agents-before" "${repo}/AGENTS.md" \
    && [[ "$(git -C "${repo}" rev-parse HEAD)" == "${head}" ]]
}

test_refuses_an_agents_md_that_holds_a_ribbon_block() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  printf '%s\n' "${START_MARK}" >> "${repo}/AGENTS.md"
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents-before"

  seed "${repo}" </dev/null >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs" ]] \
    && [[ "$(cat "${SANDBOX}/error")" == "ribbon-seed-project: AGENTS.md already holds a Ribbon block; remove it, then install" ]] \
    && cmp -s "${SANDBOX}/agents-before" "${repo}/AGENTS.md"
}

test_refuses_an_existing_ribbon_directory() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  mkdir "${repo}/.ribbon"

  seed "${repo}" </dev/null >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs" ]] \
    && [[ "$(cat "${SANDBOX}/error")" == "ribbon-seed-project: reserved path exists: ${repo}/.ribbon; left untouched" ]] \
    && [[ -d "${repo}/.ribbon" && -z "$(ls -A "${repo}/.ribbon")" ]]
}

test_refuses_a_ribbon_directory_link() {
  new_repo
  local repo="${SANDBOX}/example-project" outside="${SANDBOX}/outside" rc=0
  mkdir "${outside}"
  ln -s "${outside}" "${repo}/.ribbon"

  seed "${repo}" </dev/null >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs" ]] \
    && [[ -L "${repo}/.ribbon" && "$(readlink "${repo}/.ribbon")" == "${outside}" ]] \
    && [[ -z "$(ls -A "${outside}")" ]] \
    && grep -Fq "reserved path exists: ${repo}/.ribbon; left untouched" "${SANDBOX}/error"
}

test_refuses_an_ignored_seat_file() {
  new_repo
  local repo="${SANDBOX}/example-project" rc=0
  printf '.ribbon/\n' > "${repo}/.gitignore"

  seed "${repo}" </dev/null >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${repo}/docs" && ! -e "${repo}/.ribbon" ]] \
    && grep -Fq 'seat file is ignored by Git: .ribbon/protocol/' "${SANDBOX}/error"
}

test_receipt_v2_records_the_block_and_the_seat_files() {
  new_repo
  local repo="${SANDBOX}/example-project"

  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  seat_plan > "${SANDBOX}/seat-plan" || return 1

  python3 - "${repo}/docs/.ribbon-full-install-receipt" "${SANDBOX}/seat-plan" <<'PY'
import sys

receipt, plan = sys.argv[1:]
fields = open(receipt, "rb").read().split(b"\0")
assert fields[0] == b"ribbon-full-install-receipt-v2", fields[0]
assert fields[-1] == b"", fields[-1]
entries = [tuple(fields[i:i + 3]) for i in range(1, len(fields) - 1, 3)]
assert all(kind in (b"file", b"block", b"created-block") for kind, _, _ in entries)
blocks = [name for kind, name, _ in entries if kind in (b"block", b"created-block")]
assert blocks == [b"AGENTS.md"], blocks
files = {name for kind, name, _ in entries if kind == b"file"}
for line in open(plan, "rb").read().splitlines():
    _, installed = line.split(b"\t")
    assert b".ribbon/protocol/" + installed in files, installed
PY
}

test_uninstall_removes_the_block_with_a_filled_roster_and_gate() {
  new_repo
  local repo="${SANDBOX}/example-project"
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents-before"

  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  sed -i "s/TODO(belt): a person's name/Lollie/" "${repo}/AGENTS.md"
  sed -i 's/^The gate: TODO(belt): the exact commands, in order\.$/The gate: make test/' \
    "${repo}/AGENTS.md"

  seed --uninstall --remove-ribbon --yes "${repo}" </dev/null >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/agents-before" "${repo}/AGENTS.md" \
    && [[ ! -e "${repo}/.ribbon" && ! -e "${repo}/docs/.ribbon-full-install-receipt" ]]
}

test_uninstall_removes_an_agents_md_that_the_install_created() {
  new_repo
  local repo="${SANDBOX}/example-project"
  rm "${repo}/AGENTS.md"

  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  [[ -f "${repo}/AGENTS.md" ]] || return 1

  seed --uninstall --remove-ribbon --yes "${repo}" </dev/null >/dev/null 2>&1 || return 1

  [[ ! -e "${repo}/AGENTS.md" && ! -e "${repo}/.ribbon" ]]
}

test_uninstall_keeps_an_edited_seat_file_and_removes_the_rest() {
  new_repo
  local repo="${SANDBOX}/example-project" installed edited='flows/adr.md'

  seed "${repo}" </dev/null >/dev/null 2>&1 || return 1
  printf '\nA project edit.\n' >> "${repo}/.ribbon/protocol/${edited}"

  seed --uninstall --remove-ribbon --yes "${repo}" </dev/null > "${SANDBOX}/output" 2>&1 || return 1
  seat_plan > "${SANDBOX}/seat-plan" || return 1

  [[ -f "${repo}/.ribbon/protocol/${edited}" ]] \
    && [[ "$(tail -1 "${repo}/.ribbon/protocol/${edited}")" == 'A project edit.' ]] \
    && grep -Fq 'Review changed files manually' "${SANDBOX}/output" \
    && grep -Fxq "  .ribbon/protocol/${edited}" "${SANDBOX}/output" \
    && [[ -d "${repo}/.ribbon/protocol/flows" && -d "${repo}/.ribbon/protocol" && -d "${repo}/.ribbon" ]] \
    && [[ ! -e "${repo}/.ribbon/protocol/actors" && ! -e "${repo}/.ribbon/protocol/guidance" \
      && ! -e "${repo}/.ribbon/protocol/handlers" ]] \
    || return 1
  while IFS=$'\t' read -r _ installed; do
    [[ "${installed}" == "${edited}" || ! -e "${repo}/.ribbon/protocol/${installed}" ]] || return 1
  done < "${SANDBOX}/seat-plan"
}

test_uninstall_still_removes_an_older_full_install() {
  new_repo
  local repo="${SANDBOX}/example-project"
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents-before"
  create_older_full_install "${repo}"

  seed --uninstall --remove-ribbon --yes "${repo}" </dev/null >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/agents-before" "${repo}/AGENTS.md" \
    && [[ ! -e "${repo}/docs/.ribbon-full-install" && ! -e "${repo}/docs/.ribbon-full-install-receipt" ]]
}

readonly TESTS=(
  test_seeder_exists
  test_seeds_docs
  test_stamps_version
  test_appends_protocol_preserving_content
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
  test_uninstall_preview_leaves_installation_unchanged
  test_uninstall_without_terminal_requires_explicit_yes
  test_uninstall_removes_only_unchanged_owned_full_install_content
  test_uninstall_refuses_unproven_ownership
  test_uninstall_refuses_the_template_repository
  test_uninstall_stops_before_removal_when_a_parent_is_not_writable
  test_uninstall_keeps_an_edited_agents_block
  test_uninstall_default_no_prompt_is_visible_with_stdout_redirected
  test_uninstall_reports_completed_paths_when_a_later_removal_fails
  test_uninstall_never_follows_a_parent_swapped_during_removal
  test_block_is_the_rendering_of_the_project_structure
  test_new_agents_md_is_the_block_alone
  test_installs_the_seat_files_under_ribbon_protocol
  test_writes_no_herdr_config
  test_leaves_an_overlay_link_alone
  test_refuses_a_project_with_a_standalone_install
  test_refuses_an_agents_md_that_holds_a_ribbon_block
  test_refuses_an_existing_ribbon_directory
  test_refuses_a_ribbon_directory_link
  test_refuses_an_ignored_seat_file
  test_receipt_v2_records_the_block_and_the_seat_files
  test_uninstall_removes_the_block_with_a_filled_roster_and_gate
  test_uninstall_removes_an_agents_md_that_the_install_created
  test_uninstall_keeps_an_edited_seat_file_and_removes_the_rest
  test_uninstall_still_removes_an_older_full_install
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
  find_host_gnu_realpath || return 1
  make_stock_macos
  make_homebrew_coreutils
  run_suite ''
  PATH="${COREUTILS_BIN}:${MACOS_BIN}:${PATH}"
  run_suite ' [macOS + coreutils]'
  printf '1..%d\n' "$((PASS + FAIL))"
  (( FAIL == 0 ))
}

main "$@"
