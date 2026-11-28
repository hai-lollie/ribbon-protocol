#!/usr/bin/env bash
# Tests for scripts/ribbon-render-protocol: one function per test, run in
# order by main. Each test builds its own sandbox protocol directory under
# mktemp -d and cleanup removes it. The expected outputs come from card
# p1-01 of the protocol-pieces plan, never from the command itself.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENDER="${SCRIPT_DIR}/ribbon-render-protocol"
readonly SCRIPT_DIR RENDER

# The usage line of card p1-01, command_rules.
USAGE='usage: ribbon-render-protocol [-h] [--protocol DIR] [--set NAME=VALUE] [--list] TEMPLATE'
readonly USAGE

PASS=0
FAIL=0
SANDBOX=''
P=''
OUT=''
ERR=''
RC=0

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
# Replace the sandbox with a fresh one: an empty protocol directory and the
# capture files for stdout, stderr and the exit code.
# Globals:
#   SANDBOX, P, OUT, ERR (set)
#######################################
new_sandbox() {
  cleanup
  SANDBOX="$(mktemp -d)"
  P="${SANDBOX}/protocol"
  mkdir -p "${P}"
  OUT="${SANDBOX}/out"
  ERR="${SANDBOX}/err"
}

#######################################
# Run the command against the sandbox protocol directory, capturing stdout,
# stderr and the exit code.
# Globals:
#   P, OUT, ERR, RC (RC set)
#######################################
run() {
  "${RENDER}" --protocol "${P}" "$@" > "${OUT}" 2> "${ERR}"
  RC=$?
}

#######################################
# Assert a rendering failure: exit 1, stdout empty, stderr exactly the one
# expected line.
# Arguments:
#   Expected stderr line, then the command's arguments after --protocol.
# Globals:
#   OUT, ERR, RC
#######################################
expect_render_failure() {
  local expected="$1"
  shift
  run "$@"
  [[ ${RC} -eq 1 ]] || return 1
  [[ ! -s ${OUT} ]] || return 1
  [[ $(wc -l < "${ERR}") -eq 1 ]] || return 1
  [[ $(<"${ERR}") == "${expected}" ]]
}

#######################################
# Assert a successful render: exit 0, stderr empty, stdout byte-equal to the
# expected text given as "$1" (a trailing newline is added).
# Arguments:
#   Expected stdout without its final newline, then the command's arguments
#   after --protocol.
# Globals:
#   OUT, ERR, RC
#######################################
expect_render() {
  local expected="$1"
  shift
  run "$@"
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  printf '%s\n' "${expected}" | cmp -s - "${OUT}"
}

test_plain_template_renders_byte_for_byte() {
  new_sandbox
  printf 'alpha\nbeta\ngamma\n' > "${P}/a.md"
  run a.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  cmp -s "${P}/a.md" "${OUT}"
}

test_include_line_is_replaced_by_the_piece() {
  new_sandbox
  printf 'top\n<!-- ribbon:include b.md -->\nend\n' > "${P}/a.md"
  printf 'middle\n' > "${P}/b.md"
  expect_render 'top
middle
end' a.md
}

test_nested_includes_render_in_reading_order() {
  new_sandbox
  printf 'A\n<!-- ribbon:include sub/b.md -->\nZ\n' > "${P}/a.md"
  mkdir -p "${P}/sub"
  printf 'B\n<!-- ribbon:include c.md -->\n' > "${P}/sub/b.md"
  printf 'C\n' > "${P}/c.md"
  expect_render 'A
B
C
Z' a.md
}

test_placeholder_takes_its_value() {
  new_sandbox
  printf 'root: {{HOME_DIR}}\n' > "${P}/a.md"
  expect_render 'root: /x/y' --set HOME_DIR=/x/y a.md
}

test_every_occurrence_of_a_placeholder_is_replaced() {
  new_sandbox
  printf '{{A}} {{A}} {{B}}\n' > "${P}/a.md"
  expect_render '1 1 2' --set A=1 --set B=2 a.md
}

test_placeholder_in_an_included_piece_takes_its_value() {
  new_sandbox
  printf 'start\n<!-- ribbon:include b.md -->\n' > "${P}/a.md"
  printf 'piece says {{WORD}}\n' > "${P}/b.md"
  expect_render 'start
piece says hello' --set WORD=hello a.md
}

test_value_is_inserted_literally() {
  new_sandbox
  printf 'x {{V}} y\n' > "${P}/a.md"
  # The single quotes are the point: the value must stay literal.
  # shellcheck disable=SC2016
  expect_render 'x a&b\c\1$HOME{{OTHER}} y' --set 'V=a&b\c\1$HOME{{OTHER}}' a.md
}

test_placeholder_without_value_fails_and_names_it() {
  new_sandbox
  printf 'first\n{{MISSING}}\n' > "${P}/a.md"
  expect_render_failure \
    'ribbon-render-protocol: no value for {{MISSING}} in a.md, line 2' a.md
}

test_include_of_a_missing_piece_fails() {
  new_sandbox
  printf 'top\n<!-- ribbon:include nope.md -->\n' > "${P}/a.md"
  expect_render_failure \
    'ribbon-render-protocol: no such template: nope.md' a.md
}

test_piece_included_twice_fails() {
  new_sandbox
  printf '<!-- ribbon:include b.md -->\n<!-- ribbon:include b.md -->\n' > "${P}/a.md"
  printf 'middle\n' > "${P}/b.md"
  expect_render_failure \
    'ribbon-render-protocol: included twice: b.md' a.md
}

test_include_cycle_fails() {
  new_sandbox
  printf '<!-- ribbon:include b.md -->\n' > "${P}/a.md"
  printf '<!-- ribbon:include a.md -->\n' > "${P}/b.md"
  expect_render_failure \
    'ribbon-render-protocol: included twice: a.md' a.md
}

test_template_outside_the_protocol_directory_fails() {
  new_sandbox
  printf 'outside\n' > "${SANDBOX}/outside.md"
  expect_render_failure \
    'ribbon-render-protocol: template outside the protocol directory: ../outside.md' \
    ../outside.md
}

test_symlink_out_of_the_protocol_directory_fails() {
  new_sandbox
  printf 'secret\n' > "${SANDBOX}/secret.md"
  ln -s "${SANDBOX}/secret.md" "${P}/link.md"
  printf '<!-- ribbon:include link.md -->\n' > "${P}/a.md"
  expect_render_failure \
    'ribbon-render-protocol: template outside the protocol directory: link.md' a.md
}

test_malformed_include_fails() {
  new_sandbox
  printf 'one\ntwo\n <!-- ribbon:include b.md -->\n' > "${P}/a.md"
  expect_render_failure \
    'ribbon-render-protocol: malformed include in a.md, line 3' a.md || return 1
  printf 'one\ntwo\n<!-- ribbon:include b.md --> trailing\n' > "${P}/a.md"
  expect_render_failure \
    'ribbon-render-protocol: malformed include in a.md, line 3' a.md
}

test_piece_without_final_newline_keeps_the_next_line() {
  new_sandbox
  printf 'before\n<!-- ribbon:include b.md -->\nafter\n' > "${P}/a.md"
  printf 'middle' > "${P}/b.md"
  expect_render 'before
middle
after' a.md
}

test_list_names_every_file_in_reading_order() {
  new_sandbox
  printf 'A\n<!-- ribbon:include sub/b.md -->\nZ\n' > "${P}/a.md"
  mkdir -p "${P}/sub"
  printf 'B\n<!-- ribbon:include c.md -->\n' > "${P}/sub/b.md"
  printf 'C\n' > "${P}/c.md"
  expect_render 'a.md
sub/b.md
c.md' --list a.md
}

test_default_protocol_directory_is_beside_the_scripts() {
  new_sandbox
  mkdir -p "${SANDBOX}/scripts" "${SANDBOX}/elsewhere"
  cp "${RENDER}" "${SANDBOX}/scripts/ribbon-render-protocol"
  printf 'home sweet home\n' > "${P}/a.md"
  (
    cd "${SANDBOX}/elsewhere" || exit 1
    "${SANDBOX}/scripts/ribbon-render-protocol" a.md
  ) > "${OUT}" 2> "${ERR}"
  RC=$?
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  printf 'home sweet home\n' | cmp -s - "${OUT}"
}

test_help_prints_usage() {
  new_sandbox
  run -h
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  [[ $(head -n 1 "${OUT}") == "${USAGE}" ]] || return 1
  run --help
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  [[ $(head -n 1 "${OUT}") == "${USAGE}" ]]
}

test_missing_template_argument_prints_usage() {
  new_sandbox
  run
  [[ ${RC} -eq 2 ]] || return 1
  [[ ! -s ${OUT} ]] || return 1
  [[ $(head -n 1 "${ERR}") == "${USAGE}" ]]
}

test_invalid_placeholder_name_is_a_usage_error() {
  new_sandbox
  printf 'x\n' > "${P}/a.md"
  run --set lower=1 a.md
  [[ ${RC} -eq 2 ]] || return 1
  [[ ! -s ${OUT} ]] || return 1
  grep -q 'lower' "${ERR}"
}

#######################################
# Run the command against the repository's own protocol directory (no
# --protocol: the default beside the command), capturing stdout, stderr and
# the exit code. Used by the three repository-guard tests.
# Globals:
#   OUT, ERR, RC (RC set)
#######################################
run_repo() {
  "${RENDER}" "$@" > "${OUT}" 2> "${ERR}"
  RC=$?
}

test_root_agents_md_is_the_whole_rendering() {
  new_sandbox
  run_repo whole-structure.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  cmp -s "${SCRIPT_DIR}/../AGENTS.md" "${OUT}"
}

test_herdr_config_is_the_handler_rendering() {
  new_sandbox
  run_repo handlers/herdr_template.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  cmp -s "${SCRIPT_DIR}/../herdr-config.md" "${OUT}"
}

test_every_piece_is_read_by_one_rendering() {
  new_sandbox
  run_repo --list whole-structure.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  cp "${OUT}" "${SANDBOX}/whole.list"
  run_repo --list handlers/herdr_template.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  cp "${OUT}" "${SANDBOX}/herdr.list"
  LC_ALL=C sort "${SANDBOX}/whole.list" > "${SANDBOX}/whole.sorted"
  LC_ALL=C sort "${SANDBOX}/herdr.list" > "${SANDBOX}/herdr.sorted"
  LC_ALL=C sort "${SANDBOX}/whole.sorted" "${SANDBOX}/herdr.sorted" \
    > "${SANDBOX}/union"
  (
    cd "${SCRIPT_DIR}/../protocol" || exit 1
    find . -name '*.md' ! -name 'README.md' -printf '%P\n' | LC_ALL=C sort
  ) > "${SANDBOX}/on-disk"
  cmp -s "${SANDBOX}/union" "${SANDBOX}/on-disk" || return 1
  [[ -z $(LC_ALL=C comm -12 "${SANDBOX}/whole.sorted" "${SANDBOX}/herdr.sorted") ]]
}

TESTS=(
  test_plain_template_renders_byte_for_byte
  test_include_line_is_replaced_by_the_piece
  test_nested_includes_render_in_reading_order
  test_placeholder_takes_its_value
  test_every_occurrence_of_a_placeholder_is_replaced
  test_placeholder_in_an_included_piece_takes_its_value
  test_value_is_inserted_literally
  test_placeholder_without_value_fails_and_names_it
  test_include_of_a_missing_piece_fails
  test_piece_included_twice_fails
  test_include_cycle_fails
  test_template_outside_the_protocol_directory_fails
  test_symlink_out_of_the_protocol_directory_fails
  test_malformed_include_fails
  test_piece_without_final_newline_keeps_the_next_line
  test_list_names_every_file_in_reading_order
  test_default_protocol_directory_is_beside_the_scripts
  test_help_prints_usage
  test_missing_template_argument_prints_usage
  test_invalid_placeholder_name_is_a_usage_error
  test_root_agents_md_is_the_whole_rendering
  test_herdr_config_is_the_handler_rendering
  test_every_piece_is_read_by_one_rendering
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
