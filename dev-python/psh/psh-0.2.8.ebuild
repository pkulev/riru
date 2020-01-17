# Copyright 1999-2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

PYTHON_COMPAT=( python3_{6,7,8} )

inherit distutils-r1

DESCRIPTION="Process management library"
HOMEPAGE="http://konishchevdmitry.github.com/psh/"
SRC_URI="https://github.com/KonishchevDmitry/${PN}/archive/${PV}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE="doc test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="
	${PYTHON_DEPS}
	doc? (
		dev-python/sphinx[${PYTHON_USEDEP}]
	)
	test? (
		dev-python/pytest[${PYTHON_USEDEP}]
	)"

RDEPEND="
	${PYTHON_DEPS}
	dev-python/psys[${PYTHON_USEDEP}]
	dev-python/pcore[${PYTHON_USEDEP}]"

python_install_all() {
	distutils-r1_python_install_all

	if use doc; then
		docinto html
		dodoc -r docs/*
	fi
}

python_test() {
	echo "lol"
}
