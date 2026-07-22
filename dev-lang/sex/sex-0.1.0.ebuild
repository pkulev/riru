# Copyright 2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION="Sex is a S-expressions language."
HOMEPAGE="https://github.com/alex-eg/sex"
EGIT_REPO_URI="https://github.com/alex-eg/sex.git"

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE=""

BDEPEND=">=dev-scheme/chicken-5.4.0[static-libs]"
RDEPEND=""
DEPEND="${RDEPEND}"

src_configure() {
	emake deps || die
}
