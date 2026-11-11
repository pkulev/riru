# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Flexible tile map editor"
HOMEPAGE="https://www.mapeditor.org/ https://github.com/mapeditor/tiled"
SRC_URI="https://github.com/mapeditor/tiled/releases/download/v${PV}/Tiled-${PV}_Linux_x86_64.AppImage"
S="${DISTDIR}"

# Tiled itself is GPL-2. Bundled libtiled is BSD-2; qtpropertybrowser is BSD.
LICENSE="GPL-2 BSD BSD-2"
SLOT="0"
KEYWORDS="~amd64"

QA_PREBUILT="*"

src_install() {
	newbin "Tiled-${PV}_Linux_x86_64.AppImage" ${PN}
	dostrip -x "/usr/bin/${PN}"
}
