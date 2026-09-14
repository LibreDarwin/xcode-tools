# llbuild -- swift-build-tool, the low-level build engine SwiftPM drives,
# and llbuild.framework.
#
# Plain C++ with CMake, carrying its own copy of LLVM's Support library,
# so swift-build-tool needs neither this tree's LLVM nor a Swift compiler.
# Static, and with no tests: Apple's swift-build-tool links no llbuild
# library, only libncurses, libsqlite3, libc++ and libSystem, and those
# four it takes from the SDK exactly as theirs does.
#
# The version in parentheses is not something CMake sets.  Apple's build
# passes it as LLBUILD_VERSION_STRING; this is the one Xcode's prints.
#
# llbuild.framework is what swift-driver and swift-package load: the C API
# and the Swift bindings in one library, the bindings compiled as module
# llbuild over the framework's clang module rather than as llbuildSwift.
# CMake has no target of that shape, so it builds the static libraries and
# mk/scripts/build-llbuild-framework.sh links the framework from them.  It
# installs into SharedFrameworks, as Xcode's does; the copy with Headers
# and Modules stays in the build directory for swift-driver and SwiftPM to
# build against.
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
P_MAKE_ARGS=	swift-build-tool llbuild llbuildBuildSystem llbuildCore \
		llbuildBasic llbuildNinja llvmSupport llvmDemangle
P_POST_BUILD=	sh ${TOP}/mk/scripts/build-llbuild-framework.sh \
		    ${SWIFTC_BIN} ${MACOS_SDK} ${P_SRCDIR} ${P_OBJDIR}
P_PROGS=	bin/swift-build-tool
P_FRAMEWORKS=	fw-install/llbuild.framework
