#!/bin/sh
#
# Link swift-driver's SwiftDriver and SwiftOptions static libraries into
# libSwiftDriver.dylib, the library Apple's toolchain carries in usr/lib
# for SwiftBuild and swift-package to load.  It re-exports
# libSwiftToolsSupport.dylib, as Apple's does, and holds neither the
# driver's executor nor llbuild.
#
# Usage: link-swiftdriver.sh <swiftc> <sdk> <swift-driver-build-dir>
#            <libSwiftToolsSupport.dylib>
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -ne 4 ]; then
	echo "usage: $0 <swiftc> <sdk> <swift-driver-build-dir> <libSwiftToolsSupport.dylib>" >&2
	exit 1
fi

SWIFTC=$1 SDK=$2 B=$3 TSC=$4

cd "$B"
"$SWIFTC" -sdk "$SDK" -target arm64-apple-macosx14.0 \
    -emit-library -o libSwiftDriver.dylib -module-name SwiftDriver \
    -Xlinker -all_load lib/libSwiftDriver.a lib/libSwiftOptions.a \
    -Xlinker -noall_load lib/libCSwiftScan.a \
    -Xlinker -reexport_library -Xlinker "$TSC" \
    -Xlinker -install_name -Xlinker @rpath/libSwiftDriver.dylib \
    -Xlinker -compatibility_version -Xlinker 1

sh "$(dirname "$0")/set-rpaths.sh" libSwiftDriver.dylib \
    /usr/lib/swift @executable_path/../lib

# SwiftDriverConfig.cmake files for the projects that link a target named
# SwiftDriver, with the driver's Swift modules to import: in
# swiftdriver-dylib the dylib weakly, as Xcode's SwiftBuild frameworks
# link it, and in swiftdriver-dylib-strong plainly, as its swift-package
# does.
config() {
	mkdir -p "$1"
	cat > "$1/SwiftDriverConfig.cmake" <<EOF
foreach(t SwiftDriver SwiftOptions)
  if(NOT TARGET \${t})
    add_library(\${t} INTERFACE IMPORTED)
    set_target_properties(\${t} PROPERTIES
      INTERFACE_INCLUDE_DIRECTORIES "$B/swift"
      INTERFACE_LINK_OPTIONS "SHELL:$2")
  endif()
endforeach()
EOF
}
config swiftdriver-dylib "-Xlinker -weak_library -Xlinker $B/libSwiftDriver.dylib"
config swiftdriver-dylib-strong "$B/libSwiftDriver.dylib"
