# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit chicken-egg

DESCRIPTION="SRFI-13 string library"
HOMEPAGE="https://wiki.call-cc.org/eggref/5/srfi-13"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="dev-chicken/srfi14"
DEPEND="${RDEPEND}"
BDEPEND="test? ( dev-chicken/test )"

src_test() {
	unset CHICKEN_INSTALL_REPOSITORY CHICKEN_REPOSITORY_PATH || true
	export CHICKEN_REPOSITORY_PATH="${EPREFIX}$(chicken-egg_repository)"
	chicken-install -test -n -no-install-dependencies || die
}
