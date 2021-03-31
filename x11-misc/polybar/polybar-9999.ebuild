# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{6..9} )

inherit git-r3 cmake-utils python-single-r1

EGIT_REPO_URI="https://github.com/polybar/polybar"

DESCRIPTION="A fast and easy-to-use tool for creating status bars"
HOMEPAGE="https://github.com/polybar/polybar"

KEYWORDS="~amd64 ~x86"
LICENSE="MIT"
SLOT="0"

IUSE="alsa curl i3wm ipc mpd network pulseaudio doc"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="
	${PYTHON_DEPS}
	x11-base/xcb-proto
	x11-libs/cairo[X,xcb(+)]
	x11-libs/libxcb[xkb]
	x11-libs/xcb-util-image
	x11-libs/xcb-util-wm
	x11-libs/xcb-util-xrm
	alsa? ( media-libs/alsa-lib )
	curl? ( net-misc/curl )
	i3wm? (
		dev-libs/jsoncpp
		|| ( x11-wm/i3 x11-wm/i3-gaps )
	)
	mpd? ( media-libs/libmpdclient )
	network? ( net-wireless/wireless-tools )
	pulseaudio? ( media-sound/pulseaudio )
	doc? ( dev-python/sphinx )
"

RDEPEND="${DEPEND}"

src_configure() {
	local mycmakeargs=(
		-DENABLE_ALSA="$(usex alsa)"
		-DENABLE_CURL="$(usex curl)"
		-DENABLE_I3="$(usex i3wm)"
		-DBUILD_IPC_MSG="$(usex ipc)"
		-DENABLE_MPD="$(usex mpd)"
		-DENABLE_NETWORK="$(usex network)"
		-DENABLE_PULSEAUDIO="$(usex pulseaudio)"
		-DBUILD_DOC="$(usex doc)"
	)

	cmake-utils_src_configure
}
