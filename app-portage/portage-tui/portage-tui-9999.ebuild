# Distributed under the terms of the GNU General Public License v2
EAPI=5
DESCRIPTION="Portage terminal user interface"
SLOT="0"
LICENSE="GPL-3"
KEYWORDS="~amd64 ~arm ~x86"
S="${WORKDIR}/portage-tui-master"
RDEPEND="dev-python/pexpect dev-lang/python"
EGIT_REPO_URI="https://github.com/TyanNN/portage-tui.git"
RESTRICT="mirror"

inherit "git-2"

src_install(){
    dobin portage-tui
    dobin cats_parser.py
}
