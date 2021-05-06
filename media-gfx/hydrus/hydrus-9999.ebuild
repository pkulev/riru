# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

PYTHON_COMPAT=( python3_{3..9} )

inherit git-r3 eutils python-single-r1 desktop

DESCRIPTION="*booru style image collector and viewer"
HOMEPAGE="http://hydrusnetwork.github.io/hydrus/ https://github.com/hydrusnetwork/hydrus"
EGIT_REPO_URI="https://github.com/hydrusnetwork/hydrus.git"
IUSE="+mpv +ffmpeg miniupnpc +lz4 socks matplotlib +cloudscraper test"

LICENSE="WTFPL"
SLOT="0"
KEYWORDS=""

RESTRICT="!test? ( test )"

RDEPEND="$(python_gen_cond_dep '
	dev-python/beautifulsoup:4[${PYTHON_MULTI_USEDEP}]
	dev-python/chardet[${PYTHON_MULTI_USEDEP}]
	cloudscraper? ( dev-python/cloudscraper[${PYTHON_MULTI_USEDEP}] )
	dev-python/html5lib[${PYTHON_MULTI_USEDEP}]
	dev-python/lxml[${PYTHON_MULTI_USEDEP}]
	lz4? ( dev-python/lz4[${PYTHON_MULTI_USEDEP}] )
	dev-python/nose[${PYTHON_MULTI_USEDEP}]
	dev-python/numpy[${PYTHON_MULTI_USEDEP}]
	media-libs/opencv[python,${PYTHON_MULTI_USEDEP}]
	dev-python/pillow[${PYTHON_MULTI_USEDEP}]
	dev-python/psutil[${PYTHON_MULTI_USEDEP}]
	dev-python/pyopenssl[${PYTHON_MULTI_USEDEP}]
	socks? (
			|| ( dev-python/requests[socks5,${PYTHON_MULTI_USEDEP}]
				dev-python/PySocks[${PYTHON_MULTI_USEDEP}] )
	)
	mpv? (
		 media-video/mpv[libmpv,${PYTHON_MULTI_USEDEP}]
		 dev-python/python-mpv[${PYTHON_MULTI_USEDEP}]
	)
	dev-python/pyyaml[${PYTHON_MULTI_USEDEP}]
	dev-python/QtPy[${PYTHON_MULTI_USEDEP}]
	dev-python/requests[${PYTHON_MULTI_USEDEP}]
	dev-python/send2trash[${PYTHON_MULTI_USEDEP}]
	dev-python/service_identity[${PYTHON_MULTI_USEDEP}]
	dev-python/six[${PYTHON_MULTI_USEDEP}]
	dev-python/twisted[${PYTHON_MULTI_USEDEP}]

	ffmpeg? ( media-video/ffmpeg )
	miniupnpc? ( net-libs/miniupnpc )
	')
	${PYTHON_DEPS}"

DEPEND="${RDEPEND}
	$(python_gen_cond_dep '
	test? (
		dev-python/mock[${PYTHON_MULTI_USEDEP}]
		dev-python/httmock[${PYTHON_MULTI_USEDEP}]
		dev-python/unittest2[${PYTHON_MULTI_USEDEP}]
	)
	')
"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

src_prepare() {
	eapply "${FILESDIR}/userpath-in-local-share.patch"

	eapply_user

	if ! use test; then
		rm hydrus/hydrus_test.py
		rm -r hydrus/test/
		rm -r static/testing/
	fi

	# Contains pre-built binaries for other systems and a broken swf renderer for linux
	rm -r bin/
	# Build files used for CI, not actually needed
	rm -r static/build_files
	# Duplicate license file, not needed
	rm license.txt
	# Python requirements file, not needed
	rm requirements.txt
}

src_compile() {
	python_optimize "${S}"
}

src_test() {
	# The tests user unittest, but are run with a custom runner script.
	# QT_QPA_PLATFORM is required to make them run without X
	export QT_QPA_PLATFORM=offscreen
	"${PYTHON}" "${S}/test.py" || die "Tests failed"
}

src_install() {
	DOC="/usr/share/doc/${PF}"
	elog "Hydrus includes an excellent manual, that can either be viewed at"
	elog "${DOC}/html/help/index.html"
	elog "or accessed through the hydrus help menu."

	mv "help my client will not boot.txt" "help_my_client_will_not_boot.txt"

	DOCS="COPYING README.md Readme.txt help_my_client_will_not_boot.txt db/"
	HTML_DOCS="${S}/help/"
	einstalldocs

	# These files are copied into DOC
	rm COPYING README.md Readme.txt help_my_client_will_not_boot.txt
	rm -r help/ db/
	# The program expects to find documentation here, so add a symlink to DOC
	ln -s "${DOC}/html/help" help

	insopts -m0755
	insinto /opt/${PN}
	doins -r "${S}"/* || die "Failed to move hydrus to opt."

	exeinto /usr/bin
	doexe "${FILESDIR}/hydrus-server"
	doexe "${FILESDIR}/hydrus-client"

	domenu "${FILESDIR}/hydrus.desktop"
}
