# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit chicken-egg

DESCRIPTION="SRFI-13 string library"
HOMEPAGE="https://wiki.call-cc.org/eggref/6/srfi-13"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	dev-chicken/srfi14
"
DEPEND="${RDEPEND}"
