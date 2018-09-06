# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

DESCRIPTION="An open source toolkit based on a modern, strictly typed programming language"
HOMEPAGE="https://haxe.org/"

LICENSE="GPL-2+ MIT"
SLOT="3"
KEYWORDS="~amd64 ~x86"

EGIT_REPO_URI="https://github.com/HaxeFoundation/${PN}.git"
EGIT_COMMIT="${PV}"

PYTHON_COMPAT=( python3_{4,5,6,7} )

# Can only be build withing a git tree, otherwise it bails out
inherit eutils git-r3 python-any-r1

IUSE="+ocamlopt -test test"
REQUIRED_USE="test? ( ${PYTHON_REQUIRED_USE} )"

DEPEND="
	dev-libs/libpcre
	sys-libs/zlib
	dev-lang/neko[regexp,ssl]

	>=dev-lang/ocaml-4.02[ocamlopt?]
	dev-ml/opam

	test? (
		  net-libs/nodejs
		  dev-lang/mono
		  virtual/jdk
		  ${PYTHON_USEDEP}
	)
"
RDEPEND="
	sys-libs/zlib
	dev-libs/libpcre
"

# installsources doesn't work properly
RESTRICT="installsources"

src_prepare() {
	epatch "${FILESDIR}/remove-dep-installers.patch"

	eapply_user
}

src_compile() {
	if use ocamlopt; then
		export OCAMLOPT=ocamlopt.opt
	fi

	# Breaks if there are more than one job, just silently bails out
	emake -j1
}

src_test() {
	pushd "${S}/tests"

	export HAXE_STD_PATH="${S}/std"
	"${S}/haxe" RunCi.hxml || die

	"${S}/haxelib" setup "${S}/tests/test_repo"

	# cxx seems to require stubs-32.h which i cannot find
	# lua requires luarocks and tries to install dependencies via it
	# python tests just silently fail
	# php tests are too old for our version of php
	export TEST="macro,neko,js,java,cs python"
	neko RunCi.n || die

	popd
}
