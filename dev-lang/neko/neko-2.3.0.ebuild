# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="The Neko Virtual Machine"
HOMEPAGE="https://nekovm.org"
SRC_URI="https://github.com/HaxeFoundation/${PN}/archive/v${PV//./-}.tar.gz"

LICENSE="MIT"
SLOT="2"
KEYWORDS="amd64 x86"

IUSE="+ssl +regexp apache mysql gtk sqlite debug"
DEPEND="
	dev-libs/boehm-gc
	sys-libs/zlib

	regexp? ( dev-libs/libpcre )
	ssl? (
			 dev-libs/openssl:0
			 net-libs/mbedtls
	)
	apache? ( www-servers/apache[ssl?] )
	mysql? (  dev-db/mysql-connector-c:=[ssl?] )
	gtk? ( x11-libs/gtk+:2 )
	sqlite? ( dev-db/sqlite )
"

RDEPEND="
	dev-libs/boehm-gc
	sys-libs/zlib
	regexp? ( dev-libs/libpcre )

	ssl? (
			 dev-libs/openssl
			 net-libs/mbedtls
	)
	mysql? (  dev-db/mysql-connector-c:=[ssl?] )
	gtk? ( x11-libs/gtk+:2 )
	sqlite? ( dev-db/sqlite )
"

inherit cmake-utils

S="${WORKDIR}/neko-${PV//./-}"

src_configure() {
	local mycmakeargs=(
		"-DWITH_REGEXP=$(usex regexp)"
		"-DWITH_UI=$(usex gtk)"
		"-DWITH_SSL=$(usex ssl)"
		"-DWITH_MYSQL=$(usex mysql)"
		"-DWITH_APACHE=$(usex apache)"
		"-DWITH_SQLITE=$(usex sqlite)"
		"-DNEKO_JIT_DEBUG=$(usex debug)"
		# Fails in a sandbox
		"-DRUN_LDCONFIG=no"
	)

	cmake-utils_src_configure
}
