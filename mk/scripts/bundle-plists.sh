#!/bin/sh
#
# The Info.plist and version.plist Xcode writes into a framework or a
# bundle, for make-framework.sh and make-bundle.sh to source.
#
# Info.plist is a binary plist with the keys Xcode writes; the ones that
# describe the build (DT*, BuildMachineOSBuild) describe the machine and
# SDK this runs with, as Xcode's describe Apple's.  It is written as XML
# and converted: building it with plutil -insert gives different bytes
# from one run to the next, and the tree's builds are reproducible.
# version.plist is XML and carries the project's own build numbers.
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#

_plist_head() {
	echo '<?xml version="1.0" encoding="UTF-8"?>'
	echo '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">'
	echo '<plist version="1.0">'
	echo '<dict>'
}

_plist_tail() {
	echo '</dict>'
	echo '</plist>'
}

# _plist_string <key> <value>
_plist_string() {
	printf '\t<key>%s</key>\n\t<string>%s</string>\n' "$1" "$2"
}

# write_info_plist <path> <name> <executable-or-empty> <identifier>
#     <package-type> <short-version> <version> <minimum-macos>
write_info_plist() {
	_p=$1 _name=$2 _exe=$3 _id=$4 _type=$5 _short=$6 _version=$7 _minos=$8
	_sdkver=$(xcrun --show-sdk-version)
	_sdkbuild=$(xcrun --show-sdk-build-version)
	_xcode=$(xcode-select -p)/../Info.plist

	{
		_plist_head
		_plist_string BuildMachineOSBuild "$(sw_vers -buildVersion)"
		_plist_string CFBundleDevelopmentRegion en
		[ -n "$_exe" ] && _plist_string CFBundleExecutable "$_exe"
		_plist_string CFBundleIdentifier "$_id"
		_plist_string CFBundleInfoDictionaryVersion 6.0
		_plist_string CFBundleName "$_name"
		_plist_string CFBundlePackageType "$_type"
		_plist_string CFBundleShortVersionString "$_short"
		printf '\t<key>CFBundleSupportedPlatforms</key>\n\t<array>\n\t\t<string>MacOSX</string>\n\t</array>\n'
		_plist_string CFBundleVersion "$_version"
		_plist_string DTCompiler com.apple.compilers.llvm.clang.1_0
		_plist_string DTPlatformBuild "$_sdkbuild"
		_plist_string DTPlatformName macosx
		_plist_string DTPlatformVersion "$_sdkver"
		_plist_string DTSDKBuild "$_sdkbuild"
		_plist_string DTSDKName "macosx$_sdkver"
		_plist_string DTXcode "$(plutil -extract DTXcode raw "$_xcode" 2>/dev/null || echo 0)"
		_plist_string DTXcodeBuild "$(plutil -extract DTXcodeBuild raw "$_xcode" 2>/dev/null || echo 0)"
		_plist_string LSMinimumSystemVersion "$_minos"
		_plist_tail
	} > "$_p"
	plutil -convert binary1 "$_p"
}

# write_version_plist <path> <short-version> <version> <project>
#     <build-version>
#
# BUILD_ALIAS_OF and PRODUCT_BUILD_VERSION in the environment add those
# keys, which some of Xcode's projects carry.  SourceVersion is the
# version with each component zero-padded: 24700.0.19 -> 24700000019000000.
write_version_plist() {
	_p=$1 _short=$2 _version=$3 _project=$4 _buildversion=$5
	_source=$(echo "$_version" | awk -F. '{ printf "%d%03d%03d%03d%03d\n", $1, $2, $3, $4, $5 }')
	{
		_plist_head
		[ -n "$BUILD_ALIAS_OF" ] && _plist_string BuildAliasOf "$BUILD_ALIAS_OF"
		_plist_string BuildVersion "$_buildversion"
		_plist_string CFBundleShortVersionString "$_short"
		_plist_string CFBundleVersion "$_version"
		[ -n "$PRODUCT_BUILD_VERSION" ] && _plist_string ProductBuildVersion "$PRODUCT_BUILD_VERSION"
		_plist_string ProjectName "$_project"
		_plist_string SourceVersion "$_source"
		_plist_tail
	} > "$_p"
}

# minimum_macos <mach-o>: the minimum macOS a binary was built for.
minimum_macos() {
	otool -l "$1" | awk '/LC_BUILD_VERSION/ { f = 1 } f && $1 == "minos" { print $2; exit }'
}
