#!/usr/bin/env bash
# Tests for scripts/ribbon-render-protocol: one function per test, run in
# order by main. Each test builds its own sandbox protocol directory under
# mktemp -d and cleanup removes it. The expected outputs come from cards
# p1-01 and p2-01 of the protocol-pieces plan, never from the command itself.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENDER="${SCRIPT_DIR}/ribbon-render-protocol"
readonly SCRIPT_DIR RENDER

# The usage line of card p2-01, command_rules 9 to 13 on top of p1-01's.
USAGE='usage: ribbon-render-protocol [-h] [--protocol DIR] [--set NAME=VALUE] [--keep-from FILE] [--list | --seat-files] TEMPLATE'
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
# Assert a rendering failure against the current capture files, without
# running the command: the Verify half of expect_render_failure, for tests
# whose variants each need their own deletable command line.
# Arguments:
#   Expected stderr line.
# Globals:
#   OUT, ERR, RC
#######################################
assert_render_failure() {
  local expected="$1"
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
  run a.md
  assert_render_failure \
    'ribbon-render-protocol: malformed include in a.md, line 3' || return 1
  printf 'one\ntwo\n<!-- ribbon:include b.md --> trailing\n' > "${P}/a.md"
  OUT="${SANDBOX}/out.second"
  ERR="${SANDBOX}/err.second"
  RC=0
  run a.md
  assert_render_failure \
    'ribbon-render-protocol: malformed include in a.md, line 3'
}

test_include_line_with_a_crlf_ending_is_replaced_by_the_piece() {
  new_sandbox
  printf 'top\r\n<!-- ribbon:include b.md -->\r\nend\r\n' > "${P}/a.md"
  printf 'middle\n' > "${P}/b.md"
  run a.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  printf 'top\r\nmiddle\nend\r\n' | cmp -s - "${OUT}"
}

test_include_line_with_text_before_its_crlf_is_malformed() {
  new_sandbox
  printf '<!-- ribbon:include b.md --> \r\n' > "${P}/a.md"
  expect_render_failure \
    'ribbon-render-protocol: malformed include in a.md, line 1' a.md
}

test_include_line_at_the_end_of_a_file_without_newline_is_replaced() {
  new_sandbox
  printf 'top\n<!-- ribbon:include b.md -->' > "${P}/a.md"
  printf 'middle\n' > "${P}/b.md"
  run a.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  printf 'top\nmiddle\n' | cmp -s - "${OUT}"
}

test_unreadable_piece_fails_with_one_line() {
  new_sandbox
  printf '<!-- ribbon:include b.md -->\n' > "${P}/a.md"
  printf 'middle\n' > "${P}/b.md"
  chmod 000 "${P}/b.md"
  expect_render_failure \
    'ribbon-render-protocol: cannot read template: b.md' a.md
}

test_piece_that_is_not_utf8_fails_with_one_line() {
  new_sandbox
  printf '<!-- ribbon:include b.md -->\n' > "${P}/a.md"
  printf 'middle\n\377\n' > "${P}/b.md"
  expect_render_failure \
    'ribbon-render-protocol: cannot read template: b.md' a.md
}

test_control_characters_in_a_path_stay_on_one_line() {
  new_sandbox
  expect_render_failure \
    'ribbon-render-protocol: no such template: a\x0ab.md' $'a\nb.md'
}

test_absolute_template_path_fails() {
  new_sandbox
  printf 'alpha\n' > "${P}/a.md"
  expect_render_failure \
    "ribbon-render-protocol: template path is not relative: ${P}/a.md" \
    "${P}/a.md"
}

test_absolute_include_path_fails() {
  new_sandbox
  printf '<!-- ribbon:include %s -->\n' "${P}/b.md" > "${P}/a.md"
  printf 'middle\n' > "${P}/b.md"
  expect_render_failure \
    "ribbon-render-protocol: template path is not relative: ${P}/b.md" a.md
}

test_list_names_canonical_relative_paths() {
  new_sandbox
  mkdir -p "${P}/sub"
  printf '<!-- ribbon:include ./sub/../c.md -->\n<!-- ribbon:include link.md -->\n' \
    > "${P}/a.md"
  printf 'C\n' > "${P}/c.md"
  printf 'D\n' > "${P}/sub/d.md"
  ln -s "${P}/sub/d.md" "${P}/link.md"
  expect_render 'a.md
c.md
sub/d.md' --list a.md
}

test_sibling_directory_with_the_same_prefix_is_outside() {
  new_sandbox
  mkdir -p "${SANDBOX}/protocol-evil"
  printf 'evil\n' > "${SANDBOX}/protocol-evil/x.md"
  expect_render_failure \
    'ribbon-render-protocol: template outside the protocol directory: ../protocol-evil/x.md' \
    ../protocol-evil/x.md
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
  OUT="${SANDBOX}/out.second"
  ERR="${SANDBOX}/err.second"
  RC=0
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

test_kept_region_takes_its_body_from_the_old_file() {
  new_sandbox
  printf '<!-- ribbon:belt:start -->\ntemplate body\n<!-- ribbon:belt:end -->\n' \
    > "${P}/a.md"
  printf '<!-- ribbon:belt:start -->\nmy roster\nand a second line\n<!-- ribbon:belt:end -->\n' \
    > "${SANDBOX}/OLD"
  expect_render '<!-- ribbon:belt:start -->
my roster
and a second line
<!-- ribbon:belt:end -->' --keep-from "${SANDBOX}/OLD" a.md
}

test_kept_region_missing_from_the_old_file_keeps_the_template_body() {
  new_sandbox
  printf '<!-- ribbon:belt:start -->\ntemplate body\n<!-- ribbon:belt:end -->\n' \
    > "${P}/a.md"
  printf 'the old file has no marks\n' > "${SANDBOX}/OLD"
  expect_render '<!-- ribbon:belt:start -->
template body
<!-- ribbon:belt:end -->' --keep-from "${SANDBOX}/OLD" a.md
}

test_two_kept_regions_keep_their_own_bodies() {
  new_sandbox
  printf '<!-- ribbon:belt:start -->\ntemplate belt\n<!-- ribbon:belt:end -->\n' \
    > "${P}/a.md"
  printf '<!-- ribbon:gate:start -->\ntemplate gate\n<!-- ribbon:gate:end -->\n' \
    >> "${P}/a.md"
  printf '<!-- ribbon:gate:start -->\nmy gate\n<!-- ribbon:gate:end -->\n' \
    > "${SANDBOX}/OLD"
  printf '<!-- ribbon:belt:start -->\nmy belt\n<!-- ribbon:belt:end -->\n' \
    >> "${SANDBOX}/OLD"
  expect_render '<!-- ribbon:belt:start -->
my belt
<!-- ribbon:belt:end -->
<!-- ribbon:gate:start -->
my gate
<!-- ribbon:gate:end -->' --keep-from "${SANDBOX}/OLD" a.md
}

test_kept_body_is_inserted_verbatim() {
  new_sandbox
  printf '<!-- ribbon:belt:start -->\ntemplate body\n<!-- ribbon:belt:end -->\n' \
    > "${P}/a.md"
  printf '<!-- ribbon:belt:start -->\n{{NOPE}}\n<!-- ribbon:include x.md -->\n<!-- ribbon:belt:end -->\n' \
    > "${SANDBOX}/OLD"
  expect_render '<!-- ribbon:belt:start -->
{{NOPE}}
<!-- ribbon:include x.md -->
<!-- ribbon:belt:end -->' --keep-from "${SANDBOX}/OLD" a.md
}

test_malformed_region_in_the_old_file_fails() {
  new_sandbox
  printf '<!-- ribbon:belt:start -->\ntemplate body\n<!-- ribbon:belt:end -->\n' \
    > "${P}/a.md"
  printf '<!-- ribbon:belt:start -->\nfirst body\n<!-- ribbon:belt:start -->\n' \
    > "${SANDBOX}/OLD"
  printf 'second body\n<!-- ribbon:belt:end -->\n' >> "${SANDBOX}/OLD"
  expect_render_failure \
    "ribbon-render-protocol: malformed region belt in ${SANDBOX}/OLD" \
    --keep-from "${SANDBOX}/OLD" a.md
}

test_malformed_region_in_the_rendering_fails() {
  new_sandbox
  printf '<!-- ribbon:belt:start -->\nbody without an end mark\n' > "${P}/a.md"
  expect_render_failure \
    'ribbon-render-protocol: malformed region belt in the rendering' a.md
}

test_region_mark_with_a_crlf_ending_is_kept() {
  new_sandbox
  printf '<!-- ribbon:belt:start -->\r\nnew body\r\n<!-- ribbon:belt:end -->\r\n' \
    > "${P}/a.md"
  printf '<!-- ribbon:belt:start -->\r\nold body\r\n<!-- ribbon:belt:end -->\r\n' \
    > "${SANDBOX}/OLD"
  run --keep-from "${SANDBOX}/OLD" a.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  printf '<!-- ribbon:belt:start -->\r\nold body\r\n<!-- ribbon:belt:end -->\r\n' \
    | cmp -s - "${OUT}"
}

test_unreadable_keep_from_file_stays_on_one_line() {
  new_sandbox
  printf 'plain\n' > "${P}/a.md"
  expect_render_failure \
    'ribbon-render-protocol: cannot read no\x0ape' --keep-from $'no\npe' a.md
}

test_seat_files_are_the_pieces_the_template_does_not_read() {
  new_sandbox
  printf '<!-- ribbon:include b.md -->\n' > "${P}/a.md"
  printf 'b\n' > "${P}/b.md"
  printf 'c\n' > "${P}/c_template.md"
  mkdir -p "${P}/sub"
  printf 'd\n' > "${P}/sub/d.md"
  printf 'readme\n' > "${P}/README.md"
  printf 'readme\n' > "${P}/sub/README.md"
  printf 'x\n' > "${P}/x-structure.md"
  expect_render $'c_template.md\tc.md\nsub/d.md\tsub/d.md' --seat-files a.md
}

test_two_pieces_with_one_installed_path_fail() {
  new_sandbox
  printf 'a\n' > "${P}/a.md"
  printf 'c\n' > "${P}/c.md"
  printf 'c template\n' > "${P}/c_template.md"
  expect_render_failure \
    'ribbon-render-protocol: two pieces install as c.md' --seat-files a.md
}

test_seat_files_and_list_together_are_a_usage_error() {
  new_sandbox
  printf 'a\n' > "${P}/a.md"
  run --seat-files --list a.md
  [[ ${RC} -eq 2 ]] || return 1
  [[ ! -s ${OUT} ]]
}

#######################################
# Run the command against the repository's own protocol directory (no
# --protocol: the default beside the command), capturing stdout, stderr and
# the exit code. Used by the repository-guard tests.
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

test_project_block_has_one_roster_and_one_gate() {
  new_sandbox
  run_repo --set PROTOCOL_DIR=.ribbon/protocol project-structure.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  local mark
  for mark in '<!-- ribbon:belt:start -->' '<!-- ribbon:belt:end -->' \
              '<!-- ribbon:gate:start -->' '<!-- ribbon:gate:end -->'; do
    [[ $(grep -cF -- "${mark}" "${OUT}") -eq 1 ]] || return 1
  done
}

test_every_seat_pointer_names_a_seat_file() {
  new_sandbox
  run_repo --set PROTOCOL_DIR=.ribbon/protocol project-structure.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  # The backticks are Markdown here, not command substitution.
  # shellcheck disable=SC2016
  grep -o '`\.ribbon/protocol/[^`]*`' "${OUT}" \
    | sed 's/^`//; s/`$//' \
    | grep -v '^\.ribbon/protocol/$' | LC_ALL=C sort -u > "${SANDBOX}/pointers"
  run_repo --set PROTOCOL_DIR=.ribbon/protocol --seat-files project-structure.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  cut -f 2 "${OUT}" | sed 's#^#.ribbon/protocol/#' | LC_ALL=C sort -u \
    > "${SANDBOX}/installed"
  cmp -s "${SANDBOX}/pointers" "${SANDBOX}/installed"
}

test_whole_rendering_reads_every_piece_but_the_install_ones() {
  new_sandbox
  run_repo --list whole-structure.md
  [[ ${RC} -eq 0 ]] || return 1
  [[ ! -s ${ERR} ]] || return 1
  LC_ALL=C sort "${OUT}" > "${SANDBOX}/read.sorted"
  (
    cd "${SCRIPT_DIR}/../protocol" || exit 1
    set -o pipefail
    find . -type f -name '*.md' ! -path './README.md' ! -name '*-structure.md' \
      ! -name 'seats.md' ! -path './handlers/*' -print | sed 's|^\./||'
    printf 'whole-structure.md\n'
  ) > "${SANDBOX}/expected" || return 1
  LC_ALL=C sort "${SANDBOX}/expected" > "${SANDBOX}/expected.sorted"
  cmp -s "${SANDBOX}/read.sorted" "${SANDBOX}/expected.sorted"
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
  test_include_line_with_a_crlf_ending_is_replaced_by_the_piece
  test_include_line_with_text_before_its_crlf_is_malformed
  test_include_line_at_the_end_of_a_file_without_newline_is_replaced
  test_unreadable_piece_fails_with_one_line
  test_piece_that_is_not_utf8_fails_with_one_line
  test_control_characters_in_a_path_stay_on_one_line
  test_absolute_template_path_fails
  test_absolute_include_path_fails
  test_list_names_canonical_relative_paths
  test_sibling_directory_with_the_same_prefix_is_outside
  test_piece_without_final_newline_keeps_the_next_line
  test_list_names_every_file_in_reading_order
  test_default_protocol_directory_is_beside_the_scripts
  test_help_prints_usage
  test_missing_template_argument_prints_usage
  test_invalid_placeholder_name_is_a_usage_error
  test_kept_region_takes_its_body_from_the_old_file
  test_kept_region_missing_from_the_old_file_keeps_the_template_body
  test_two_kept_regions_keep_their_own_bodies
  test_kept_body_is_inserted_verbatim
  test_malformed_region_in_the_old_file_fails
  test_malformed_region_in_the_rendering_fails
  test_region_mark_with_a_crlf_ending_is_kept
  test_unreadable_keep_from_file_stays_on_one_line
  test_seat_files_are_the_pieces_the_template_does_not_read
  test_two_pieces_with_one_installed_path_fail
  test_seat_files_and_list_together_are_a_usage_error
  test_root_agents_md_is_the_whole_rendering
  test_herdr_config_is_the_handler_rendering
  test_project_block_has_one_roster_and_one_gate
  test_every_seat_pointer_names_a_seat_file
  test_whole_rendering_reads_every_piece_but_the_install_ones
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
