#!/bin/bash
# Generated inputs for omageeko.spec. lib/common.sh build_packages runs this
# before stamping, so upstream.lock or packages.map changes always rebuild it.
set -euo pipefail
root=$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)
pkg="$root/packages/omageeko"

while IFS='=' read -r key value; do
  [[ -n $key && $key != \#* ]] && printf -v "lock_${key}" '%s' "$value"
done < "$root/upstream.lock"

# Spec: commit, date and release from upstream.lock
commit_date=${lock_commit_date%%T*}
sed -i -E \
  -e "s/^%global commit .*/%global commit $lock_commit/" \
  -e "s/^%global commit_date .*/%global commit_date ${commit_date//-/}/" \
  -e "s/^%global upstream_release .*/%global upstream_release ${lock_release#v}/" \
  "$pkg/omageeko.spec"

# pkgmap.tsv for the omarchy-pkg-* ports: <arch-name> <target> <note>
awk '!/^#/ && NF >= 3 && $1 !~ /^\+/ {
  note = ""
  if ((i = index($0, "#")) > 0) { note = substr($0, i + 1); sub(/^ +/, "", note) }
  printf "%s\t%s\t%s\n", $1, $3, note
}' "$root/packages.map" > "$pkg/pkgmap.tsv"

# The migration classifier ships in the RPM (omageeko-update gates migrations
# with it even without a checkout); the source of truth is tools/omageeko-bump
install -m755 "$root/tools/omageeko-bump" "$pkg/omageeko-bump"
