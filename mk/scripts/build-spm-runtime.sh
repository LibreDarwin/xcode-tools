#!/bin/sh
#
# Build SwiftPM's runtime libraries the way Apple's toolchain ships them:
# lib/swift/pm/ManifestAPI/libPackageDescription.dylib, which holds both
# PackageDescription and CompilerPluginSupport, and
# lib/swift/pm/PluginAPI/libPackagePlugin.dylib -- universal, with a
# textual interface and a swiftdoc per architecture and no binary module.
#
# SwiftPM's CMake builds these as three libraries, one architecture at a
# time, and with other flags than Apple's.  Apple builds them with SwiftPM
# itself, from Package.swift, where the PackageDescription product is the
# two targets in one dylib; the flags below are the ones Apple's
# interfaces record, and the sources go in the sorted order SwiftPM gives
# them, which is the order the declarations come out in.
#
# Usage: build-spm-runtime.sh <swiftc> <sdk> <swiftpm-src> <workdir> <dest>
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -ne 5 ]; then
	echo "usage: $0 <swiftc> <sdk> <swiftpm-src> <workdir> <dest>" >&2
	exit 1
fi

SWIFTC=$1
SDK=$2
SRC=$3/Sources/Runtimes
W=$4
DEST=$5
MINOS=14.0
ARCHS="x86_64 arm64"

# module <arch> <name> [flags...]: compile one module whole, to an
# object and a module directory, under $W/<arch>.
module() {
	a=$1 m=$2
	shift 2
	o=$W/$a
	mkdir -p "$o/$m.swiftmodule"
	"$SWIFTC" -sdk "$SDK" -target $a-apple-macos$MINOS \
	    -parse-as-library -whole-module-optimization -num-threads 0 \
	    -enable-library-evolution -swift-version 5 -O \
	    -package-description-version 999.0 \
	    -enable-experimental-feature MemberImportVisibility \
	    -enable-experimental-feature DebugDescriptionMacro \
	    -user-module-version 24907 -package-name swiftpm \
	    -module-name $m -I "$o" "$@" \
	    -emit-object -o "$o/$m.o" \
	    -emit-module-path "$o/$m.swiftmodule/$a-apple-macos.swiftmodule" \
	    -emit-module-interface-path \
	        "$o/$m.swiftmodule/$a-apple-macos.swiftinterface" \
	    $(find "$SRC/$m" -name '*.swift' | LC_ALL=C sort)
}

# dylib <arch> <name> <objects...>
dylib() {
	a=$1 n=$2
	shift 2
	"$SWIFTC" -sdk "$SDK" -target $a-apple-macos$MINOS \
	    -emit-library -o "$W/$a/lib$n.dylib" "$@" \
	    -Xlinker -install_name -Xlinker @rpath/lib$n.dylib \
	    -Xlinker -current_version -Xlinker 1 \
	    -Xlinker -compatibility_version -Xlinker 1
}

rm -rf "$W"
for a in $ARCHS; do
	module $a PackageDescription -DUSE_IMPL_ONLY_IMPORTS
	module $a CompilerPluginSupport
	module $a PackagePlugin
	dylib $a PackageDescription \
	    "$W/$a/PackageDescription.o" "$W/$a/CompilerPluginSupport.o"
	dylib $a PackagePlugin "$W/$a/PackagePlugin.o"
done

for d in ManifestAPI:PackageDescription:"PackageDescription CompilerPluginSupport" \
         PluginAPI:PackagePlugin:PackagePlugin; do
	dir=${d%%:*}
	rest=${d#*:}
	lib=${rest%%:*}
	mods=${rest#*:}

	rm -rf "$DEST/$dir"
	mkdir -p "$DEST/$dir"
	lipo -create $(for a in $ARCHS; do echo "$W/$a/lib$lib.dylib"; done) \
	    -output "$DEST/$dir/lib$lib.dylib"
	for m in $mods; do
		mkdir -p "$DEST/$dir/$m.swiftmodule"
		for a in $ARCHS; do
			for x in swiftinterface swiftdoc; do
				cp "$W/$a/$m.swiftmodule/$a-apple-macos.$x" \
				    "$DEST/$dir/$m.swiftmodule/"
			done
		done
	done
done
