# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

# TODO: use release instead of master

EAPI=5

DESCRIPTION="ASUS laptop tools (backlight, keyboard backight and etc.)"
HOMEPAGE="https://github.com/pkulev/laptasus.git"
SRC_URI="https://github.com/pkulev/${PN}/archive/master.zip -> ${P}.zip"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND=""
HDEPEND=""
RDEPEND="${HDEPEND}"

src_unpack() {
	default
	mv ${PN}-*/ ${P} || die
}
