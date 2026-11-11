# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Upstream publishes a self-contained .txz, not an AppImage. This package
# uses the AppImage that repacks those official binaries.
DESCRIPTION="Ebook management application"
HOMEPAGE="https://calibre-ebook.com/ https://github.com/ivan-hc/Calibre-appimage"
SRC_URI="https://github.com/ivan-hc/Calibre-appimage/releases/download/continuous-stable/Calibre-stable_${PV}-x86_64.AppImage"
S="${DISTDIR}"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"

QA_PREBUILT="*"

src_install() {
	newbin "Calibre-stable_${PV}-x86_64.AppImage" ${PN}
	dostrip -x "/usr/bin/${PN}"
}
