#!/bin/sh
#
# Build dyld_info and dyld_analyzer with xcodebuild, from the patched copy
# of src/apple/dyld that mk/port.mk makes.
#
# Both are built the way Apple build them into the toolchain: as part of
# the ld project (RC_ProjectName=ld), against the internal SDK this tree
# assembles, reporting ld's version.  Each gets its own xcconfig, because
# they differ in what they link: dyld_info disassembles through libLTO and
# needs llvm-c's headers to do it, while Apple's dyld_analyzer links
# nothing but libc++ and libSystem.  An -xcconfig is used rather than
# settings on the command line so that $(inherited) keeps the project's
# own flags.
#
# Usage: build-dyld-tools.sh <top> <workdir>
#
# Copyright (c) 2026 Sunneva N. Mariu <sunnevanattsol@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause
#
set -e

if [ $# -ne 2 ]; then
	echo "usage: $0 <top> <workdir>" >&2
	exit 1
fi

TOP=$1
WORK=$2
SDK=${TOP}/build/release/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.Internal.sdk
TCLIB=${TOP}/build/release/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib
LLVM=${TOP}/src/swiftlang-llvm/llvm-project/llvm
LLVM_BUILD=${TOP}/build/ports/llvm/build

# ld's version in the Xcode this tree tracks: Apple's dyld_info and
# dyld_analyzer print it for -v, from RC_ProjectSourceVersion.
LD_VERSION=1267

for f in "${SDK}/usr/local/include/libc_private.h" "${TCLIB}/libLTO.dylib"; do
	if [ ! -e "$f" ]; then
		echo "$0: ${f} is missing -- build the SDK and the llvm port first" >&2
		exit 1
	fi
done

# DYLD_EXCLAVEKIT_UNAVAILABLE annotates dyld's own mach-o/dyld.h and is
# defined by nothing in the source release; Apple's internal SDK supplies
# it.  Empty, as the installed header defines it.
cat > "${WORK}/dyld_analyzer.xcconfig" <<'EOF'
OTHER_CFLAGS = $(inherited) -DDYLD_EXCLAVEKIT_UNAVAILABLE=
EOF
cat > "${WORK}/dyld_info.xcconfig" <<EOF
OTHER_CFLAGS = \$(inherited) -DDYLD_EXCLAVEKIT_UNAVAILABLE=
SYSTEM_HEADER_SEARCH_PATHS = \$(inherited) ${LLVM}/include ${LLVM_BUILD}/include
LIBRARY_SEARCH_PATHS = ${TCLIB} \$(inherited)
OTHER_LDFLAGS = \$(inherited) -lLTO
EOF

cd "${WORK}/src"
for t in dyld_info dyld_analyzer; do
	xcodebuild -project dyld.xcodeproj -target "$t" -configuration Release \
	    -xcconfig "${WORK}/${t}.xcconfig" \
	    SDKROOT="${SDK}" \
	    RC_ProjectName=ld \
	    RC_ProjectSourceVersion=${LD_VERSION} \
	    ARCHS="$(uname -m)" \
	    SYMROOT="${WORK}/sym" OBJROOT="${WORK}/obj" \
	    CODE_SIGNING_ALLOWED=NO \
	    GCC_TREAT_WARNINGS_AS_ERRORS=NO \
	    build
done
