# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"

inherit eutils linux-mod

DESCRIPTION="A kernel module for the ASIX USB 2.0 low power AX88772B/AX88772A/AX88760/AX88772/AX88178 ethernet controllers"
HOMEPAGE="http://www.asix.com.tw"
SRC_URI="http://www.github.com/pankshok/${PN}/archive/master.zip -> ${P}.zip"

LICENSE="GPL"
SLOT="0"
KEYWORDS="~amd64 amd64"
IUSE=""

DEPEND=""
HDEPEND=">=sys-kernel/gentoo-sources-3.10.14"
RDEPEND="${HDEPEND}"

src_unpack() {
	default
	# rename directory from git snapshot tarball
	mv ${PN}-*/ ${P} || die
}

src_prepare() {
	#patch to get rid of wierd Xauthority error
	epatch ${FILESDIR}/${P}-makefile.patch
	#patch to make new gcc happy
	epatch ${FILESDIR}/${P}-timedatemacro.patch
}

src_configure() {
	# to fix No rule to make target '/usr/src/linux-3.14.29-gentoo/arch/amd64/Makefile' error
	unset ARCH
}

src_compile() {
	# to supress QA notice
	MAKEOPTS=-j1
	emake
}

src_install() {
	MODULE_NAMES="asix(kernel/drivers/net/usb)"
	linux-mod_src_install
}

pkg_setup() {
	linux-mod_pkg_setup
}

pkg_postinst() {
	linux-mod_pkg_postinst
	einfo "For more info about asix kernel driver see:"
	einfo "${HOMEPAGE}"
	einfo "If there are problems with installation, please contact me:"
	einfo "Pavel Kulyov <email: kulyov.pavel@gmail.com>"
}

