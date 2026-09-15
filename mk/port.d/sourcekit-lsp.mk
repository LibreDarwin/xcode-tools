# sourcekit-lsp -- the language server, built as Apple's is: with SwiftPM,
# from the checkouts beside it, with SwiftPM, swift-docc, indexstore-db and
# the rest linked in statically.  Apple's build does the same from a
# dependencies/ directory; the names its manifest expects are laid out as
# links next to the copy of the source (see P_BUILDSYS=swiftpm in
# mk/port.mk), including the three whose checkouts here are named
# differently: swiftpm, llbuild and cmark.
#
# Stripped, with only /usr/lib/swift as a run path, which is what Xcode's
# carries.
#
# And the two plugins sourcekitd loads for it, libSwiftSourceKitPlugin
# into the service and libSwiftSourceKitClientPlugin into the client:
# code completion goes through them, and without them sourcekit-lsp
# answers hover and diagnostics and completes nothing.  sourcekit-lsp
# looks for them in usr/lib as dylibs before it looks for frameworks, and
# Xcode's dylibs are what these match -- two exported entry points, 6.3.0,
# Xcode's install name and run path.  Xcode's SwiftSourceKitPlugin and
# SwiftSourceKitClientPlugin frameworks are another build, from Xcode's own
# SwiftSourceKitExtensions project, and are not made here.
.include "${TOP}/mk/with-swift-cmake.mk"

SKLSP_PLUGIN_ARGS=	-Xlinker -exported_symbol -Xlinker _sourcekitd_plugin_initialize \
			-Xlinker -exported_symbol -Xlinker _sourcekitd_plugin_initialize_2 \
			-Xlinker -current_version -Xlinker 6.3.0 \
			-Xlinker -compatibility_version -Xlinker 1.0.0 \
			-Xlinker -headerpad_max_install_names
SKLSP_LIBDIR=	/Applications/Xcode.app/Contents/Developer/${XCTOOLCHAIN}/usr/lib

P_BUILDSYS=	swiftpm
P_SWIFTPM_PRODUCT=	sourcekit-lsp SwiftSourceKitPlugin SwiftSourceKitClientPlugin
P_SWIFTPM_ARGS.SwiftSourceKitPlugin=	${SKLSP_PLUGIN_ARGS}
P_SWIFTPM_ARGS.SwiftSourceKitClientPlugin=	${SKLSP_PLUGIN_ARGS}
P_SWIFTPM_DEPS=	cmark swiftlang-llvm/swift-cmark \
		indexstore-db swiftlang-llvm/indexstore-db \
		llbuild swiftlang-llvm/swift-llbuild \
		swift-argument-parser swiftlang-llvm/swift-argument-parser \
		swift-asn1 swiftlang-llvm/swift-asn1 \
		swift-atomics swiftlang-llvm/swift-atomics \
		swift-build swiftlang-llvm/swift-build \
		swift-certificates swiftlang-llvm/swift-certificates \
		swift-collections swiftlang-llvm/swift-collections \
		swift-crypto swiftlang-llvm/swift-crypto \
		swift-docc swiftlang-llvm/swift-docc \
		swift-docc-symbolkit swiftlang-llvm/swift-docc-symbolkit \
		swift-driver swiftlang-llvm/swift-driver \
		swift-lmdb swiftlang-llvm/swift-lmdb \
		swift-markdown swiftlang-llvm/swift-markdown \
		swift-nio swiftlang-llvm/swift-nio \
		swift-syntax swiftlang-llvm/swift-syntax \
		swift-system swiftlang-llvm/swift-system \
		swift-toolchain-sqlite swiftlang-llvm/swift-toolchain-sqlite \
		swift-tools-protocols swiftlang-llvm/swift-tools-protocols \
		swift-tools-support-core swiftlang-llvm/swift-tools-support-core \
		swiftpm swiftlang-llvm/swift-package-manager
P_POST_BUILD=	strip sourcekit-lsp && \
		sh ${TOP}/mk/scripts/set-rpaths.sh sourcekit-lsp /usr/lib/swift && \
		for p in SwiftSourceKitPlugin SwiftSourceKitClientPlugin; do \
			strip -x lib$$p.dylib && \
			install_name_tool -id ${SKLSP_LIBDIR}/lib$$p.dylib lib$$p.dylib && \
			sh ${TOP}/mk/scripts/set-rpaths.sh lib$$p.dylib /usr/lib/swift || \
			exit 1; \
		done
P_PROGS=	sourcekit-lsp
P_LIBS=		libSwiftSourceKitPlugin.dylib libSwiftSourceKitClientPlugin.dylib
