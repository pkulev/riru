# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg-utils

# Build, I guess.
BV="17892"

DESCRIPTION="Client for the Synology Drive Server for syncing and sharing files."
HOMEPAGE="https://kb.synology.com/en-global/DSM/help/SynologyDriveClient/synologydriveclient?version=7"
SRC_URI="https://global.synologydownload.com/download/Utility/SynologyDriveClient/${PV}-${BV}/Ubuntu/Installer/synology-drive-client-${BV}.x86_64.deb"
S="${WORKDIR}"

LICENSE="Synology"
SLOT="0"
KEYWORDS="~amd64"
IUSE="nautilus"

RESTRICT="bindist mirror strip"
QA_PREBUILT="*"

RDEPEND="nautilus? ( gnome-base/nautilus )"

src_unpack() {
	default
	unpack "${WORKDIR}"/data.tar.xz

	# Provided docs are useless.
	rm -r usr/share/doc || die
}

src_install() {
	if ! use nautilus; then
		rm -f  opt/Synology/SynologyDrive/package/cloudstation/icon-overlay/15/lib/plugin-cb{,-4}.so || die
	fi
	# XXX: I can't find libQt5Pdf.so, really where can it be?
	rm -f opt/Synology/SynologyDrive/package/cloudstation/lib/plugins/imageformats/libqpdf.so || die
	# NOTE: probably old library, there's extensions-4.
	rm -rf usr/lib/nautilus/extensions-3.0 || die

	insinto /
	doins -r opt/
	doins -r usr/

	# Fix permissions
	chmod +x "${ED}"/usr/bin/* || die
	chmod +x "${ED}"/opt/Synology/SynologyDrive/bin/* || die

	domenu usr/share/applications/"${PN}".desktop
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_icon_cache_update
}
