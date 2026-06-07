# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the MIT license

EAPI=8

inherit meson

DESCRIPTION="OpenGL Snake game using SDL2"
HOMEPAGE="https://github.com/alex-eg/GLSnake"
SRC_URI="https://github.com/alex-eg/GLSnake/archive/refs/tags/v${PV}.tar.gz"
S="${WORKDIR}/GLSnake-${PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

RDEPEND="
	media-libs/libsdl2
	media-libs/sdl2-mixer
	media-libs/sdl2-ttf
	virtual/opengl
"
BDEPEND=">=dev-build/meson-1.2.3"

src_configure() {
	local emesonargs=(
		"-Dresource_dir=/usr/share/glsnake/resources/"
	)
	meson_src_configure
}

src_install() {
	exeinto /usr/bin
	newbin "${BUILD_DIR}/snake" glsnake

	insinto /usr/share/glsnake/resources
	doins -r "${S}"/resources/.
}
