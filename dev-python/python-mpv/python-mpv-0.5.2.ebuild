EAPI=7

PYTHON_COMPAT=( python3_{6..9} )

inherit distutils-r1
DESCRIPTION="A ctypes-based python interface to the mpv media player"
HOMEPAGE="https://github.com/jaseg/${PN}"
SRC_URI="https://github.com/jaseg/${PN}/archive/v${PV}.tar.gz"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="${PYTHON_DEPS}"
RDEPEND="${PYTHON_DEPS}"
