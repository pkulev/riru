# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
ETYPE="sources"
printf "${PV}"
DESCRIPTION="A kernel module for the ASIX USB 2.0 low power AX88772B/AX88772A/AX88760/AX88772/AX88178 ethernet controllers"
HOMEPAGE="http://www.asix.com.tw"
SRC_URI="http://www.github.com/pankshok/asix/archive/master.zip -> ${PV}.zip"



LICENSE="GPL"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND=">=sys-kernel/gentoo-sources-3.10.14"
DEPEND="${RDEPEND}"

pkg_postinst() {
	einfo "For more info about asix kernel driver see:"
	einfo "$HOMEPAGE}"
	einfo "If there is problems with installation, please contact me"
	einfo "Pavel Kulyov <email: kulyov.pavel@gmail.com>"
}

pkg_preinst() {
	einfo "${KERNEL_URI}"
}
