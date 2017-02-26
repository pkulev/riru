# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

PYTHON_COMPAT=( python{2_6,2_7} )

inherit git-2 cmake-utils python-single-r1

EGIT_REPO_URI="https://github.com/jaagr/polybar"
EGIT_HAS_SUBMODULES=1


DESCRIPTION="A fast and easy-to-use tool for creating status bars."
HOMEPAGE="https://github.com/jaagr/polybar"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~x86 ~amd64"

DEPEND="x11-libs/cairo
x11-proto/xcb-proto
x11-libs/xcb-util-image
x11-libs/xcb-util-wm
x11-libs/xcb-util-xrm
dev-libs/jsoncpp
media-libs/alsa-lib
${PYTHON_DEPS}
"
RDEPEND="${DEPEND}"

src_configure() {
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install
}
