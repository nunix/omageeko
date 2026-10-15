# omageeko: port of Arch's extra/bluez-tools (0.2.0-6, git 7cb788c).
# Provides bt-agent, which Omarchy's bt-agent.service runs as the pairing agent;
# without it bluetoothd has no agent and pairing loops ("No agent available").
%global commit 7cb788c9c43facfd2d14ff50e16d6a19f033a6a7
%global debug_package %{nil}

Name:           bluez-tools
Version:        0.2.0+git7cb788c
Release:        6.omageeko%{?dist}
Summary:        Tools to manage Bluetooth devices (bt-agent, bt-adapter, bt-device, ...)
License:        GPL-2.0-or-later
URL:            https://github.com/khvzak/bluez-tools
Source0:        %{url}/archive/%{commit}.tar.gz#/%{name}-%{commit}.tar.gz
BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  libtool
BuildRequires:  make
BuildRequires:  gcc
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(gio-2.0)
BuildRequires:  readline-devel
Requires:       bluez

%description
Command-line tools for BlueZ 5: bt-adapter, bt-agent, bt-device, bt-network
and bt-obex. Omarchy uses bt-agent as an auto-accepting pairing agent.

%prep
%setup -q -n %{name}-%{commit}

%build
# GCC 10+ defaults to -fno-common; this code still relies on common symbols
export CFLAGS="%{optflags} -fcommon"
./autogen.sh --prefix=%{_prefix}
%make_build

%install
%make_install

%files
%license COPYING
%{_bindir}/bt-*
%{_mandir}/man1/bt-*
