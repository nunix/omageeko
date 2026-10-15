# Shared helpers for omageeko layer scripts. Source it, don't execute it.

set -euo pipefail

OMAGEEKO_ROOT="${OMAGEEKO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OMAGEEKO_REPO_DIR="/var/lib/omageeko/repo"
OMAGEEKO_REPO_ALIAS="omageeko-local"
OMAGEEKO_BUILDER_IMAGE="localhost/omageeko-builder:tw"
OMAGEEKO_UPSTREAM="$OMAGEEKO_ROOT/upstream"

# Upstream pin (repo/branch/commit) from upstream.lock
while IFS='=' read -r key value; do
  [[ -n $key && $key != \#* ]] && printf -v "UPSTREAM_${key^^}" '%s' "$value"
done < "$OMAGEEKO_ROOT/upstream.lock"

log() { printf '\e[1;34m[omageeko]\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m[omageeko]\e[0m %s\n' "$*" >&2; }
die() { printf '\e[1;31m[omageeko]\e[0m %s\n' "$*" >&2; exit 1; }

require_user() {
  (( EUID != 0 )) || die "Run as your normal user; sudo is used where needed."
  sudo -n true 2>/dev/null || die "Passwordless sudo is required (or run 'sudo -v' first)."
}

# zypper_install pkg... : installs only what is missing
zypper_install() {
  local missing=()
  for pkg in "$@"; do
    rpm -q --whatprovides "$pkg" &>/dev/null || missing+=("$pkg")
  done
  if (( ${#missing[@]} )); then
    log "Installing: ${missing[*]}"
    sudo zypper --non-interactive install --no-recommends "${missing[@]}"
  fi
}

# Snapper pre/post pair around a layer: snap_begin "<layer>" ... snap_end
SNAP_PRE=""
snap_begin() {
  SNAP_LAYER="$1"
  if command -v snapper &>/dev/null && sudo snapper list-configs 2>/dev/null | grep -q '^root '; then
    SNAP_PRE=$(sudo snapper create --type pre --cleanup-algorithm number --print-number \
      --description "omageeko: $SNAP_LAYER")
    log "Snapper pre-snapshot #$SNAP_PRE"
    trap 'snap_end failed' ERR
  fi
}
snap_end() {
  local status="${1:-ok}"
  trap - ERR
  if [[ -n $SNAP_PRE ]]; then
    local post
    post=$(sudo snapper create --type post --pre-number "$SNAP_PRE" --cleanup-algorithm number \
      --print-number --description "omageeko: $SNAP_LAYER ($status)")
    log "Snapper post-snapshot #$post (rollback diff: snapper status $SNAP_PRE..$post)"
    SNAP_PRE=""
  fi
}

# Fetch the pinned upstream omarchy tree into $OMAGEEKO_UPSTREAM
fetch_upstream() {
  if [[ -d $OMAGEEKO_UPSTREAM/.git ]] && [[ $(git -C "$OMAGEEKO_UPSTREAM" rev-parse HEAD) == "$UPSTREAM_COMMIT" ]]; then
    log "Upstream already at ${UPSTREAM_COMMIT:0:12}"
    return
  fi
  if [[ ! -d $OMAGEEKO_UPSTREAM/.git ]]; then
    rm -rf "$OMAGEEKO_UPSTREAM"
    git init -q "$OMAGEEKO_UPSTREAM"
    git -C "$OMAGEEKO_UPSTREAM" remote add origin "$UPSTREAM_REPO"
  fi
  log "Fetching $UPSTREAM_REPO@${UPSTREAM_COMMIT:0:12} ($UPSTREAM_BRANCH)"
  git -C "$OMAGEEKO_UPSTREAM" fetch -q --depth 1 origin "$UPSTREAM_COMMIT"
  git -C "$OMAGEEKO_UPSTREAM" -c advice.detachedHead=false checkout -q FETCH_HEAD
}

# Run a command inside the builder container: project at /src, local repo at /repo.
# Rootless podman maps container root to the invoking user, so outputs are user-owned.
in_builder() {
  podman run --rm --security-opt label=disable \
    -v "$OMAGEEKO_ROOT:/src" -v "$OMAGEEKO_REPO_DIR:/repo" \
    -v omageeko-zypp-cache:/var/cache/zypp \
    -w /src "$OMAGEEKO_BUILDER_IMAGE" "$@"
}

# map_packages <layer> : TW package names for a layer from packages.map (plain entries only)
map_packages() {
  awk -v layer="$1" '!/^#/ && $2 == layer && $3 !~ /^[@-]/ {
    n = split($3, a, ","); for (i = 1; i <= n; i++) print a[i]
  }' "$OMAGEEKO_ROOT/packages.map" | sort -u
}

# map_special <layer> <kind> : entries like @repo:<x>, @build, @flatpak:<id> for a layer
map_special() {
  awk -v layer="$1" -v kind="@$2" '!/^#/ && $2 == layer && index($3, kind) == 1 { print $1, $3 }' \
    "$OMAGEEKO_ROOT/packages.map"
}

# ---- RPM builds (packages/<name>/<name>.spec) in the builder container
# A package rebuilds only when its stamp changes: hash of packages/<name>/ plus
# the repo versions of the packages in packages/<name>/rebuild-on.
# Force with OMAGEEKO_REBUILD=all or OMAGEEKO_REBUILD="name1 name2".
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

# The builder must not be on a newer Tumbleweed snapshot than the host
check_builder_snapshot() {
  podman image exists "$OMAGEEKO_BUILDER_IMAGE" || die "Builder image missing: run layer 00"
  local host builder
  host=$(. /etc/os-release && echo "$VERSION_ID")
  builder=$(in_builder bash -c 'zypper -q ref >/dev/null; zypper -q -n dup --no-recommends >/dev/null; . /etc/os-release; echo $VERSION_ID' | tail -1)
  if (( builder > host )); then
    die "Host is on Tumbleweed $host, builder on $builder. Run 'sudo zypper dup' (and reboot if needed) first."
  fi
}

# build_packages name... : build changed packages into the local repo
build_packages() {
  local name spec stamp log_file
  mkdir -p "$STAMP_DIR" "$OMAGEEKO_REPO_DIR/.logs"
  sudo zypper --non-interactive --quiet refresh >/dev/null
  for name in "$@"; do
    spec="packages/$name/$name.spec"
    [[ -f $OMAGEEKO_ROOT/$spec ]] || die "Missing spec: $spec"
    stamp=$(package_stamp "$name")
    if needs_build "$name" "$stamp"; then
      log "Building $name"
      log_file="$OMAGEEKO_REPO_DIR/.logs/$name.log"
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
}

# install_local_rpms rpm... : install or upgrade to the newest omageeko-local builds
install_local_rpms() {
  sudo zypper --non-interactive refresh "$OMAGEEKO_REPO_ALIAS" >/dev/null
  sudo zypper --non-interactive install --no-recommends --from "$OMAGEEKO_REPO_ALIAS" "$@"
}
