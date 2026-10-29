# omageeko: port of omarchy-pkgs/pkgbuilds/ttfx (0.5.1-1)
%global debug_package %{nil}

Name:           ttfx
Version:        0.5.1
Release:        1.omageeko%{?dist}
Summary:        Terminal text effects as a single static binary (Rust port of terminaltexteffects)
License:        MIT
URL:            https://github.com/omacom/ttfx
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz
BuildRequires:  cargo
BuildRequires:  rust

%description
ttfx renders terminaltexteffects-style animations of text in the terminal.
Omarchy's screensaver (omarchy-screensaver) animates the branding logo with it.

%prep
%autosetup -p1

%build
export CARGO_TARGET_DIR=target
cargo build --locked --release

%install
install -Dm755 target/release/ttfx %{buildroot}%{_bindir}/ttfx
install -d %{buildroot}%{_datadir}/bash-completion/completions %{buildroot}%{_datadir}/zsh/site-functions
target/release/ttfx --print-completion bash > %{buildroot}%{_datadir}/bash-completion/completions/ttfx
target/release/ttfx --print-completion zsh > %{buildroot}%{_datadir}/zsh/site-functions/_ttfx

%files
%license LICENSE NOTICE
%doc README.md
%{_bindir}/ttfx
%{_datadir}/bash-completion/completions/ttfx
%{_datadir}/zsh/site-functions/_ttfx
