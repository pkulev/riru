# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_P="BambuStudio_ubuntu24.04-v02.07.01.62-20260616195227"
MY_TAG="v02.07.01.62"

DESCRIPTION="Bambu Lab slicer for 3D printers"
HOMEPAGE="https://bambulab.com/en/download/studio https://github.com/bambulab/BambuStudio"
SRC_URI="https://github.com/bambulab/BambuStudio/releases/download/${MY_TAG}/${MY_P}.AppImage"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND="
	media-libs/mesa
	media-libs/gst-plugins-base
	media-libs/gstreamer
	net-libs/webkit-gtk:4.1
	x11-libs/gtk+:3
"

S="${DISTDIR}"

src_install() {
	install -d "${ED}/opt/${PN}"
	install -m 755 "${DISTDIR}/${MY_P}.AppImage" "${ED}/opt/${PN}/${PN}.AppImage"

	exeinto /usr/bin
	newexe "${FILESDIR}/${PN}" bambu-studio

	dostrip -x opt/${PN}/${PN}.AppImage
}
