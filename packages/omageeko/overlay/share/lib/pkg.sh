# omageeko: package helpers shared by the Tumbleweed ports of omarchy-pkg-*.
# Sourced, not executed. Upstream Omarchy commands name Arch packages; these
# helpers translate them with /usr/share/omageeko/pkgmap.tsv (generated from
# omageeko's packages.map) and act through zypper or flatpak.

OMAGEEKO_PKGMAP=${OMAGEEKO_PKGMAP:-/usr/share/omageeko/pkgmap.tsv}

# omageeko_pkg_resolve <arch-name> : prints one target per line
#   rpm:<name>      install/query with zypper/rpm
#   flatpak:<id>    install/query with flatpak (Flathub)
#   skip:<reason>   intentionally not available on omageeko
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
    @repo:*) echo "rpm:$name" ;;
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
      flatpak:*) omageeko_flatpak_installed "${target#flatpak:}" || return 1 ;;
      skip:*) return 1 ;;
    esac
  done < <(omageeko_pkg_resolve "$1")
  return 0
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
