#!/bin/sh
#
# Link swift-tools-support-core's static libraries into
# libSwiftToolsSupport.dylib, the single library Apple's toolchain carries
# for TSCBasic and TSCUtility, and write a TSCConfig.cmake beside it that
# gives swift-driver's CMake that dylib as both.  The Swift modules stay
# where the build put them.
#
# Usage: link-swifttoolssupport.sh <swiftc> <sdk> <tsc-build-dir>
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -ne 3 ]; then
	echo "usage: $0 <swiftc> <sdk> <tsc-build-dir>" >&2
	exit 1
fi

SWIFTC=$1
SDK=$2
B=$3

cd "$B"
"$SWIFTC" -sdk "$SDK" -emit-library -o libSwiftToolsSupport.dylib \
    -module-name SwiftToolsSupport \
    -Xlinker -all_load \
    lib/libTSCBasic.a lib/libTSCUtility.a lib/libTSCLibc.a lib/libTSCclibc.a \
    -Xlinker -install_name -Xlinker @rpath/libSwiftToolsSupport.dylib \
    -Xlinker -compatibility_version -Xlinker 1

# Apple's run paths.  Named rather than left to swiftc, which adds
# /usr/lib/swift through the legacy driver and not through swift-driver.
sh "$(dirname "$0")/set-rpaths.sh" libSwiftToolsSupport.dylib \
    /usr/lib/swift @executable_path/../lib

mkdir -p tsc-dylib
cat > tsc-dylib/TSCConfig.cmake <<EOF
if(NOT TARGET TSCBasic)
  foreach(t TSCBasic TSCUtility)
    add_library(\${t} SHARED IMPORTED)
    set_target_properties(\${t} PROPERTIES
      IMPORTED_LOCATION "${B}/libSwiftToolsSupport.dylib"
      INTERFACE_INCLUDE_DIRECTORIES "${B}/swift")
  endforeach()
endif()
EOF
