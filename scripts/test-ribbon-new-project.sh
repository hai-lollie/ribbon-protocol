#!/usr/bin/env bash
# Tests for scripts/ribbon-new-project: one function per test, run in order
# by main, once on the host's tools and once as a Mac with Homebrew coreutils.
# Each test builds its own throwaway projects dir; the real template repo
# provides the seeds. Project and instance names are generic.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RIBBON_HOME="$(dirname "${SCRIPT_DIR}")"
INSTALLER="${SCRIPT_DIR}/ribbon-new-project"
readonly SCRIPT_DIR RIBBON_HOME INSTALLER

PASS=0
FAIL=0
SANDBOX=''
PROJECTS=''
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
# Run the installer in uninstall mode against the sandbox projects dir.
# Arguments:
#   Remaining installer arguments.
#######################################
uninstall() {
  "${INSTALLER}" --projects "${PROJECTS}" --uninstall "$@"
}

#######################################
# Run a command with stdin on a pseudo-terminal, answering its question
# with the given answer; the exit code is the command's, and its stderr
# is printed on stdout.
# Arguments:
#   The answer ('n' or 'yes'), then the command and its arguments.
#######################################
run_on_a_terminal() {
  local answer="$1"
  shift
  python3 - "${answer}" "$@" <<'PY'
import os
import pty
import subprocess
import sys

answer, command = sys.argv[1], sys.argv[2:]
master, slave = pty.openpty()
process = subprocess.Popen(command, stdin=slave,
                           stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
os.close(slave)
os.write(master, answer.encode() + b"\n")
stderr = process.stderr.read()
process.wait()
os.close(master)
sys.stdout.buffer.write(stderr)
sys.exit(process.returncode)
PY
}

#######################################
# A ribbon 1 standalone install, made by hand: an AGENTS.local.md with a
# ribbon 1 block (belt marks, no gate), the pointer line in AGENTS.md,
# the ribbon 1 hook, and an instance with a live plan.
# Arguments:
#   The project repo path.
#######################################
make_older_standalone_install() {
  local repo="$1" instance="${PROJECTS}/example-project"
  mkdir -p "${instance}/docs/tasks"
  printf 'live plan\n' > "${instance}/docs/tasks/live-plan.yaml"
  printf '%s\n' "${repo}" > "${instance}/project-repo"
  cat > "${repo}/AGENTS.local.md" <<'EOF'
# my notes

<!-- ribbon:standalone:start -->
# Ribbon Protocol, standalone mode
<!-- ribbon:belt:start -->
| Role | Agent | Model |
|---|---|---|
| Senior architect | Ana | human |
<!-- ribbon:belt:end -->
old rules text
<!-- ribbon:standalone:end -->
EOF
  printf '\n%s\n' 'Ribbon Protocol (standalone): this machine'"'"'s working files live outside this repository; read AGENTS.local.md for where each file lives.' \
    >> "${repo}/AGENTS.md"
  mkdir -p "${repo}/.git/hooks"
  sed 's/AGENTS.local.md /AGENTS.local.md herdr-config.md /' \
    "${RIBBON_HOME}/scripts/standalone-post-checkout" > "${repo}/.git/hooks/post-checkout"
  chmod +x "${repo}/.git/hooks/post-checkout"
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

#######################################
# Render a template of the real protocol with the six values a fresh
# install of example-project uses: the test's oracle, never the
# installer's own output.
# Arguments:
#   Renderer arguments after the --set values (mode flags and TEMPLATE).
#######################################
render_standalone() {
  "${RIBBON_HOME}/scripts/ribbon-render-protocol" \
    --protocol "${RIBBON_HOME}/protocol" \
    --set "RIBBON_HOME=${RIBBON_HOME}" \
    --set "RIBBON_PROJECTS=${PROJECTS}" \
    --set "INSTANCE=${PROJECTS}/example-project" \
    --set "PROJECT_NAME=example-project" \
    --set "PROJECT_REPO=${SANDBOX}/repos/example-project" \
    --set "PROTOCOL_DIR=${PROJECTS}/example-project/.ribbon/protocol" \
    "$@"
}

#######################################
# Succeed when the standalone block body of an AGENTS.local.md is the
# given rendering, without trailing whitespace, byte for byte.
# Arguments:
#   AGENTS.local.md path, rendering file path.
#######################################
assert_block_is_rendering() {
  python3 - "$1" "$2" <<'PY'
import sys

local = open(sys.argv[1], "rb").read()
expected = open(sys.argv[2], "rb").read()
start = b"<!-- ribbon:standalone:start -->\n"
end = b"\n<!-- ribbon:standalone:end -->"
if start not in local or end not in local:
    sys.exit(1)
body = local.split(start, 1)[1].split(end, 1)[0]
sys.exit(0 if body == expected.rstrip() else 1)
PY
}

#######################################
# Print the bytes of an AGENTS.local.md outside the standalone block: the
# prefix before the start mark, a NUL, the suffix after the end mark.
# Arguments:
#   AGENTS.local.md path.
#######################################
block_outside() {
  python3 - "$1" <<'PY'
import sys

data = open(sys.argv[1], "rb").read()
start = b"<!-- ribbon:standalone:start -->"
end = b"<!-- ribbon:standalone:end -->"
pre = data.split(start, 1)[0]
post = data.split(end, 1)[1]
sys.stdout.buffer.write(pre + b"\x00" + post)
PY
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

test_writes_no_herdr_config() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  [[ -f "${SANDBOX}/repos/example-project/AGENTS.local.md" ]] \
    && [[ -d "${PROJECTS}/example-project" ]] \
    && [[ ! -e "${SANDBOX}/repos/example-project/herdr-config.md" ]]
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
  install example-project --update >/dev/null 2>&1 || return 1
  [[ ! -e "${SANDBOX}/repos/example-project/rules/testing.md" ]]
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

test_update_preserves_existing_project_rules_byte_for_byte() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" name
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  for name in README.md testing.md clojure.md; do
    printf '# Project-owned %s\r\nNo trailing newline' "${name}" > "${SANDBOX}/${name}"
    cp "${SANDBOX}/${name}" "${repo}/rules/${name}"
  done

  install example-project --update >/dev/null 2>&1 || return 1

  for name in README.md testing.md clojure.md; do
    cmp -s "${SANDBOX}/${name}" "${repo}/rules/${name}" || return 1
  done
}

test_update_does_not_write_to_a_rule_linked_to_project_instructions() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  ln -f "${repo}/AGENTS.md" "${repo}/rules/testing.md"
  cp "${repo}/AGENTS.md" "${SANDBOX}/before"

  install example-project --update >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.md" \
    && [[ "${repo}/AGENTS.md" -ef "${repo}/rules/testing.md" ]]
}

test_install_skips_dangling_project_rule_entries() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" name
  mkdir -p "${repo}/rules" "${HOME}/.claude/rules"
  printf 'import candidate\n' > "${HOME}/.claude/rules/personal.md"
  for name in testing.md personal.md; do
    ln -s "${SANDBOX}/missing-target" "${repo}/rules/${name}"
  done

  install example-project "${repo}" --import-rules personal.md >/dev/null 2>&1 || return 1

  for name in testing.md personal.md; do
    [[ "$(readlink "${repo}/rules/${name}")" == "${SANDBOX}/missing-target" && ! -e "${repo}/rules/${name}" ]] || return 1
  done
  [[ -f "${repo}/rules/README.md" ]]
}

test_force_rejects_linked_project_rules_before_rebuild() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" live_card="${PROJECTS}/example-project/docs/tasks/live-card.yaml" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  mv "${repo}/rules" "${SANDBOX}/outside-rules"
  ln -s "${SANDBOX}/outside-rules" "${repo}/rules"
  printf 'live work\n' > "${live_card}"
  mkdir -p "${HOME}/.claude/rules"
  printf 'new rule\n' > "${HOME}/.claude/rules/new.md"

  install example-project "${repo}" --force --yes --import-rules new.md >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${SANDBOX}/outside-rules/new.md" ]] \
    && grep -Fq 'unsafe project directory' "${SANDBOX}/error" \
    && grep -Fxq 'live work' "${live_card}" \
    && [[ "$(readlink "${repo}/rules")" == "${SANDBOX}/outside-rules" ]]
}

test_update_rejects_linked_instance_directory_before_writing() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" docs="${PROJECTS}/example-project/docs" rc=0
  local outside="${SANDBOX}/outside-tasks"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  mv "${docs}/tasks" "${outside}"
  ln -s "${outside}" "${docs}/tasks"
  printf 'outside template bytes\r\nKeep me' > "${SANDBOX}/before-template"
  cp "${SANDBOX}/before-template" "${outside}/_template.plan.yaml"
  printf 'instance version unchanged\n' > "${docs}/README.md"

  install example-project --update >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 ]] \
    && grep -Fq 'unsafe instance directory' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/before-template" "${outside}/_template.plan.yaml" \
    && grep -Fxq 'instance version unchanged' "${docs}/README.md" \
    && [[ "$(readlink "${docs}/tasks")" == "${outside}" ]]
}

test_update_rejects_a_linked_instance_template_before_writing() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" docs="${PROJECTS}/example-project/docs" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  printf 'outside bytes\r\nNo trailing newline' > "${SANDBOX}/before"
  cp "${SANDBOX}/before" "${SANDBOX}/outside-template"
  ln -sf "${SANDBOX}/outside-template" "${docs}/tasks/_template.plan.yaml"
  printf 'instance version unchanged\n' > "${docs}/README.md"

  install example-project --update >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 ]] \
    && grep -Fq 'unsafe instance file' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/before" "${SANDBOX}/outside-template" \
    && grep -Fxq 'instance version unchanged' "${docs}/README.md"
}

test_update_does_not_rewrite_a_project_readme_linked_to_instance() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" docs="${PROJECTS}/example-project/docs" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  mkdir "${repo}/docs"
  printf 'shared README bytes\r\nKeep me' > "${docs}/README.md"
  ln "${docs}/README.md" "${repo}/docs/README.md"
  cp "${repo}/docs/README.md" "${SANDBOX}/before"

  install example-project --update >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 ]] \
    && grep -Fq 'would change existing project path: docs/README.md' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/before" "${repo}/docs/README.md" \
    && [[ "${repo}/docs/README.md" -ef "${docs}/README.md" ]]
}

test_force_preserves_a_project_readme_linked_to_live_instance_work() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  mkdir "${repo}/docs"
  printf '# Live work\n' > "${instance}/docs/tasks/live-card.yaml"
  ln -s "${instance}/docs/tasks/live-card.yaml" "${repo}/docs/README.md"

  install example-project "${repo}" --force --yes >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 ]] \
    && grep -Fq 'docs/README.md points inside the instance' "${SANDBOX}/error" \
    && grep -Fxq '# Live work' "${repo}/docs/README.md" \
    && [[ "$(readlink "${repo}/docs/README.md")" == "${instance}/docs/tasks/live-card.yaml" ]]
}

test_force_rejects_a_project_directory_link_to_the_instance_parent() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  mkdir "${repo}/docs"
  ln -s "${PROJECTS}" "${repo}/docs/shared"
  printf 'live work\n' > "${instance}/docs/tasks/live-card.yaml"

  install example-project "${repo}" --force --yes >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 ]] \
    && grep -Fq 'unsafe project directory link' "${SANDBOX}/error" \
    && grep -Fxq 'live work' "${repo}/docs/shared/example-project/docs/tasks/live-card.yaml" \
    && [[ "$(readlink "${repo}/docs/shared")" == "${PROJECTS}" ]]
}

test_update_rejects_a_linked_project_docs_root() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" outside="${SANDBOX}/outside-docs" rc=0
  local version="${PROJECTS}/example-project/docs/README.md"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  mkdir "${outside}"
  ln -s "${outside}" "${repo}/docs"
  ln -s "${version}" "${outside}/README.md"
  printf 'shared version\n' > "${version}"

  install example-project --update >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 ]] \
    && grep -Fq 'unsafe project directory link' "${SANDBOX}/error" \
    && grep -Fxq 'shared version' "${outside}/README.md" \
    && [[ "$(readlink "${repo}/docs")" == "${outside}" ]]
}

test_update_keeps_links_to_missing_instance_directories_dangling() {
  local name repo instance target rc failed=0
  for name in docs/tasks docs/llm-context/history; do
    new_sandbox
    repo="${SANDBOX}/repos/example-project"
    instance="${PROJECTS}/example-project"
    install example-project "${repo}" >/dev/null 2>&1 || return 1
    mkdir "${repo}/docs"
    target="${instance}/${name}"
    mv "${target}" "${SANDBOX}/kept-dir"
    ln -s "${target}" "${repo}/docs/README.md"
    printf 'instance stamp unchanged\n' > "${instance}/docs/README.md"

    rc=0
    install example-project --update >/dev/null 2> "${SANDBOX}/error" || rc=$?

    if [[ "${rc}" != 1 || -e "${target}" || "$(readlink "${repo}/docs/README.md")" != "${target}" ]] \
      || ! grep -Fq 'would change existing project path: docs/README.md' "${SANDBOX}/error" \
      || ! grep -Fxq 'instance stamp unchanged' "${instance}/docs/README.md"; then
      printf 'update populated the linked directory: %s\n' "${name}" >&2
      failed=1
    fi
  done
  return "${failed}"
}

test_update_does_not_complete_a_missing_symlink_traversal() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" docs="${PROJECTS}/example-project/docs" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  mkdir "${repo}/docs"
  mv "${docs}/tasks" "${SANDBOX}/kept-tasks"
  printf 'Existing instance content\n' > "${docs}/original.md"
  ln -s "${docs}/tasks/../original.md" "${repo}/docs/README.md"
  [[ ! -e "${repo}/docs/README.md" ]] || return 1
  printf 'instance stamp unchanged\n' > "${docs}/README.md"

  install example-project --update >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == 1 && ! -e "${docs}/tasks" && ! -e "${repo}/docs/README.md" ]] \
    && grep -Fq 'would change existing project path: docs/README.md' "${SANDBOX}/error" \
    && grep -Fxq 'instance stamp unchanged' "${docs}/README.md"
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

test_update_replaces_the_block_and_keeps_the_rest() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  sed -i '/ribbon:standalone:start/a dropped line inside the managed block' "${repo}/AGENTS.local.md"
  cp "${repo}/AGENTS.md" "${SANDBOX}/AGENTS.md.before"
  block_outside "${repo}/AGENTS.local.md" > "${SANDBOX}/outside.before"

  install example-project --update >/dev/null 2>&1 || return 1

  ! grep -q 'dropped line inside the managed block' "${repo}/AGENTS.local.md" || return 1
  cmp -s "${SANDBOX}/AGENTS.md.before" "${repo}/AGENTS.md" || return 1
  block_outside "${repo}/AGENTS.local.md" > "${SANDBOX}/outside.after"
  cmp -s "${SANDBOX}/outside.before" "${SANDBOX}/outside.after"
}

test_update_refuses_an_older_block() {
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
  local rc=0

  install example-project --update > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  cmp -s "${SANDBOX}/before" "${local_md}" || return 1
  grep -Fq 'holds an older standalone block' "${SANDBOX}/stderr" || return 1
  grep -Fq '| Senior architect | Ana | human | the problem | nothing |' "${SANDBOX}/stdout"
}

test_force_replaces_the_block_and_keeps_the_roster() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  sed -i "s/TODO(belt): a person's name/Ana/" "${repo}/AGENTS.local.md"
  sed -i '/ribbon:standalone:start/a dropped line inside the managed block' "${repo}/AGENTS.local.md"
  cp "${repo}/AGENTS.md" "${SANDBOX}/AGENTS.md.before"

  install example-project "${repo}" --force >/dev/null 2>&1 || return 1

  grep -q '^| Senior architect | Ana |' "${repo}/AGENTS.local.md" || return 1
  ! grep -q 'dropped line inside the managed block' "${repo}/AGENTS.local.md" || return 1
  cmp -s "${SANDBOX}/AGENTS.md.before" "${repo}/AGENTS.md"
}

test_update_keeps_one_belt_section() {
  new_sandbox
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1
  install example-project --update >/dev/null 2>&1
  install example-project --update >/dev/null 2>&1
  local local_md="${SANDBOX}/repos/example-project/AGENTS.local.md"
  [[ "$(belt_count 'ribbon:belt:start')" == "1" ]] \
    && [[ "$(belt_count 'ribbon:belt:end')" == "1" ]] \
    && [[ "$(belt_count 'ribbon:gate:start')" == "1" ]] \
    && [[ "$(belt_count 'ribbon:gate:end')" == "1" ]] \
    && [[ "$(grep -c '^| Seat | Agent | Model |$' "${local_md}")" == "1" ]]
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
    && sed -n '/ribbon:belt:start/,/ribbon:belt:end/p' "${local_md}" \
      | grep -q '^| Seat | Agent | Model |$' \
    && ! sed -n '/ribbon:belt:start/,/ribbon:belt:end/p' "${local_md}" \
      | grep -q '^## The belt$' \
    && [[ "$(belt_count 'ribbon:gate:start')" == "1" ]]
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
  local rc=0
  install example-project "${HOME}" >/dev/null 2> "${SANDBOX}/error" || rc=$?
  [[ "${rc}" == 1 && ! -e "${HOME}/AGENTS.local.md" ]] \
    && grep -Fq 'refusing to install into your home directory' "${SANDBOX}/error"
}

test_refuses_template_as_project_repo() {
  new_sandbox
  local rc=0
  install example-project "${RIBBON_HOME}" >/dev/null 2> "${SANDBOX}/error" || rc=$?
  [[ "${rc}" == 1 ]] \
    && grep -Fq 'refusing to install into the template repository itself' "${SANDBOX}/error"
}

# The instance path does not exist yet and only reaches into the repo
# through the link, so only a canonical path of a missing path catches it.
test_refuses_symlinked_overlap() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  ln -s "${repo}" "${SANDBOX}/repo-link"
  "${INSTALLER}" --projects "${SANDBOX}/repo-link" example-project "${repo}" \
    >/dev/null 2> "${SANDBOX}/error" || rc=$?
  [[ "${rc}" == 1 && ! -e "${repo}/example-project" && ! -e "${repo}/AGENTS.local.md" ]] \
    && grep -Fq 'project repo and instance path overlap' "${SANDBOX}/error"
}

test_refuses_template_as_instance() {
  new_sandbox
  local tmpl="${PROJECTS}/example-project"
  mkdir -p "${tmpl}/docs/tasks" "${tmpl}/docs/llm-context" "${tmpl}/rules" "${tmpl}/scripts" "${tmpl}/protocol"
  printf '# fake template\n' > "${tmpl}/AGENTS.standalone.md"
  printf '# fake\n' > "${tmpl}/AGENTS.md"
  printf 'ribbon 1\n' > "${tmpl}/VERSION"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${tmpl}/scripts/"
  cp "${RIBBON_HOME}/protocol/standalone-structure.md" "${tmpl}/protocol/"
  cp "${RIBBON_HOME}/scripts/ribbon-render-protocol" "${tmpl}/scripts/"
  chmod +x "${tmpl}/scripts/ribbon-render-protocol"
  local rc=0
  install --ribbon-home "${tmpl}" example-project \
      "${SANDBOX}/repos/example-project" --force >/dev/null 2> "${SANDBOX}/error" || rc=$?
  [[ "${rc}" == 1 && -f "${tmpl}/AGENTS.standalone.md" ]] \
    && grep -Fq 'overlaps the template repository' "${SANDBOX}/error"
}

test_refuses_template_inside_instance() {
  new_sandbox
  local tmpl="${PROJECTS}/example-project/inner-template"
  mkdir -p "${tmpl}/docs/tasks" "${tmpl}/docs/llm-context" "${tmpl}/rules" "${tmpl}/scripts" "${tmpl}/protocol"
  printf '# fake\n' > "${tmpl}/AGENTS.standalone.md"
  printf '# fake\n' > "${tmpl}/AGENTS.md"
  printf 'ribbon 1\n' > "${tmpl}/VERSION"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${tmpl}/scripts/"
  cp "${RIBBON_HOME}/protocol/standalone-structure.md" "${tmpl}/protocol/"
  cp "${RIBBON_HOME}/scripts/ribbon-render-protocol" "${tmpl}/scripts/"
  chmod +x "${tmpl}/scripts/ribbon-render-protocol"
  local rc=0
  install --ribbon-home "${tmpl}" example-project \
      "${SANDBOX}/repos/example-project" --force >/dev/null 2> "${SANDBOX}/error" || rc=$?
  [[ "${rc}" == 1 && -f "${tmpl}/AGENTS.standalone.md" ]] \
    && grep -Fq 'overlaps the template repository' "${SANDBOX}/error"
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

test_update_rejects_instruction_aliases_of_refresh_destinations() {
  local row name destination kind repo rc failed=0
  for row in \
      'CLAUDE.md docs/README.md symlink' \
      'CLAUDE.local.md docs/tasks/_template.task.yaml hardlink' \
      'AGENTS.local.md project-repo hardlink'; do
    read -r name destination kind <<< "${row}"
    new_sandbox
    repo="${SANDBOX}/repos/example-project"
    install example-project "${repo}" >/dev/null 2>&1 || return 1
    destination="${PROJECTS}/example-project/${destination}"
    printf '# Protected instructions\r\nDo not rewrite' > "${SANDBOX}/before"
    cp "${SANDBOX}/before" "${destination}"
    if [[ "${kind}" == symlink ]]; then
      ln -sf "${destination}" "${repo}/${name}"
    else
      ln -f "${destination}" "${repo}/${name}"
    fi
    printf 'original version\n' > "${SANDBOX}/version"
    if [[ "${destination}" != "${PROJECTS}/example-project/docs/README.md" ]]; then
      cp "${SANDBOX}/version" "${PROJECTS}/example-project/docs/README.md"
    fi
    cp "${PROJECTS}/example-project/docs/README.md" "${SANDBOX}/instance-readme"

    rc=0
    install example-project "${repo}" --update >/dev/null 2> "${SANDBOX}/error" || rc=$?

    if [[ "${rc}" != "1" ]] \
      || ! grep -Fq "would overwrite ${name}" "${SANDBOX}/error" \
      || ! cmp -s "${SANDBOX}/before" "${repo}/${name}" \
      || ! cmp -s "${SANDBOX}/instance-readme" "${PROJECTS}/example-project/docs/README.md"; then
      printf 'update did not protect: %s\n' "${row}" >&2
      failed=1
    fi
  done
  return "${failed}"
}

test_update_rejects_an_instruction_hardlink_to_the_managed_hook() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  git -C "${repo}" init -q
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  local hook="${repo}/.git/hooks/post-checkout"
  printf '\n# Protected instructions\n' >> "${hook}"
  ln "${hook}" "${repo}/CLAUDE.md"
  cp "${hook}" "${SANDBOX}/before"
  printf 'original version\n' > "${PROJECTS}/example-project/docs/README.md"

  install example-project --update >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == "1" ]] \
    && grep -Fq 'would overwrite CLAUDE.md' "${SANDBOX}/error" \
    && cmp -s "${SANDBOX}/before" "${repo}/CLAUDE.md" \
    && grep -Fxq 'original version' "${PROJECTS}/example-project/docs/README.md"
}

test_force_keeps_a_working_overlay_link_outside_the_instance() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  local live_card="${PROJECTS}/example-project/docs/tasks/live-card.yaml"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  printf 'custom overlay\n' > "${repo}/shared-overlay.md"
  ln -sf shared-overlay.md "${repo}/herdr-config.md"
  printf 'old instance work\n' > "${live_card}"

  install example-project "${repo}" --force --yes >/dev/null 2>&1 || return 1

  [[ ! -e "${live_card}" && "$(readlink "${repo}/herdr-config.md")" == shared-overlay.md ]] \
    && grep -Fxq 'custom overlay' "${repo}/herdr-config.md"
}

test_rule_seeds_and_imports_keep_instruction_aliases_dangling() {
  local row mode name destination repo instance rc failed=0
  local -a flags
  for row in \
      'install CLAUDE.md rules/testing.md' \
      'update CLAUDE.md rules/testing.md' \
      'force CLAUDE.local.md rules/testing.md' \
      'install CLAUDE.local.md rules/personal.md' \
      'update CLAUDE.local.md rules/personal.md' \
      'force CLAUDE.local.md rules/personal.md'; do
    read -r mode name destination <<< "${row}"
    new_sandbox
    repo="${SANDBOX}/repos/example-project"
    instance="${PROJECTS}/example-project"
    flags=()
    if [[ "${mode}" != install ]]; then
      flags=("--${mode}")
      mkdir -p "${instance}/docs/tasks"
      printf 'live work\n' > "${instance}/docs/tasks/live-card.yaml"
    fi
    if [[ "${destination}" == rules/personal.md ]]; then
      mkdir -p "${HOME}/.claude/rules"
      printf '# Personal rule\n' > "${HOME}/.claude/rules/personal.md"
      flags+=(--import-rules personal.md)
    fi
    ln -s "${destination}" "${repo}/${name}"
    cp "${repo}/AGENTS.md" "${SANDBOX}/before"

    rc=0
    install example-project "${repo}" "${flags[@]}" --yes >/dev/null 2> "${SANDBOX}/error" || rc=$?

    if [[ "${rc}" != "1" || -e "${repo}/rules" || -e "${instance}/docs/README.md" ]] \
      || ! grep -Fq "would overwrite ${name}" "${SANDBOX}/error" \
      || ! cmp -s "${SANDBOX}/before" "${repo}/AGENTS.md" \
      || [[ "$(readlink "${repo}/${name}")" != "${destination}" ]]; then
      printf 'install did not protect: %s\n' "${row}" >&2
      failed=1
    fi
    if [[ "${mode}" == install ]]; then
      [[ ! -e "${instance}" ]] || failed=1
    else
      grep -Fxq 'live work' "${instance}/docs/tasks/live-card.yaml" || failed=1
    fi
  done
  return "${failed}"
}

test_install_rejects_an_instruction_link_into_the_new_instance() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  ln -s "${instance}/docs/README.md" "${repo}/CLAUDE.md"

  install example-project "${repo}" >/dev/null 2> "${SANDBOX}/error" || rc=$?

  [[ "${rc}" == "1" && ! -e "${instance}" ]] \
    && grep -Fq 'CLAUDE.md points inside the instance' "${SANDBOX}/error"
}

test_force_refuses_an_older_block_without_belt_marks() {
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
  local rc=0

  install example-project "${repo}" --force --yes > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.local.md" || return 1
  [[ -d "${PROJECTS}/example-project/docs/tasks" ]] || return 1
  grep -Fq 'holds an older standalone block' "${SANDBOX}/stderr" || return 1
  [[ ! -s "${SANDBOX}/stdout" ]]
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
  install example-project "${SANDBOX}/repos/example-project" >/dev/null 2>&1 || return 1
  mkdir -p "${PROJECTS}/example-project/repo-inside"
  printf '# inside AGENTS\n' > "${PROJECTS}/example-project/repo-inside/AGENTS.md"
  local rc=0
  install example-project "${PROJECTS}/example-project/repo-inside" --force \
      >/dev/null 2> "${SANDBOX}/error" || rc=$?
  [[ "${rc}" == 1 && -d "${PROJECTS}/example-project/docs" ]] \
    && grep -Fq 'project repo and instance path overlap' "${SANDBOX}/error"
}

# A stock Mac's BSD realpath has no -m, so nothing resolves a path that does
# not exist yet: the installer stops before any write and names the fix.
test_refuses_without_gnu_realpath() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  PATH="${MACOS_BIN}:${PATH}" "${INSTALLER}" --projects "${PROJECTS}" example-project "${repo}" \
    >/dev/null 2> "${SANDBOX}/error" || rc=$?
  [[ "${rc}" == 1 && ! -e "${PROJECTS}/example-project" && ! -e "${repo}/AGENTS.local.md" ]] \
    && grep -Fq 'brew install coreutils' "${SANDBOX}/error"
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

test_block_is_the_rendering_of_the_standalone_structure() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  render_standalone standalone-structure.md > "${SANDBOX}/expected" || return 1
  assert_block_is_rendering "${repo}/AGENTS.local.md" "${SANDBOX}/expected"
}

test_installs_the_seat_files_in_the_instance() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  render_standalone --seat-files standalone-structure.md > "${SANDBOX}/seats" || return 1
  [[ -s "${SANDBOX}/seats" ]] || return 1
  local path installed
  while IFS=$'\t' read -r path installed; do
    render_standalone "${path}" > "${SANDBOX}/expected-seat" || return 1
    cmp -s "${SANDBOX}/expected-seat" "${instance}/.ribbon/protocol/${installed}" || return 1
  done < "${SANDBOX}/seats"
}

test_update_keeps_the_roster_and_the_gate() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  local local_md="${repo}/AGENTS.local.md"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  sed -i 's/TODO(belt): "Kuro-chan" or "Claude Opus"/Kuro-chan/' "${local_md}"
  sed -i 's/The gate: TODO(belt): the exact commands, in order\./The gate: make check./' "${local_md}"
  sed -i '/ribbon:standalone:start/a stale line inside the block' "${local_md}"
  cp "${local_md}" "${SANDBOX}/old-block"

  install example-project --update >/dev/null 2>&1 || return 1

  ! grep -q 'stale line inside the block' "${local_md}" || return 1
  render_standalone --keep-from "${SANDBOX}/old-block" standalone-structure.md \
    > "${SANDBOX}/expected" || return 1
  assert_block_is_rendering "${local_md}" "${SANDBOX}/expected" || return 1
  grep -q '^| Architect | Kuro-chan |' "${local_md}" || return 1
  grep -Fqx 'The gate: make check.' "${local_md}"
}

test_update_rewrites_the_seat_files_and_drops_stray_ones() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  printf 'edited by hand\n' > "${instance}/.ribbon/protocol/actors/architect.md"
  printf 'stray\n' > "${instance}/.ribbon/protocol/old.md"

  install example-project --update >/dev/null 2>&1 || return 1

  [[ ! -e "${instance}/.ribbon/protocol/old.md" ]] || return 1
  render_standalone actors/architect_template.md > "${SANDBOX}/expected-seat" || return 1
  cmp -s "${SANDBOX}/expected-seat" "${instance}/.ribbon/protocol/actors/architect.md"
}

test_refuses_a_project_with_a_full_install_block() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  printf '\n<!-- ribbon:full-install:start -->\n' >> "${repo}/AGENTS.md"
  cp "${repo}/AGENTS.md" "${SANDBOX}/before"

  install example-project "${repo}" > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'has a full install' "${SANDBOX}/stderr" || return 1
  [[ ! -e "${PROJECTS}/example-project" ]] || return 1
  [[ ! -e "${repo}/AGENTS.local.md" ]] || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.md"
}

test_refuses_a_project_with_a_full_install_record() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  mkdir -p "${repo}/docs"
  printf 'receipt\n' > "${repo}/docs/.ribbon-full-install"
  cp "${repo}/AGENTS.md" "${SANDBOX}/before"

  install example-project "${repo}" > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'has a full install' "${SANDBOX}/stderr" || return 1
  [[ ! -e "${PROJECTS}/example-project" ]] || return 1
  [[ ! -e "${repo}/AGENTS.local.md" ]] || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.md"
}

test_render_failure_stops_before_any_write() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  local fake="${SANDBOX}/fake-template"
  mkdir -p "${fake}/protocol" "${fake}/docs/tasks" "${fake}/docs/llm-context" \
    "${fake}/rules" "${fake}/scripts"
  cp "${RIBBON_HOME}/protocol/standalone-structure.md" "${fake}/protocol/"
  printf '#!/usr/bin/env bash\nprintf "boom\\n" >&2\nexit 1\n' \
    > "${fake}/scripts/ribbon-render-protocol"
  chmod +x "${fake}/scripts/ribbon-render-protocol"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${fake}/scripts/"
  printf 'ribbon 1\n' > "${fake}/VERSION"
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before-local"
  cp "${instance}/docs/README.md" "${SANDBOX}/before-readme"
  cp "${instance}/.ribbon/protocol/actors/architect.md" "${SANDBOX}/before-seat"
  local rc=0

  install --ribbon-home "${fake}" example-project --update \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fxq 'ribbon-new-project: cannot render the protocol: boom' "${SANDBOX}/stderr" || return 1
  cmp -s "${SANDBOX}/before-local" "${repo}/AGENTS.local.md" || return 1
  cmp -s "${SANDBOX}/before-readme" "${instance}/docs/README.md" || return 1
  cmp -s "${SANDBOX}/before-seat" "${instance}/.ribbon/protocol/actors/architect.md"
}

test_update_keeps_the_roster_of_a_crlf_file() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  local local_md="${repo}/AGENTS.local.md"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  sed -i "s/TODO(belt): a person's name/Ana/" "${local_md}"
  sed -i '/ribbon:standalone:start/a stale line inside the block' "${local_md}"
  sed -i 's/$/\r/' "${local_md}"

  install example-project --update >/dev/null 2>&1 || return 1

  ! grep -q 'stale line inside the block' "${local_md}" || return 1
  grep -q '^| Senior architect | Ana |' "${local_md}"
}

test_writes_no_herdr_config_and_names_the_handler() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" > "${SANDBOX}/summary" 2>&1 || return 1
  [[ -f "${repo}/AGENTS.local.md" ]] || return 1
  [[ -d "${PROJECTS}/example-project" ]] || return 1
  [[ ! -e "${repo}/herdr-config.md" ]] || return 1
  grep -Fq 'handlers/herdr.md' "${SANDBOX}/summary" || return 1
  grep -Fxq "Seeded from: ${RIBBON_HOME} — the field guide is read from there; each seat's files are rendered under ${PROJECTS}/example-project/.ribbon/protocol/." \
    "${PROJECTS}/example-project/docs/README.md"
}

test_uninstall_previews_by_default() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  git -C "${repo}" init -q || return 1
  printf '# my notes\n' > "${repo}/AGENTS.local.md"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents.before"
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/local.before"
  cp "${repo}/.git/hooks/post-checkout" "${SANDBOX}/hook.before"

  uninstall example-project > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || return 1

  grep -Fxq 'Would remove Ribbon-owned blocks, lines and files:' "${SANDBOX}/stdout" || return 1
  grep -Fxq '  AGENTS.local.md (Ribbon block only)' "${SANDBOX}/stdout" || return 1
  grep -Fxq '  AGENTS.md (Ribbon pointer line only)' "${SANDBOX}/stdout" || return 1
  grep -Fxq "  ${repo}/.git/hooks/post-checkout" "${SANDBOX}/stdout" || return 1
  grep -Fxq 'Dry run only; use --uninstall --remove-ribbon to apply.' "${SANDBOX}/stdout" || return 1
  cmp -s "${SANDBOX}/agents.before" "${repo}/AGENTS.md" || return 1
  cmp -s "${SANDBOX}/local.before" "${repo}/AGENTS.local.md" || return 1
  cmp -s "${SANDBOX}/hook.before" "${repo}/.git/hooks/post-checkout"
}

test_uninstall_without_terminal_requires_yes() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents.before"
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/local.before"

  uninstall example-project --remove-ribbon > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'non-interactive removal requires --yes; nothing removed' "${SANDBOX}/stderr" || return 1
  cmp -s "${SANDBOX}/agents.before" "${repo}/AGENTS.md" || return 1
  cmp -s "${SANDBOX}/local.before" "${repo}/AGENTS.local.md"
}

test_uninstall_restores_agents_md_and_removes_a_created_agents_local_md() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents.before"
  install example-project "${repo}" >/dev/null 2>&1 || return 1

  uninstall example-project --remove-ribbon --yes >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/agents.before" "${repo}/AGENTS.md" || return 1
  [[ ! -e "${repo}/AGENTS.local.md" ]]
}

test_uninstall_keeps_the_rest_of_agents_local_md() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  printf '# my notes\n' > "${repo}/AGENTS.local.md"
  install example-project "${repo}" >/dev/null 2>&1 || return 1

  uninstall example-project --remove-ribbon --yes >/dev/null 2>&1 || return 1

  printf '# my notes\n' | cmp -s - "${repo}/AGENTS.local.md"
}

test_uninstall_removes_the_managed_hook() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  git -C "${repo}" init -q || return 1
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  [[ -f "${repo}/.git/hooks/post-checkout" ]] || return 1

  uninstall example-project --remove-ribbon --yes >/dev/null 2>&1 || return 1

  [[ ! -e "${repo}/.git/hooks/post-checkout" ]]
}

test_uninstall_leaves_a_foreign_hook_and_names_it() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  git -C "${repo}" init -q || return 1
  mkdir -p "${repo}/.git/hooks"
  printf '#!/bin/sh\n# my own hook\nexit 0\n' > "${repo}/.git/hooks/post-checkout"
  install example-project "${repo}" >/dev/null 2>&1 || return 1

  uninstall example-project --remove-ribbon --yes > "${SANDBOX}/stdout" 2>&1 || return 1

  printf '#!/bin/sh\n# my own hook\nexit 0\n' | cmp -s - "${repo}/.git/hooks/post-checkout" || return 1
  grep -Fq "${repo}/.git/hooks/post-checkout (not Ribbon's hook)" "${SANDBOX}/stdout"
}

test_uninstall_leaves_the_instance_and_names_it() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1

  uninstall example-project --remove-ribbon --yes > "${SANDBOX}/stdout" 2>&1 || return 1

  [[ -d "${instance}/docs/tasks" ]] || return 1
  [[ "$(tail -1 "${SANDBOX}/stdout")" \
    == "Standalone removal complete. The instance stays: ${instance}." ]]
}

test_uninstall_leaves_herdr_config_and_names_it() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  printf '# my overlay\n' > "${repo}/herdr-config.md"
  install example-project "${repo}" >/dev/null 2>&1 || return 1

  uninstall example-project --remove-ribbon --yes > "${SANDBOX}/stdout" 2>&1 || return 1

  printf '# my overlay\n' | cmp -s - "${repo}/herdr-config.md" || return 1
  grep -Fq 'herdr-config.md (Ribbon cannot prove it wrote it)' "${SANDBOX}/stdout"
}

test_uninstall_removes_an_older_standalone_install() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  git -C "${repo}" init -q || return 1
  make_older_standalone_install "${repo}"

  uninstall example-project --remove-ribbon --yes >/dev/null 2>&1 || return 1

  printf '# example-project AGENTS\n' | cmp -s - "${repo}/AGENTS.md" || return 1
  printf '# my notes\n' | cmp -s - "${repo}/AGENTS.local.md" || return 1
  [[ ! -e "${repo}/.git/hooks/post-checkout" ]] || return 1
  [[ -f "${PROJECTS}/example-project/docs/tasks/live-plan.yaml" ]]
}

test_uninstall_refuses_broken_marks_and_removes_nothing() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  sed -i '/ribbon:standalone:end/d' "${repo}/AGENTS.local.md"
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents.before"
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/local.before"

  uninstall example-project --remove-ribbon --yes > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'unclosed, duplicated or out-of-order' "${SANDBOX}/stderr" || return 1
  cmp -s "${SANDBOX}/agents.before" "${repo}/AGENTS.md" || return 1
  cmp -s "${SANDBOX}/local.before" "${repo}/AGENTS.local.md"
}

test_uninstall_without_an_instance_takes_the_repo_path() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  mv "${PROJECTS}/example-project" "${SANDBOX}/instance-away"

  uninstall example-project "${repo}" --remove-ribbon --yes >/dev/null 2>&1 || return 1

  ! grep -q 'ribbon:standalone:start' "${repo}/AGENTS.local.md" || return 1
  ! grep -q 'AGENTS\.local\.md' "${repo}/AGENTS.md"
}

test_uninstall_then_install_brings_the_new_layout() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  git -C "${repo}" init -q || return 1
  make_older_standalone_install "${repo}"

  uninstall example-project --remove-ribbon --yes >/dev/null 2>&1 || return 1
  install example-project "${repo}" --force >/dev/null 2>&1 || return 1

  grep -q 'ribbon:gate:start' "${repo}/AGENTS.local.md" || return 1
  [[ -f "${PROJECTS}/example-project/.ribbon/protocol/actors/architect.md" ]]
}

test_force_refuses_a_template_without_version_before_deleting_the_instance() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  printf 'live work\n' > "${instance}/docs/tasks/live-card.yaml"
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before"
  local fake="${SANDBOX}/no-version-template"
  mkdir -p "${fake}/protocol" "${fake}/docs/tasks" "${fake}/docs/llm-context" \
    "${fake}/rules" "${fake}/scripts"
  cp "${RIBBON_HOME}/protocol/standalone-structure.md" "${fake}/protocol/"
  cp "${RIBBON_HOME}/scripts/ribbon-render-protocol" "${fake}/scripts/"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${fake}/scripts/"

  install example-project "${repo}" --force --yes --ribbon-home "${fake}" \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'VERSION' "${SANDBOX}/stderr" || return 1
  grep -Fxq 'live work' "${instance}/docs/tasks/live-card.yaml" || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.local.md"
}

test_update_refuses_a_seat_directory_link() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  mv "${instance}/.ribbon/protocol/actors" "${SANDBOX}/outside-actors"
  ln -s "${SANDBOX}/outside-actors" "${instance}/.ribbon/protocol/actors"
  cp "${SANDBOX}/outside-actors/architect.md" "${SANDBOX}/architect.before"

  install example-project --update > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'unsafe seat file:' "${SANDBOX}/stderr" || return 1
  cmp -s "${SANDBOX}/architect.before" "${SANDBOX}/outside-actors/architect.md"
}

test_update_refuses_a_hard_linked_seat_file() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  printf 'live work\n' > "${instance}/docs/tasks/live.yaml"
  ln -f "${instance}/docs/tasks/live.yaml" "${instance}/.ribbon/protocol/actors/architect.md"

  install example-project --update > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'unsafe seat file:' "${SANDBOX}/stderr" || return 1
  grep -Fxq 'live work' "${instance}/docs/tasks/live.yaml"
}

test_update_stops_when_the_sweep_cannot_list() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before-block"
  cp "${instance}/.ribbon/protocol/actors/architect.md" "${SANDBOX}/before-seat"
  local standin="${SANDBOX}/find-standin"
  mkdir -p "${standin}"
  # The single quotes are the point: the stand-in is a script, written literally.
  # shellcheck disable=SC2016
  printf '#!/usr/bin/env bash\nfor a in "$@"; do [[ "${a}" == *".ribbon/protocol"* ]] && exit 7; done\nexec %q "$@"\n' \
    "$(command -v find)" > "${standin}/find"
  chmod +x "${standin}/find"

  PATH="${standin}:${PATH}" "${INSTALLER}" --projects "${PROJECTS}" --update example-project \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'cannot list' "${SANDBOX}/stderr" || return 1
  cmp -s "${SANDBOX}/before-block" "${repo}/AGENTS.local.md" || return 1
  cmp -s "${SANDBOX}/before-seat" "${instance}/.ribbon/protocol/actors/architect.md"
}

test_refuses_a_crlf_full_install_mark() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  printf '# example-project AGENTS\r\n<!-- ribbon:full-install:start -->\r\n' \
    > "${repo}/AGENTS.md"

  install example-project "${repo}" > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'has a full install' "${SANDBOX}/stderr" || return 1
  [[ ! -e "${PROJECTS}/example-project" ]] || return 1
  [[ ! -e "${repo}/AGENTS.local.md" ]]
}

test_gate_mark_inside_a_sentence_is_no_region() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  cat > "${repo}/AGENTS.local.md" <<'EOF'
<!-- ribbon:standalone:start -->
# Ribbon Protocol, standalone mode
<!-- ribbon:belt:start -->
| Seat | Agent | Model |
|---|---|---|
<!-- ribbon:belt:end -->
Explain <!-- ribbon:gate:start --> as text.
<!-- ribbon:standalone:end -->
EOF
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before"

  install example-project "${repo}" > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'holds an older standalone block' "${SANDBOX}/stderr" || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.local.md"
}

test_refuses_an_agents_local_md_that_links_to_the_overlay() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  printf '# my overlay\n' > "${repo}/herdr-config.md"
  ln -s herdr-config.md "${repo}/AGENTS.local.md"

  install example-project "${repo}" > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'is a link to another file' "${SANDBOX}/stderr" || return 1
  printf '# my overlay\n' | cmp -s - "${repo}/herdr-config.md" || return 1
  [[ ! -e "${PROJECTS}/example-project" ]]
}

test_refuses_a_backtick_in_the_project_repo_path() {
  new_sandbox
  local weird="${SANDBOX}/repos/back\`tick" rc=0
  mkdir -p "${weird}"
  printf '# backtick project AGENTS\n' > "${weird}/AGENTS.md"

  install example-project "${weird}" > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'unsupported character in the project repo path:' "${SANDBOX}/stderr" || return 1
  [[ ! -e "${PROJECTS}/example-project" ]]
}

test_refuses_a_block_that_names_a_missing_seat_file() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  local fake="${SANDBOX}/missing-seat-template"
  mkdir -p "${fake}/docs/tasks" "${fake}/docs/llm-context" "${fake}/rules" "${fake}/scripts"
  cp -R "${RIBBON_HOME}/protocol" "${fake}/protocol"
  rm "${fake}/protocol/actors/general-coder_template.md"
  cp "${RIBBON_HOME}/scripts/ribbon-render-protocol" "${fake}/scripts/"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${fake}/scripts/"
  printf 'ribbon 2\n' > "${fake}/VERSION"

  install example-project "${repo}" --ribbon-home "${fake}" \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'the block names a seat file that the template does not have: actors/general-coder.md' \
    "${SANDBOX}/stderr" || return 1
  [[ ! -e "${PROJECTS}/example-project" ]] || return 1
  [[ ! -e "${repo}/AGENTS.local.md" ]]
}

test_uninstall_refuses_a_repo_path_that_differs_by_an_lf() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before"

  uninstall example-project "${repo}"$'\n' --remove-ribbon --yes \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.local.md"
}

test_uninstall_refuses_a_linked_project_repo_pointer() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  mv "${instance}/project-repo" "${SANDBOX}/pointer-target"
  ln -s "${SANDBOX}/pointer-target" "${instance}/project-repo"
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before"

  uninstall example-project --remove-ribbon --yes \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'the instance has no usable project-repo pointer; nothing removed' "${SANDBOX}/stderr" || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.local.md"
}

test_mark_text_inside_prose_is_no_frame() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  cat > "${repo}/AGENTS.local.md" <<'EOF'
# My notes
The start mark <!-- ribbon:standalone:start --> appears in this sentence.
project rules stay here
The end mark <!-- ribbon:standalone:end --> appears in this sentence too.
EOF
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/prose"

  install example-project "${repo}" >/dev/null 2>&1 || return 1
  grep -Fq 'project rules stay here' "${repo}/AGENTS.local.md" || return 1
  grep -q 'ribbon:standalone:start -->$' "${repo}/AGENTS.local.md" || return 1

  uninstall example-project --remove-ribbon --yes >/dev/null 2>&1 || return 1

  cmp -s "${SANDBOX}/prose" "${repo}/AGENTS.local.md"
}

test_uninstall_refuses_a_real_start_without_a_real_end() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  cat > "${repo}/AGENTS.local.md" <<'EOF'
<!-- ribbon:standalone:start -->
# Ribbon Protocol, standalone mode
The end mark <!-- ribbon:standalone:end --> is only prose here.
EOF
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before"

  uninstall example-project "${repo}" --remove-ribbon --yes \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'unclosed, duplicated or out-of-order' "${SANDBOX}/stderr" || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.local.md"
}

test_uninstall_asks_on_a_terminal() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before"

  run_on_a_terminal n "${INSTALLER}" --projects "${PROJECTS}" \
    --uninstall --remove-ribbon example-project > "${SANDBOX}/prompt-n" 2>&1 || rc=$?
  [[ "${rc}" == 0 ]] || return 1
  grep -Fq '[y/N]' "${SANDBOX}/prompt-n" || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.local.md" || return 1

  rc=0
  run_on_a_terminal yes "${INSTALLER}" --projects "${PROJECTS}" \
    --uninstall --remove-ribbon example-project > "${SANDBOX}/prompt-yes" 2>&1 || rc=$?
  [[ "${rc}" == 0 ]] || return 1
  grep -Fq '[y/N]' "${SANDBOX}/prompt-yes" || return 1
  ! grep -q 'ribbon:standalone:start' "${repo}/AGENTS.local.md"
}

test_uninstall_refuses_an_unwritable_hooks_directory_before_any_removal() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  git -C "${repo}" init -q || return 1
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/local.before"
  cp "${repo}/AGENTS.md" "${SANDBOX}/agents.before"
  chmod a-w "${repo}/.git/hooks"

  uninstall example-project --remove-ribbon --yes \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?
  chmod u+w "${repo}/.git/hooks"

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'permission denied:' "${SANDBOX}/stderr" || return 1
  cmp -s "${SANDBOX}/local.before" "${repo}/AGENTS.local.md" || return 1
  cmp -s "${SANDBOX}/agents.before" "${repo}/AGENTS.md"
}

test_uninstall_removes_a_crlf_pointer_line() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  python3 - "${repo}/AGENTS.md" <<'PY'
import sys

path = sys.argv[1]
data = open(path, "rb").read()
open(path, "wb").write(data.replace(b"\r\n", b"\n").replace(b"\n", b"\r\n"))
PY

  uninstall example-project --remove-ribbon --yes >/dev/null 2>&1 || return 1

  printf '# example-project AGENTS\r\n' | cmp -s - "${repo}/AGENTS.md" || return 1
  [[ ! -e "${repo}/AGENTS.local.md" ]]
}

test_force_refuses_a_version_with_a_second_line() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  printf 'live work\n' > "${instance}/docs/tasks/live-card.yaml"
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before"
  local fake="${SANDBOX}/two-line-version-template"
  mkdir -p "${fake}/protocol" "${fake}/docs/tasks" "${fake}/docs/llm-context" \
    "${fake}/rules" "${fake}/scripts"
  cp "${RIBBON_HOME}/protocol/standalone-structure.md" "${fake}/protocol/"
  cp "${RIBBON_HOME}/scripts/ribbon-render-protocol" "${fake}/scripts/"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${fake}/scripts/"
  printf 'ribbon 8\nan unexpected second line\n' > "${fake}/VERSION"

  install example-project "${repo}" --force --yes --ribbon-home "${fake}" \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'invalid Ribbon seed version' "${SANDBOX}/stderr" || return 1
  grep -Fxq 'live work' "${instance}/docs/tasks/live-card.yaml" || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.local.md"
}

test_update_never_writes_through_a_stale_temporary_name() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  printf 'witness\n' > "${SANDBOX}/witness.md"
  ln -s "${SANDBOX}/witness.md" "${instance}/.ribbon/protocol/actors/architect.md.ribbon-new"
  printf '\nUser edit.\n' >> "${instance}/.ribbon/protocol/actors/architect.md"

  install example-project --update >/dev/null 2>&1 || return 1

  grep -Fxq 'witness' "${SANDBOX}/witness.md" || return 1
  local path installed
  render_standalone --seat-files standalone-structure.md > "${SANDBOX}/seats" || return 1
  while IFS=$'\t' read -r path installed; do
    [[ -f "${instance}/.ribbon/protocol/${installed}" \
      && ! -L "${instance}/.ribbon/protocol/${installed}" ]] || return 1
  done < "${SANDBOX}/seats"
}

test_refuses_an_agents_local_md_chain_that_ends_at_the_overlay() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  mkdir -p "${SANDBOX}/repos/shared"
  printf '# my overlay\n' > "${repo}/herdr-config.md"
  ln -s "${repo}/herdr-config.md" "${SANDBOX}/repos/shared/AGENTS.local.md"
  ln -s "../shared/AGENTS.local.md" "${repo}/AGENTS.local.md"

  install example-project "${repo}" > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'is a link to another file or has other names' "${SANDBOX}/stderr" || return 1
  printf '# my overlay\n' | cmp -s - "${repo}/herdr-config.md" || return 1
  [[ ! -e "${PROJECTS}/example-project" ]]
}

test_update_keeps_a_worktree_link_a_link() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  git -C "${repo}" init -q || return 1
  git -C "${repo}" add AGENTS.md || return 1
  git -C "${repo}" -c user.name=test -c user.email=test@example.com commit -qm init || return 1
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  local wt="${SANDBOX}/wt"
  git -C "${repo}" worktree add -q -b linked "${wt}" || return 1
  [[ -L "${wt}/AGENTS.local.md" ]] || return 1
  local fake="${SANDBOX}/edited-template"
  mkdir -p "${fake}/docs/tasks" "${fake}/docs/llm-context" "${fake}/rules" "${fake}/scripts"
  cp -R "${RIBBON_HOME}/protocol" "${fake}/protocol"
  printf '\nAn edited sentence of guidance.\n' >> "${fake}/protocol/guidance/memory.md"
  cp "${RIBBON_HOME}/scripts/ribbon-render-protocol" "${fake}/scripts/"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${fake}/scripts/"
  printf 'ribbon 2\n' > "${fake}/VERSION"

  install example-project --update --ribbon-home "${fake}" "${wt}" >/dev/null 2>&1 || return 1

  grep -Fq 'An edited sentence of guidance.' "${repo}/AGENTS.local.md" || return 1
  [[ -L "${wt}/AGENTS.local.md" ]] \
    && [[ "$(readlink "${wt}/AGENTS.local.md")" == "${repo}/AGENTS.local.md" ]]
}

test_refuses_a_hard_linked_agents_local_md() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  printf 'notes\n' > "${repo}/notes.md"
  ln -f "${repo}/notes.md" "${repo}/AGENTS.local.md"

  install example-project "${repo}" > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'is a link to another file or has other names' "${SANDBOX}/stderr" || return 1
  printf 'notes\n' | cmp -s - "${repo}/notes.md" || return 1
  [[ ! -e "${PROJECTS}/example-project" ]]
}

test_relative_projects_render_absolute_seat_paths() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  (
    cd "${SANDBOX}" || exit 1
    "${INSTALLER}" --projects ribbon-projects example-project "${repo}"
  ) > "${SANDBOX}/summary" 2>&1 || return 1

  # The single quotes are the point: the backticks are literal Markdown.
  # shellcheck disable=SC2016
  grep -o '`[^`]*/\.ribbon/protocol/[^`]*\.md`' "${repo}/AGENTS.local.md" \
    > "${SANDBOX}/pointers" || return 1
  [[ -s "${SANDBOX}/pointers" ]] || return 1
  local pointer
  while IFS= read -r pointer; do
    pointer="${pointer#\`}"
    pointer="${pointer%\`}"
    [[ "${pointer}" == /* ]] || return 1
    [[ -f "${pointer}" ]] || return 1
  done < "${SANDBOX}/pointers"
}

test_claude_links_to_the_agents_files_stay_supported() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  printf '# my notes\n' > "${repo}/AGENTS.local.md"
  ln -s AGENTS.md "${repo}/CLAUDE.md"
  ln -s AGENTS.local.md "${repo}/CLAUDE.local.md"

  install example-project "${repo}" >/dev/null 2>&1 || return 1
  [[ -L "${repo}/CLAUDE.md" && -L "${repo}/CLAUDE.local.md" ]] || return 1
  grep -q 'ribbon:standalone:start -->$' "${repo}/AGENTS.local.md" || return 1

  install example-project --update >/dev/null 2>&1 || return 1
  [[ -L "${repo}/CLAUDE.md" && -L "${repo}/CLAUDE.local.md" ]] \
    && grep -q 'ribbon:standalone:start -->$' "${repo}/AGENTS.local.md"
}

test_update_refuses_an_unwritable_seat_directory_before_any_write() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before-block"
  cp "${instance}/.ribbon/protocol/flows/adr.md" "${SANDBOX}/before-seat"
  chmod 0555 "${instance}/.ribbon/protocol/flows"
  local fake="${SANDBOX}/edited-template"
  mkdir -p "${fake}/docs/tasks" "${fake}/docs/llm-context" "${fake}/rules" "${fake}/scripts"
  cp -R "${RIBBON_HOME}/protocol" "${fake}/protocol"
  printf '\nAn edited sentence of the adr flow.\n' >> "${fake}/protocol/flows/adr.md"
  cp "${RIBBON_HOME}/scripts/ribbon-render-protocol" "${fake}/scripts/"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${fake}/scripts/"
  printf 'ribbon 2\n' > "${fake}/VERSION"

  install example-project --update --ribbon-home "${fake}" \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?
  chmod u+w "${instance}/.ribbon/protocol/flows"

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'not writable:' "${SANDBOX}/stderr" || return 1
  cmp -s "${SANDBOX}/before-block" "${repo}/AGENTS.local.md" || return 1
  cmp -s "${SANDBOX}/before-seat" "${instance}/.ribbon/protocol/flows/adr.md"
}

test_install_refuses_an_unwritable_rules_directory_before_any_write() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  mkdir -p "${repo}/rules"
  chmod 0555 "${repo}/rules"

  install example-project "${repo}" > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?
  chmod u+w "${repo}/rules"

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'not writable:' "${SANDBOX}/stderr" || return 1
  [[ ! -e "${PROJECTS}/example-project" ]] || return 1
  [[ ! -e "${repo}/AGENTS.local.md" ]]
}

test_refuses_a_projects_directory_whose_real_name_holds_a_backtick() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" rc=0
  mkdir -p "${SANDBOX}/real\`tick-projects"
  ln -s "${SANDBOX}/real\`tick-projects" "${SANDBOX}/projects-link"

  "${INSTALLER}" --projects "${SANDBOX}/projects-link" example-project "${repo}" \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'unsupported character in the projects directory' "${SANDBOX}/stderr" || return 1
  [[ ! -e "${SANDBOX}/real\`tick-projects/example-project" ]] || return 1
  [[ ! -e "${repo}/AGENTS.local.md" ]]
}

test_relative_ribbon_home_renders_an_absolute_field_guide_path() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project"
  (
    cd "${RIBBON_HOME}/.." || exit 1
    "${INSTALLER}" --projects "${PROJECTS}" --ribbon-home "${RIBBON_HOME##*/}" \
      example-project "${repo}"
  ) > "${SANDBOX}/summary" 2>&1 || return 1

  # The single quotes are the point: the backticks are literal Markdown.
  # shellcheck disable=SC2016
  grep -o '`[^`]*docs/field-guide\.md`' "${repo}/AGENTS.local.md" \
    > "${SANDBOX}/guide" || return 1
  [[ -s "${SANDBOX}/guide" ]] || return 1
  local guide
  while IFS= read -r guide; do
    guide="${guide#\`}"
    guide="${guide%\`}"
    [[ "${guide}" == /* ]] || return 1
    [[ -f "${guide}" ]] || return 1
  done < "${SANDBOX}/guide"
}

test_force_refuses_a_version_with_junk_after_its_line() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project" rc=0
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  printf 'live work\n' > "${instance}/docs/tasks/live-card.yaml"
  cp "${repo}/AGENTS.local.md" "${SANDBOX}/before"
  local fake="${SANDBOX}/junk-version-template"
  mkdir -p "${fake}/protocol" "${fake}/docs/tasks" "${fake}/docs/llm-context" \
    "${fake}/rules" "${fake}/scripts"
  cp "${RIBBON_HOME}/protocol/standalone-structure.md" "${fake}/protocol/"
  cp "${RIBBON_HOME}/scripts/ribbon-render-protocol" "${fake}/scripts/"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${fake}/scripts/"
  printf 'ribbon 8\njunk' > "${fake}/VERSION"

  install example-project "${repo}" --force --yes --ribbon-home "${fake}" \
    > "${SANDBOX}/stdout" 2> "${SANDBOX}/stderr" || rc=$?

  [[ "${rc}" == 1 ]] || return 1
  grep -Fq 'invalid Ribbon seed version' "${SANDBOX}/stderr" || return 1
  grep -Fxq 'live work' "${instance}/docs/tasks/live-card.yaml" || return 1
  cmp -s "${SANDBOX}/before" "${repo}/AGENTS.local.md"
}

test_update_keeps_the_mode_of_a_rewritten_seat() {
  new_sandbox
  local repo="${SANDBOX}/repos/example-project" instance="${PROJECTS}/example-project"
  install example-project "${repo}" >/dev/null 2>&1 || return 1
  chmod 0600 "${instance}/.ribbon/protocol/flows/adr.md"
  local fake="${SANDBOX}/edited-template"
  mkdir -p "${fake}/docs/tasks" "${fake}/docs/llm-context" "${fake}/rules" "${fake}/scripts"
  cp -R "${RIBBON_HOME}/protocol" "${fake}/protocol"
  printf '\nAn edited sentence of the adr flow.\n' >> "${fake}/protocol/flows/adr.md"
  cp "${RIBBON_HOME}/scripts/ribbon-render-protocol" "${fake}/scripts/"
  cp "${RIBBON_HOME}/scripts/standalone-post-checkout" "${fake}/scripts/"
  printf 'ribbon 2\n' > "${fake}/VERSION"

  install example-project --update --ribbon-home "${fake}" >/dev/null 2>&1 || return 1

  [[ "$(stat -c %a "${instance}/.ribbon/protocol/flows/adr.md")" == 600 ]]
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
  test_writes_no_herdr_config
  test_seeds_rules_into_repo
  test_update_seeds_rules_when_missing
  test_update_does_not_resurrect_deleted_theme
  test_import_rules_flag
  test_import_rules_missing_file_fails
  test_import_rules_preflight_before_any_write
  test_non_interactive_imports_nothing
  test_update_preserves_existing_project_rules_byte_for_byte
  test_update_does_not_write_to_a_rule_linked_to_project_instructions
  test_install_skips_dangling_project_rule_entries
  test_force_rejects_linked_project_rules_before_rebuild
  test_update_rejects_linked_instance_directory_before_writing
  test_update_rejects_a_linked_instance_template_before_writing
  test_update_does_not_rewrite_a_project_readme_linked_to_instance
  test_force_preserves_a_project_readme_linked_to_live_instance_work
  test_force_rejects_a_project_directory_link_to_the_instance_parent
  test_update_rejects_a_linked_project_docs_root
  test_update_keeps_links_to_missing_instance_directories_dangling
  test_update_does_not_complete_a_missing_symlink_traversal
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
  test_update_replaces_the_block_and_keeps_the_rest
  test_update_refuses_an_older_block
  test_force_replaces_the_block_and_keeps_the_roster
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
  test_update_rejects_instruction_aliases_of_refresh_destinations
  test_update_rejects_an_instruction_hardlink_to_the_managed_hook
  test_force_keeps_a_working_overlay_link_outside_the_instance
  test_rule_seeds_and_imports_keep_instruction_aliases_dangling
  test_install_rejects_an_instruction_link_into_the_new_instance
  test_force_refuses_an_older_block_without_belt_marks
  test_rejects_surplus_positionals
  test_import_rejects_directory_operand
  test_refuses_overlapping_repo_and_instance
  test_refuses_without_gnu_realpath
  test_import_rules_usage_order_works
  test_import_rules_requires_one_value
  test_import_rules_rejects_paths
  test_install_keeps_existing_project_theme
  test_block_is_the_rendering_of_the_standalone_structure
  test_installs_the_seat_files_in_the_instance
  test_update_keeps_the_roster_and_the_gate
  test_update_rewrites_the_seat_files_and_drops_stray_ones
  test_refuses_a_project_with_a_full_install_block
  test_refuses_a_project_with_a_full_install_record
  test_render_failure_stops_before_any_write
  test_update_keeps_the_roster_of_a_crlf_file
  test_writes_no_herdr_config_and_names_the_handler
  test_uninstall_previews_by_default
  test_uninstall_without_terminal_requires_yes
  test_uninstall_restores_agents_md_and_removes_a_created_agents_local_md
  test_uninstall_keeps_the_rest_of_agents_local_md
  test_uninstall_removes_the_managed_hook
  test_uninstall_leaves_a_foreign_hook_and_names_it
  test_uninstall_leaves_the_instance_and_names_it
  test_uninstall_leaves_herdr_config_and_names_it
  test_uninstall_removes_an_older_standalone_install
  test_uninstall_refuses_broken_marks_and_removes_nothing
  test_uninstall_without_an_instance_takes_the_repo_path
  test_uninstall_then_install_brings_the_new_layout
  test_force_refuses_a_template_without_version_before_deleting_the_instance
  test_update_refuses_a_seat_directory_link
  test_update_refuses_a_hard_linked_seat_file
  test_update_stops_when_the_sweep_cannot_list
  test_refuses_a_crlf_full_install_mark
  test_gate_mark_inside_a_sentence_is_no_region
  test_refuses_an_agents_local_md_that_links_to_the_overlay
  test_refuses_a_backtick_in_the_project_repo_path
  test_refuses_a_block_that_names_a_missing_seat_file
  test_uninstall_refuses_a_repo_path_that_differs_by_an_lf
  test_uninstall_refuses_a_linked_project_repo_pointer
  test_mark_text_inside_prose_is_no_frame
  test_uninstall_refuses_a_real_start_without_a_real_end
  test_uninstall_asks_on_a_terminal
  test_uninstall_refuses_an_unwritable_hooks_directory_before_any_removal
  test_uninstall_removes_a_crlf_pointer_line
  test_force_refuses_a_version_with_a_second_line
  test_update_never_writes_through_a_stale_temporary_name
  test_refuses_an_agents_local_md_chain_that_ends_at_the_overlay
  test_update_keeps_a_worktree_link_a_link
  test_refuses_a_hard_linked_agents_local_md
  test_relative_projects_render_absolute_seat_paths
  test_claude_links_to_the_agents_files_stay_supported
  test_update_refuses_an_unwritable_seat_directory_before_any_write
  test_install_refuses_an_unwritable_rules_directory_before_any_write
  test_refuses_a_projects_directory_whose_real_name_holds_a_backtick
  test_relative_ribbon_home_renders_an_absolute_field_guide_path
  test_force_refuses_a_version_with_junk_after_its_line
  test_update_keeps_the_mode_of_a_rewritten_seat
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
