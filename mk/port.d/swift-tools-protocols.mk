# swift-tools-protocols -- the Language Server and Build Server Protocol
# frameworks SwiftBuild and swift-package load from SharedFrameworks.
#
# Five of them, as Xcode ships: LanguageServerProtocol,
# BuildServerProtocol, LanguageServerProtocolTransport, SKLogging and
# ToolsProtocolsSwiftExtensions.  CMake builds them as dylibs;
# mk/scripts/frameworkize.sh gives them their framework names and lays
# them out.  Built with library evolution, as Xcode's are -- theirs carry
# the dispatch thunks and descriptors only a resilient build exports --
# and at 0.0.9, which is the API theirs have.
#
# The version numbers are Xcode's: the libraries' current version is
# 6.3.0, and the bundles are 6.3.0.10 of the SourceKitLSPFrameworks
# project, build 17, which is an alias of SourceKitLSP.
.include "${TOP}/mk/with-swift-cmake.mk"

STP_FRAMEWORKS=	ToolsProtocolsSwiftExtensions SKLogging \
		LanguageServerProtocol BuildServerProtocol \
		LanguageServerProtocolTransport

P_BUILDSYS=	cmake
P_CMAKE_SRC=	.
P_OBJDIR=	${P_WORKDIR}/build
P_NOSTAGE=	yes
# Everything goes in the Swift flags: CMake compiles and links a Swift
# library in one swiftc invocation and gives it neither the deployment
# target nor CMAKE_SHARED_LINKER_FLAGS, so without these the libraries
# come out for macOS 26 at current version 0.0.0.
P_CONFIGURE_ARGS=	${SWIFT_CMAKE_ARGS} \
	-DBUILD_SHARED_LIBS=YES \
	'-DCMAKE_Swift_FLAGS=-enable-library-evolution -target arm64-apple-macosx14.0 -Xlinker -headerpad_max_install_names -Xlinker -current_version -Xlinker 6.3.0'
P_MAKE_ARGS=	${STP_FRAMEWORKS}
P_POST_BUILD=	BUILD_ALIAS_OF=SourceKitLSP \
		sh ${TOP}/mk/scripts/frameworkize.sh lib fw-install com.apple.dt \
		    1.0 6.3.0.10 SourceKitLSPFrameworks 17 ${STP_FRAMEWORKS}
P_PROGS=
P_FRAMEWORKS=	${STP_FRAMEWORKS:S|^|fw-install/|:S|$|.framework|}
