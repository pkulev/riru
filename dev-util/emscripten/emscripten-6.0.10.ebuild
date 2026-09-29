# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..15} )

inherit python-single-r1

DESCRIPTION="Compile C and C++ into WebAssembly"
HOMEPAGE="https://emscripten.org/"

# emsdk release tag -> emscripten-releases commit, from
# https://github.com/emscripten-core/emsdk/blob/main/emscripten-releases-tags.json
# This release expects LLVM 24. Gentoo has no such slot, and the 2017
# dev-util/emscripten ebuilds (fastcomp) cannot drive this toolchain.
RELEASES_HASH="666337b525e673e769121856d175f6f52b8ead64"
SRC_URI="https://storage.googleapis.com/webassembly/emscripten-releases-builds/linux/${RELEASES_HASH}/wasm-binaries.tar.xz -> ${P}-wasm-binaries.tar.xz"
S="${WORKDIR}/install"

# emscripten: MIT UoI-NCSA
# bundled LLVM/clang, libc++, compiler-rt: Apache-2.0-with-LLVM-exceptions
# bundled binaryen: Apache-2.0
# wasm sysroot musl: MIT
LICENSE="Apache-2.0 Apache-2.0-with-LLVM-exceptions MIT UoI-NCSA"
SLOT="0"
KEYWORDS="~amd64"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	>=net-libs/nodejs-18.3.0
	virtual/zlib:=
"

# Upstream release build: clang, lld, binaryen, and the prebuilt wasm sysroot.
QA_PREBUILT="*"

src_compile() {
	:
}

src_install() {
	local dest=/usr/$(get_libdir)/${PN}
	local tool

	# Private prefix. The bundled clang must not land on PATH ahead of the
	# system compiler; only the em* drivers are wrapped into /usr/bin.
	dodir "${dest}"
	cp -a . "${ED}${dest}/" || die
	rm -rf "${ED}${dest}/emscripten/test" || die

	# $CFGDIR is the directory containing this file. See tools/config.py.
	cat > "${ED}${dest}/emscripten/.emscripten" <<-EOF || die
		LLVM_ROOT = '\$CFGDIR/../bin'
		BINARYEN_ROOT = '\$CFGDIR/..'
		NODE_JS = '${EPREFIX}/usr/bin/node'
	EOF

	dostrip -x "${dest}"

	while read -r tool; do
		[[ -n ${tool} ]] || continue
		cat > "${T}/${tool}" <<-EOF || die
			#!/bin/sh
			export EMSDK_PYTHON="\${EMSDK_PYTHON:-${EPREFIX}/usr/bin/${EPYTHON}}"
			exec "${EPREFIX}${dest}/emscripten/${tool}" "\$@"
		EOF
		newbin "${T}/${tool}" "${tool}"
	done < <(find emscripten -maxdepth 1 -type f -perm /111 ! -name '*.py' ! -name '*.mjs' -printf '%f\n')
}

pkg_postinst() {
	elog "emcc uses the LLVM 24 toolchain shipped with this package."
	elog "It is installed under /usr/$(get_libdir)/${PN} and is not placed on PATH."
	elog "The prebuilt library cache is not user-writable. If a link fails because"
	elog "a system library is missing from that cache, point EM_CACHE at a writable directory."
}
