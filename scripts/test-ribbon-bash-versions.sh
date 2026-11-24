#!/usr/bin/env bash
# Opt-in tests for the installers' bash version check, under real old bash in
# podman: bash 3.2, which macOS ships as /bin/bash, must refuse before any
# write, and bash 4.4, the oldest supported, must install. The first run
# builds one image per version from the public bash images, adding the tools
# both installers need: GNU coreutils, git and python3.
# Each scenario is shell code for the container's bash, so it stays in single
# quotes on purpose.
# shellcheck disable=SC2016
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RIBBON_HOME="$(dirname "${SCRIPT_DIR}")"
IMAGE_PACKAGES='coreutils git python3'
readonly SCRIPT_DIR RIBBON_HOME IMAGE_PACKAGES

PASS=0
FAIL=0

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
# Build, once, an image of one bash version with the installers' tools. The
# tag names the packages, so a changed list builds a fresh image.
# Globals:
#   IMAGE_PACKAGES
# Arguments:
#   1: the bash version, e.g. 3.2.
# Outputs:
#   The image name on STDOUT.
#######################################
bash_image() {
  local version="$1" context
  local image="localhost/ribbon-test-bash:${version}-${IMAGE_PACKAGES// /-}"
  if ! podman image exists "${image}"; then
    context="$(mktemp -d)"
    printf 'FROM docker.io/library/bash:%s\nRUN apk add --no-cache %s\n' "${version}" "${IMAGE_PACKAGES}" \
      > "${context}/Containerfile"
    podman build -q -t "${image}" "${context}" >/dev/null
    local status=$?
    rm -rf "${context}"
    (( status == 0 )) || return 1
  fi
  printf '%s\n' "${image}"
}

#######################################
# Run a scenario under one bash version, in a throwaway container holding the
# template read-only at /ribbon and, under /sandbox, a home, a projects dir
# and a project repository with one commit.
# Arguments:
#   1: the bash version.
#   2: the scenario, shell code whose exit status is the result.
#######################################
in_bash() {
  local image
  image="$(bash_image "$1")" || return 1
  podman run --rm --security-opt label=disable -v "${RIBBON_HOME}:/ribbon:ro" \
    -e HOME=/sandbox/home "${image}" bash -c '
      mkdir -p /sandbox/home /sandbox/projects /sandbox/repo
      printf "# example-project AGENTS\n" > /sandbox/repo/AGENTS.md
      git -C /sandbox/repo init -q
      git -C /sandbox/repo config user.email test@example.com
      git -C /sandbox/repo config user.name test
      git -C /sandbox/repo add AGENTS.md
      git -C /sandbox/repo commit -qm init
      '"$2"
}

test_new_project_refuses_bash_3_2() {
  in_bash 3.2 '
    rc=0
    /ribbon/scripts/ribbon-new-project --projects /sandbox/projects example-project /sandbox/repo \
      </dev/null >/dev/null 2>/sandbox/error || rc=$?
    [ "${rc}" = 1 ] && [ ! -e /sandbox/projects/example-project ] \
      && [ ! -e /sandbox/repo/AGENTS.local.md ] \
      && grep -q "needs bash 4.4 or newer" /sandbox/error \
      && grep -q "brew install bash" /sandbox/error'
}

test_seed_project_refuses_bash_3_2() {
  in_bash 3.2 '
    rc=0
    /ribbon/scripts/ribbon-seed-project /sandbox/repo </dev/null >/dev/null 2>/sandbox/error || rc=$?
    [ "${rc}" = 1 ] && [ ! -e /sandbox/repo/docs ] && [ ! -e /sandbox/repo/rules ] \
      && [ "$(git -C /sandbox/repo rev-list --count HEAD)" = 1 ] \
      && grep -q "needs bash 4.4 or newer" /sandbox/error \
      && grep -q "brew install bash" /sandbox/error'
}

test_new_project_installs_on_bash_4_4() {
  in_bash 4.4 '
    /ribbon/scripts/ribbon-new-project --projects /sandbox/projects example-project /sandbox/repo \
      </dev/null >/dev/null \
      && [ -f /sandbox/projects/example-project/docs/README.md ] \
      && [ -f /sandbox/repo/AGENTS.local.md ]'
}

test_seed_project_installs_on_bash_4_4() {
  in_bash 4.4 '
    /ribbon/scripts/ribbon-seed-project /sandbox/repo </dev/null >/dev/null \
      && [ -d /sandbox/repo/docs ] && [ -d /sandbox/repo/rules ] \
      && [ "$(git -C /sandbox/repo rev-list --count HEAD)" = 2 ]'
}

readonly TESTS=(
  test_new_project_refuses_bash_3_2
  test_seed_project_refuses_bash_3_2
  test_new_project_installs_on_bash_4_4
  test_seed_project_installs_on_bash_4_4
)

main() {
  command -v podman >/dev/null 2>&1 \
    || { printf 'test-ribbon-bash-versions: needs podman\n' >&2; return 1; }
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
