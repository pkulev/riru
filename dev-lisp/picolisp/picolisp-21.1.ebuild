# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit llvm

DESCRIPTION="PicoLisp - programming language and database"
HOMEPAGE="http://picolisp.com/wiki/"
SRC_URI="http://software-lab.de/picoLisp-${PV}.tgz"

LICENSE="MIT X11"
SLOT="0"
KEYWORDS="~x86 ~amd64"

BDEPEND=">=sys-devel/clang-3.5
"

DEPEND="${LLVM_DEPEND}
"

S=${WORKDIR}/pil21

src_compile() {
	cd "${S}/src"
	emake || die "emake failed"
}

src_install() {
	chmod -x ${S}/bin/picolisp
	dobin ${S}/bin/picolisp
	dobin ${S}/bin/pil
	mkdir -p ${D}/usr/lib/
	cp -R ${S}/lib ${D}/usr/lib/picolisp
}
