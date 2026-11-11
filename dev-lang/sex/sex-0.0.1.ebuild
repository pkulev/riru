# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Sex: for passionate software developers"
HOMEPAGE="https://git.kotobank.ch/alex-eg/sex"
SRC_URI="https://git.kotobank.ch/alex-eg/${PN}/archive/${PV}.tar.gz -> ${P}.tar.gz"
# Gitea tag archives unpack to the repository name.
S="${WORKDIR}/${PN}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
RESTRICT="!test? ( test )"

# Eggs are linked into sexc (-static); they are not needed at runtime.
# Installed, sexc finds the standard library under ../share/sex.
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
BDEPEND="
	${DEPEND}
	test? ( dev-chicken/test )
"

sex_prepare_env() {
	# Drop a user Chicken venv so csc sees Portage eggs.
	unset CHICKEN_INSTALL_REPOSITORY CHICKEN_REPOSITORY_PATH \
		  CHICKEN_EGG_CACHE CHICKEN_INSTALL_PREFIX || true
}

src_compile() {
	sex_prepare_env
	emake
}

src_test() {
	sex_prepare_env
	emake check
}

src_install() {
	sex_prepare_env
	emake DESTDIR="${D}" prefix="${EPREFIX}/usr" install
	dodoc Readme.org
	docinto examples
	dodoc -r example || die
}
