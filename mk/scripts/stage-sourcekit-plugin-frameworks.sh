#!/bin/sh
#
# Lay out SwiftSourceKitPlugin.framework and SwiftSourceKitClientPlugin.framework
# the way Xcode's toolchain has them in usr/lib.
#
# Xcode ships SourceKit-LSP's two plugins twice: as the dylibs sourcekit-lsp
# loads, and as frameworks, which Xcode's own editor loads.  Apple publish
# no source for the frameworks -- they come from an internal project,
# SwiftSourceKitExtensions -- but what is in them is sourcekit-lsp's plugin
# code, built another way: the service plugin links sourcekitdInProc rather
# than loading it, the client plugin finds sourcekitd.framework beside itself,
# both are entered through sourcekitd_plugin_initialize, and CompletionScoring's
# types are the service framework's own.  mk/patches/sourcekit-lsp-frameworks
# makes a copy of sourcekit-lsp build that way; this takes the two dylibs it
# makes and lays them out as frameworks.
#
# Usage: stage-sourcekit-plugin-frameworks.sh <arm64-release-dir> <dest-dir>
#            [<x86_64-release-dir>]
#
# The release directories are SwiftPM's .build/<triple>/release; from the
# x86_64 one only the modules are taken, which Xcode's frameworks carry for
# both architectures around a binary that is arm64 alone.
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
	echo "usage: $0 <arm64-release-dir> <dest-dir> [<x86_64-release-dir>]" >&2
	exit 1
fi

ARM64=$1
DEST=$2
X86_64=$3
SCRIPTS=$(dirname "$0")
. "$SCRIPTS/bundle-plists.sh"

# framework <name> <module> <bundle-identifier>
framework() {
	n=$1 m=$2 id=$3
	fw=$DEST/$n.framework
	rm -rf "$fw"
	mkdir -p "$fw/Versions/A/Resources" "$fw/Versions/A/Modules/$m.swiftmodule"

	cp "$ARM64/lib$n.dylib" "$fw/Versions/A/$n"
	install_name_tool -id "@rpath/$n.framework/Versions/A/$n" "$fw/Versions/A/$n"
	sh "$SCRIPTS/set-rpaths.sh" "$fw/Versions/A/$n" /usr/lib/swift @loader_path/../../..

	write_info_plist "$fw/Versions/A/Resources/Info.plist" "$n" "$n" "$id" \
	    FMWK 1.0 24700 "$(minimum_macos "$fw/Versions/A/$n")"
	write_version_plist "$fw/Versions/A/Resources/version.plist" \
	    1.0 24700 SwiftSourceKitExtensions 1939

	for a in arm64:"$ARM64" x86_64:"$X86_64"; do
		arch=${a%%:*} dir=${a#*:}
		[ -n "$dir" ] || continue
		cp "$dir/Modules/$m.swiftmodule" \
		    "$fw/Versions/A/Modules/$m.swiftmodule/$arch-apple-macos.swiftmodule"
		cp "$dir/Modules/$m.swiftdoc" \
		    "$fw/Versions/A/Modules/$m.swiftmodule/$arch-apple-macos.swiftdoc"
	done

	ln -s A "$fw/Versions/Current"
	ln -s "Versions/Current/$n" "$fw/$n"
	ln -s Versions/Current/Resources "$fw/Resources"
	ln -s Versions/Current/Modules "$fw/Modules"
}

framework SwiftSourceKitPlugin SwiftSourceKitPlugin com.apple.dt.swift-sourcekit-plugin
framework SwiftSourceKitClientPlugin SwiftSourceKitClientPlugin_XcodeDefault \
    com.apple.dt.swift-sourcekit-client-plugin
