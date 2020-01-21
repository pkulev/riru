# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit qmake-utils xdg-utils

DESCRIPTION="Powerful yet simple to use screenshot software"
HOMEPAGE="https://flameshot.js.org/"
SRC_URI="https://github.com/lupoDharkael/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="+dbus"

FS_LINGUAS="
	ca es fr hu ka pl ru tr zh_CN zh_TW
"

for lingua in ${FS_LINGUAS}; do
	IUSE="${IUSE} l10n_${lingua/_/-}"
done

RDEPEND="
	dev-qt/qtcore:5
	dev-qt/qtgui:5
	dev-qt/qtwidgets:5
	dev-qt/qtnetwork:5
	dev-qt/qtsvg:5
	dbus? (
		dev-qt/qtdbus:5
		sys-apps/dbus
	)
"

BDEPEND="
	${RDEPEND}
	dev-qt/linguist-tools
"

src_prepare() {
	default

	# QA check in case linguas are added or removed
	enum() {
		echo ${#}
	}

	[[ $(enum ${FS_LINGUAS}) -eq $(enum $(echo translations/*.ts)) ]] \
		|| die "Numbers of recorded and actual linguas do not match"
	unset enum

	# Remove localisations
	local lingua
	for lingua in ${FS_LINGUAS}; do
		if ! use l10n_${lingua/_/-}; then
			sed -i ${PN}.pro -e "/\.*Internationalization_${lingua}\.ts.*/d" || die
			rm translations/Internationalization_${lingua}.ts || die
		fi
	done
	append-cflags -DNOSTATIC
	append-cxxflags -DNOSTATIC
}

src_configure() {
	local lrelease="$(qt_get_bindir)/lrelease"
	lrelease ${PN}.pro || die

	eqmake5 PREFIX="/usr" || die
}

src_install() {
	dobin "${PN}"
	domenu "${PN}.desktop"

	emake INSTALL_ROOT="${D}" install
}

pkg_postinst() {
	xdg_icon_cache_update
}

pkg_postrm() {
	xdg_icon_cache_update
}
