# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="5"
#What and why
ETYPE="sources"
MERGE_TYPE="source"

DESCRIPTION="A kernel module for the ASIX USB 2.0 low power AX88772B/AX88772A/AX88760/AX88772/AX88178 ethernet controllers"
HOMEPAGE="http://www.asix.com.tw"
SRC_URI="http://www.github.com/pankshok/${PN}/archive/master.zip -> ${P}.zip"

#WORKDIR = "${PORTAGE_TMPDIR}/portage/${CATEGORY}/${PF}/work"

#WONTFIX:
S="${WORKDIR}/${P}"

# P		Package name and version (excluding revision, if any), for example vim-6.3.
# PN	Package name, for example vim.
# PV	Package version (excluding revision, if any), for example 6.3. It should reflect the upstream versioning scheme.
# PR	Package revision, or r0 if no revision exists.
# PVR	Package version and revision (if any), for example 6.3, 6.3-r1.
# PF	Full package name, ${PN}-${PVR}, for example vim-6.3-r1.
# A	All the source files for the package (excluding those which are not available because of USE flags).
# CATEGORY	Package's category, for example app-editors.
# FILESDIR	Path to the ebuild's files/ directory, commonly used for small patches and files. Value: "${PORTDIR}/${CATEGORY}/${PN}/files".
# WORKDIR	Path to the ebuild's root build directory. Value: "${PORTAGE_BUILDDIR}/work".
# T	Path to a temporary directory which may be used by the ebuild. Value: "${PORTAGE_BUILDDIR}/temp".
# D	Path to the temporary install directory. Value: "${PORTAGE_BUILDDIR}/image".
# ROOT	Path to the root directory. When not using ${D}, always prepend ${ROOT} to the path.
# DISTDIR	Contains the path to the directory where all the files fetched for the package are stored.

LICENSE="GPL"
SLOT="0"
KEYWORDS="~amd64 amd64"
IUSE=""

DEPEND=""
HDEPEND=">=sys-kernel/gentoo-sources-3.10.14"
RDEPEND="${HDEPEND}"

src_unpack() {
	if [[ ${PV} == 99999999* ]]; then
		eerror "I don't know that to do! HEELP!!!" && die
	else
		default
		# rename directory from git snapshot tarball
		mv ${PN}-*/ ${P} || die
	fi
}

pkg_postinst() {
	einfo "For more info about asix kernel driver see:"
	einfo "${HOMEPAGE}"
	einfo "If there are problems with installation, please contact me:"
	einfo "Pavel Kulyov <email: kulyov.pavel@gmail.com>"
	elog  "This is log message ZAZAZAZA"
	ewarn "This is warniing!"
	eerror " this is unbelievable shit!"
}

pkg_preinst() {
	einfo "${KERNEL_URI}ololo"
}

src_install() {
	emake DEST="${D}" TARGET="${WORKDIR}/${PN}" install
}

src_compile() {
	einfo "Started compile phase"

}


