#!/bin/sh
#
# Build llbuild.framework the way Xcode's is: one library holding
# llbuild's C API and its Swift bindings, the bindings compiled as the
# Swift overlay of the framework's own clang module -- module llbuild, not
# llbuildSwift -- and nothing exported but the C API and the Swift module.
# CMake builds the pieces; this links them.
#
# Two frameworks come out, in <build-dir>:
#
#   fw/llbuild.framework       for building against: Headers, Modules
#                              and the Swift module, as swift-driver and
#                              SwiftPM need it
#   fw-install/llbuild.framework  what Xcode installs, laid out by
#                              make-framework.sh
#
# Usage: build-llbuild-framework.sh <swiftc> <sdk> <llbuild-src> <build-dir>
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -ne 4 ]; then
	echo "usage: $0 <swiftc> <sdk> <llbuild-src> <build-dir>" >&2
	exit 1
fi

SWIFTC=$1 SDK=$2 SRC=$3 B=$4
FW=$B/fw/llbuild.framework
A=$FW/Versions/A

# The version Xcode's reports, and its project build number.
VERSION=24700.0.19
BUILDVERSION=317

rm -rf "$B/fw" "$B/fw-install"
mkdir -p "$A/Headers" "$A/Modules" "$A/Resources"
cp "$SRC"/products/libllbuild/include/llbuild/*.h "$A/Headers/"
cp "$SRC"/products/llbuild-framework/llbuild-module.modulemap "$A/Modules/module.modulemap"
ln -s A "$FW/Versions/Current"
for d in Headers Modules Resources; do
	ln -s "Versions/Current/$d" "$FW/$d"
done
ln -s Versions/Current/llbuild "$FW/llbuild"

# What the framework exports: the C API, the Swift module, the metadata
# for the imported C types, and the one extension it puts on Foundation.
cat > "$B/fw/exports.txt" <<'EOF'
_llb_*
_$s7llbuild*
_$sSo*
_$s10Foundation4DateV7llbuild*
EOF

"$SWIFTC" -sdk "$SDK" -target arm64-apple-macosx14.0 -O -wmo -parse-as-library \
    -module-name llbuild -import-underlying-module -F "$B/fw" \
    -emit-module -emit-module-path "$A/Modules/llbuild.swiftmodule/arm64-apple-macos.swiftmodule" \
    -emit-library -o "$A/llbuild" \
    "$SRC"/products/llbuildSwift/BuildSystemBindings.swift \
    "$SRC"/products/llbuildSwift/CoreBindings.swift \
    "$SRC"/products/llbuildSwift/BuildDBBindings.swift \
    "$SRC"/products/llbuildSwift/BuildKey.swift \
    "$SRC"/products/llbuildSwift/Internals.swift \
    "$SRC"/products/llbuildSwift/BuildValue.swift \
    "$SRC"/products/llbuildSwift/NinjaManifest.swift \
    -Xlinker -all_load "$B/lib/libllbuild.a" -Xlinker -noall_load \
    "$B/lib/libllbuildBuildSystem.a" "$B/lib/libllbuildCore.a" \
    "$B/lib/libllbuildBasic.a" "$B/lib/libllbuildNinja.a" \
    "$B/lib/libllvmSupport.a" "$B/lib/libllvmDemangle.a" \
    -Xlinker -lsqlite3 -Xlinker -lncurses \
    -Xlinker -framework -Xlinker Foundation -Xlinker -lobjc -Xlinker -lc++ \
    -Xlinker -exported_symbols_list -Xlinker "$B/fw/exports.txt" \
    -Xlinker -install_name -Xlinker @rpath/llbuild.framework/Versions/A/llbuild \
    -Xlinker -compatibility_version -Xlinker 1 \
    -Xlinker -current_version -Xlinker $VERSION

sh "$(dirname "$0")/set-rpaths.sh" "$A/llbuild" /usr/lib/swift

# An LLBuildConfig.cmake for swift-driver's CMake, which links targets
# named llbuild and llbuildSwift: both are the framework, and neither
# names it to the link.  import llbuild autolinks it by name, which puts
# it after everything else, where Apple's swift-driver has it; so the
# targets carry only the -F that lets the compile and the link find it.
cat > "$B/fw/LLBuildConfig.cmake" <<EOF
foreach(t llbuild llbuildSwift)
  if(NOT TARGET \${t})
    add_library(\${t} INTERFACE IMPORTED)
    set_target_properties(\${t} PROPERTIES
      INTERFACE_COMPILE_OPTIONS "-F$B/fw"
      INTERFACE_LINK_OPTIONS "-F$B/fw")
  endif()
endforeach()
EOF

mkdir -p "$B/fw-install"
sh "$(dirname "$0")/make-framework.sh" "$A/llbuild" \
    "$B/fw-install/llbuild.framework" com.apple.dt.llbuild 1.0 $VERSION \
    llbuild $BUILDVERSION
