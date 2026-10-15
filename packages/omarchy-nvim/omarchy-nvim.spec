# omageeko: port of omarchy-pkgs/pkgbuilds/omarchy-nvim (2026.9.21-5)
# LazyVim starter + Omarchy's config, with every plugin pre-installed and slimmed
# at build time (network access in the builder), seeded through /etc/skel.
%global debug_package %{nil}
%global __os_install_post %{nil}
%global __requires_exclude_from ^(%{_sysconfdir}/skel|%{_datadir}/omarchy-nvim)/.*$
%global __provides_exclude_from ^(%{_sysconfdir}/skel|%{_datadir}/omarchy-nvim)/.*$

Name:           omarchy-nvim
Version:        2026.9.21
Release:        5.omageeko%{?dist}
Summary:        Pre-built LazyVim configuration with cached plugins (Omarchy)
License:        MIT
URL:            https://github.com/LazyVim/LazyVim
Source0:        https://github.com/LazyVim/starter/archive/refs/heads/main.tar.gz#/lazyvim-starter-main.tar.gz
Source1:        lazyvim.json
Source2:        omarchy-nvim-setup
ExclusiveArch:  x86_64
BuildRequires:  neovim >= 0.9.0
BuildRequires:  git-core
BuildRequires:  curl
BuildRequires:  tar
BuildRequires:  tree-sitter
BuildRequires:  nodejs-default
BuildRequires:  npm-default
BuildRequires:  gcc
Requires:       neovim >= 0.9.0
Requires:       git-core

%description
Omarchy's Neovim setup: LazyVim with Omarchy theme hot-reload, transparency and
options, all plugins cached so the first launch needs no downloads.
omarchy-nvim-setup / omarchy-nvim-refresh copy it into a user's home.

%prep
%setup -q -c

%build
export HOME="$PWD/build-home"
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state" XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
cp -r starter-main "$XDG_CONFIG_HOME/nvim"
rm -rf "$XDG_CONFIG_HOME/nvim/.git"
cp -r %{_sourcedir}/lua %{_sourcedir}/plugin "$XDG_CONFIG_HOME/nvim/"
cp %{SOURCE1} "$XDG_CONFIG_HOME/nvim/"
echo "Installing LazyVim plugins..."
nvim --headless "+Lazy! sync" "+qa!" || true

# Omarchy's slimming (verbatim from the PKGBUILD)
slim_lazy_repos() {
  local data_dir="$1"
  local dir

  for dir in "$data_dir"/lazy/*/; do
    [[ -d "$dir/.git" ]] || continue

    # Exclude test suites via sparse-checkout rather than rm: the worktree
    # stays clean, so the restore pass in package() does not resurrect them
    # and future :Lazy checkouts keep honoring the exclusion. snacks.nvim
    # alone ships 18 MB of tests.
    git -C "$dir" sparse-checkout set --no-cone '/*' '!/test/' '!/tests/' '!/spec/'

    # Cut history down to the checked-out tips: drop the refs that pin older
    # objects, mark every remaining tip as a shallow boundary, then gc. This
    # is half the package -- ~70 MB of .git across the plugins. `git fetch`
    # into a shallow repo stays shallow and re-fetches tags, so :Lazy update
    # still works.
    #
    # Keep refs/remotes/origin/HEAD. It pins no objects (it is a symref, and
    # stays readable after its target ref is gone), but lazy.nvim resolves the
    # default branch through it for plugins parked on a detached HEAD by a
    # version pin -- lazy.nvim, LazyVim and blink.cmp. Without it, get_branch()
    # returns nil and every lockfile write asserts, so :Lazy install/update/sync
    # dies with E5113 on a fresh install.
    git -C "$dir" for-each-ref --format='%%(refname)' refs/remotes refs/tags |
      while IFS= read -r ref; do
        [[ $ref == refs/remotes/origin/HEAD ]] && continue
        git -C "$dir" update-ref -d "$ref"
      done
    rm -f "$dir/.git/FETCH_HEAD" "$dir/.git/ORIG_HEAD"
    {
      git -C "$dir" rev-parse HEAD
      git -C "$dir" for-each-ref --format='%%(objectname)' refs/heads
    } | sort -u >"$dir/.git/shallow"
    git -C "$dir" reflog expire --expire=all --all

    # lazy.nvim clones with --filter=blob:none, which marks the pack as a
    # promisor pack that gc refuses to repack or prune. The repo is shallow
    # at its tips now, so everything reachable exists locally: drop the
    # promisor markers and the stale commit-graph, then gc for real. Future
    # fetches simply run unfiltered.
    git -C "$dir" config --unset-all remote.origin.promisor || true
    git -C "$dir" config --unset-all remote.origin.partialclonefilter || true
    rm -f "$dir/.git/objects/pack/"*.promisor "$dir/.git/objects/info/commit-graph"
    rm -rf "$dir/.git/objects/info/commit-graphs"
    git -C "$dir" -c gc.writeCommitGraph=false gc --prune=now --quiet
  done
}
slim_lazy_repos "$XDG_DATA_HOME/nvim"
test -d "$XDG_DATA_HOME/nvim/lazy/lazy.nvim" || { echo "LazyVim plugin sync failed" >&2; exit 1; }

%install
export HOME="$PWD/build-home"
export XDG_CONFIG_HOME="$HOME/.config" XDG_DATA_HOME="$HOME/.local/share"
restore_lazy_worktrees() {
  local data_dir="$1"
  local dir

  for dir in "$data_dir"/lazy/*/; do
    [[ -d "$dir/.git" ]] || continue
    git --git-dir="$dir/.git" --work-tree="$dir" restore .
  done
}
pkg=%{buildroot}%{_datadir}/%{name}
install -dm755 "$pkg"
cp -a "$XDG_CONFIG_HOME/nvim" "$pkg/config"
cp -a "$XDG_DATA_HOME/nvim" "$pkg/data"
rm -rf "$pkg/data/site"/*
mkdir -p "$pkg/data/site"
chmod -R 755 "$pkg"
find "$pkg" -type f -exec chmod 644 {} \;
restore_lazy_worktrees "$pkg/data"
install -dm755 %{buildroot}%{_sysconfdir}/skel/.config %{buildroot}%{_sysconfdir}/skel/.local/share
cp -a "$pkg/config" %{buildroot}%{_sysconfdir}/skel/.config/nvim
cp -a "$pkg/data" %{buildroot}%{_sysconfdir}/skel/.local/share/nvim
ln -snf ../../../../.local/state/omarchy/current/theme/neovim.lua \
  %{buildroot}%{_sysconfdir}/skel/.config/nvim/lua/plugins/theme.lua
rm -rf "$pkg/data"
install -Dm755 %{SOURCE2} %{buildroot}%{_bindir}/omarchy-nvim-setup
ln -s omarchy-nvim-setup %{buildroot}%{_bindir}/omarchy-nvim-refresh

%files
%{_bindir}/omarchy-nvim-setup
%{_bindir}/omarchy-nvim-refresh
%{_datadir}/%{name}/
%{_sysconfdir}/skel/.config/nvim/
%{_sysconfdir}/skel/.local/share/nvim/
