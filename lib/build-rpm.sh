#!/bin/bash
# Build one omageeko RPM inside the builder container.
# Usage (in container): lib/build-rpm.sh packages/<name>/<name>.spec
# Expects the project at /src and the local repo at /repo (see in_builder).

set -euo pipefail

spec="$1"
pkgdir=$(dirname "$spec")
topdir=/tmp/rpmbuild

echo ">>> Syncing builder with current Tumbleweed"
# One unreachable repo (a DNS blip on codecs.opensuse.org) must not fail every
# build; the dup below works from the metadata that did refresh
zypper --non-interactive --quiet refresh || echo ">>> refresh had errors (continuing)"
zypper --non-interactive --quiet dist-upgrade --no-recommends

rm -rf "$topdir"
mkdir -p "$topdir"/{SOURCES,SPECS,BUILD,RPMS,SRPMS}
# Patches and extra files (and subdirectories) ship next to the spec
cp -a "$pkgdir"/. "$topdir/SOURCES/"
rm -f "$topdir"/SOURCES/*.spec

echo ">>> Installing BuildRequires"
mapfile -t buildreqs < <(rpmspec -q --buildrequires "$spec" | sed -E 's/ +([<>=]+) +/\1/')
if (( ${#buildreqs[@]} )); then
  if ! zypper --non-interactive --quiet install --no-recommends "${buildreqs[@]}"; then
    # Packman sometimes publishes builds against a library Tumbleweed has just
    # dropped or renamed (ffmpeg 9 needing liboapv.so.1 after 20261020), and its
    # higher priority keeps zypper on the broken candidate. This container is
    # thrown away, so retry once with Tumbleweed's own packages.
    if zypper --non-interactive --quiet lr packman-essentials >/dev/null 2>&1; then
      echo ">>> BuildRequires not installable with Packman; retrying with Tumbleweed's packages"
      zypper --non-interactive --quiet modifyrepo --disable packman-essentials
      zypper --non-interactive --quiet install --no-recommends --allow-vendor-change "${buildreqs[@]}"
    else
      exit 1
    fi
  fi
fi

echo ">>> Fetching sources"
# TW has no spectool: take remote Source URLs from the parsed spec.
# A "#/name" fragment sets the local file name (standard Fedora/SUSE convention).
rpmspec -P "$spec" | sed -nE 's/^Source[0-9]*:[[:space:]]*((https?|ftp):\/\/.*)$/\1/p' |
  while read -r url; do
    file=${url##*/}
    [[ $url == *'#/'* ]] && file=${url##*#/} && url=${url%%#/*}
    if [[ ! -f $topdir/SOURCES/$file ]]; then
      echo "    $file"
      curl -fsSL --retry 3 -o "$topdir/SOURCES/$file" "$url"
    fi
  done

echo ">>> Building"
# %{?dist} = build timestamp, so every rebuild is a newer release zypper will upgrade to
rpmbuild --define "_topdir $topdir" --define "dist .b$(date -u +%Y%m%d%H%M%S)" -ba "$spec"

echo ">>> Publishing to local repo"
for rpm in "$topdir"/RPMS/*/*.rpm; do
  arch=$(basename "$(dirname "$rpm")")
  mkdir -p "/repo/$arch"
  cp -f "$rpm" "/repo/$arch/"
  echo "    $arch/$(basename "$rpm")"
done
mkdir -p /repo/src
cp -f "$topdir"/SRPMS/*.src.rpm /repo/src/
createrepo_c --quiet --update /repo
