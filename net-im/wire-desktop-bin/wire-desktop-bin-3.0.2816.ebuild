# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

MY_PN="${PN/-desktop-bin/}"

inherit pax-utils
DESCRIPTION="Wire for desktop"
HOMEPAGE="https://wire.com https://github.com/wireapp/wire-desktop"
SRC_URI="https://github.com/wireapp/wire-desktop/releases/download/release/${PV}/${MY_PN}-${PV}-x86_64.AppImage"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RESTRICT="bindist mirror"

RDEPEND="gnome-base/gconf:2
         dev-libs/nss
         x11-libs/libXtst
         net-print/cups"

QA_PREBUILT="opt/Wire/wire-desktop"

S="${WORKDIR}"

src_install() {
	exeinto /opt/Wire
	newexe "${DISTDIR}/${MY_PN}-${PV}-x86_64.AppImage" wire-desktop

	fperms +x "/opt/Wire/wire-desktop"

	dosym /opt/Wire/wire-desktop /usr/bin/wire-desktop
}
