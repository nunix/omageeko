#!/bin/bash
# Layer 00 - verify bootstrap

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"
set +e
fail=0
check() {
  local desc="$1"; shift
  if "$@" &>/dev/null; then
    printf '  \e[32mok\e[0m   %s\n' "$desc"
  else
    printf '  \e[31mFAIL\e[0m %s\n' "$desc"; fail=1
  fi
}

check "git installed" command -v git
check "podman rootless" bash -c '[[ $(podman info --format {{.Host.Security.Rootless}}) == true ]]'
check "packman repo enabled" bash -c 'zypper lr packman-essentials | grep -q "Enabled *: Yes"'
check "libavcodec from Packman" bash -c 'rpm -q --qf "%{VENDOR}\n" $(rpm -qa "libavcodec[0-9]*" | head -1) | grep -qi packman'
check "local repo dir has repodata" test -f "$OMAGEEKO_REPO_DIR/repodata/repomd.xml"
check "local repo registered" zypper lr "$OMAGEEKO_REPO_ALIAS"
check "builder image exists" podman image exists "$OMAGEEKO_BUILDER_IMAGE"
check "builder has rpmbuild/cmake/cargo/go" in_builder bash -c 'rpmbuild --version && cmake --version && cargo --version && go version'
probe_repo_write() {
  in_builder touch /repo/.probe && [[ $(stat -c %U "$OMAGEEKO_REPO_DIR/.probe") == "$USER" ]] && rm "$OMAGEEKO_REPO_DIR/.probe"
}
check "builder writes user-owned files to /repo" probe_repo_write
check "upstream at pinned commit" bash -c "[[ \$(git -C $OMAGEEKO_UPSTREAM rev-parse HEAD) == $UPSTREAM_COMMIT ]]"
check "upstream has quattro layout" test -f "$OMAGEEKO_UPSTREAM/default/hypr/bootstrap.lua"

exit $fail
