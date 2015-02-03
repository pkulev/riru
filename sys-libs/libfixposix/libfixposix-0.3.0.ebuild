# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit autotools;

DESCRIPTION="Thin wrapper over POSIX syscalls"
HOMEPAGE="https://github.com/sionescu/libfixposix"
SRC_URI="https://github.com/sionescu/libfixposix/archive/v${PV}.tar.gz -> libfixposix-${PV}.tar.gz"

LICENSE="As is"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

DEPEND="sys-libs/glibc"
RDEPEND="${DEPEND}"

src_prepare() {
	eautoreconf;
}