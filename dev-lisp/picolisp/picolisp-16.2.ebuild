 # Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=6

DESCRIPTION="PicoLisp - programming language and database"
HOMEPAGE="http://picolisp.com/wiki/"
SRC_URI="http://software-lab.de/picoLisp-${PV}.tgz"

LICENSE="MIT X11"
SLOT="0"
KEYWORDS="~x86 ~amd64"

S=${WORKDIR}/picoLisp

src_compile() {
	if use x86; then
		SRC_PATH=${S}/src
	else if use amd64; then
		SRC_PATH=${S}/src64
	     fi
	fi
	cd ${SRC_PATH}
	emake || die "emake failed"
}

src_install() {
	chmod -x ${S}/bin/picolisp
	dobin ${S}/bin/picolisp
	dobin ${S}/bin/pil
	mkdir -p ${D}/usr/lib/
	cp -R ${S}/lib ${D}/usr/lib/picolisp
}
