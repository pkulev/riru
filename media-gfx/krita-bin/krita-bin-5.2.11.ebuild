# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Free digital painting application. Digital Painting, Creative Freedom!"
HOMEPAGE="https://www.kde.org/applications/graphics/krita/ https://krita.org/"
SRC_URI="http://download.kde.org/stable/krita/${PV}/krita-${PV}-x86_64.AppImage"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

S="${DISTDIR}"

src_install() {
	newbin krita-${PV}-x86_64.AppImage ${PN}
	dostrip -x /usr/bin/krita-bin ${PN}
}
