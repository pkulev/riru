# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Scheme interpreter and native Scheme to C compiler"
HOMEPAGE="https://www.call-cc.org/"
SRC_URI="https://code.call-cc.org/releases/${PV}/${P}.tar.gz"

LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="doc static-libs"

chicken_emake() {
	# -j1: the generated rules are not safe for parallel make.
	emake -j1 \
		PLATFORM="linux" \
		PREFIX="${EPREFIX}/usr" \
		C_COMPILER="$(tc-getCC)" \
		C_COMPILER_OPTIMIZATION_OPTIONS="${CFLAGS}" \
		CXX_COMPILER="$(tc-getCXX)" \
		LINKER="$(tc-getCC)" \
		HOSTSYSTEM="${CBUILD}" \
		LINKER_OPTIONS="${LDFLAGS}" \
		"$@"
}

src_prepare() {
	default

	# because chicken's upstream is in the habit of using variables that
	# portage also uses :( eg. $ARCH and $A
	sed -i \
		-e "s/A\([[:space:]]*?=\|)\)/z&/" \
		-e "s/ARCH/z&/" \
		-e "/LICENSE /d" \
		Makefile.* {defaults,rules}.make || die

	sed -i \
		-e "s|/lib|/$(get_libdir)|" \
		-e "s|\$(DATADIR)/doc|\$(SHAREDIR)/doc/${PF}|" \
		defaults.make || die

	sed -i \
		-e "/\$(CHICKEN_DO_PROGRAM)\$(EXE):/,/^$/s/\(\$<\)/\$(LINKER_OPTIONS) \1/" \
		rules.make || die

	use doc || sed -i "/\$(SEP)manual/d" rules.make || die
}

src_configure() {
	# Hand-written configure script, not autotools. It rejects GNU
	# options that econf would pass (--build, --libdir, ...).
	local confargs=(
		--prefix="${EPREFIX}/usr"
		--platform=linux
		--c-compiler="$(tc-getCC)"
		--linker="$(tc-getCC)"
	)
	tc-is-cross-compiler && confargs+=( --host="${CHOST}" )

	CC="$(tc-getCC)" CFLAGS="${CFLAGS}" ./configure "${confargs[@]}" || die
}

src_compile() {
	chicken_emake
}

src_test() {
	chicken_emake check
}

src_install() {
	chicken_emake DESTDIR="${D}" install
	einstalldocs
	use static-libs || find "${ED}" -name '*.a' -delete || die

	# let portage track this file (created later)
	# CHICKEN 6 uses binary compatibility version 12 (CHICKEN 5 used 11).
	touch "${ED}"/usr/$(get_libdir)/${PN}/12/modules.db || die
}

pkg_postinst() {
	# create modules.db file in ${ROOT}
	chicken-install -update-db || die
}
