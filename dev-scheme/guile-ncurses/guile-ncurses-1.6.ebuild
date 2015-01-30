# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-scheme/guile-gui/guile-gui-0.2.ebuild,v 1.7 2010/09/24 13:33:56 jlec Exp $

EAPI=4

DESCRIPTION="Guile Scheme ffi to ncurses library for text-based console UI"
HOMEPAGE="http://www.gnu.org/software/guile-ncurses/"
SRC_URI="http://mirror.tochlab.net/pub/gnu/guile-ncurses/${P}.tar.gz"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86 ~amd64-linux ~x86-linux"
RDEPEND="dev-scheme/guile
	 sys-libs/ncurses"
DEPEND="${RDEPEND}"

src_configure() {
        econf --with-guilesitedir="/usr/share/guile/site"
}

src_install() {
	make DESTDIR="${D}" install
	dodoc ${S}/README
}
