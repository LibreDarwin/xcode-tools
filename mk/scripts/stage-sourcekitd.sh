#!/bin/sh
#
# Lay out SourceKit the way Xcode's toolchain has it in usr/lib:
# sourcekitd.framework, the XPC client, with SourceKitService.xpc inside
# it, and sourcekitdInProc.framework, which the service links and which
# sourcekit-lsp can load in process.
#
# The swift build makes all three, in a form that works from the build
# tree and differs from Xcode's where it shows:
#
#   - the service is named org.swift.SourceKitService.<version>_<toolchain>
#     and the frameworks org.swift.<name>; Xcode's are com.apple.  The
#     client reads the name from Resources/xpc_service_name.txt and XPC
#     finds the service by its bundle identifier, so the two are changed
#     together and nothing else carries the name.
#   - the frameworks carry Headers, and the XPC client framework Modules;
#     Xcode's ship neither, and only sourcekitdInProc keeps its module map.
#   - no version.plist, which Xcode's bundles all have, and the service's
#     Info.plist lacks XPCService._ExponentialThrottling.
#   - the run paths are the build tree's, and libc++ is @rpath/libc++.1.dylib,
#     the LLVM port's, which none of those run paths reach.  Xcode's name
#     the system's /usr/lib/libc++.1.dylib, as swift.mk has swift-demangle
#     do.
#
# Info.plists are written as XML and converted, so the output is the same
# every time; see bundle-plists.sh.
#
# Usage: stage-sourcekitd.sh <build-lib-dir> <dest-dir>
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -ne 2 ]; then
	echo "usage: $0 <build-lib-dir> <dest-dir>" >&2
	exit 1
fi

LIB=$1
DEST=$2
SCRIPTS=$(dirname "$0")
VERSION=6.3.3.1.3
. "$SCRIPTS/bundle-plists.sh"

# relink <binary> <rpath>...: the system's libc++, then Xcode's run paths.
relink() {
	_b=$1
	shift
	install_name_tool -change @rpath/libc++.1.dylib /usr/lib/libc++.1.dylib "$_b"
	sh "$SCRIPTS/set-rpaths.sh" "$_b" "$@"
}

# plist <in> <out> [sed-expr...]: rename, and write binary.
plist() {
	_in=$1 _out=$2
	shift 2
	sed -e 's/org\.swift\./com.apple./' "$@" "$_in" > "$_out"
	plutil -convert binary1 "$_out"
}

# framework <name> <rpath>...: the versioned framework, without Headers.
framework() {
	n=$1
	shift
	src=$LIB/$n.framework/Versions/A
	fw=$DEST/$n.framework
	rm -rf "$fw"
	mkdir -p "$fw/Versions/A/Resources"
	cp "$src/$n" "$fw/Versions/A/$n"
	sed -e 's/^org\.swift\./com.apple./' "$src/Resources/xpc_service_name.txt" \
	    > "$fw/Versions/A/Resources/xpc_service_name.txt"
	plist "$src/Resources/Info.plist" "$fw/Versions/A/Resources/Info.plist"
	write_version_plist "$fw/Versions/A/Resources/version.plist" \
	    1.0 $VERSION swiftlang 3
	ln -s A "$fw/Versions/Current"
	ln -s Versions/Current/Resources "$fw/Resources"
	ln -s "Versions/Current/$n" "$fw/$n"
	relink "$fw/Versions/A/$n" "$@"
}

framework sourcekitd /usr/lib/swift \
    @loader_path/../../../swift/host/compiler @loader_path/../../../

framework sourcekitdInProc /usr/lib/swift \
    @loader_path/../../../swift/host/compiler @loader_path/../../../
mkdir -p "$DEST/sourcekitdInProc.framework/Versions/A/Modules"
cp "$LIB/sourcekitdInProc.framework/Versions/A/Modules/module.modulemap" \
    "$DEST/sourcekitdInProc.framework/Versions/A/Modules/"
ln -s Versions/Current/Modules "$DEST/sourcekitdInProc.framework/Modules"

# The service, inside the client framework.
svc=Versions/A/XPCServices/SourceKitService.xpc/Contents
mkdir -p "$DEST/sourcekitd.framework/$svc/MacOS"
cp "$LIB/sourcekitd.framework/$svc/MacOS/SourceKitService" \
    "$DEST/sourcekitd.framework/$svc/MacOS/"
plist "$LIB/sourcekitd.framework/$svc/Info.plist" \
    "$DEST/sourcekitd.framework/$svc/Info.plist" \
    -e 's|^\([[:space:]]*\)<key>ServiceType</key>|\1<key>_ExponentialThrottling</key>\
\1<false/>\
\1<key>ServiceType</key>|'
write_version_plist "$DEST/sourcekitd.framework/$svc/version.plist" \
    1.0 $VERSION swiftlang 3
ln -s Versions/Current/XPCServices "$DEST/sourcekitd.framework/XPCServices"
relink "$DEST/sourcekitd.framework/$svc/MacOS/SourceKitService" \
    /usr/lib/swift @loader_path/../../../../../../../swift/host/compiler \
    @loader_path/../../../../../../../
