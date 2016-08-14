# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=6

inherit git-r3

DESCRIPTION="Portage terminal user interface."
HOMEPAGE="https://github.com/TyanNN/portage-tui"
EGIT_REPO_URI="https://github.com/TyanNN/${PN}.git"
LICENSE="GPL-3"
SLOT="0"
RESTRICT="mirror"
RDEPEND="dev-python/pexpect
	dev-lang/python"
S="${WORKDIR}/${P}"

src_install(){
	dobin portage-tui
	dobin cats_parser.py
}
