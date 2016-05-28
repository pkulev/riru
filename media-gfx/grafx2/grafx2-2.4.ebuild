# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

DESCRIPTION="A pixelart-oriented painting program"
HOMEPAGE="http://pulkomandy.tk/projects/GrafX2/downloads"
SRC_URI="http://pulkomandy.tk/projects/GrafX2/downloads/21 -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="ttf lua"

DEPEND="media-libs/libsdl
	media-libs/sdl-image
	media-libs/freetype
	media-libs/libpng
	ttf? ( media-libs/sdl-ttf )
	lua? ( >=dev-lang/lua-5.1.0 )"
RDEPEND=""

S=${WORKDIR}/${PN}

src_prepare() {
	sed -i s/lua5\.1/lua/g src/Makefile
        eapply_user
}

src_compile() {
	use ttf || MYCNF="NOTTF=1"
	use lua || MYCNF="${MYCNF} NOLUA=1"
	cd ${WORKDIR}/${PN}/src/
	emake ${MYCNF} || die "emake failed"
}

src_install() {
	cd ${WORKDIR}/${PN}/src/
	emake DESTDIR="${D}" PREFIX="/usr" install || die "Install failed"
}

pkg_postinst() {
	elog "Please report bugs upstream:"
	elog "http://pulkomandy.tk/projects/GrafX2/query"
}
