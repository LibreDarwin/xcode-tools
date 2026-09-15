# swift-package-manager -- swift-package, which Xcode's toolchain also
# carries as swift-build, swift-test, swift-run, swift-sdk,
# swift-experimental-sdk, swift-package-collection and
# swift-package-registry (links, in mk/bundle.mk), and the libraries a
# manifest or a plugin is built against, lib/swift/pm.
#
# Xcode's swift-package is SwiftPM's multi-call binary, one program for
# every command, with the libraries it is made of linked in statically.
# The patches (mk/patches/swift-package-manager) are what CMake needs to
# build it that way:
#
#   0001  the swift-package-manager executable, and the
#         PackageCollectionsCommand library it links, which CMake has no
#         target for, linked as Xcode's is
#   0002  static, an exported library brings the static libraries it links
#         into the export set with it
#
# The manifest and plugin libraries are not taken from CMake, which builds
# them one architecture at a time, as three libraries, with other flags
# than Apple's; mk/scripts/build-spm-runtime.sh builds them as Apple's are.
#
# Built against the ports before it: llbuild.framework,
# libSwiftDriver.dylib, libSwiftToolsSupport, SwiftBuild.framework and the
# tools-protocols frameworks, and swift-syntax from its checkout.  LLVM's
# headers and the ArgumentParserInternal modules the swift-build port makes
# are there for SwiftBuild's modules, which import both.
.include "${TOP}/mk/with-swift-cmake.mk"

SPM_PATCHES!=	ls ${TOP}/mk/patches/swift-package-manager/*.patch 2>/dev/null || true
SPM_PORTS=	${TOP}/build/ports
SPM_LLVM_INCLUDE=	-I${TOP}/src/swiftlang-llvm/llvm-project/llvm/include \
			-I${SPM_PORTS}/llvm/build/include

# Xcode's run paths for swift-package, in Xcode's order.
SPM_RPATHS=	/usr/lib/swift \
		@executable_path/../../../../../SharedFrameworks \
		@executable_path/../../../../../SharedFrameworks/SwiftBuild.framework/Versions/A/PlugIns/SWBBuildService.bundle/Contents/Frameworks \
		@executable_path/../../../../../SharedFrameworks/SwiftBuild.framework/Versions/A/PlugIns/SWBBuildSystem.bundle/Contents/Frameworks \
		@executable_path/../../../../../Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib \
		@executable_path/../../../../../Developer/Toolchains/XcodeDefault.xctoolchain/usr/local/include/SwiftToolsSupport \
		@executable_path/../lib/swift/pm \
		@executable_path/../lib/swift/pm/SwiftBuild.framework/PlugIns/SWBBuildService.bundle/Contents/Frameworks \
		@executable_path/../lib/swift/pm/llbuild \
		@executable_path/../lib \
		@executable_path/../

P_COPY=		yes
P_PREPARE=	for p in ${SPM_PATCHES}; do patch -s -p1 < $$p || exit 1; done
P_BUILDSYS=	cmake
P_CMAKE_SRC=	.
P_OBJDIR=	${P_WORKDIR}/build
P_NOSTAGE=	yes
P_MAKE_ARGS=	swift-package-manager
P_CONFIGURE_ARGS=	${SWIFT_CMAKE_ARGS} \
	-DBUILD_SHARED_LIBS=NO \
	-DSwiftPM_ENABLE_RUNTIME=NO \
	-DCMAKE_POLICY_DEFAULT_CMP0195=NEW \
	-DArgumentParser_DIR=${SPM_PORTS}/swift-argument-parser/build/cmake/modules \
	-DLLBuild_DIR=${SPM_PORTS}/llbuild/build/fw \
	-DSwiftDriver_DIR=${SPM_PORTS}/swift-driver/build/swiftdriver-dylib-strong \
	-DTSC_DIR=${SPM_PORTS}/swift-tools-support-core/build/tsc-dylib \
	-DSwiftSystem_DIR=${SPM_PORTS}/swift-system/build/cmake/modules \
	-DSwiftCollections_DIR=${SPM_PORTS}/swift-collections/build/cmake/modules \
	-DSwiftASN1_DIR=${SPM_PORTS}/swift-asn1/build/cmake/modules \
	-DSwiftCrypto_DIR=${SPM_PORTS}/swift-crypto/build/cmake/modules \
	-DSwiftCertificates_DIR=${SPM_PORTS}/swift-certificates/build/cmake/modules \
	-DSwiftToolsProtocols_DIR=${SPM_PORTS}/swift-tools-protocols/build/cmake/modules \
	-DSwiftBuild_DIR=${SPM_PORTS}/swift-build/build/cmake/modules \
	-DSWIFTPM_PATH_TO_SWIFT_SYNTAX_SOURCE=${TOP}/src/swiftlang-llvm/swift-syntax \
	'-DCMAKE_Swift_FLAGS=-F ${SPM_PORTS}/llbuild/build/fw ${SPM_LLVM_INCLUDE} -I${SPM_PORTS}/swift-build/argumentparserinternal/modules'
P_POST_BUILD=	cp bin/swift-package-manager bin/swift-package && \
		sh ${TOP}/mk/scripts/set-rpaths.sh bin/swift-package ${SPM_RPATHS} && \
		sh ${TOP}/mk/scripts/build-spm-runtime.sh ${SWIFTC_BIN} \
		    ${MACOS_SDK} ${P_BUILDSRC} runtime lib/swift/pm
P_PROGS=	bin/swift-package
P_TREES=	lib/swift/pm
