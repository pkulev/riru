# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

ESVN_REPO_URI="https://code.call-cc.org/svn/chicken-eggs/release/5/srfi-13/tags/${PV}"
ESVN_USER="anonymous"
ESVN_PASSWORD=""
inherit subversion

DESCRIPTION="SRFI-13 string library."
HOMEPAGE="https://wiki.call-cc.org/eggref/5/srfi-13"
S="${WORKDIR}/${PV}"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~x86 ~amd64 ~arm64"
IUSE="test"

RDEPEND=">=dev-scheme/chicken-5.3.0
	dev-chicken/srfi14
"
DEPEND="${RDEPEND}"
BDEPEND=">=dev-scheme/chicken-5.3.0
	test? ( dev-chicken/test )
"

src_compile() {
	chicken-install -v -no-install -no-install-dependencies || die
}

src_install() {
	CHICKEN_D=$(chicken-install -repository)
	insinto ${CHICKEN_D}
	doins *.so
}
