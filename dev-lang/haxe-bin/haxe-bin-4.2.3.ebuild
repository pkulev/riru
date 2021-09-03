# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="An open source toolkit based on a modern, strictly typed programming language"
HOMEPAGE="https://haxe.org/"

LICENSE="GPL-2+ MIT"
SLOT="4"
KEYWORDS="~amd64"

SRC_URI="https://github.com/HaxeFoundation/haxe/releases/download/${PV}/haxe-${PV}-linux64.tar.gz"

IUSE="test"
REQUIRED_USE="test? ( ${PYTHON_REQUIRED_USE} )"

DEPEND="
	dev-libs/libpcre
	sys-libs/zlib
	dev-lang/neko[regexp,ssl]

	test? (
		  net-libs/nodejs
		  ${PYTHON_USEDEP}
	)
"
RDEPEND="
	sys-libs/zlib
	dev-libs/libpcre
"

# installsources doesn't work properly
RESTRICT="installsources"

S="${WORKDIR}/haxe_20210701100239_1385eda"

src_install() {
	dobin haxe haxelib

	insinto /usr/share/haxe
	doins -r std
}