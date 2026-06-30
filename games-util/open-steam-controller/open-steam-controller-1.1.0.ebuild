# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# CRATES and LICENSE maintained with: pycargoebuild -c -i ${PN}-${PV}.ebuild

EAPI=8

CRATES=""

inherit cargo desktop linux-info udev xdg

DESCRIPTION="Tray application for the Steam Controller (2026) without Steam"
HOMEPAGE="https://github.com/LennardKittner/OpenSteamController"
SRC_URI="
	https://github.com/LennardKittner/OpenSteamController/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
"
if [[ ${PKGBUMPING} != ${PVR} ]]; then
	SRC_URI+="
		https://github.com/pkulev/riru/releases/download/1.0.0/${P}-crates.tar.xz
	"
fi

S="${WORKDIR}/OpenSteamController-${PV}"

RUST_MIN_VER="1.88.0"

LICENSE="MIT"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD-2 BSD ISC MIT MPL-2.0
	UoI-NCSA Unicode-3.0 Unlicense WTFPL-2 ZLIB
"
SLOT="0"
KEYWORDS="~amd64"

RESTRICT="test"

DEPEND="
	dev-libs/hidapi
	dev-libs/libusb:1
	sys-apps/dbus
	virtual/libudev
"
RDEPEND="${DEPEND}"

QA_FLAGS_IGNORED="usr/bin/open-steam-controller"

pkg_setup() {
	linux-info_pkg_setup
	rust_pkg_setup
}

pkg_pretend() {
	local CONFIG_CHECK="~INPUT_UINPUT"
	[[ ${MERGE_TYPE} != buildonly ]] && check_extra_config
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
