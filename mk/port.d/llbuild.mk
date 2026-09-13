# llbuild -- swift-build-tool, the low-level build engine SwiftPM drives.
#
# Plain C++ with CMake, carrying its own copy of LLVM's Support library,
# so it needs neither this tree's LLVM nor a Swift compiler.  Static, and
# with no tests: Apple's swift-build-tool links no llbuild library, only
# libncurses, libsqlite3, libc++ and libSystem, and those four it takes
# from the SDK exactly as theirs does.
#
# The version in parentheses is not something CMake sets.  Apple's build
# passes it as LLBUILD_VERSION_STRING; this is the one Xcode's prints.
#
# The Swift bindings are built too, and not installed: swift-driver links
# llbuildSwift statically, as Apple's does, and finds it through the
# LLBuildConfig.cmake this build writes.
.include "${TOP}/mk/with-swift-cmake.mk"

P_BUILDSYS=	cmake
P_CMAKE_SRC=	.
P_OBJDIR=	${P_WORKDIR}/build
P_NOSTAGE=	yes
P_CONFIGURE_ARGS=	${SWIFT_CMAKE_ARGS} \
	-DBUILD_SHARED_LIBS=OFF \
	-DBUILD_TESTING=OFF \
	-DLLBUILD_SUPPORT_BINDINGS=Swift \
	'-DCMAKE_CXX_FLAGS=-DLLBUILD_VERSION_STRING=\"llbuild-24700.0.19\"'
P_MAKE_ARGS=	swift-build-tool llbuildSwift
P_PROGS=	bin/swift-build-tool
