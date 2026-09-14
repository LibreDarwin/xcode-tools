# swift-build -- SwiftBuild.framework, the build system swift-package runs,
# as Xcode's SharedFrameworks carry it.
#
# CMake builds the libraries, the build service and swbuild from a patched
# copy; mk/scripts/assemble-swiftbuild.sh makes the frameworks and bundles
# Xcode has of them.  The patches (mk/patches/swift-build) are the
# differences between a CMake build and Xcode's:
#
#   0001  the platforms load as plugin bundles, as Xcode's do, rather than
#         being linked into the service
#   0002  a module finds its resources in its own framework, which is
#         where Xcode's keep them
#   0003  SwiftBuild and SWBProjectModel are built with library evolution,
#         and only they are
#   0004  and with Xcode's module ABI names, XCBuild and XCBProjectModel,
#         which is what swift-package's references to them are mangled with
#
# Built against the ports before it: llbuild.framework (with
# LLBUILD_FRAMEWORK, which is what makes SWBLLBuild import it rather than
# llbuildSwift), libSwiftDriver.dylib weakly, the tools-protocols
# frameworks, and swift-system, the argument parser and
# libSwiftToolsSupport.  LLVM's headers -- the source's and the build's,
# which has llvm-config.h -- and libRemarks.dylib are what the
# optimization-remarks support compiles against; Xcode's frameworks link
# libRemarks weakly and Xcode ships none, so neither is installed.
# Unused libraries are dead-stripped from the link, as Xcode's are.  The
# link flags are spelled -Xlinker for C as well as Swift: CMake hands the
# shared linker flags to swiftc too, which does not take -Wl, and clang
# takes both.
.include "${TOP}/mk/with-swift-cmake.mk"

SWB_PATCHES!=	ls ${TOP}/mk/patches/swift-build/*.patch 2>/dev/null || true
SWB_PORTS=	${TOP}/build/ports
SWB_LLBUILD_FW=	${SWB_PORTS}/llbuild/build/fw
SWB_LLVM_INCLUDE=	-I${TOP}/src/swiftlang-llvm/llvm-project/llvm/include \
			-I${SWB_PORTS}/llvm/build/include
SWB_REMARKS=	${SWB_PORTS}/llvm/build/lib/libRemarks.dylib
SWB_LDFLAGS=	-headerpad_max_install_names -current_version 24900.0.3 \
		-dead_strip_dylibs -weak_library ${SWB_REMARKS}

P_COPY=		yes
P_PREPARE=	for p in ${SWB_PATCHES}; do patch -s -p1 < $$p || exit 1; done
P_BUILDSYS=	cmake
P_CMAKE_SRC=	.
P_OBJDIR=	${P_WORKDIR}/build
P_NOSTAGE=	yes
P_CONFIGURE_ARGS=	${SWIFT_CMAKE_ARGS} \
	-DBUILD_SHARED_LIBS=YES \
	-DSwiftBuild_USE_LLBUILD_FRAMEWORK=YES \
	-DArgumentParser_DIR=${SWB_PORTS}/swift-argument-parser/build/cmake/modules \
	-DLLBuild_DIR=${SWB_LLBUILD_FW} \
	-DSwiftDriver_DIR=${SWB_PORTS}/swift-driver/build/swiftdriver-dylib \
	-DSwiftToolsProtocols_DIR=${SWB_PORTS}/swift-tools-protocols/build/cmake/modules \
	-DSwiftSystem_DIR=${SWB_PORTS}/swift-system/build/cmake/modules \
	-DTSC_DIR=${SWB_PORTS}/swift-tools-support-core/build/tsc-dylib \
	'-DCMAKE_C_FLAGS=${SWB_LLVM_INCLUDE}' \
	'-DCMAKE_CXX_FLAGS=${SWB_LLVM_INCLUDE}' \
	'-DCMAKE_SHARED_LINKER_FLAGS=${SWB_LDFLAGS:S/^/-Xlinker /}' \
	'-DCMAKE_Swift_FLAGS=-F ${SWB_LLBUILD_FW} -DLLBUILD_FRAMEWORK ${SWB_LLVM_INCLUDE} ${SWB_LDFLAGS:S/^/-Xlinker /}'
P_POST_BUILD=	sh ${TOP}/mk/scripts/assemble-swiftbuild.sh ${P_OBJDIR} \
		    ${P_BUILDSRC} fw-install ${SWIFTC_BIN} ${MACOS_SDK} \
		    ${SWB_LLBUILD_FW} \
		    ${SWB_PORTS}/swift-driver/build/swift \
		    ${SWB_PORTS}/swift-tools-support-core/build/swift \
		    ${SWB_PORTS}/swift-system/build/swift \
		    ${SWB_PORTS}/swift-argument-parser/build/swift \
		    ${SWB_LLVM_INCLUDE:S/^-I//}
P_PROGS=
P_FRAMEWORKS=	fw-install/SwiftBuild.framework
