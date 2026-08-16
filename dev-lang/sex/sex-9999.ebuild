# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="Sex: for passionate software developers"
HOMEPAGE="https://github.com/alex-eg/sex"
EGIT_REPO_URI="https://github.com/alex-eg/sex.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="test"
RESTRICT="!test? ( test )"

# Eggs needed at sexc build time and when expanding Sex macros.
COMMON_DEPEND="
	>=dev-scheme/chicken-5.4.0
	dev-chicken/brev-separate
	dev-chicken/fmt
	dev-chicken/getopt-long
	dev-chicken/matchable
	dev-chicken/srfi1
	dev-chicken/srfi13
	dev-chicken/srfi69
	dev-chicken/tree
"
DEPEND="${COMMON_DEPEND}"
RDEPEND="${COMMON_DEPEND}"
BDEPEND="
	${COMMON_DEPEND}
	test? ( dev-chicken/test )
"

src_compile() {
	unset CHICKEN_INSTALL_REPOSITORY || true
	local repo="/usr/$(get_libdir)/chicken/11"
	export CHICKEN_REPOSITORY_PATH="${EPREFIX}${repo}${CHICKEN_REPOSITORY_PATH:+:${CHICKEN_REPOSITORY_PATH}}"
	emake
}

src_test() {
	unset CHICKEN_INSTALL_REPOSITORY || true
	local repo="/usr/$(get_libdir)/chicken/11"
	export CHICKEN_REPOSITORY_PATH="${EPREFIX}${repo}${CHICKEN_REPOSITORY_PATH:+:${CHICKEN_REPOSITORY_PATH}}"
	emake sex-tests
	./sex-tests || die "sex-tests failed"
}

src_install() {
	dobin sexc
	dodoc Readme.org
	docinto examples
	dodoc -r example || die
}
