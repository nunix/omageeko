# omageeko: package helpers shared by the Tumbleweed ports of omarchy-pkg-*.
# Sourced, not executed. Upstream Omarchy commands name Arch packages; these
# helpers translate them with /usr/share/omageeko/pkgmap.tsv (generated from
# omageeko's packages.map) and act through zypper or flatpak.

OMAGEEKO_PKGMAP=${OMAGEEKO_PKGMAP:-/usr/share/omageeko/pkgmap.tsv}
OMAGEEKO_REPOS=${OMAGEEKO_REPOS:-/usr/share/omageeko/repos.tsv}

# omageeko_pkg_resolve <arch-name> : prints one target per line
#   rpm:<name>              install/query with zypper/rpm
#   repo:<alias>:<name>     rpm from a vendor repo (repos.tsv), enabled on first use
#   flatpak:<id>            install/query with flatpak (Flathub)
#   box:<pkg>               Omarchy's Arch package inside the omageeko distrobox (omageeko-box)
#   none:                   nothing to install on Tumbleweed (counts as present)
#   skip:<reason>           intentionally not available on omageeko
# Names absent from the map are assumed to share the Arch name.
omageeko_pkg_resolve() {
  local name=$1 target note
  if [[ -r $OMAGEEKO_PKGMAP ]]; then
    target=$(awk -F'\t' -v n="$name" '$1 == n { print $2; exit }' "$OMAGEEKO_PKGMAP")
    note=$(awk -F'\t' -v n="$name" '$1 == n { print $3; exit }' "$OMAGEEKO_PKGMAP")
  fi
  case "$target" in
    "") echo "rpm:$name" ;;
    -) echo "skip:${note:-not available on omageeko}" ;;
    @flatpak:*) echo "flatpak:${target#@flatpak:}" ;;
    @build:*) echo "rpm:${target#@build:}" ;;
    @build) echo "rpm:$name" ;;
    @repo:*:*) echo "repo:${target#@repo:}" ;;
    @repo:*) echo "rpm:$name" ;;
    @none) echo "none:" ;;
    @box:*) echo "box:${target#@box:}" ;;
    *) tr ',' '\n' <<<"$target" | sed 's/^/rpm:/' ;;
  esac
}

omageeko_flatpak_installed() {
  command -v flatpak &>/dev/null && flatpak info "$1" &>/dev/null
}

# omageeko_pkg_installed <arch-name> : true when every target is installed
omageeko_pkg_installed() {
  local target
  while read -r target; do
    case "$target" in
      rpm:*) rpm -q --whatprovides -- "${target#rpm:}" &>/dev/null || return 1 ;;
      repo:*) rpm -q --whatprovides -- "${target##*:}" &>/dev/null || return 1 ;;
      flatpak:*) omageeko_flatpak_installed "${target#flatpak:}" || return 1 ;;
      box:*) omageeko-box has "${target#box:}" || return 1 ;;
      none:*) ;;
      skip:*) return 1 ;;
    esac
  done < <(omageeko_pkg_resolve "$1")
  return 0
}

# omageeko_repo_enable <alias> : add a vendor repo from repos.tsv (key first, GPG check on)
omageeko_repo_enable() {
  local alias=$1 url key
  zypper lr "$alias" &>/dev/null && return 0
  read -r url key < <(awk -F'\t' -v a="$alias" '$1 == a { print $2, $3; exit }' "$OMAGEEKO_REPOS")
  if [[ -z $url ]]; then
    echo "omageeko: unknown vendor repo '$alias' (not in $OMAGEEKO_REPOS)" >&2
    return 1
  fi
  echo "Adding vendor repository $alias ($url)"
  omageeko_sudo rpm --import "$key" || return 1
  omageeko_sudo zypper --non-interactive addrepo --refresh --priority 95 "$url" "$alias" || return 1
  omageeko_sudo zypper --non-interactive refresh "$alias"
}

# omageeko_sudo <cmd...> : run as root (directly when already root)
omageeko_sudo() {
  if (( EUID == 0 )); then
    "$@"
  else
    sudo "$@"
  fi
}

# Installed package names, one per line (rpm and flatpak app ids)
omageeko_installed_names() {
  rpm -qa --qf '%{NAME}\n'
  command -v flatpak &>/dev/null && flatpak list --app --columns=application 2>/dev/null
}
