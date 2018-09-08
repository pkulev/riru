# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

CRATES="
ansi_term-0.11.0
atty-0.2.10
bitflags-1.0.3
cfg-if-0.1.3
dtoa-0.4.2
clap-2.31.2
cloudabi-0.0.3
fuchsia-zircon-0.3.3
fuchsia-zircon-sys-0.3.3
log-0.4.1
libc-0.2.41
proc-macro2-0.4.4
rand-0.5.5
rand_core-0.2.1
redox_syscall-0.1.40
redox_termios-0.1.1
remove_dir_all-0.5.1
serde-1.0.64
serde_derive-1.0.21
serde_derive_internals-0.17.0
serde_json-1.0.19
strsim-0.7.0
syn-0.11.11
syn-0.14.1
synom-0.11.3
vec_map-0.8.1
tempfile-3.0.3
termion-1.5.1
textwrap-0.9.0
toml-0.4.6
itoa-0.4.1
quote-0.3.15
quote-0.6.3
unicode-width-0.1.5
unicode-xid-0.0.4
unicode-xid-0.1.0
winapi-0.3.4
winapi-i686-pc-windows-gnu-0.4.0
winapi-x86_64-pc-windows-gnu-0.4.0
"

inherit cargo

DESCRIPTION="Mozilla cbindgen"
HOMEPAGE=""
SRC_URI="https://github.com/eqrion/${PN}/archive/v${PV}.tar.gz $(cargo_crate_uris ${CRATES})"

RESTRICT="mirror"
LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS="~amd64 ~x86"
DEPEND=">=virtual/rust-1.28"
RDEPEND="${DEPEND}"
