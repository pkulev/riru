# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Guile Scheme ffi to ncurses library for text-based console UI"
HOMEPAGE="https://www.gnu.org/software/guile-ncurses/"
SRC_URI="https://mirror.tochlab.net/pub/gnu/guile-ncurses/${P}.tar.gz"
LICENSE="GPL-2"

SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-scheme/guile
	sys-libs/ncurses
"
DEPEND="${RDEPEND}"

src_configure() {
	econf --with-guilesitedir="/usr/share/guile/site"
}

src_install() {
	make DESTDIR="${D}" install
	dodoc README
}
