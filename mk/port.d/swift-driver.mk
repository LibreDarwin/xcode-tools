# swift-driver -- the Swift compiler driver, and swift-help.
#
# swiftc hands a compile to swift-driver when it finds one beside it;
# without it, it falls back to the legacy C++ driver and says so.  Built
# with CMake against the ports before it: the argument parser statically,
# as Apple's is; libSwiftToolsSupport.dylib dynamically, through the
# TSCConfig that port writes; and llbuild.framework dynamically, through
# the LLBuildConfig mk/scripts/build-llbuild-framework.sh writes -- Apple's
# swift-driver loads llbuild.framework from SharedFrameworks and imports
# its Swift module, llbuild, where a CMake build links llbuildSwift in.
#
# From a copy, for the version.  Apple's prints "swift-driver version:
# 1.148.6"; the source reads SWIFT_DRIVER_VERSION, which only Apple's
# build defines, so the copy gets a definition and the compile the
# condition that uses it.
#
# The run paths are rewritten to Apple's: CMake's point into the build
# tree, and the binaries have to find libSwiftToolsSupport.dylib in
# ../lib once installed.
.include "${TOP}/mk/with-swift-cmake.mk"

SWIFT_DRIVER_VERSION=	1.148.6

P_COPY=		yes
P_PREPARE=	printf '\nlet SWIFT_DRIVER_VERSION = "%s"\n' ${SWIFT_DRIVER_VERSION} \
		    >> Sources/SwiftDriver/Driver/DriverVersion.swift
P_BUILDSYS=	cmake
P_CMAKE_SRC=	.
P_OBJDIR=	${P_WORKDIR}/build
P_NOSTAGE=	yes
P_CONFIGURE_ARGS=	${SWIFT_CMAKE_ARGS} \
	-DBUILD_SHARED_LIBS=NO \
	-DCMAKE_Swift_FLAGS=-DSWIFT_DRIVER_VERSION_DEFINED \
	-DArgumentParser_DIR=${TOP}/build/ports/swift-argument-parser/build/cmake/modules \
	-DTSC_DIR=${TOP}/build/ports/swift-tools-support-core/build/tsc-dylib \
	-DLLBuild_DIR=${TOP}/build/ports/llbuild/build/fw
P_MAKE_ARGS=	swift-driver swift-help
P_POST_BUILD=	sh ${TOP}/mk/scripts/set-rpaths.sh bin/swift-driver \
		    /usr/lib/swift @executable_path/../lib \
		    @executable_path/../../../../../SharedFrameworks \
		    @executable_path/../lib/swift/pm/llbuild && \
		sh ${TOP}/mk/scripts/set-rpaths.sh bin/swift-help \
		    /usr/lib/swift @executable_path/../lib
P_PROGS=	bin/swift-driver bin/swift-help
