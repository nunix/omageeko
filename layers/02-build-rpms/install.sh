#!/bin/bash
# Layer 02 - build RPMs
# Builds software missing from Tumbleweed (packages/<name>/<name>.spec) in the
# omageeko-builder container, publishes it to the local repo, installs it.
#
# A package is rebuilt only when its stamp changes: hash of packages/<name>/
# plus the repo versions of the packages listed in packages/<name>/rebuild-on
# (ABI-bound dependencies, e.g. Qt for quickshell, hyprland for the plugin).
# Force with OMAGEEKO_REBUILD=all or OMAGEEKO_REBUILD="quickshell owe".

source "$(dirname "$(readlink -f "$0")")/../../lib/common.sh"

# Build order; also the install set for this layer
PACKAGES=(
  quickshell
  owe
  omarchy-hyprland-titlebars
  hyprland-preview-share-picker
  jetbrains-mono-nerd-fonts
  ia-writer-fonts
)
# RPM names to install (owe's spec also builds owe-lockfeed)
INSTALL=(
  quickshell
  owe
  owe-lockfeed
  omarchy-hyprland-titlebars
  hyprland-preview-share-picker
  jetbrains-mono-nerd-fonts
  ia-writer-fonts
)
STAMP_DIR="$OMAGEEKO_REPO_DIR/.stamps"

repo_version() {
  zypper --no-refresh -q info "$1" 2>/dev/null | awk '/^Version/ { print $3; exit }'
}

package_stamp() {
  local dir="$OMAGEEKO_ROOT/packages/$1"
  {
    (cd "$dir" && find . -type f -print0 | sort -z | xargs -0 sha256sum)
    if [[ -f $dir/rebuild-on ]]; then
      while read -r dep; do
        [[ -n $dep ]] && echo "$dep $(repo_version "$dep")"
      done < "$dir/rebuild-on"
    fi
  } | sha256sum | cut -d' ' -f1
}

needs_build() {
  local name="$1" stamp="$2"
  [[ ${OMAGEEKO_REBUILD:-} == "all" || " ${OMAGEEKO_REBUILD:-} " == *" $name "* ]] && return 0
  [[ ! -f $STAMP_DIR/$name || $(cat "$STAMP_DIR/$name") != "$stamp" ]]
}

require_user
podman image exists "$OMAGEEKO_BUILDER_IMAGE" || die "Builder image missing: run layer 00"

# Built RPMs link against the builder's Tumbleweed snapshot; the host must not be older
host_snapshot=$(. /etc/os-release && echo "$VERSION_ID")
builder_snapshot=$(in_builder bash -c 'zypper -q ref >/dev/null; zypper -q -n dup --no-recommends >/dev/null; . /etc/os-release; echo $VERSION_ID' | tail -1)
if (( builder_snapshot > host_snapshot )); then
  die "Host is on Tumbleweed $host_snapshot, builder on $builder_snapshot. Run 'sudo zypper dup' (and reboot if needed) first."
fi

mkdir -p "$STAMP_DIR"
sudo zypper --non-interactive --quiet refresh >/dev/null

for name in "${PACKAGES[@]}"; do
  spec="packages/$name/$name.spec"
  [[ -f $OMAGEEKO_ROOT/$spec ]] || die "Missing spec: $spec"
  stamp=$(package_stamp "$name")
  if needs_build "$name" "$stamp"; then
    log "Building $name"
    log_file="$OMAGEEKO_REPO_DIR/.logs/$name.log"
    mkdir -p "$(dirname "$log_file")"
    if in_builder lib/build-rpm.sh "$spec" >"$log_file" 2>&1; then
      echo "$stamp" > "$STAMP_DIR/$name"
    else
      tail -30 "$log_file" >&2
      die "Build failed for $name (full log: $log_file)"
    fi
  else
    log "$name is up to date"
  fi
done

snap_begin "02-build-rpms"
sudo zypper --non-interactive refresh "$OMAGEEKO_REPO_ALIAS" >/dev/null
# Install or upgrade to the newest local builds
sudo zypper --non-interactive install --no-recommends --from "$OMAGEEKO_REPO_ALIAS" "${INSTALL[@]}"
fc-cache -f >/dev/null
snap_end

log "Layer 02 done. Run layers/02-build-rpms/verify.sh"
