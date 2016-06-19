#Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$
EAPI=6

DESCRIPTION="Vk CLI"
HOMEPAGE="https://github.com/HaCk3Dq/vk"
SRC_URI="https://github.com/HaCk3Dq/vk/releases/download/${PV}/${P}-x86_64-bin.7z"
LICENSE="Apache 2.0"
SLOT="0"
IUSE="mpv"
KEYWORDS="~amd64"
RESTRICT="mirror"
RDEPEND="sys-libs/ncurses net-misc/curl dev-libs/openssl mpv? ( media-video/mpv )"
S="${WORKDIR}"

src_install() {
	mv ${P}-x86_64 vk-cli
	dobin vk-cli
}
