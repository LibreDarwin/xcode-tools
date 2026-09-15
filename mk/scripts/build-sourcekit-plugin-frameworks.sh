#!/bin/sh
#
# Build SwiftSourceKitPlugin.framework and SwiftSourceKitClientPlugin.framework,
# the plugins Xcode's editor loads, from a patched copy of sourcekit-lsp.
#
# The patches (mk/patches/sourcekit-lsp-frameworks) make the copy build the
# plugins the way Xcode's frameworks are built: the service plugin with its
# sourcekitd function tables filled from sourcekitdInProc, which it links, and
# both entered through sourcekitd_plugin_initialize.  The two dylibs are then
# linked exporting what Xcode's frameworks export and nothing else, and
# stage-sourcekit-plugin-frameworks.sh makes frameworks of them.
#
# The copy sits beside the one the port builds, in the port's work directory,
# where the dependency links SwiftPM's local mode wants already are.  The
# modules are built for x86_64 as well, which Xcode's frameworks carry; that
# link has no x86_64 sourcekitdInProc to resolve against, and only the modules
# are kept from it.
#
# Usage: build-sourcekit-plugin-frameworks.sh <top> <sourcekit-lsp-src>
#            <workdir> <swiftpm-bin> <sdk> <sourcekitd-lib-dir> <dest>
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -ne 7 ]; then
	echo "usage: $0 <top> <sourcekit-lsp-src> <workdir> <swiftpm-bin> <sdk> <sourcekitd-lib-dir> <dest>" >&2
	exit 1
fi

TOP=$1
SRC=$2
WORK=$3
BIN=$4
SDK=$5
SKDLIB=$6
DEST=$7
PATCHES=$TOP/mk/patches/sourcekit-lsp-frameworks
FWSRC=$WORK/frameworks-src

rm -rf "$FWSRC"
rsync -a --exclude .build --exclude .git "$SRC/" "$FWSRC/"
for p in "$PATCHES"/*.patch; do
	patch -s -p1 -d "$FWSRC" < "$p"
done

# build <triple> <product> [flags...]
build() {
	triple=$1 product=$2
	shift 2
	(cd "$FWSRC" && env -u DEVELOPER_DIR SDKROOT="$SDK" SWIFTCI_USE_LOCAL_DEPS=1 \
	    PATH="$BIN:$PATH" "$BIN/swift-build" -c release --triple "$triple" \
	    -Xswiftc -target -Xswiftc "$triple" \
	    -Xlinker -current_version -Xlinker 1.0.0 \
	    -Xlinker -compatibility_version -Xlinker 1.0.0 \
	    -Xlinker -headerpad_max_install_names \
	    --product "$product" "$@")
}

for n in SwiftSourceKitPlugin SwiftSourceKitClientPlugin; do
	build arm64-apple-macosx14.0 $n -Xlinker -dead_strip_dylibs \
	    -Xlinker -F"$SKDLIB" -Xlinker -framework -Xlinker sourcekitdInProc \
	    -Xlinker -exported_symbols_list -Xlinker "$PATCHES/$n.exports"
	build x86_64-apple-macosx14.0 $n \
	    -Xlinker -undefined -Xlinker dynamic_lookup
done

mkdir -p "$DEST"
sh "$TOP/mk/scripts/stage-sourcekit-plugin-frameworks.sh" \
    "$FWSRC/.build/arm64-apple-macosx/release" "$DEST" \
    "$FWSRC/.build/x86_64-apple-macosx/release"
