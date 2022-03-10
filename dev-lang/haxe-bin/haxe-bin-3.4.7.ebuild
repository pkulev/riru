# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="An open source toolkit based on a modern, strictly typed programming language"
HOMEPAGE="https://haxe.org/"

LICENSE="GPL-2+ MIT"
SLOT="4"
KEYWORDS="~amd64"

SRC_URI="https://github.com/HaxeFoundation/haxe/releases/download/${PV}/haxe-${PV}-linux64.tar.gz"

DEPEND="
	dev-libs/libpcre
	sys-libs/zlib
	dev-lang/neko[ssl]
"

# installsources doesn't work properly
RESTRICT="installsources"

S="${WORKDIR}/haxe_20180221160843_bb7b827"

src_install() {
	dobin haxe haxelib

	insinto /usr/share/haxe
	doins -r std
}
