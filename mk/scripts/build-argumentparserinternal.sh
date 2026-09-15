#!/bin/sh
#
# ArgumentParserInternal, the argument parser Xcode's SwiftBuild frameworks
# use: not linked into them, as a CMake build links ArgumentParser, but
# taken from the system, which carries it as
# /System/Library/PrivateFrameworks/ArgumentParserInternal.framework.
#
# Linked in, SWBUtil exports the parser's classes, and swift-package, which
# links a copy of its own, then has two of each: the runtime finds a type by
# name in one and its conformances in the other, and swift-package cannot
# parse its own command line.  Under Xcode's module name the two are
# different types.
#
# The framework is swift-argument-parser 1.5.1 built with library evolution,
# ArgumentParserToolInfo compiled under the same ABI name; built that way,
# its exports are the framework's but for one CommandConfiguration
# initializer nothing in SwiftBuild calls.  What is built here is what
# linking against it takes -- the two modules and a stub of the framework --
# and a CMake config that hands SwiftBuild's CMake that as ArgumentParser,
# its imports aliased to ArgumentParserInternal.
#
# Usage: build-argumentparserinternal.sh <swiftc> <sdk> <argument-parser-src> <dest>
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -ne 4 ]; then
	echo "usage: $0 <swiftc> <sdk> <argument-parser-src> <dest>" >&2
	exit 1
fi

SWIFTC=$1
SDK=$2
SRC=$3/Sources
D=$4
FW=/System/Library/PrivateFrameworks/ArgumentParserInternal.framework/Versions/A/ArgumentParserInternal

rm -rf "$D"
mkdir -p "$D/modules" "$D/Frameworks/ArgumentParserInternal.framework"

# module <name> <sources-dir> [flags...]
module() {
	m=$1 dir=$2
	shift 2
	# One source per line: the parser's directories have spaces in their
	# names.
	IFS='
'
	set -- "$@" $(find "$dir" -name '*.swift' | LC_ALL=C sort)
	unset IFS
	"$SWIFTC" -sdk "$SDK" -target arm64-apple-macos14.0 \
	    -parse-as-library -whole-module-optimization -O \
	    -enable-library-evolution -module-name $m -I "$D/modules" \
	    -emit-module -emit-module-path "$D/modules/$m.swiftmodule" "$@"
}

module ArgumentParserToolInfo "$SRC/ArgumentParserToolInfo" \
    -module-abi-name ArgumentParserInternal
module ArgumentParserInternal "$SRC/ArgumentParser"

sh "$(dirname "$0")/make-tbd.sh" "$FW" \
    "$D/Frameworks/ArgumentParserInternal.framework/ArgumentParserInternal.tbd"

cat > "$D/ArgumentParserConfig.cmake" <<EOF
if(NOT TARGET ArgumentParser)
  add_library(ArgumentParser INTERFACE IMPORTED)
  set_target_properties(ArgumentParser PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "$D/modules"
    INTERFACE_COMPILE_OPTIONS "\$<\$<COMPILE_LANGUAGE:Swift>:SHELL:-module-alias ArgumentParser=ArgumentParserInternal>"
    INTERFACE_LINK_OPTIONS "SHELL:-F $D/Frameworks;SHELL:-framework ArgumentParserInternal")
endif()
EOF
