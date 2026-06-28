# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.88.0"

inherit cargo desktop git-r3 linux-info udev xdg

DESCRIPTION="Tray application for the Steam Controller (2026) without Steam"
HOMEPAGE="https://github.com/LennardKittner/OpenSteamController"
EGIT_REPO_URI="https://github.com/LennardKittner/OpenSteamController.git"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+="
	0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2
	CC0-1.0 ISC LGPL-2.1+ MPL-2.0 Unicode-3.0 Unlicense WTFPL-2 ZLIB
"
SLOT="0"
KEYWORDS=""

RESTRICT="test"

DEPEND="
	dev-libs/hidapi
	dev-libs/libusb:1
	sys-apps/dbus
	virtual/libudev
"
RDEPEND="${DEPEND}"
BDEPEND="
	virtual/pkgconfig
	virtual/rust
"

QA_FLAGS_IGNORED="usr/bin/open-steam-controller"

pkg_setup() {
	linux-info_pkg_setup
	rust_pkg_setup
}

pkg_pretend() {
	local CONFIG_CHECK="~INPUT_UINPUT"
	[[ ${MERGE_TYPE} != buildonly ]] && check_extra_config
}

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

# FIXME: wait for https://github.com/LennardKittner/OpenSteamController/pull/2 being merged.
src_prepare() {
	default
	sed -i 's/Categories=Game, Utility/Categories=Game;Utility/' \
		open-steam-controller.desktop || die
}

src_install() {
	cargo_src_install

	udev_dorules "${S}/99-open-steam-controller.rules"
	domenu "${S}/open-steam-controller.desktop"
}

pkg_postinst() {
	udev_reload
	xdg_desktop_database_update
}

pkg_postrm() {
	udev_reload
	xdg_desktop_database_update
}
