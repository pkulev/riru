# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="Sex: for passionate software developers"
HOMEPAGE="https://git.kotobank.ch/alex-eg/sex"
EGIT_REPO_URI="https://git.kotobank.ch/alex-eg/sex.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="test"
RESTRICT="!test? ( test )"

# Eggs are linked into sexc (-static); they are not needed at runtime.
DEPEND="
	>=dev-scheme/chicken-6.0.0[static-libs]
	dev-chicken/brev-separate
	dev-chicken/fmt
	dev-chicken/getopt-long
	dev-chicken/matchable
	dev-chicken/srfi1
	dev-chicken/srfi13
	dev-chicken/srfi69
"
RDEPEND=""
BDEPEND="
	${DEPEND}
	test? ( dev-chicken/test )
"

src_compile() {
	# Drop a user Chicken venv so csc sees Portage eggs.
	unset CHICKEN_INSTALL_REPOSITORY CHICKEN_REPOSITORY_PATH \
		  CHICKEN_EGG_CACHE CHICKEN_INSTALL_PREFIX || true
	emake
}

src_test() {
	unset CHICKEN_INSTALL_REPOSITORY CHICKEN_REPOSITORY_PATH \
		  CHICKEN_EGG_CACHE CHICKEN_INSTALL_PREFIX || true
	emake check
}

src_install() {
	dobin sexc
	dodoc Readme.org
	docinto examples
	dodoc -r example || die
}
