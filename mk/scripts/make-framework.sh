#!/bin/sh
#
# Lay a built library out as a framework the way Xcode's SharedFrameworks
# are: Versions/A/<name> and Versions/A/Resources/{Info,version}.plist,
# with Versions/Current, <name> and Resources linked at the top.  Nothing
# else -- Xcode's installed frameworks carry no Headers or Modules.
#
# Info.plist has the keys Xcode writes, as a binary plist; the build
# environment ones (DT*, BuildMachineOSBuild) describe the machine and SDK
# this runs with, as Xcode's describe Apple's.  version.plist carries the
# project's own build numbers.
#
# Usage: make-framework.sh <library> <dest>/<name>.framework <identifier>
#            <short-version> <version> <project> <build-version>
#            [<resource>...]
#
# BUILD_ALIAS_OF in the environment adds that key to version.plist, which
# frameworks built under another project's name carry.
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -lt 7 ]; then
	echo "usage: $0 <library> <name>.framework <identifier> <short-version> <version> <project> <build-version> [<resource>...]" >&2
	exit 1
fi

LIB=$1 FW=$2 ID=$3 SHORT=$4 VERSION=$5 PROJECT=$6 BUILDVERSION=$7
shift 7
NAME=$(basename "$FW" .framework)

rm -rf "$FW"
mkdir -p "$FW/Versions/A/Resources"
cp "$LIB" "$FW/Versions/A/$NAME"
for r in "$@"; do
	cp -R "$r" "$FW/Versions/A/Resources/"
done
ln -s A "$FW/Versions/Current"
ln -s "Versions/Current/$NAME" "$FW/$NAME"
ln -s Versions/Current/Resources "$FW/Resources"

SDK=$(xcrun --show-sdk-path)
SDKVER=$(xcrun --show-sdk-version)
SDKBUILD=$(xcrun --show-sdk-build-version)
XCODE=$(xcode-select -p)/../Info.plist
MINOS=$(otool -l "$LIB" | awk '/LC_BUILD_VERSION/ { f = 1 } f && $1 == "minos" { print $2; exit }')

P="$FW/Versions/A/Resources/Info.plist"
plutil -create binary1 "$P"
plutil -insert BuildMachineOSBuild -string "$(sw_vers -buildVersion)" "$P"
plutil -insert CFBundleDevelopmentRegion -string en "$P"
plutil -insert CFBundleExecutable -string "$NAME" "$P"
plutil -insert CFBundleIdentifier -string "$ID" "$P"
plutil -insert CFBundleInfoDictionaryVersion -string 6.0 "$P"
plutil -insert CFBundleName -string "$NAME" "$P"
plutil -insert CFBundlePackageType -string FMWK "$P"
plutil -insert CFBundleShortVersionString -string "$SHORT" "$P"
plutil -insert CFBundleSupportedPlatforms -array "$P"
plutil -insert CFBundleSupportedPlatforms.0 -string MacOSX "$P"
plutil -insert CFBundleVersion -string "$VERSION" "$P"
plutil -insert DTCompiler -string com.apple.compilers.llvm.clang.1_0 "$P"
plutil -insert DTPlatformBuild -string "$SDKBUILD" "$P"
plutil -insert DTPlatformName -string macosx "$P"
plutil -insert DTPlatformVersion -string "$SDKVER" "$P"
plutil -insert DTSDKBuild -string "$SDKBUILD" "$P"
plutil -insert DTSDKName -string "macosx$SDKVER" "$P"
plutil -insert DTXcode -string "$(plutil -extract DTXcode raw "$XCODE" 2>/dev/null || echo 0)" "$P"
plutil -insert DTXcodeBuild -string "$(plutil -extract DTXcodeBuild raw "$XCODE" 2>/dev/null || echo 0)" "$P"
plutil -insert LSMinimumSystemVersion -string "$MINOS" "$P"

# version.plist is XML in Xcode's frameworks, and SourceVersion is the
# version with each component zero-padded: 24700.0.19 -> 24700000019000000.
SOURCE=$(echo "$VERSION" | awk -F. '{ printf "%d%03d%03d%03d%03d\n", $1, $2, $3, $4, $5 }')
ALIAS=
if [ -n "$BUILD_ALIAS_OF" ]; then
	ALIAS=$(printf '\t<key>BuildAliasOf</key>\n\t<string>%s</string>\n' "$BUILD_ALIAS_OF")
fi
cat > "$FW/Versions/A/Resources/version.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
${ALIAS:+$ALIAS
}	<key>BuildVersion</key>
	<string>$BUILDVERSION</string>
	<key>CFBundleShortVersionString</key>
	<string>$SHORT</string>
	<key>CFBundleVersion</key>
	<string>$VERSION</string>
	<key>ProjectName</key>
	<string>$PROJECT</string>
	<key>SourceVersion</key>
	<string>$SOURCE</string>
</dict>
</plist>
EOF
