#!/bin/sh
#
# Assemble SwiftBuild.framework from a CMake build of swift-build, the way
# Xcode's SharedFrameworks carry it:
#
#   SwiftBuild.framework/Versions/A/
#     SwiftBuild
#     Resources/{Info,version}.plist
#     Support/swbuild, and xcbuild linked to it
#     PlugIns/SWBBuildService.bundle/Contents/
#       MacOS/SWBBuildService            the build service
#       Frameworks/SWB*.framework        the fifteen it runs on
#       PlugIns/SWB*PlatformPlugin.bundle/Contents/
#         MacOS/SWB*PlatformPlugin       a bundle exporting initializePlugin
#         Frameworks/SWB*Platform.framework
#
# CMake builds every library as lib<Name>.dylib and neither bundle.  So,
# in the build directory: every library and both executables are renamed
# to the framework install names, the platform plugins are linked from
# their one source file, and each binary gets the run paths Xcode's has.
# Then make-framework.sh and make-bundle.sh lay it out in <dest>.
#
# Resources are what Xcode's frameworks carry: every file of the module's
# source directory that is not Swift, flattened -- CMakeLists.txt and the
# en.lproj strings included, a README not -- for SWBCore, SWBMacro and
# the platforms, and nothing for the rest.
#
# Usage: assemble-swiftbuild.sh <build-dir> <source-dir> <dest>
#            <swiftc> <sdk> <llbuild-framework-dir> <module-search-dir>...
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -lt 6 ]; then
	echo "usage: $0 <build-dir> <source-dir> <dest> <swiftc> <sdk> <llbuild-framework-dir> <module-search-dir>..." >&2
	exit 1
fi

B=$1 SRC=$2 DEST=$3 SWIFTC=$4 SDK=$5 LLBUILD_FW=$6
shift 6
HERE=$(dirname "$0")

# Xcode's numbers for this SwiftBuild.
SHORT=16.0
VERSION=24900.0.3
PROJECT=XCBuild
BUILDVERSION=136
PRODUCT_BUILD_VERSION=17F113
export PRODUCT_BUILD_VERSION

SERVICE="SWBBuildService SWBBuildSystem SWBCAS SWBCLibc SWBCSupport SWBCore
	SWBLLBuild SWBLibc SWBMacro SWBProjectModel SWBProtocol SWBServiceCore
	SWBTaskConstruction SWBTaskExecution SWBUtil"
PLATFORMS="SWBAndroidPlatform SWBApplePlatform SWBGenericUnixPlatform
	SWBQNXPlatform SWBUniversalPlatform SWBWebAssemblyPlatform
	SWBWindowsPlatform"
ALL="SwiftBuild $SERVICE $PLATFORMS"

# --- install names ----------------------------------------------------

rename() {
	for m in $ALL; do
		install_name_tool -change "@rpath/lib$m.dylib" \
		    "@rpath/$m.framework/Versions/A/$m" "$1"
	done
}
for n in $ALL; do
	install_name_tool -id "@rpath/$n.framework/Versions/A/$n" "$B/lib/lib$n.dylib"
	rename "$B/lib/lib$n.dylib"
done
rename "$B/bin/SWBBuildServiceBundle"
rename "$B/bin/swbuild"

# --- the platform plugins ---------------------------------------------
#
# Each is PluginMain.swift linked as a bundle against its platform, SWBCore
# and SWBUtil, named in the order Xcode's loads them.
mkdir -p "$B/plugins"
INCLUDES="-I $B/swift -I $SRC/Sources/SWBCSupport -I $SRC/Sources/SWBCLibc/include -F $LLBUILD_FW"
for d in "$@"; do
	INCLUDES="$INCLUDES -I $d"
done
for p in $PLATFORMS; do
	# shellcheck disable=SC2086
	"$SWIFTC" -sdk "$SDK" -target arm64-apple-macosx14.0 -O -wmo \
	    -parse-as-library -module-name "${p}Plugin" $INCLUDES \
	    "$SRC/Sources/${p}Plugin/PluginMain.swift" \
	    -emit-library -Xlinker -bundle -o "$B/plugins/${p}Plugin" \
	    -Xlinker -L"$B/lib" \
	    -Xlinker -lSWBUtil -Xlinker -lSWBCore -Xlinker -l"$p" \
	    -Xlinker -framework -Xlinker Foundation -Xlinker -lobjc
	rename "$B/plugins/${p}Plugin"
done

# --- run paths --------------------------------------------------------

# From a framework inside the service bundle, eleven levels up is
# Contents, beside which Developer's toolchain is.
UP11=@loader_path/../../../../../../../../../../..
FWRPATHS="@loader_path/../../.. @loader_path/Frameworks
	$UP11/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib
	$UP11/Developer/Toolchains/XcodeDefault.xctoolchain/usr/local/lib"
rpaths() {
	f=$1
	shift
	# shellcheck disable=SC2046,SC2086
	sh "$HERE/set-rpaths.sh" "$f" "$@"
}
for n in $SERVICE $PLATFORMS; do
	case $n in
	SWBCLibc)	rpaths "$B/lib/lib$n.dylib" $FWRPATHS ;;
	SWBCSupport)	rpaths "$B/lib/lib$n.dylib" /usr/lib/swift $FWRPATHS @executable_path/../Frameworks ;;
	SWBLLBuild)	rpaths "$B/lib/lib$n.dylib" /usr/lib/swift $FWRPATHS @loader_path/../../../../../../../../../.. ;;
	*)		rpaths "$B/lib/lib$n.dylib" /usr/lib/swift $FWRPATHS ;;
	esac
done
rpaths "$B/lib/libSwiftBuild.dylib" /usr/lib/swift \
    @loader_path/PlugIns/SWBBuildService.bundle/Contents/Frameworks
rpaths "$B/bin/SWBBuildServiceBundle" /usr/lib/swift \
    @loader_path/../Frameworks @loader_path/../../../../../../..
rpaths "$B/bin/swbuild" /usr/lib/swift @executable_path/ \
    @executable_path/../../../.. @executable_path/../Frameworks
for p in $PLATFORMS; do
	rpaths "$B/plugins/${p}Plugin" /usr/lib/swift @loader_path/../Frameworks
done

# --- layout -----------------------------------------------------------

# A framework, and for SWBCore, SWBMacro and the platforms its resources:
# the module's source files that are not Swift, flattened.  Copied by find
# rather than passed as arguments, because several of the strings files
# have spaces in their names.
framework() {
	n=$1 dest=$2 id=com.apple.dt.$1
	[ "$n" = SWBBuildService ] && id=com.apple.dt.SWBBuildService.Framework
	sh "$HERE/make-framework.sh" "$B/lib/lib$n.dylib" "$dest/$n.framework" \
	    "$id" $SHORT $VERSION $PROJECT $BUILDVERSION
	case $n in
	SWBCore|SWBMacro|*Platform)
		find "$SRC/Sources/$n" -type f ! -name '*.swift' ! -name README.md \
		    -exec cp {} "$dest/$n.framework/Versions/A/Resources/" \; ;;
	esac
}

rm -rf "$DEST/SwiftBuild.framework"
mkdir -p "$DEST"
framework SwiftBuild "$DEST"
A=$DEST/SwiftBuild.framework/Versions/A
ln -s Versions/Current/PlugIns "$DEST/SwiftBuild.framework/PlugIns"

mkdir -p "$A/Support"
cp "$B/bin/swbuild" "$A/Support/swbuild"
ln -s swbuild "$A/Support/xcbuild"

SB=$A/PlugIns/SWBBuildService.bundle
MINOS=$(. "$HERE/bundle-plists.sh"; minimum_macos "$B/bin/SWBBuildServiceBundle")
sh "$HERE/make-bundle.sh" "$B/bin/SWBBuildServiceBundle" "$SB" \
    com.apple.dt.SWBBuildService $SHORT $VERSION $PROJECT $BUILDVERSION "$MINOS"
mkdir -p "$SB/Contents/Frameworks" "$SB/Contents/PlugIns"
for n in $SERVICE; do
	framework "$n" "$SB/Contents/Frameworks"
done
for p in $PLATFORMS; do
	PB=$SB/Contents/PlugIns/${p}Plugin.bundle
	sh "$HERE/make-bundle.sh" "$B/plugins/${p}Plugin" "$PB" \
	    "com.apple.dt.${p}Plugin" $SHORT $VERSION $PROJECT $BUILDVERSION "$MINOS"
	mkdir -p "$PB/Contents/Frameworks"
	framework "$p" "$PB/Contents/Frameworks"
done
