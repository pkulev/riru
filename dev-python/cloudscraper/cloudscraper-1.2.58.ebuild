EAPI=7

PYTHON_COMPAT=( python3_{6..9} )

inherit distutils-r1
DESCRIPTION="A Python module to bypass Cloudflare's anti-bot page."
HOMEPAGE="https://github.com/VeNoMouS/${PN}"
SRC_URI="https://github.com/VeNoMouS/${PN}/archive/${PV}.tar.gz"

LICENSE="AGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

IUSE=""
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="${PYTHON_DEPS}"
RDEPEND="${PYTHON_DEPS} $(python_gen_cond_dep '
		dev-python/requests[${PYTHON_USEDEP}]
		dev-python/requests-toolbelt[${PYTHON_USEDEP}]
		dev-python/pyparsing[${PYTHON_USEDEP}]
')"
