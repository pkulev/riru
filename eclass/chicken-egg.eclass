# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: chicken-egg.eclass
# @MAINTAINER:
# riru overlay
# @SUPPORTED_EAPIS: 8
# @BLURB: Build and install CHICKEN Scheme eggs into the image repository
# @DESCRIPTION:
# Fetches a versioned egg (via henrietta by default, or Call-CC SVN tags)
# and installs compiled artifacts under /usr/$(get_libdir)/chicken/<abi>.
#
# Egg "release" tags can change contents under the same version; neither
# henrietta nor SVN fetch adds DIST digests, so Manifest checks stay stable
# when upstream rewrites a tag.
#
# @EXAMPLE:
# @CODE
# EAPI=8
# inherit chicken-egg
# DESCRIPTION="SRFI-1 list library"
# LICENSE="BSD"
# SLOT="0"
# KEYWORDS="~amd64"
# @CODE
#
# For eggs whose Portage package name differs from the upstream egg name
# (e.g. srfi1 -> srfi-1), set CHICKEN_EGG before inherit or rely on the
# automatic srfiN -> srfi-N mapping.

case ${EAPI} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

# @ECLASS_VARIABLE: CHICKEN_EGG
# @DESCRIPTION:
# Upstream egg name as used by henrietta / the CHICKEN eggs tree. Defaults to
# PN, except PN matching srfiN becomes srfi-N.
if [[ -z ${CHICKEN_EGG} ]]; then
	case ${PN} in
		srfi[0-9]|srfi[0-9][0-9]|srfi[0-9][0-9][0-9])
			CHICKEN_EGG="srfi-${PN#srfi}"
			;;
		*)
			CHICKEN_EGG=${PN}
			;;
	esac
fi

# @ECLASS_VARIABLE: CHICKEN_EGG_ABI
# @DESCRIPTION:
# CHICKEN binary compatibility version (directory under lib/chicken/).
# Chicken 5.3/5.4 use ABI 11.
: "${CHICKEN_EGG_ABI:=11}"

# @ECLASS_VARIABLE: CHICKEN_EGG_FETCH
# @DESCRIPTION:
# How to obtain egg sources: "henrietta" (default; chicken-install HTTP
# retrieve) or "svn" (Call-CC eggs repo tags). Henrietta is preferred because
# the SVN endpoint is often slow/timeout-prone; neither approach adds DIST
# digests, so mutable egg tags will not break Manifest checks.
: "${CHICKEN_EGG_FETCH:=henrietta}"

# @ECLASS_VARIABLE: CHICKEN_EGG_SVN_URI
# @DESCRIPTION:
# Full SVN URI for the egg tag. Defaults to the official eggs repo tag path.
: "${CHICKEN_EGG_SVN_URI:=https://code.call-cc.org/svn/chicken-eggs/release/5/${CHICKEN_EGG}/tags/${PV}}"

# @ECLASS_VARIABLE: ESVN_USER
# @DESCRIPTION:
# SVN username for Call-CC eggs (anonymous).
: "${ESVN_USER:=anonymous}"

# @ECLASS_VARIABLE: ESVN_PASSWORD
# @DESCRIPTION:
# SVN password for Call-CC eggs (empty string).
: "${ESVN_PASSWORD:=}"

RDEPEND+=" >=dev-scheme/chicken-5.3.0"
DEPEND+=" ${RDEPEND}"
BDEPEND+=" >=dev-scheme/chicken-5.3.0"
[[ ${CHICKEN_EGG_FETCH} == svn ]] && BDEPEND+=" dev-vcs/subversion"

S="${WORKDIR}/${P}"

# @FUNCTION: chicken-egg_repository
# @DESCRIPTION:
# Return the Portage-managed chicken egg repository path (no EPREFIX).
chicken-egg_repository() {
	echo "/usr/$(get_libdir)/chicken/${CHICKEN_EGG_ABI}"
}

# @FUNCTION: chicken-egg_src_unpack
# @DESCRIPTION:
# Fetch egg sources via svn export or chicken-install -retrieve.
chicken-egg_src_unpack() {
	mkdir -p "${S}" || die

	case ${CHICKEN_EGG_FETCH} in
		svn)
			einfo "svn export ${CHICKEN_EGG_SVN_URI}"
			# Empty password with anonymous is required by Call-CC.
			svn export --force --non-interactive \
				--username "${ESVN_USER}" --password "${ESVN_PASSWORD}" \
				"${CHICKEN_EGG_SVN_URI}" "${S}" \
				|| die "svn export failed for ${CHICKEN_EGG_SVN_URI}"
			;;
		henrietta)
			local cache="${T}/egg-cache"
			mkdir -p "${cache}" || die
			unset CHICKEN_INSTALL_REPOSITORY CHICKEN_REPOSITORY_PATH || true
			export CHICKEN_EGG_CACHE="${cache}"
			einfo "chicken-install -r ${CHICKEN_EGG}:${PV}"
			chicken-install -r "${CHICKEN_EGG}:${PV}" \
				|| die "henrietta retrieve failed for ${CHICKEN_EGG}:${PV}"
			[[ -d ${cache}/${CHICKEN_EGG} ]] \
				|| die "egg cache missing ${cache}/${CHICKEN_EGG}"
			cp -a "${cache}/${CHICKEN_EGG}/." "${S}/" || die
			;;
		*)
			die "${ECLASS}: unknown CHICKEN_EGG_FETCH=${CHICKEN_EGG_FETCH}"
			;;
	esac
}

# @FUNCTION: chicken-egg_src_compile
# @DESCRIPTION:
# Build the egg without installing; Portage supplies egg dependencies.
chicken-egg_src_compile() {
	local repo
	repo="$(chicken-egg_repository)"

	# Avoid picking up a user-local egg repository.
	unset CHICKEN_INSTALL_REPOSITORY CHICKEN_REPOSITORY_PATH || true
	export CHICKEN_REPOSITORY_PATH="${EPREFIX}${repo}"

	chicken-install -n -no-install-dependencies || die
}

# @FUNCTION: chicken-egg_src_install
# @DESCRIPTION:
# Install the full egg into ${ED}'s chicken repository.
chicken-egg_src_install() {
	local repo
	repo="$(chicken-egg_repository)"
	dodir "${repo}"

	unset CHICKEN_INSTALL_REPOSITORY CHICKEN_REPOSITORY_PATH || true
	export CHICKEN_INSTALL_REPOSITORY="${ED}${repo}"
	export CHICKEN_REPOSITORY_PATH="${EPREFIX}${repo}:${ED}${repo}"

	chicken-install -no-install-dependencies || die
}

EXPORT_FUNCTIONS src_unpack src_compile src_install
