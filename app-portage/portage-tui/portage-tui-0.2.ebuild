# Distributed under the terms of the GNU General Public License v2
EAPI=5
DESCRIPTION="Portage terminal user interface"
SLOT="0"
SRC_URI="https://github.com/TyanNN/portage-tui/archive/0.2.tar.gz"
LICENSE="GPL v3"
KEYWORDS="~amd64 ~arm ~x86"
S="${WORKDIR}"
RDEPEND="dev-python/pexpect dev-lang/python"

src_install(){
    dobin portage-tui
    dobin cats_parser.py
}
