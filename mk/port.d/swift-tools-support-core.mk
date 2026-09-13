# swift-tools-support-core -- libSwiftToolsSupport.dylib, which
# swift-driver and swift-help link.
#
# CMake builds TSCBasic and TSCUtility as libraries of their own, where
# Apple's toolchain carries SwiftPM's product: one dylib holding both.  So
# the static libraries are built and then linked into that dylib, and
# swift-driver's CMake is given a TSCConfig of ours that names it --
# see mk/scripts/link-swifttoolssupport.sh.
.include "${TOP}/mk/with-swift-cmake.mk"

P_BUILDSYS=	cmake
P_CMAKE_SRC=	.
P_OBJDIR=	${P_WORKDIR}/build
P_NOSTAGE=	yes
P_CONFIGURE_ARGS=	${SWIFT_CMAKE_ARGS} \
	-DBUILD_SHARED_LIBS=NO \
	-DBUILD_TESTING=OFF
P_POST_BUILD=	sh ${TOP}/mk/scripts/link-swifttoolssupport.sh \
		    ${SWIFTC_BIN} ${MACOS_SDK} ${P_OBJDIR}
P_PROGS=
P_LIBS=		libSwiftToolsSupport.dylib
